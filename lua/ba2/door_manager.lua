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

hook.Add("InitPostEntity", "BA2_InitializeDoorChildrenTable", function()
    if not BA2_DoorChildren then
        BA2_DoorChildren = {}

        for i, ent in pairs(ents.GetAll()) do
            if (string.StartWith(ent:GetClass(),"func_door") or string.StartWith(ent:GetClass(),"prop_door")) and ent:MapCreationID() ~= -1 then
                local doorMaster = ent:GetInternalVariable("m_hMaster")
                if IsValid(doorMaster) and doorMaster:MapCreationID() ~= -1 then
                    BA2_DoorChildren[doorMaster:MapCreationID()] = ent:MapCreationID()
                end
            end
        end
    end
end)

--[[
    The second case is comparatively easier to deal with.
    If a door is broken while better door breaking is enabled, we open that door.
    As a result, that door tells its companion to open through the Map I/O system.
    We prevent this input from being processed so that we can open the companion door through the BA2_BreakDoor method.
]]

hook.Add("AcceptInput", "BA2_BreakChildViaMapIO", function( ent, name, activator, caller, data )
    if name == "Open" and caller.BA2_DoorBroken and not ent.BA2_DoorBroken and GetConVar("ba2_zom_betterdoorbreaking"):GetBool() then
        BA2_BreakDoor(ent, caller.BA2_BreakForce)
        return true
    end
end)


function BA2_BreakDoor(ent, force)
    if ent.BA2_DoorBroken then return end

    ent.BA2_DoorBroken = true
    ent.BA2_BreakForce = force

    local usedEntityForProp = ent

    local doBetterDoorBreaking = GetConVar("ba2_zom_betterdoorbreaking"):GetBool()

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

    -- these are defined here to make sure they can be accessed where they need to be
    local originalUnlockedSound, originalMovingSound, originalOpenSound, originalMovingNoise, originalArrivalNoise, originalReturnDelay, doorIsSilent--, childOriginalReturnDelay

    local soundUnlockedVariable = "soundunlockedoverride"
    local soundMoveVariable = "soundmoveoverride"
    local soundOpenVariable = "soundopenoverride"
    local noiseMovingVariable = "noise1"
    local noiseArrivedVariable = "noise2" -- real nice names i have to work with here
    local returnDelayVariable = "returndelay"

    local doorMasterVariable = "m_hMaster"

    if doBetterDoorBreaking then
        originalUnlockedSound = ent:GetInternalVariable(soundUnlockedVariable)
        originalMovingSound = ent:GetInternalVariable(soundMoveVariable)
        originalOpenSound = ent:GetInternalVariable(soundOpenVariable)
        originalMovingNoise = ent:GetInternalVariable(noiseMovingVariable)
        originalArrivalNoise = ent:GetInternalVariable(noiseArrivedVariable)
        originalReturnDelay = ent:GetInternalVariable(returnDelayVariable)

        if not originalReturnDelay then
            returnDelayVariable = "m_flWait"
            originalReturnDelay = ent:GetInternalVariable(returnDelayVariable)
        end

        doorIsSilent = ent:HasSpawnFlags(4096)
        -- for doors that automatically close, get them to not do that while we're messing with it
        if originalReturnDelay ~= -1 then
            ent:SetSaveValue(returnDelayVariable, -1)
        end

        -- make the door silent temporarily (if we need to) so you don't hear door opening sfx when the zombie breaks the door

        if not doorIsSilent then
            ent:SetSaveValue(soundUnlockedVariable, "DoorSound.Null")
            ent:SetSaveValue(soundMoveVariable, "DoorSound.Null")
            ent:SetSaveValue(soundOpenVariable, "DoorSound.Null")
            ent:SetSaveValue(noiseMovingVariable, "DoorSound.Null")
            ent:SetSaveValue(noiseArrivedVariable, "DoorSound.Null")
        end

        local childDoorMapCreationID = BA2_DoorChildren[ent:MapCreationID()]
        if childDoorMapCreationID then
            childDoor = ents.GetMapCreatedEntity(childDoorMapCreationID)
            if IsValid(childDoor) and not childDoor.BA2_DoorBroken then
                BA2_BreakDoor(childDoor, force)
            end
        end

        local doorMaster = ent:GetInternalVariable(doorMasterVariable, ent)
        if IsValid(doorMaster) and not doorMaster.BA2_DoorBroken then
            BA2_BreakDoor(doorMaster, force)
        end

        -- open that shit!
        ent:Fire("Unlock")
        ent:Fire("Open")
    end

    -- if the functional door is an invisible brush where the visible "door" is a prop
    -- god damn you rp_riverden_v1a
    if table.IsEmpty(ent:GetMaterials()) then
        for i, child in pairs(ent:GetChildren()) do
            if child:GetModel() then
                usedEntityForProp = child
                break
            end
        end

        if usedEntityForProp == ent then -- if we didn't find a suitable child (this should NEVER happen!)
            ErrorNoHalt("Door entity ", ent, " has no materials and has no suitable children to use as a prop!")
        end
    end

    local prop = ents.Create("prop_physics")
    prop:SetModel(usedEntityForProp:GetModel())
    prop:SetSkin(usedEntityForProp:GetSkin() or 0)
    prop:SetBodygroup(0,usedEntityForProp:GetBodygroup(0) or 0)
    prop:SetPos(usedEntityForProp:GetPos())
    prop:SetAngles(usedEntityForProp:GetAngles())
    prop:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
    prop:SetSolid(SOLID_NONE)

    prop:Spawn()
    prop:Activate()
    prop:GetPhysicsObject():ApplyForceCenter(force)

    if IsValid(ent) then
        ent:SetNoDraw(true)
        ent:SetSolid(SOLID_NONE)
    end

    if usedEntityForProp ~= ent and IsValid(usedEntityForProp) then
        usedEntityForProp:SetNoDraw(true)
        usedEntityForProp:SetSolid(SOLID_NONE)
    end

    local doorRespawn = GetConVar("ba2_zom_doorrespawn"):GetFloat()
    if doorRespawn > 0 then
        timer.Simple(doorRespawn,function()
            if IsValid(ent) and ent.BA2_DoorHealth ~= 200 then
                if doBetterDoorBreaking then
                    -- if the doors started locked or open, we need to know that while returning stuff to normal
                    local doorStartsLocked = ent:HasSpawnFlags(2048)
                    local doorStartsOpen = ent:HasSpawnFlags(1) or (ent:GetInternalVariable("m_eSpawnPosition") ~= 0)

                    if originalReturnDelay ~= -1 then
                        ent:SetSaveValue(returnDelayVariable, originalReturnDelay)
                    end

                    if doorStartsLocked then
                        ent:Fire("Lock")
                    end

                    if not doorStartsOpen then
                        ent:Fire("Close")
                    end

                    -- give the door its sounds back
                    if not doorIsSilent then
                        ent:SetSaveValue(soundUnlockedVariable, originalUnlockedSound)
                        ent:SetSaveValue(soundMoveVariable, originalMovingSound)
                        ent:SetSaveValue(soundOpenVariable, originalOpenSound)
                        ent:SetSaveValue(noiseMovingVariable, originalMovingNoise)
                        ent:SetSaveValue(noiseArrivedVariable, originalArrivalNoise)
                    end

                    -- if IsValid(childDoor) and childOriginalReturnDelay ~= -1 then
                    --     childDoor:SetSaveValue(returnDelayVariable, childOriginalReturnDelay)
                    -- end
                end

                ent:SetNoDraw(false)
                ent:SetCollisionGroup(COLLISION_GROUP_NONE)
                ent:SetSolid(SOLID_OBB)
                ent.BA2_DoorHealth = 200
                ent.BA2_DoorBroken = false
            end

            if usedEntityForProp ~= ent and IsValid(usedEntityForProp) then
                usedEntityForProp:SetNoDraw(false)
                usedEntityForProp:SetCollisionGroup(COLLISION_GROUP_NONE)
                usedEntityForProp:SetSolid(SOLID_OBB)
            end

            SafeRemoveEntity(prop)
        end)
    end
end