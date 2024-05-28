---@class huffman_child<T>: {[integer]: huffman_tree<T>}
---@class huffman_tree<T>: {data: (T | huffman_child<T>)}

local M = {}

---@param v integer
---@return integer
local function bit_length(v)
	for i = 0, 64 do
		if v == 0 then
			return i
		end
		v = bit.rshift(v, 1)
	end
	return 0
end

---@param bit_lengths integer[]
function M.deflate_huffman(bit_lengths)
	-- TODO: figure out how this is supposed to work, the docs are worthless.
	local codes_of_length = {}
	local code = 0
	codes_of_length[0] = 0
	for _, v in ipairs(bit_lengths) do
		local length = bit_lengths(v)
		codes_of_length[length] = (codes_of_length[length] or 0) + 1
	end
	--[[for bits = 1, MAX_BITS do
		code = bit.lshift(code + codes_of_length[bits - 1], 1)
		next_code[bits] = code
	end]]
end

---@generic T
---@param tree huffman_tree<T>
---@param path byte_array
---@return T
function M.traverse_huffman(tree, path)
	for _, v in ipairs(path.data) do
		tree = tree.data[v]
	end
	return tree.data
end

return M
