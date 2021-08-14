--[[
    There are two main ways that double doors are made in Source.

    1. Set the child door's "master" keyvalue. The child door will open whenever the master door does.
        In a very counterintuitive fashion, this is done in Hammer by specifying the names of the slaves on the master door.
        This differs from in-game, where the child doors have a reference to the master door (and NOT the other way around).
    2. Use Map I/O on each of the doors to make one open when the other opens.

    The second one appears to be the preferred method (aka the one listed on the Valve Developer Wiki), but some mappers still use the first one.
]]

--[[
    In the case of the first method, we need to know to destroy a door's child if we're destroying the master.
    There's no built-in way to find a door's children when the master is specified within the child doors.
    To get around this, we construct a table of child doors that can be examined when destroying a master door.
    We don't have to worry about this when destroying a child door -- the master door can be easily retrieved then.

    This uses map creation IDs instead of entity IDs so we don't have to worry about IDs changing between map cleanups.
    This hooks into "InitPostEntity" to make sure that all map entities are loaded when we do this.
]]

local function initDoorChildrenTable()
    if not BA2_DoorChildren then
        BA2_DoorChildren = {}

        for i, ent in pairs(ents.GetAll()) do
            local class = ent:GetClass()
            if (string.StartWith(class, "func_door") or string.StartWith(class, "prop_door")) and ent:MapCreationID() ~= -1 then
                local doorMaster = ent:GetInternalVariable("m_hMaster")
                if IsValid(doorMaster) and doorMaster:MapCreationID() ~= -1 then
                    BA2_DoorChildren[doorMaster:MapCreationID()] = ent:MapCreationID()
                end
            end
        end
    end
end

hook.Add("InitPostEntity", "BA2_InitializeDoorChildrenTable", initDoorChildrenTable)

--[[
    The second case is comparatively easier to deal with.
    If a door is broken while better door breaking is enabled, we open that door.
    As a result, that door tells its companion to open through the Map I/O system.
    We prevent this input from being processed so that we can open the companion door through the BA2_BreakDoor method.
]]

hook.Add("AcceptInput", "BA2_BreakChildViaMapIO", function( ent, name, activator, caller, data )
    if caller.BA2_DoorInternalsInitialized then
        if name == "Open" and caller.BA2_DoorBroken and not ent.BA2_DoorBroken then
            BA2_BreakDoor(ent, caller.BA2_BreakForce)
            return true
        elseif name == "Close" and not caller.BA2_DoorBroken and ent.BA2_DoorBroken then
            BA2_RepairDoor(ent)
            print(caller, " demands that ", ent, " be restored!")
            return true
        end
    end
end)

-- to understand all of the weird hasspawnflags, fire, and internalvariable things in here, look at: 
    -- https://developer.valvesoftware.com/wiki/Func_door
        -- FLAGS:
            -- flag 4096: door is silent
            -- flag 2048: door starts locked
            -- flag 1 (obsolete, but some may still use it): door starts open
        -- INPUTS (FIRED):
            -- Open, Close, Unlock, Lock: all pretty self explanatory
    -- https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/server/doors.cpp
        -- noise1, noise2, m_flWait
    -- https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/server/props.cpp
        -- soundunlockedoverride, soundmoveoverride, soundopenoverride, m_eSpawnPosition, returndelay
-- either m_flWait or returndelay is used to determine return delay depending on the type of door
-- either noise1/2 or soundunlocked/move/openoverride are used for moving sounds depending on the type of door, but we set/reset them both (no harm done)
-- m_eSpawnPosition and flag 1 are both checked here when determining if the door starts open

local soundUnlockedVariable = "soundunlockedoverride"
local soundMoveVariable = "soundmoveoverride"
local soundOpenVariable = "soundopenoverride"
local noiseMovingVariable = "noise1"
local noiseArrivedVariable = "noise2" -- real nice names i have to work with here

local doorMasterVariable = "m_hMaster"

local function initDoorInternals(ent)
    ent.BA2_ReturnDelayVariable = "returndelay"

    ent.BA2_OriginalUnlockedSound = ent:GetInternalVariable(soundUnlockedVariable)
    ent.BA2_OriginalMovingSound = ent:GetInternalVariable(soundMoveVariable)
    ent.BA2_OriginalOpenSound = ent:GetInternalVariable(soundOpenVariable)
    ent.BA2_OriginalMovingNoise = ent:GetInternalVariable(noiseMovingVariable)
    ent.BA2_OriginalArrivalNoise = ent:GetInternalVariable(noiseArrivedVariable)
    ent.BA2_OriginalReturnDelay = ent:GetInternalVariable(ent.BA2_ReturnDelayVariable)

    if not ent.BA2_OriginalReturnDelay then
        ent.BA2_ReturnDelayVariable = "m_flWait"
        ent.BA2_OriginalReturnDelay = ent:GetInternalVariable(ent.BA2_ReturnDelayVariable)
    end

    ent.BA2_DoorIsSilent = ent:HasSpawnFlags(4096)
    -- for doors that automatically close, get them to not do that while we're messing with it
    if ent.BA2_OriginalReturnDelay ~= -1 then
        ent:SetSaveValue(ent.BA2_ReturnDelayVariable, -1)
    end

    -- if the functional door is an invisible brush where the visible "door" is a prop
    -- god damn you rp_riverden_v1a
    ent.BA2_PropsToCreate = {ent}

    if table.IsEmpty(ent:GetMaterials()) then
        ent.BA2_PropsToCreate = {}
    end

    for i, child in pairs(ent:GetChildren()) do
        if child:GetModel() then
            table.insert(ent.BA2_PropsToCreate, child)
        end
    end

    if table.IsEmpty(ent.BA2_PropsToCreate) then -- if we didn't find a suitable child (this should NEVER happen!)
        ErrorNoHalt("[BA2] Door entity ", ent, "(", ent:MapCreationID(), " ", game.GetMap(), ") has no materials and has no suitable children to use as a prop!")
    end

    -- if table.IsEmpty(ent:GetMaterials()) then
    --     for i, child in pairs(ent:GetChildren()) do
    --         if child:GetModel() then
    --             ent.BA2_UsedEntityForProp = child
    --             break
    --         end
    --     end

    --     if ent.BA2_UsedEntityForProp == ent then 
    --         ErrorNoHalt("[BA2] Door entity ", ent, "(", ent:MapCreationID(), " ", game.GetMap(), ") has no materials and has no suitable children to use as a prop!")
    --     end
    -- end

    ent.BA2_DoorInternalsInitialized = true
end

local function checkForCompanion(ent)
    if not BA2_DoorChildren then
        -- because InitPostEntity just doesn't fire sometimes??? fuck you gmod
        initDoorChildrenTable()
    end

    local childDoorMapCreationID = BA2_DoorChildren[ent:MapCreationID()]
    if childDoorMapCreationID then
        childDoor = ents.GetMapCreatedEntity(childDoorMapCreationID)
        if IsValid(childDoor) then
            return childDoor
        end
    end

    local doorMaster = ent:GetInternalVariable(doorMasterVariable, ent)
    if IsValid(doorMaster) then
        return doorMaster
    end
end

local function hideEntity(ent)
    ent:SetNoDraw(true)
    ent:SetSolid(SOLID_NONE)
end

local function restoreEntity(ent)
    ent:SetNoDraw(false)
    ent:SetCollisionGroup(COLLISION_GROUP_NONE)
    ent:SetSolid(SOLID_OBB)
end

local function createDebrisProp(ent, force)
    local prop = ents.Create("prop_physics")
    prop:SetModel(ent:GetModel())
    prop:SetSkin(ent:GetSkin() or 0)
    prop:SetBodygroup(0,ent:GetBodygroup(0) or 0)
    prop:SetPos(ent:GetPos())
    prop:SetAngles(ent:GetAngles())
    prop:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
    prop:SetSolid(SOLID_NONE)

    prop:Spawn()
    prop:Activate()
    local physObj = prop:GetPhysicsObject()
    if IsValid(physObj) then -- why the HELL is this necessary?
        physObj:ApplyForceCenter(force)
    end

    return prop
end

function BA2_BreakDoor(ent, forward)
    if ent.BA2_DoorBroken then return end

    local entPhysObj = ent:GetPhysicsObject()
    if IsValid(entPhysObj) then
        force = forward * entPhysObj:GetVolume() * 0.5
    else
        force = forward * 5000
    end

    ent.BA2_DoorBroken = true
    ent.BA2_BreakForce = forward
    ent.BA2_CreatedProps = {}

    if not ent.BA2_DoorInternalsInitialized then
        initDoorInternals(ent)
    end

    -- make the door silent temporarily (if we need to) so you don't hear door opening sfx when the zombie breaks the door

    if not ent.BA2_DoorIsSilent then
        ent:SetSaveValue(soundUnlockedVariable, "DoorSound.Null")
        ent:SetSaveValue(soundMoveVariable, "DoorSound.Null")
        ent:SetSaveValue(soundOpenVariable, "DoorSound.Null")
        ent:SetSaveValue(noiseMovingVariable, "DoorSound.Null")
        ent:SetSaveValue(noiseArrivedVariable, "DoorSound.Null")
    end

    local companion = checkForCompanion(ent)
    if companion and not companion.BA2_DoorBroken then
        BA2_BreakDoor(companion, forward)
    end

    hideEntity(ent)

    -- open that shit!
    ent:Fire("Unlock")
    ent:Fire("Open")

    -- prevent player from using the invisible door
    ent:Fire("Lock")

    -- local prop = ents.Create("prop_physics")
    -- prop:SetModel(ent.BA2_UsedEntityForProp:GetModel())
    -- prop:SetSkin(ent.BA2_UsedEntityForProp:GetSkin() or 0)
    -- prop:SetBodygroup(0,ent.BA2_UsedEntityForProp:GetBodygroup(0) or 0)
    -- prop:SetPos(ent.BA2_UsedEntityForProp:GetPos())
    -- prop:SetAngles(ent.BA2_UsedEntityForProp:GetAngles())
    -- prop:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
    -- prop:SetSolid(SOLID_NONE)

    -- prop:Spawn()
    -- prop:Activate()
    -- prop:GetPhysicsObject():ApplyForceCenter(force)

    -- ent.BA2_PropDoor = prop

    for index, entToPropify in pairs(ent.BA2_PropsToCreate) do
        if IsValid(entToPropify) then
            hideEntity(entToPropify)
            ent.BA2_CreatedProps[index] = createDebrisProp(entToPropify, force)
        end
    end

    -- if IsValid(ent) then
    --     ent:SetNoDraw(true)
    --     ent:SetSolid(SOLID_NONE)
    -- end

    -- if ent.BA2_UsedEntityForProp ~= ent and IsValid(ent.BA2_UsedEntityForProp) then
    --     ent.BA2_UsedEntityForProp:SetNoDraw(true)
    --     ent.BA2_UsedEntityForProp:SetSolid(SOLID_NONE)
    -- end

    local doorRespawn = GetConVar("ba2_zom_doorrespawn"):GetFloat()
    if doorRespawn > 0 then
        timer.Simple(doorRespawn,function()
            BA2_RepairDoor(ent)
        end)
    end
end

function BA2_RepairDoor(ent)
    if not ent.BA2_DoorBroken or not ent.BA2_DoorInternalsInitialized then return end

    if IsValid(ent) then
        -- if the doors started locked or open, we need to know that while returning stuff to normal
        local doorStartsLocked = ent:HasSpawnFlags(2048)
        local doorStartsOpen = ent:HasSpawnFlags(1) or (ent:GetInternalVariable("m_eSpawnPosition") ~= 0)

        if ent.BA2_OriginalReturnDelay ~= -1 then
            ent:SetSaveValue(ent.BA2_ReturnDelayVariable, ent.BA2_OriginalReturnDelay)
        end

        -- give the door its sounds back
        if not ent.BA2_DoorIsSilent then
            ent:SetSaveValue(soundUnlockedVariable, ent.BA2_OriginalUnlockedSound)
            ent:SetSaveValue(soundMoveVariable, ent.BA2_OriginalMovingSound)
            ent:SetSaveValue(soundOpenVariable, ent.BA2_OriginalOpenSound)
            ent:SetSaveValue(noiseMovingVariable, ent.BA2_OriginalMovingNoise)
            ent:SetSaveValue(noiseArrivedVariable, ent.BA2_OriginalArrivalNoise)
        end

        restoreEntity(ent)

        ent:Fire("Unlock")

        if not doorStartsOpen then
            ent:Fire("Close")
        end

        if doorStartsLocked then
            ent:Fire("Lock")
        end

        -- ent:SetNoDraw(false)
        -- ent:SetCollisionGroup(COLLISION_GROUP_NONE)
        -- ent:SetSolid(SOLID_OBB)
        for index, propifiedEnt in pairs(ent.BA2_PropsToCreate) do
            local createdProp = ent.BA2_CreatedProps[index]
            if IsValid(createdProp) then
                SafeRemoveEntity(createdProp)
            end

            if IsValid(propifiedEnt) then
                restoreEntity(propifiedEnt)
            end
        end
        ent.BA2_DoorHealth = 200
        ent.BA2_DoorBroken = false

        local companion = checkForCompanion(ent)
        if companion and companion.BA2_DoorBroken then
            BA2_RepairDoor(companion)
        end
    end

    -- if ent.BA2_UsedEntityForProp ~= ent and IsValid(ent.BA2_UsedEntityForProp) then
    --     ent.BA2_UsedEntityForProp:SetNoDraw(false)
    --     ent.BA2_UsedEntityForProp:SetCollisionGroup(COLLISION_GROUP_NONE)
    --     ent.BA2_UsedEntityForProp:SetSolid(SOLID_OBB)
    -- end

    -- SafeRemoveEntity(ent.BA2_PropDoor)
end