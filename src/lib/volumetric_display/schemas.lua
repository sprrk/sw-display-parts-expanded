local FloatField = require("sw-lua-lib/composite/schema/fields/float_field")
local BoolField = require("sw-lua-lib/composite/schema/fields/bool_field")
local Ascii3Field = require("sw-lua-lib/composite/schema/fields/ascii3_field")
local CompositeSchema = require("sw-lua-lib/composite/schema/schema")

---@class (exact) EntityPosition
---@field x number
---@field y number
---@field z number

---@class (exact) EntityGroupCreateMessage
---@field id integer
---@field origin EntityPosition

---@class (exact) EntityGroupDeleteMessage
---@field id integer

---@class (exact) EntityGroupSetActiveMessage
---@field id integer
---@field active boolean

---@class (exact) VoxelCreateMessage
---@field groupID integer
---@field origin EntityPosition
---@field size number

---@class (exact) TextCreateMessage
---@field groupID integer
---@field origin EntityPosition
---@field size number
---@field t1 string
---@field t2 string
---@field t3 string
---@field t4 string

---@type CompositeSchema<EntityGroupCreateMessage>
local EntityGroupCreateMessageSchema = CompositeSchema({
	id = FloatField(1),
	origin = CompositeSchema({ x = FloatField(2), y = FloatField(3), z = FloatField(4) }, 1),
})

---@type CompositeSchema<EntityGroupDeleteMessage>
local EntityGroupDeleteMessageSchema = CompositeSchema({
	id = FloatField(1),
})

---@type CompositeSchema<EntityGroupSetActiveMessage>
local EntityGroupSetActiveMessageSchema = CompositeSchema({
	id = FloatField(1),
	active = BoolField(1),
})

---@type CompositeSchema<VoxelCreateMessage>
local VoxelCreateMessageSchema = CompositeSchema({
	groupID = FloatField(1),
	origin = CompositeSchema({ x = FloatField(2), y = FloatField(3), z = FloatField(4) }, 1),
	size = FloatField(5),
})

---@type CompositeSchema<TextCreateMessage>
local TextCreateMessageSchema = CompositeSchema({
	groupID = FloatField(1),
	origin = CompositeSchema({ x = FloatField(2), y = FloatField(3), z = FloatField(4) }, 1),
	size = FloatField(5),
	t1 = Ascii3Field(6),
	t2 = Ascii3Field(7),
	t3 = Ascii3Field(8),
	t4 = Ascii3Field(9),
})

local MESSAGE_TYPES = {
	CREATE_GROUP = 1,
	UPDATE_GROUP_POS = 2,
	DELETE_GROUP = 3,
	ACTIVATE_GROUP = 4,
	DEACTIVATE_GROUP = 5,
	CREATE_VOXEL = 6,
	DELETE_VOXEL = 7,
	CREATE_TEXT = 8,
}

return {
	EntityGroupCreateMessageSchema = EntityGroupCreateMessageSchema,
	EntityGroupDeleteMessageSchema = EntityGroupDeleteMessageSchema,
	EntityGroupSetActiveMessageSchema = EntityGroupSetActiveMessageSchema,
	VoxelCreateMessageSchema = VoxelCreateMessageSchema,
	TextCreateMessageSchema = TextCreateMessageSchema,
	MESSAGE_TYPES = MESSAGE_TYPES,
}
