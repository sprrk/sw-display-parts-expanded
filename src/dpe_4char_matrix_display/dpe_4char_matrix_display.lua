local DotMatrixDisplay = require("../lib/dot_matrix_display/display")
local useElectricCharge = require("../lib/use_electric_charge")

local signCMP = require("sw-lua-lib/cmp/sign_cmp_version")
local unpackText = require("sw-lua-lib/ascii3packer/unpack")

local observable = require("sw-lua-lib/observer/simple_observable")

local ELECTRIC_USAGE = 0.0001

local COMPOSITE_SLOT = 0
local ELECTRIC_SLOT = 0
local DISPLAY_SLOT = 0

local VERSION_SIGNATURE = signCMP(1) -- CMP version 1
local MESSAGE_TYPE_SET_DOT_MATRIX_TEXT = 1000

local powered = false

local display = DotMatrixDisplay({ x = 0, y = 0, z = 0 }, 4, 0.003, component.renderMesh0)
local displayEnabled = false

local _, setDisplayEnabled = observable(false, function(v)
	display:setEnabled(v)
	displayEnabled = v
end)

---@param handlers table<CMPMessageType, fun(data: CompositeData)>
---@return fun(data: CompositeData): nil
local function makeMessageReceiver(handlers)
	---@param data CompositeData
	return function(data)
		local floats = data.float_values

		if floats[32] ~= VERSION_SIGNATURE then
			return -- Probably not a message; drop silently
		end

		local messageType = floats[31]

		local handler = handlers[messageType]
		if handler then
			handler(data)
		else
			error("no handler")
		end
	end
end

local receiveMessage = makeMessageReceiver({
	[MESSAGE_TYPE_SET_DOT_MATRIX_TEXT] =
		---@param data CompositeData
		function(data)
			local text = unpackText(data.float_values)
			display:setText(text)
		end,
})

function onTick(_)
	setDisplayEnabled(component.getInputLogicSlotBool(DISPLAY_SLOT))

	powered = useElectricCharge(ELECTRIC_SLOT, ELECTRIC_USAGE)
	if powered then
		local composite, compositeOk = component.getInputLogicSlotComposite(COMPOSITE_SLOT)
		if compositeOk then
			receiveMessage(composite)
		end
	end
end

function onRender()
	if powered and displayEnabled then
		display:render()
	end
end
