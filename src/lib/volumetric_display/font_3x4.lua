-- Based on the following font:
-- https://web.archive.org/web/20260323192244/https://www.reddit.com/media?url=https%3A%2F%2Fi.redd.it%2Fz5ytt03tgvua1.png
local fontSheet3x4 = {
	-- Region 32-96 of the ascii code chart:
	--SP  !   "   #   $   %   &   '   (    )  *   +   ,   -   .   /
	"     █  █ █ █ █  ██ █ █ ███   █   █ █                           ",
	"     █      ███ ██   █  █ █  █   █   █  █ █  █                █ ",
	"            ███  ██ █    ██      █   █   █  ███ ██  ███      █  ",
	"     █      █ █ ██  █ █ ███       █ █   █ █  █   █       █  █   ",
	--0   1   2   3   4   5   6   7   8   9   :   ;   <   =   >   ?
	"███  █  ███ ███ █ █ ███ █   ███ ███ ███  █   █              ███ ",
	"█ █ ██    █  ██ █ █ ██  ███   █ ███ █ █           █ ███ █    ██ ",
	"█ █  █  ██    █ ███   █ █ █  █  █ █ ███  █   █   █       █      ",
	"███ ███ ███ ███   █ ███ ███  █  ███   █     █     █ ███ █    █  ",
	--@   A   B   C   D   E   F   G   H   I   J   K   L   M   N   O
	"███  █  ██   ██ ██  ███ ███  ██ █ █ ███   █ █ █ █   ███ █ █ ███",
	"███ █ █ ██  █   █ █ █   █   █   █ █  █    █ █ █ █   ███ ███ █ █",
	"███ ███ █ █ █   █ █ ██  ██  █ █ ███  █  █ █ ██  █   █ █ ███ █ █",
	"███ █ █ ██   ██ ██  ███ █    ██ █ █ ███  █  █ █ ███ █ █ █ █ ███",
	--P   Q   R   S   T   U   V   W   X   Y   Z   [   \   ]   ^   _
	"██   █  ██   ██ ███ █ █ █ █ █ █ █ █ █ █ ███ ███     ███  █     ",
	"█ █ █ █ █ █ █    █  █ █ █ █ █ █  █  █ █   █ █   █     █ █ █    ",
	"██  ███ ██    █  █  █ █ █ █ ███  █   █  █   █    █    █        ",
	"█    ██ █ █ ██   █  ███  █  ███ █ █  █  ███ ███   █ ███     ███",
	--`   a   b   c   d   e   f   g   h   i   j   k   l   m   n   o
	"█       █         █      ██  ██ █    █    █ █                  ",
	" █   ██ ██   ██  ██ ███ █   █   █           █ █ █   ███ ██  ███",
	"    █ █ █ █ █   █ █ ██  ██  █ █ ███  █    █ ██  █   ███ █ █ █ █",
	"     ██ ██  ███  ██ ███ █   ███ █ █  █  ██  █ █ ██  █ █ █ █ ███",
	--p   q   r   s   t   u   v   w   x   y   z   {   |   }   ~  DEL
	"                 █                           ██  █  ██      ███",
	"███ ███  ██  ██ ███ █ █ █ █ █ █ █ █ █ █ ██   █   █   █   ██ ███",
	"███ ███ █    █   █  █ █ █ █ ███  █   █   █  ██   █   ██ ██  ███",
	"█     █ █   ██   ██ ███  █  ███ █ █  █   ██  ██  █  ██      ███",
}

---@param c string
---@return table[] positions Positions in run-length encoding format {x, y, length}
local function getCharPositions(c)
	local asciiVal = string.byte(c)

	-- Only handle printable ASCII characters (32-126)
	if asciiVal < 32 or asciiVal > 126 then
		return {}
	end

	-- Calculate position in the font sheet
	local charIndex = asciiVal - 32 -- Start from space (32)
	local row = math.floor(charIndex / 16)
	local col = charIndex % 16

	local positions = {}

	-- Check each pixel in the 3x4 grid for this character
	for y = 0, 3 do
		local rowStr = fontSheet3x4[1 + y] -- 1-indexed
		local startX = nil
		local length = 0

		for x = 0, 2 do
			local charPos = col * 4 + x + 1 -- 1-indexed, 4 chars per column position
			local pixel = string.sub(rowStr, charPos, charPos)

			if pixel ~= " " then
				if startX == nil then
					startX = x
				end
				length = length + 1
			else
				if startX ~= nil then
					table.insert(positions, { startX, y, length })
					startX = nil
					length = 0
				end
			end
		end

		-- Handle case where line ends with a filled pixel
		if startX ~= nil then
			table.insert(positions, { startX, y, length })
		end
	end

	return positions
end

---@param c string
---@param xOffset number
---@param yOffset number
---@return Matrix[]
local function char(c, xOffset, yOffset)
	local result = {}
	local positions = getCharPositions(c)

	for _, pos in ipairs(positions) do
		local startX, y, length = pos[1], pos[2], pos[3]
		-- Create a run of voxels for this row segment
		for x = startX, startX + length - 1 do
			local t = matrix.translation(x + xOffset, yOffset - y, 0)
			table.insert(result, t)
		end
	end

	return result
end

return char
