local ffi = require("ffi")
local bit_lib = require("bits")

---Different to byte_reader because this thing is slower and generally more jank.
---@class bit_reader
---@field data ffi.cdata*
---@field shift integer
---@field read_bits fun(self: bit_reader, count: integer): bit_array
---@field skip fun(self: bit_reader, count: integer)

---@param self bit_reader
---@param count integer
---@return bit_array
local function read_bits(self, count)
	local out = {}
	for _ = 1, count do
		local byte = self.data[0]
		local bit = bit_lib.get_bits(byte, self.shift, self.shift)
		out[#out + 1] = bit == 1
		self:skip(1)
	end
	return bit_lib.construct_bit_array(out)
end

---@param self bit_reader
---@param count integer
local function skip(self, count)
	self.shift = self.shift + count
	self.data = self.data + ffi.cast("int", math.floor(self.shift / 8))
	self.shift = self.shift % 8
end

---@param ptr ffi.cdata*
---@param shift integer?
---@return bit_reader
local create_bit_reader = function(ptr, shift)
	shift = shift or 0
	ptr = ptr + ffi.cast("int", math.floor(shift / 8))
	shift = shift % 8
	return { data = ptr, shift = shift, read_bits = read_bits, skip = skip }
end

return create_bit_reader
