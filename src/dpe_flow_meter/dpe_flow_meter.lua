-- Component details:
-- Type: Flow meter
-- Displays fluid flow.

local SETTINGS_READ_INTERVAL = 60
local NEEDLE_SWEEP_ANGLE_DEG = 270
local DEFAULT_SCALE = 100.0
local ANGLE_RESOLUTION_DEG = 1.0
local MAX_CACHE_INDEX = math.floor(NEEDLE_SWEEP_ANGLE_DEG / ANGLE_RESOLUTION_DEG)

-- Slot definitions
local FLOW_INPUT_SLOT = 0
local SETTINGS_SLOT = 0
local ODOMETER_OUTPUT_SLOT = 0

-- Odometer configuration
local COUNTER_WHEEL_Y = -0.175
local COUNTER_WHEEL_Z = 0.06
local ODOMETER_PERSISTENCE_ID = "odometer"
local WHEEL_RESOLUTION_DEG = 9
local DEGREES_PER_DIGIT = 36
local WHEEL_COUNT = 6
local WHEEL_POSITIONS = { -0.0375, -0.0225, -0.0075, 0.0075, 0.0225, 0.0375 } -- From right (0.1 L) to left (1000 L)
local WHEEL_MESH_INDICES = { 2, 1, 1, 1, 1, 1 } -- White wheel first, then black wheels

local initialized = false
local flow = 0
local settings_read_ticks = 0
local odometer_liters = 0.0 -- Total volume passed since last reset

local FLOW_CACHE = {}

---@class FlowMeterSettings
---@field max_flow number

---@type FlowMeterSettings
local settings = {
	max_flow = 1.0,
}

---@param value number
---@param min number
---@param max number
---@return number
local function clamp(value, min, max)
	return value < min and min or value > max and max or value
end

local function rebuildFlowCache()
	for i = 0, MAX_CACHE_INDEX do
		local angle_deg = i * ANGLE_RESOLUTION_DEG
		local angle_rad = math.rad(-NEEDLE_SWEEP_ANGLE_DEG * 0.5 + angle_deg)
		FLOW_CACHE[i] = matrix.rotationY(angle_rad)
	end
end

local WHEEL_CACHE = {}
local function rebuildWheelCache()
	local function createWheelTransform(wheel_index, angle_deg)
		local angle_rad = math.rad(angle_deg)
		local rot = matrix.rotationX(angle_rad)
		local pos = matrix.translation(WHEEL_POSITIONS[wheel_index], COUNTER_WHEEL_Y, COUNTER_WHEEL_Z)
		return matrix.multiply(pos, rot)
	end

	for wheel_index = 1, WHEEL_COUNT do
		WHEEL_CACHE[wheel_index] = {}

		if wheel_index == 1 then
			-- White wheel: smooth interpolation
			local steps = math.floor(360 / WHEEL_RESOLUTION_DEG) + 1
			for step = 0, steps - 1 do
				WHEEL_CACHE[wheel_index][step] = createWheelTransform(wheel_index, step * WHEEL_RESOLUTION_DEG)
			end
		else
			-- Black wheels: snap to exact digits (10 positions)
			for digit = 0, 9 do
				WHEEL_CACHE[wheel_index][digit] = createWheelTransform(wheel_index, digit * DEGREES_PER_DIGIT)
			end
		end
	end
end

local function initialize()
	initialized = true
end

function onTick(_)
	local composite, _ = component.getInputLogicSlotComposite(SETTINGS_SLOT)

	if not initialized then
		initialize()
		rebuildFlowCache()
		rebuildWheelCache()
	end

	-- Read settings every few ticks
	settings_read_ticks = (settings_read_ticks + 1) % SETTINGS_READ_INTERVAL
	if settings_read_ticks == 0 then
		local _scale = composite.float_values[1]
		if _scale > 0 then
			settings.max_flow = _scale * 10
		else
			settings.max_flow = DEFAULT_SCALE * 10
		end
	end

	-- Calculate the flow for the display
	local _flow, flow_get_ok = component.getInputLogicSlotFloat(FLOW_INPUT_SLOT)
	flow = flow_get_ok and _flow or 0

	if composite.bool_values[1] then
		-- Reverse mode
		flow = -flow
	end

	-- Update odometer
	odometer_liters = odometer_liters + (flow / 60)
	if composite.bool_values[2] then
		odometer_liters = 0.0
	end

	component.setOutputLogicSlotFloat(ODOMETER_OUTPUT_SLOT, odometer_liters)

	initialized = true
end

function onRender()
	if not initialized then
		return
	end

	-- Render needle
	local t = clamp(flow / settings.max_flow, 0, 1)
	local index = math.floor(t * MAX_CACHE_INDEX + 0.5)
	component.renderMesh0(FLOW_CACHE[index])

	-- Render odometer wheels
	local value = odometer_liters
	for wheel_index = 1, WHEEL_COUNT do
		local scale = 10 ^ (wheel_index - 2) -- 0.1, 1, 10, 100, 1000, 10000
		local digit = (value / scale) % 10 -- 0.0 .. 9.999

		local cache_index
		if wheel_index == 1 then
			-- White wheel: smooth interpolation
			local step_f = (digit * DEGREES_PER_DIGIT) / WHEEL_RESOLUTION_DEG
			cache_index = math.floor(step_f + 0.5) % #WHEEL_CACHE[wheel_index]
		else
			-- Black wheels: snap to current digit
			cache_index = math.floor(digit) % 10
		end

		local mesh_index = WHEEL_MESH_INDICES[wheel_index]
		local transform = WHEEL_CACHE[wheel_index][cache_index]

		if mesh_index == 1 then
			component.renderMesh1(transform)
		else
			component.renderMesh2(transform)
		end
	end
end

function onParse()
	local value_out, success = parser.parseNumber(ODOMETER_PERSISTENCE_ID, odometer_liters)
	if success and value_out then
		odometer_liters = value_out
	end
end
