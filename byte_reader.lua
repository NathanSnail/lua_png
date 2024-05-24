local M = {}
local ffi = require("ffi")

---@class byte_array
---@field data integer[]
---@field get fun(self: byte_array, index: integer): integer
---@field set fun(self: byte_array, index: integer, value: integer)
---@field push fun(self: byte_array, value: integer)
---@field concat_push fun(self: byte_array, other: byte_array)

---@class byte_reader
---@field read_be fun(self: byte_reader, count: integer): integer
---@field mem_eq fun(self: byte_reader, other: ffi.cdata*, count: integer): boolean
---@field read_str fun(self: byte_reader, count: integer): string
---@field skip fun(self: byte_reader, count: integer)
---@field read_hex fun(self: byte_reader, count: integer): string
---@field read_array fun(self: byte_reader, count: integer): byte_array
---@field data ffi.cdata*

---@param self byte_reader
---@param count integer
local function skip(self, count)
	self.data = self.data + ffi.cast("int", count)
end

---@param self byte_reader
---@param count integer
---@return integer
local function read_be(self, count)
	local v = 0
	for i = 0, count - 1 do
		v = v * 0x100
		v = v + self.data[i]
	end
	self:skip(count)
	return v
end

---@param self byte_reader
---@param count integer
---@return string
local function read_hex(self, count)
	local out = ""
	for i = 0, count - 1 do
		local cur = string.format("%x", self.data[i])
		if cur:len() == 1 then
			cur = "0" .. cur
		end
		out = out .. cur
	end
	self:skip(count)
	return out
end

---@param self byte_reader
---@param other ffi.cdata*
---@param count integer
---@return boolean
local function mem_eq(self, other, count)
	local data = self.data
	self:skip(count)
	for i = 0, count - 1 do
		if data[i] ~= other[i] then
			return false
		end
	end
	return true
end

---@param self byte_reader
---@param count integer
---@return string
local function read_str(self, count)
	local out = ""
	for i = 0, count - 1 do
		local char = string.char(self.data[i])
		out = out .. char
	end
	self:skip(count)
	return out
end

---@param self byte_reader
---@param count integer
---@return byte_array
local function read_array(self, count)
	local arr = M.new_byte_array()
	for _ = 1, count do
		arr:push(self:read_be(1))
	end
	return arr
end

---@param data ffi.cdata*
---@return byte_reader
function M.new_byte_reader(data)
	---@type byte_reader
	local byte_reader = {
		read_be = read_be,
		read_str = read_str,
		mem_eq = mem_eq,
		data = data,
		skip = skip,
		read_hex = read_hex,
		read_array = read_array,
	}
	return byte_reader
end

---@param data integer[]?
---@return byte_array
function M.new_byte_array(data)
	data = data or {}
	---@type byte_array
	local array = {
		data = data,
		get = function(self, index)
			return self.data[index + 1]
		end,
		set = function(self, index, value)
			self.data[index + 1] = value
		end,
		push = function(self, value)
			self.data[#self.data + 1] = value
		end,
		concat_push = function(self, other)
			for _, v in ipairs(other.data) do
				self:push(v)
			end
		end,
	}
	return array
end

return M
