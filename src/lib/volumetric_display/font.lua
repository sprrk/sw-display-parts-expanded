---@class (exact) FontSheet
---@field minAsciiCode integer
---@field maxAsciiCode integer
---@field width integer Font width in pixels
---@field height integer Font height in pixels
---@field gap integer Horizontal gap in pixels between each character
---@field sheet string[] Rows of strings

---@class (exact) CharPixel
---@field [1] integer X
---@field [2] integer Y

---@param sheet FontSheet
---@return Font
local function Font(sheet)
	---@class Font
	---@field sheet FontSheet
	local instance = { sheet = sheet }

	---@type table<string, CharPixel[]>
	local charCache = {}

	---@param c string
	---@return CharPixel[]
	function instance:char(c)
		local cached = charCache[c]
		if cached then
			return cached
		end

		local asciiVal = string.byte(c)

		-- Only handle ASCII characters present in sheet
		if asciiVal < sheet.minAsciiCode or asciiVal > sheet.maxAsciiCode then
			error("Invalid ascii code")
		end

		-- Calculate position in the font sheet
		local charIndex = asciiVal - sheet.minAsciiCode -- Start from first code in sheet
		local rowIndex = math.floor(charIndex / 16)
		local colIndex = (charIndex % 16)

		local gapOffset = 0
		if colIndex > 0 then
			gapOffset = sheet.gap * colIndex
		end

		local results = {}

		for y = 1, sheet.height do
			local row = sheet.sheet[rowIndex * sheet.height + y]
			for x = 1, sheet.width do
				local i = colIndex * sheet.width + x + gapOffset
				local pixel = row:sub(i, i)
				if pixel ~= " " then
					table.insert(results, { x, y })
				end
			end
		end

		charCache[c] = results

		return results
	end

	return instance
end

return Font
