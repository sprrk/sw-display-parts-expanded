local packText = require("sw-lua-lib/ascii3packer/pack")
local signCMP = require("sw-lua-lib/cmp/sign_cmp_version")
local observable = require("sw-lua-lib/observer/simple_observable")
local snap = require("sw-lua-lib/extramath/snap")

local VERSION_SIGNATURE = signCMP(1) -- CMP version 1
local MESSAGE_TYPE_SET_DOT_MATRIX_TEXT = 1000

local writeFunc = require("sw-lua-lib/composite/mc_write")

---@param v number
---@return string
local function intstr(v)
	return tostring(snap(v, 1))
end

---@param text string
---@param charCount integer
---@return string
local function alignLeft(text, charCount)
	return text .. string.rep(" ", charCount - #text)
end

---@param text string
---@param unit string
---@param charCount integer
---@return string
local function alignRightWithUnit(text, unit, charCount)
	local combined = text .. unit
	return string.rep(" ", charCount - #combined) .. combined
end

---@param text string The text to display (ASCII, max. 24 chars)
---@return CompositeData
local function serialize(text)
	-- Pack text into an array with 3-char bitmasks and pass that to message body

	local floats = { [31] = MESSAGE_TYPE_SET_DOT_MATRIX_TEXT, [32] = VERSION_SIGNATURE }

	local packed = packText(text:sub(1, 24))
	local n = #packed
	for i = 1, n do
		floats[i] = packed[i] or 0
	end

	return { float_values = floats, bool_values = {} }
end

---@param value number
---@param charCount integer
---@return string|nil
local function overflowIndicator(value, charCount)
	local intDigits = #intstr(value)
	if intDigits <= charCount then
		return nil -- no overflow
	end

	return (value < 0) and "LO" or "HI"
end

---@param charCount integer
---@return fun(value: number|integer): string
local function makeFloatFormatter(charCount)
	local strf = string.format

	return function(value)
		local overflow = overflowIndicator(value, charCount)
		if overflow then
			return alignLeft(overflow, charCount)
		end

		local text = strf("%f", value)

		local intDigits = #intstr(value)

		if intDigits == charCount - 1 then
			-- This would render a trailing dot; truncate extra
			return text:sub(1, charCount - 1) .. " "
		else
			-- Round last decimal properly
			local decimals = math.max(charCount - intDigits - 1, 0)
			local fmt = strf("%%.%df", decimals)
			return strf(fmt, value)
		end
	end
end

---@param charCount integer
---@param unit string
---@param multiplier number|nil
---@return fun(value: number): string
local function makeUnitFormatter(charCount, unit, multiplier)
	multiplier = multiplier or 1
	return function(value)
		local scaled = value * multiplier
		local overflow = overflowIndicator(scaled, charCount - #unit)
		if overflow then
			return alignLeft(overflow, charCount)
		end

		return alignRightWithUnit(intstr(scaled), unit, charCount)
	end
end

local CHAR_COUNT = math.floor(property.getNumber("Char count"))

---@alias DisplayMode
---| 1 Float
---| 2 Integer
---| 3 Celsius
---| 4 Percentage
---| 5 Degree

---@type DisplayMode
local displayMode = math.floor(property.getNumber("Mode") or 1)

local formatters = {
	[1] = makeFloatFormatter(CHAR_COUNT),
	[2] = makeUnitFormatter(CHAR_COUNT, ""),
	[3] = makeUnitFormatter(CHAR_COUNT, "C"),
	[4] = makeUnitFormatter(CHAR_COUNT, "%", 100),
	[5] = makeUnitFormatter(CHAR_COUNT, string.char(32 + 144)),
}

local format = formatters[displayMode]

local _, setDisplayNumber = observable(0, function(v)
	local message = serialize(format(v))

	writeFunc(message)
end)

function onTick()
	setDisplayNumber(input.getNumber(1))
end
