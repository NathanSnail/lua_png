local ffi = require("ffi")

local M = {}

---@param data integer
---@param start integer
---@param stop integer
---@return integer
local function get_bits(data, start, stop)
	local mask = 0
	for i = start, stop do
		mask = mask + math.pow(2, i)
	end
	return bit.rshift(bit.band(data, mask), start)
end

---@param data byte_reader
---@param size integer
---@return byte_reader
function M.decompress(data, size)
	local last = ffi.cast("int", data.data) + size
	local compression_data = data:read_be(1)
	local compression_method = get_bits(compression_data, 0, 3)
	local compression_info = get_bits(compression_data, 4, 7)
	if compression_info == 15 then
		error("reserved compression info used")
	end
	local compression_window = math.pow(2, compression_info + 8)
	print(compression_window)
	if compression_method ~= 8 then
		error("not deflate compressed")
	end

	local extra_flags = data:read_be(1)
	-- local flag_check = get_bits(extra_flags, 0, 4)
	-- this is only used to make sure the data isn't corrupted.
	local flag_dict = get_bits(extra_flags, 5, 5)
	local dict_id
	if flag_dict == 1 then
		dict_id = data:read_be(4)
	end
	local compression_level = get_bits(extra_flags, 6, 7)
	if compression_level > 3 then
		error("invalid compression level")
	end
	if (compression_data * 0x100 + extra_flags) % 31 ~= 0 then
		-- given this is %31, aren't we wasting data? there are 32 states.
		-- given %32 doesn't work i assume the alternatives are more complicated.
		-- regardless, i don't really like this checksum method.
		error("corrupted zlib header, flag check broken")
	end
	print(flag_dict, compression_level)
end

return M
