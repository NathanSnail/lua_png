local M = {}

---@param data integer
---@param start integer
---@param stop integer
---@return integer
function M.get_bits(data, start, stop)
	local mask = 0
	for i = start, stop do
		mask = mask + math.pow(2, i)
	end
	return bit.rshift(bit.band(data, mask), start)
end

---@class bit_array
---@field data boolean[]
---@field get fun(self: bit_array, index: integer): boolean?
---@field set fun(self: bit_array, index: integer, value: boolean)
---@field len fun(self: bit_array): integer
---@field eqi fun(self: bit_array, other: integer): boolean
---@field eq fun(self: bit_array, other: bit_array): boolean
---@field dump fun(self: bit_array): string
---@field be fun(self: bit_array): integer

---@param data boolean[]
---@return bit_array
function M.construct_bit_array(data)
	---@type bit_array
	local v = {
		data = data,
		get = function(self, index)
			return self.data[index + 1]
		end,
		set = function(self, index, value)
			self.data[index + 1] = value
		end,
		len = function(self)
			return #self.data
		end,
		eqi = function(self, other)
			local other_arr = {}
			while other ~= 0 do
				local b = bit.band(other, 0x01)
				other_arr[#other_arr + 1] = b == 1
				other = bit.rshift(other, 1)
			end
			local other_bits = M.construct_bit_array(other_arr)
			return self:eq(other_bits)
		end,
		eq = function(self, other)
			if #self.data ~= #other.data then
				return false
			end
			for k, v in ipairs(self.data) do
				if other.data[k] ~= v then
					return false
				end
			end
			return true
		end,
		dump = function(self)
			local o = ""
			for _, v in ipairs(self.data) do
				o = o .. (v and 1 or 0)
			end
			return o
		end,
		be = function (self)
			local v = 0
			for _, b in ipairs(self.data) do
				v = v * 2
				v = v + b
			end
			return v
		end
	}
	return v
end

return M
