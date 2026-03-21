local fontMap3x4 = {
	-- Minimum Alpha:
	-- https://gist.github.com/jjmajava/977646457e00be87bb2e
	-- https://web.archive.org/web/20260318170222/https://gist.githubusercontent.com/jjmajava/977646457e00be87bb2e/raw/411e3e19eb6733f6edf7bb3960864346a2e59c66/mininum.txt
	a = {
		{ 0, 1, 1 },
		{ 1, 0, 1 },
		{ 1, 1, 1 },
		{ 1, 0, 1 },
	},
	b = {
		{ 1, 1, 0 },
		{ 1, 1, 1 },
		{ 1, 0, 1 },
		{ 1, 1, 1 },
	},
	-- TODO: And so on
}

---@param c string
---@param xOffset number
---@param yOffset number
---@return Matrix[]
local function char(c, xOffset, yOffset)
	local result = {}
	local m = fontMap3x4[c]
	for y = 1, 4 do
		for x = 1, 3 do
			if m[x][y] then
				local t = matrix.translation(x + xOffset, y + yOffset, 0)
				table.insert(result, t)
			end
		end
	end
	return result
end

--local charCache = {}
--
-----@param c string
-----@return Matrix[]
--local function getChar(c)
--	local cached = charCache[c]
--	if cached then
--		return cached
--	else
--		local ch = char(c)
--		charCache[c] = ch
--		return ch
--	end
--end

return char
