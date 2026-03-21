local schemas = require("lib/volumetric_display/schemas")
local CompositePublisher = require("sw-lua-lib/composite/publisher")

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
	publisher:add(createGroupMsg, 2)
end

---@param origin EntityPosition
---@return nil
local function createVoxel(origin)
	local msg = schemas.VoxelCreateMessageSchema:serialize({
		groupID = GROUP_ID,
		origin = origin,
		size = 1.0,
	})
	publisher:add(msg, 2)
end

---@return nil
local function initialize()
	-- Create a group
	createGroup()

	-- Add a few voxels to it
	createVoxel({ x = 0, y = 0, z = 0 })
	createVoxel({ x = 0, y = 1, z = 0 })
	createVoxel({ x = 0, y = 2, z = 0 })

	-- TODO: Add a text to it
end

function onTick()
	if not initialized then
		initialize()
		initialized = true
	end

	publisher:tick()
end
