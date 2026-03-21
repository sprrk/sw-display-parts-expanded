local char = require("lib/volumetric_display/font_3x4")
local schemas = require("lib/volumetric_display/schemas")
local makeMessageReceiverFunc = require("sw-lua-lib/cmp/message_receiver")
local MESSAGE_TYPES = schemas.MESSAGE_TYPES

-- NOTE: Use cases:
--       - Debug displays
--       - Monochrome displays
--       - LIDAR display
--       - Ship depth/seabed display
--       - Holo UIs

-- TODO: Add more group commands:
--       - Visually replace group with another group (hide A, show B)

-- TODO: Implement renderables within groups
--       - Create/update/delete logic
--       - Assign ID per renderable
--       - Pixel, line, box, plane, circle, circleF, character etc.
--       - Allow updating position

---@alias RenderFunc fun(): nil

local renderer = {
	---@param m Matrix
	---@return RenderFunc
	mesh0 = function(m)
		local f = component.renderMesh0

		---@return nil
		return function()
			f(m)
		end
	end,
}

---@param origin EntityPosition
local function Voxel(origin)
	---@class Voxel
	---@field origin EntityPosition
	local instance = { origin = origin }

	---@return RenderFunc[]
	function instance:getRenderFuncs()
		return { renderer.mesh0(origin) }
	end

	return instance
end

---@param data TextCreateMessage
local function Text(data)
	local text = data.t1 .. data.t2 .. data.t3 .. data.t4

	---@class Text
	---@field origin EntityPosition
	---@field text string
	local instance = { origin = data.origin, text = text }

	-- Rasterize/pre-render
	local positions = {}
	for i = 1, #text do
		local c = text:sub(i, i)
		table.insert(positions, char(c, data.origin.x, data.origin.y))
	end

	---@return RenderFunc[]
	function instance:getRenderFuncs()
		local funcs = {}
		for i = 1, #positions do
			local pos = positions[i]
			table.insert(funcs, renderer.mesh0(pos))
		end
		return funcs
	end

	return instance
end

---@param origin EntityPosition
local function EntityGroup(origin)
	-- TODO: Implement funcionality to set group offset position
	--       - This will require recalculating the matrix array, perhaps
	--         we can do that somewhat efficiently by directly editing the
	--         data inside the matrix instead of calling matrix.translate() etc

	---@class EntityGroup
	---@field origin EntityPosition
	---@field active boolean
	local instance = { origin = origin, active = true }

	local dirty = false

	---@type RenderFunc[]
	local renderFuncs = {}

	---@type (Voxel|Text)[]
	local entities = {}

	---@type boolean[]
	local entityInitStates = {}

	---@param voxel Voxel
	function instance:addVoxel(voxel)
		table.insert(entities, voxel)
		table.insert(entityInitStates, false)
		dirty = true
	end

	---@param text Text
	function instance:addText(text)
		table.insert(entities, text)
		table.insert(entityInitStates, false)
		dirty = true
	end

	---@return RenderFunc[]
	function instance:getRenderFuncs()
		if not self.active then
			return {}
		end

		if not dirty then
			-- Skip early if nothing changed
			return renderFuncs
		end

		local funcs = {}
		for i = 1, #entities do
			local entityInitialized = entityInitStates[i]
			if not entityInitialized then -- Only pre-render when necessary
				local entity = entities[i]
				local entityFuncs = entity:getRenderFuncs()
				for v = 1, #entityFuncs do
					table.insert(funcs, entityFuncs[v])
				end
				entityInitStates[i] = true
			end
		end

		dirty = false

		return renderFuncs
	end

	return instance
end

---@type table<integer, EntityGroup>
local entityGroups = {}

local function groupActivityHandler()
	return function(data)
		local msg = schemas.EntityGroupSetActiveMessageSchema:deserialize(data)
		local group = entityGroups[msg.id]
		if group then
			group.active = msg.active
		end
	end
end

local receiveMessage = makeMessageReceiverFunc({
	[MESSAGE_TYPES.CREATE_GROUP] = function(data)
		local msg = schemas.EntityGroupCreateMessageSchema:deserialize(data)
		entityGroups[msg.id] = EntityGroup(msg.origin)
	end,
	[MESSAGE_TYPES.UPDATE_GROUP_POS] = function(data)
		-- TODO: Update group position
	end,
	[MESSAGE_TYPES.DELETE_GROUP] = function(data)
		local msg = schemas.EntityGroupDeleteMessageSchema:deserialize(data)
		entityGroups[msg.id] = nil
	end,
	[MESSAGE_TYPES.ACTIVATE_GROUP] = groupActivityHandler(),
	[MESSAGE_TYPES.DEACTIVATE_GROUP] = groupActivityHandler(),

	[MESSAGE_TYPES.CREATE_VOXEL] = function(data)
		local msg = schemas.VoxelCreateMessageSchema:deserialize(data)
		local group = entityGroups[msg.groupID]
		if group then
			group:addVoxel(Voxel(msg.origin))
		end
	end,
	[MESSAGE_TYPES.DELETE_VOXEL] = function(data)
		-- TODO: Delete voxel with ID
	end,

	[MESSAGE_TYPES.CREATE_TEXT] = function(data)
		local msg = schemas.TextCreateMessageSchema:deserialize(data)
		local group = entityGroups[msg.groupID]
		if group then
			group:addText(Text(msg))
		end
	end,
})

function onTick()
	local inputData = component.getInputLogicSlotComposite(1)
	receiveMessage(inputData)

	-- TODO: Outpu debug data, i.e. number of render funcs, cache hit rate, etc.
end

function onRender()
	for i = 1, #entityGroups do
		local funcs = entityGroups[i]:getRenderFuncs()
		for f = 1, #funcs do
			funcs[f]()
		end
	end
end
