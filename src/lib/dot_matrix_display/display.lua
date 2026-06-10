local CHAR_MAP = require("lib/dot_matrix_display/font_5x7")

---@param mask integer
---@return boolean
local function hasBit(mask, b)
	return math.floor(mask / (2 ^ b)) % 2 == 1
end

---@class (exact) RunLengthEncoding
---@field [1] integer Start index
---@field [2] integer Length

---@param data integer[] An array containing only 0s and 1s.
---@return RunLengthEncoding[] runLengths A list of {startIndex, runLength} for runs of 1s.
--- Perform run-length encoding on a sequence of 0s and 1s.
--- Only encodes runs of 1s.
local function runLengthEncode(data)
	local result = {}
	local i = 1
	local n = #data

	while i <= n do
		if data[i] == 1 then
			local start = i
			local length = 0
			while i <= n and data[i] == 1 do
				length = length + 1
				i = i + 1
			end
			table.insert(result, { start, length })
		else
			i = i + 1
		end
	end

	return result
end

---@class (exact) DotMatrixDisplayOrigin
---@field x number X position
---@field y number Y position
---@field z number Z position

---@param origin DotMatrixDisplayOrigin
---@param charCount integer Amount of characters
---@param pixelSize number
---@return DotMatrixDisplay
local function DotMatrixDisplay(origin, charCount, pixelSize)
	---@class DotMatrixDisplay
	local instance = {}

	local buffers = {}
	local _chars = {}
	for i = 1, charCount do
		buffers[i] = {}
		_chars[i] = ""
	end
	local fontWidth = 5
	local fontHeight = 7
	local enabled = true

	local originX = origin.x
		+ (pixelSize * 2.5)
		- (pixelSize * fontHeight * 0.5)
		- (charCount * 0.5 * fontWidth * pixelSize)
	local originY = origin.y
	local originZ = origin.z - (pixelSize * 0.5) + (pixelSize * fontHeight * 0.5)

	---@type string
	local currentValue = ""

	local renderMesh0 = component.renderMesh0 -- TODO: Allow configuring render func via arg

	-- -- Re-usable pixel buffer
	local rowBuffer = {}
	local columnBuffer = {}
	for r = 1, fontHeight do
		rowBuffer[r] = {}
	end
	for c = 1, fontWidth do
		columnBuffer[c] = {}
	end

	---@param x integer Grid position X
	---@param y integer Grid position Y
	---@param w integer Width in pixels
	---@param h integer Height in pixels
	---@return Matrix
	local function segment(x, y, w, h)
		-- Draw a segment starting at x,y ending at x+w,y-h

		local basePos = matrix.translation(originX + (x * pixelSize), originY, originZ - y * pixelSize)

		if w > 1 or h > 1 then
			local scale = matrix.scale(w, 1, h)

			-- Scaling happens at the center of the segment, so we have to reposition
			-- Example: at width 2 we have to shift by half a pixel, at width 3 by a full pixel
			local offset = matrix.translation((w - 1) * 0.5 * pixelSize, 0, -(h - 1) * 0.5 * pixelSize)

			return matrix.multiply(matrix.multiply(basePos, offset), scale)
		else
			return basePos
		end
	end

	local charBaseSegmentsCache = {}

	---@param char string
	---@return Matrix[]
	local function getCharBaseSegments(char)
		local cached = charBaseSegmentsCache[char]
		if cached ~= nil then
			return cached
		end

		local index = string.byte(char) - 31
		local charData = CHAR_MAP[index]

		if not charData then
			charData = CHAR_MAP[1]
		end

		-- Example char:
		-- charData = { 14, 17, 17, 17, 31, 17, 17 } -- [33] 'A'
		--  ["A"] = {
		-- 		{ 0, 1, 1, 1, 0 },
		-- 		{ 1, 0, 0, 0, 1 },
		-- 		{ 1, 0, 0, 0, 1 },
		-- 		{ 1, 0, 0, 0, 1 },
		-- 		{ 1, 1, 1, 1, 1 },
		-- 		{ 1, 0, 0, 0, 1 },
		-- 		{ 1, 0, 0, 0, 1 },
		-- 	}

		if #charData ~= fontHeight then
			error()
		end

		-- Populate the row and column buffers for this char
		for r = 1, fontHeight do
			local mask = charData[r]
			for c = 1, fontWidth do
				local val = 0
				-- Font map is right-to-left
				if hasBit(mask, fontWidth - c) then
					val = 1
				end
				rowBuffer[r][c] = val
				columnBuffer[c][r] = val
			end
		end

		local segments = {}

		-- Track which pixels are already rendered as part of larger segments
		local rendered = {}
		for r = 1, fontHeight do
			rendered[r] = {}
			for c = 1, fontWidth do
				rendered[r][c] = false
			end
		end

		local ti = table.insert

		-- Create horizontal segments
		for r = 1, fontHeight do
			local row = rowBuffer[r]
			local lengths = runLengthEncode(row)
			for i = 1, #lengths do
				local start = lengths[i][1]
				local length = lengths[i][2]

				if length > 1 then
					ti(segments, segment(start - 1, r - 1, length, 1))

					-- Mark covered pixels
					for k = 0, length - 1 do
						rendered[r][start + k] = true
					end
				end
			end
		end

		-- Create vertical segments
		for c = 1, fontWidth do
			local column = columnBuffer[c]
			local lengths = runLengthEncode(column)
			for i = 1, #lengths do
				local start = lengths[i][1]
				local length = lengths[i][2]

				if length > 1 then
					ti(segments, segment(c - 1, start - 1, 1, length))

					-- Mark covered pixels
					for k = 0, length - 1 do
						rendered[start + k][c] = true
					end
				end
			end
		end

		-- Render isolated pixels (not part of any >1 run)
		for r = 1, fontHeight do
			for c = 1, fontWidth do
				if rowBuffer[r][c] == 1 and not rendered[r][c] then
					ti(segments, segment(c - 1, r - 1, 1, 1))
				end
			end
		end

		charBaseSegmentsCache[char] = segments

		return segments
	end

	local charSegmentsCache = {}

	---@param char string
	---@param i integer Char index
	---@return Matrix[]
	local function getCharSegments(char, i)
		local cached = (charSegmentsCache[char] or {})[i]
		if cached ~= nil then
			return cached
		end

		local baseSegments = getCharBaseSegments(char)

		local segments = {}

		local charOffset = (fontWidth + 1) -- 1px gap
		local xOffset = (i - 1) * charOffset

		-- Move segments to correct position on screen
		for idx = 1, #baseSegments do
			table.insert(segments, matrix.multiply(matrix.translation(xOffset * pixelSize, 0, 0), baseSegments[idx]))
		end

		if charSegmentsCache[char] == nil then
			charSegmentsCache[char] = {}
		end
		charSegmentsCache[char][i] = segments

		return segments
	end

	---@param char string
	---@param i integer Char index
	local function setChar(char, i)
		if _chars[i] == char then
			return
		end
		_chars[i] = char

		buffers[i] = getCharSegments(char, i)
	end

	local function refresh()
		for i = 1, charCount do
			setChar(currentValue:sub(i, i), i)
		end
	end

	---@param value string
	function instance:setText(value)
		if currentValue ~= value then
			currentValue = value

			if enabled then
				refresh()
			end
		end
	end

	function instance:clear()
		for i = 1, charCount do
			buffers[i] = {}
			_chars[i] = ""
		end
	end

	---@param v boolean
	function instance:setEnabled(v)
		if enabled ~= v then
			enabled = v
			if enabled then
				refresh()
			end
		end
	end

	function instance:render()
		if enabled then
			for i = 1, charCount do
				local buf = buffers[i]
				local nBuf = #buf
				for j = 1, nBuf do
					renderMesh0(buf[j])
				end
			end
		end
	end

	return instance
end

return DotMatrixDisplay
