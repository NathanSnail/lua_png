---@class handler_result
---@field type string
---@field data table<string, any>

---@alias handler_fn fun(reader: byte_reader, length: integer, chunk_handlers: handler_result[]): handler_result

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
	end,
}

return M
