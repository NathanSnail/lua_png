local ffi = require("ffi")
local huffman = require("huffman")
local t = {data={[0] = {data = "A"}, [1] = {data = {[0] = {data = "B"}, [1] = {data = "C"}}}}}
print(huffman.traverse_huffman(t, {data = {1,0}}))
print(huffman.traverse_huffman(t, {data = {0}}))
print(huffman.traverse_huffman(t, {data = {1,1}}))
local make_reader = require("byte_reader").new_byte_reader
local handlers = require("chunk_handlers")
local compression = require("compression")

---@param data byte_reader
---@param chunk_values handler_result[]
local function do_chunk(data, chunk_values)
	local length = data:read_be(4)
	local chunk_type = data:read_str(4)
	local first = chunk_type:sub(1, 1)
	local optional = first:lower() == first
	local chunk_data = make_reader(data.data)
	data:skip(length)
	local crc = data:read_be(4)
	-- TODO: error if crc is wrong
	--print(length, chunk_type, optional, crc)
	if handlers[chunk_type] then
		table.insert(chunk_values, { type = chunk_type, data = handlers[chunk_type](chunk_data, length, chunk_values) })
	else
		if optional then
			print("WARN: unknown optional header " .. chunk_type)
		else
			print("ERR: unknown mandatory header " .. chunk_type)
		end
	end
end

---@param chunk_handlers handler_result[]
---@return byte_reader data
local function get_data_stream(chunk_handlers)
	local data_stream = {}
	local ptr = 0
	for k, v in ipairs(chunk_handlers) do
		if v.type == "IDAT" then
			for i = 0, #v.data.bytes do
				ptr = ptr + 1
				data_stream[ptr] = v.data.bytes[i]
			end
		end
	end
	return make_reader(ffi.new("unsigned char[?]", #data_stream, data_stream)), ptr
end

---@param data byte_reader
---@param max integer
---@return handler_result[]
local function get_chunks(data, max)
	local chunk_values = {}
	local start = ffi.cast("int", data.data)
	local header = { 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A }
	if not data:mem_eq(ffi.new("unsigned char[?]", #header, header), 8) then
		error("invalid png")
	end
	while ffi.cast("int", data.data) - start < max do
		do_chunk(data, chunk_values)
	end
	return chunk_values
end

local content = assert(assert(io.open("test.png", "rb")):read("*a"))
local png = make_reader(ffi.cast("unsigned char*", content))
local chunk_values = get_chunks(png, content:len())
local data_stream, size = get_data_stream(chunk_values)
local decompressed = compression.decompress(data_stream, size)
