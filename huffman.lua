---@class huffman_child<T>: {[integer]: huffman_tree<T>}
---@class huffman_tree<T>: {data: (T | huffman_child<T>)}

---@param bit_lengths integer[]
local function deflate_huffman(bit_lengths) end
