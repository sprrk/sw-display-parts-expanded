local CompositePublisher = require("sw-lua-lib/composite/publisher")
local packText = require("sw-lua-lib/ascii3packer/pack")
local signCMP = require("sw-lua-lib/cmp/sign_cmp_version")

local VERSION_SIGNATURE = signCMP(1) -- CMP version 1
local MESSAGE_TYPE_SET_DOT_MATRIX_TEXT = 1000

local QUEUE_SIZE_BITS = 4 -- Tiny queue should be plenty for now
local writeFunc = require("sw-lua-lib/composite/mc_write")
local publisher = CompositePublisher(writeFunc, QUEUE_SIZE_BITS)

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

---@param text string
local function setText(text)
	local message = serialize(text)

	publisher:add(message, 2)
end

local currentIndex = 1
local currentTick = 1
local pattern = {
	"Hell",
	"ello",
	"llo!",
	"lo! ",
	"o!  ",
	"!   ",
	"    ",
	"   H",
	"  He",
	" Hel",
}

function onTick()
	setText(pattern[currentIndex])

	currentTick = currentTick + 1
	if currentTick == 15 then
		currentTick = 1

		currentIndex = currentIndex + 1
		if currentIndex > #pattern then
			currentIndex = 1
		end
	end

	-- setText("1234")

	publisher:tick()
end
