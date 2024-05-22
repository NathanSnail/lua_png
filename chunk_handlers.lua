local ffi = require("ffi")

---@class handler_result
---@field type string
---@field data table<string, any>

---@alias handler_fn fun(reader: byte_reader, length: integer, chunk_handlers: handler_result[]): table<string, any>

---@param chunk_handlers handler_result[]
---@param to_locate string
---@return handler_result
local function locate_chunk(chunk_handlers, to_locate)
	for _, v in ipairs(chunk_handlers) do
		if v.type == to_locate then
			return v
		end
	end
	error("could not find requested chunk " .. to_locate)
end

---@enum
local PALLETE_TYPE = {
	true_colour = 2,
	indexed_colour = 3,
}

---@type table<string, handler_fn>
local M = {
	IHDR = function(reader, length, chunk_handlers)
		local width, height = reader:read_be(4), reader:read_be(4)
		local depth = reader:read_be(1)
		local pow = math.log(depth, 2)
		if math.abs(math.floor(pow + 0.5) - pow) > 0.000000001 or depth > 16 then
			error("invalid bit depth")
		end
		local colour_type = reader:read_be(1)
		if colour_type > 6 or colour_type == 1 or colour_type == 5 then
			error("invalid colour type")
		end
		local filter_method = reader:read_be(1)
		if filter_method ~= 0 then
			error("invalid filter method")
		end
		local interlace_method = reader:read_be(1)
		if interlace_method > 1 then
			error("invalid interlace method")
		end
		return {
			width = width,
			height = height,
			depth = depth,
			colour_type = colour_type,
			interlaced = interlace_method == 1,
		}
	end,
	tRNS = function(reader, length, chunk_handlers)
		local IDHR = locate_chunk(chunk_handlers, "IHDR")
		---@type integer
		local colour_type = IDHR.data.colour_type
		local data = {}
		if colour_type == PALLETE_TYPE.indexed_colour then
			data.pallete_transparency = {}
			for i = 0, length - 1 do
				data.pallete_transparency[i + 1] = reader:read_be(1)
			end
			data.pallete_transparency =
				ffi.new("unsigned char[?]", #data.pallete_transparency, data.pallete_transparency)
		elseif colour_type == PALLETE_TYPE.true_colour then
			data.transparent_colour = {
				red = reader:read_be(2),
				green = reader:read_be(2),
				blue = reader:read_be(2),
			}
		else
			error("Cannot include tRNS chunk in colour type " .. colour_type)
		end
		return data
	end,
	IDAT = function(reader, length, chunk_handlers)
		local success = pcall(locate_chunk, chunk_handlers, "IDAT")
		if success and not chunk_handlers[#chunk_handlers].type == "IDAT" then
			error("Gap between IDAT chunks")
		end
		local bytes = {}
		for i = 0, length - 1 do
			bytes[i] = reader:read_be(1)
		end
		return { bytes = bytes }
	end,
	IEND = function(reader, length, chunk_handlers)
		return {}
	end,
}

return M
