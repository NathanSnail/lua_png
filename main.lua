local ffi = require("ffi")
local make_reader = require("byte_reader").new_byte_reader
local handlers = require("chunk_handlers")

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

---@param data byte_reader
---@param max integer
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
end

local content = assert(assert(io.open("test.png", "rb")):read("*a"))
local png = make_reader(ffi.cast("unsigned char*", content))
get_chunks(png, content:len())
