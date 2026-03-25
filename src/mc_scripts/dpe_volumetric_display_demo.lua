local schemas = require("lib/volumetric_display/schemas")
local CompositePublisher = require("sw-lua-lib/composite/publisher")
local encodeMessage = require("sw-lua-lib/cmp/encode_message").makeMessageEncoderFunc()
local MESSAGE_TYPES = schemas.MESSAGE_TYPES

local QUEUE_SIZE_BITS = 4 -- Tiny queue should be plenty for now
local writeFunc = require("sw-lua-lib/composite/mc_write")
local publisher = CompositePublisher(writeFunc, QUEUE_SIZE_BITS)

local GROUP_ID = 1

local initialized = false

---@return nil
local function createGroup()
	local createGroupMsg = schemas.EntityGroupCreateMessageSchema:serialize({
		id = GROUP_ID,
		origin = { x = 0, y = 0, z = 0 },
	})

	local message, err = encodeMessage(createGroupMsg, MESSAGE_TYPES.CREATE_GROUP)
	if err or not message then
		error()
	end

	publisher:add(message, 2)
end

---@param origin EntityPosition
---@param size number
---@return nil
local function createVoxel(origin, size)
	local createVoxelMsg = schemas.VoxelCreateMessageSchema:serialize({
		groupID = GROUP_ID,
		origin = origin,
		size = size,
	})

	local message, err = encodeMessage(createVoxelMsg, MESSAGE_TYPES.CREATE_VOXEL)
	if err or not message then
		error()
	end

	publisher:add(message, 2)
end

---@param origin EntityPosition
---@return nil
local function createText(origin)
	local createTextMsg = schemas.TextCreateMessageSchema:serialize({
		groupID = GROUP_ID,
		origin = origin,
		size = 0.25,
		t1 = "abc",
		t2 = "def",
		t3 = "ABC",
		t4 = "DEF",
	})

	local message, err = encodeMessage(createTextMsg, MESSAGE_TYPES.CREATE_TEXT)
	if err or not message then
		error()
	end

	publisher:add(message, 2)
end

---@return nil
local function initialize()
	-- Create a group
	createGroup()

	-- Add a few voxels
	createVoxel({ x = 0, y = 0, z = 1 }, 0.25)
	createVoxel({ x = 0, y = 0, z = 2 }, 0.25)
	createVoxel({ x = -0.125, y = 0.125, z = -1.125 }, 0.5)

	-- Add some text
	createText({ x = 1, y = 5, z = 0 })
end

function onTick()
	if not initialized then
		initialize()
		initialized = true
	end

	publisher:tick()
end
