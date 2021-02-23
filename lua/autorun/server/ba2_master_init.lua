include("autorun/ba2_shared.lua")

util.AddNetworkString("BA2NoNavmeshWarn")
util.AddNetworkString("BA2ReloadCustoms")

-- CreateConVar("ba2_cos_defaultcolor_r",133,FCVAR_ARCHIVE,[[Just save yourself the trouble and set this in the options menu.]])
-- CreateConVar("ba2_cos_defaultcolor_g",165,FCVAR_ARCHIVE,[[Just save yourself the trouble and set this in the options menu.]])
-- CreateConVar("ba2_cos_defaultcolor_b",180,FCVAR_ARCHIVE,[[Just save yourself the trouble and set this in the options menu.]])

CreateConVar("ba2_hs_max",40,FCVAR_ARCHIVE,[[The maximum number of Horde Spawner-created zombies that can be alive at once.
    More zombies means more difficulty - for both you and your machine.]],1)
CreateConVar("ba2_hs_interval",1,FCVAR_ARCHIVE,[[The Horde Spawner will wait this long before spawning a new group of zombies.
    The lower this is, the faster zombies will spawn.]],0.1)
CreateConVar("ba2_hs_saferadius",500,FCVAR_ARCHIVE,[[The Horde Spawner cannot spawn zombies closer to potential targets than this distance.
    You may need to turn this value down on very small maps.]],0)
CreateConVar("ba2_hs_appearance",1,FCVAR_ARCHIVE,[[Configures the type of zombie the Horde Spawner creates.
    0: Citizens
    1: Rebels
    2: Cobmine
    3: Custom
    4: Any of the above
    5: Any except Custom Infected]],0,5
)
CreateConVar("ba2_hs_cleanup",1,FCVAR_ARCHIVE,[[If enabled, the Horde Spawner will also remove all of the zombies it created when it gets deleted.]])
concommand.Add("ba2_hs_delete",BA2_DestroyHS,nil,"Destroys the active Horde Spawner, if it exists.")

CreateConVar("ba2_inf_contagionmult",1,FCVAR_ARCHIVE,[[Mutliply the distance the Bio-Virus can spread to others by this amount.
    Set to 0 to disable contagion.]],0)
CreateConVar("ba2_inf_plymult",1,FCVAR_ARCHIVE,[[Multiply infection received by players by this amount.
    Set to 0 to prevent player infection.]],0)
CreateConVar("ba2_inf_npcmult",1,FCVAR_ARCHIVE,[[Multiply infection received by NPCs by this amount.
    Set to 0 to prevent NPC infection.]],0)
CreateConVar("ba2_inf_plyraise",1,FCVAR_ARCHIVE,[[If enabled, players killed by the Bio-Virus will be raised into zombies.]])
CreateConVar("ba2_inf_npcraise",1,FCVAR_ARCHIVE,[[If enabled, NPCs killed by the Bio-Virus will be raised into zombies.]])
CreateConVar("ba2_inf_dmgmult",1,FCVAR_ARCHIVE,[[Multiply damage dealt by infection by this amount.]],0)
CreateConVar("ba2_inf_killtoraise",1,FCVAR_ARCHIVE,[[If enabled, the Bio-Virus or one of its hosts must directly kill a victim to raise them into a zombie.
    This means that you can kill an infected entity to prevent them from becoming a zombie, or commit suicide to prevent yourself from being raised.]])
CreateConVar("ba2_inf_romeromode",0,FCVAR_ARCHIVE,[[If enabled, all entities who die will become a zombie regardless of their infection level.]])

CreateConVar("ba2_zom_pursuitspeed",1,FCVAR_ARCHIVE,[[Configures the speed zombies run at when they find a target.
    0: Pacing speed ("*yawn* Let me get a drink...")
    1: Running ("Give me some space, will you?")
    2: Full sprint ("OH GOD RUN")]],0,2
)
CreateConVar("ba2_zom_health",100,FCVAR_ARCHIVE,[[Zombies have this much health. Minimum 1. Only affects new zombies.]],1)
CreateConVar("ba2_zom_dmgmult",1,FCVAR_ARCHIVE,[[Multiply zombie damage per attack by this amount.]],0)
CreateConVar("ba2_zom_infectionmult",1,FCVAR_ARCHIVE,[[Multiply zombie infection per attack by this amount.]],0)
CreateConVar("ba2_zom_nonheadshotmult",1,FCVAR_ARCHIVE,[[Multiply zombie damage received on non-headshots by this amount.]],0,1)
CreateConVar("ba2_zom_damagestun",1,FCVAR_ARCHIVE,[[If enabled, zombies will stagger if they take more than half their current health in damage.]])
CreateConVar("ba2_zom_emergetime",8,FCVAR_ARCHIVE,[[After getting killed by an infectious source, entities will take this long to rise into a zombie.]])
CreateConVar("ba2_zom_armdamage",1,FCVAR_ARCHIVE,[[If enabled, zombies can have their arms broken.
    Each lost arm halves damage output. If both arms are broken, the zombie cannot grab targets or break down barricades.]])
CreateConVar("ba2_zom_legdamage",1,FCVAR_ARCHIVE,[[If enabled, zombies can have their legs broken.
    Legs are harder to break than arms, but breaking one forces them to crawl, making them slower and easier to headshot.]])
CreateConVar("ba2_zom_explimbdamage",1,FCVAR_ARCHIVE,[[If enabled, zombies have a chance to lose a random limb when they take explosive damage. (NYI)]])
CreateConVar("ba2_zom_medicdropchance",20,FCVAR_ARCHIVE,[[The percent chance for an Infected Rebel with a Medic model to drop a Health Vial on death.
    Set to 0 to disable this feature.]],0,100)
CreateConVar("ba2_zom_breakobjects",1,FCVAR_ARCHIVE,[[If enabled, zombies can swat at and damage props and doors in their way.]])
CreateConVar("ba2_zom_breakphys",1,FCVAR_ARCHIVE,[[If enabled, zombies can unfreeze and unconstrain props with their swatting.]])
CreateConVar("ba2_zom_breakdoors",1,FCVAR_ARCHIVE,[[If enabled, zombies can break down standard doors.]])
CreateConVar("ba2_zom_doorrespawn",30,FCVAR_ARCHIVE,[[The time in seconds it takes for a door to respawn after getting broken down.
    If this value is zero or less, then the door will not respawn until the map is cleaned up.]],0)

CreateConVar("ba2_misc_corpselife",10,FCVAR_ARCHIVE,[[The amount of time before a zombie's corpse is cleaned up.
    Set to -1 for infinite lifetime.]],-1
)
CreateConVar("ba2_misc_navmeshwarn",1,FCVAR_ARCHIVE,[[If enabled, Zambo the Helper Zombie will notify you if the map has no navmesh when you load in.]])
CreateConVar("ba2_misc_maxfilters",4,FCVAR_ARCHIVE,[[The maximum number of gas mask filters each player can carry.
    Set to -1 to disable this limit.]],-1)
CreateConVar("ba2_misc_startwithmask",0,FCVAR_ARCHIVE,[[If enabled, all players will spawn with a gas mask on their person.]])
CreateConVar("ba2_misc_deathdropmask",1,FCVAR_ARCHIVE,[[If enabled, players will drop their gas mask on death.]])
CreateConVar("ba2_misc_deathdropfilter",1,FCVAR_ARCHIVE,[[If enabled, players will drop all of their gas mask filters on death.]])
CreateConVar("ba2_misc_headshoteff",1,FCVAR_ARCHIVE,[[If enabled, zombies' heads have a chance to comically explode when they are killed by a headshot.]])
CreateConVar("ba2_misc_airwastevisuals",1,FCVAR_ARCHIVE,[[If enabled, air waste will turn the map's fog green.]])

concommand.Add("ba2_misc_maggots",BA2_ToggleMaggotMode,nil,"If God had wanted you to live, he would not have created ME!")


-- Net messages
net.Receive("BA2ReloadCustoms",function(l,p)
    if p:IsAdmin() then
        BA2_WriteToAltModels(net.ReadTable())
        BA2_ReloadCustoms()
    end
end)

-- Unique functions
function BA2_AddInfection(ent,amnt)
    if amnt < 0 then return end
    if not IsValid(ent) or not (ent:IsNPC() or ent:IsPlayer()) then return end
    if ent:IsPlayer() and !ent:Alive() then return end
    if ent:IsNPC() and BA2_ConvertibleNpcs[ent:GetClass()] == nil then return end

    amnt = math.floor(amnt)
    if ent:IsPlayer() then
        amnt = amnt * GetConVar("ba2_inf_plymult"):GetFloat()
    elseif ent:IsNPC() then
        amnt = amnt * GetConVar("ba2_inf_npcmult"):GetFloat()
    end

    if amnt == 0 then return end

    if ent.BA2Infection == nil then
        ent.BA2Infection = amnt
    else
        ent.BA2Infection = ent.BA2Infection + amnt
    end
end

function BA2_InfectionTick(ent)
    if ent.BA2Infection == nil or ent.BA2Infection == 0 then return end

    if ent:IsPlayer() and ent:GetInfoNum("ba2_cl_infdmgeff",1) == 1 then
        ent:ScreenFade(SCREENFADE.IN,Color(74,127,0,64),.75,0)
    end

    local dmg = DamageInfo()
    dmg:SetDamage(math.random(3,5) * GetConVar("ba2_inf_dmgmult"):GetFloat())
    dmg:SetDamageType(DMG_DIRECT)
    dmg:SetDamageCustom(DMG_BIOVIRUS)
    dmg:SetAttacker(BA2_InfectionManager())
    dmg:SetInflictor(BA2_InfectionManager())

    local lastArmor = nil
    if ent:IsPlayer() and ent:Armor() > 0 then
        lastArmor = ent:Armor()
        ent:SetArmor(0)
    end
    ent:TakeDamageInfo(dmg)
    if lastArmor then
        ent:SetArmor(lastArmor)
    end

    if IsValid(ent) or (ent:IsPlayer() and ent:Alive()) then
        timer.Simple(0,function()
            if ent.BA2Infection == nil then return end

            if IsValid(ent) and GetConVar("ba2_inf_contagionmult"):GetFloat() > 0 and !BA2_GetActiveMask(ent) then
                for i,e in pairs(ents.FindInSphere(ent:GetPos(),100 * GetConVar("ba2_inf_contagionmult"):GetFloat())) do
                    if e ~= ent and !BA2_GetActiveMask(ent) then
                        if e.BA2Infection == nil then
                            e.BA2Infection = 1
                        elseif e.BA2Infection < ent.BA2Infection then
                            BA2_AddInfection(e,ent.BA2Infection / math.random(4,8))
                        end
                    end
                end
            end
            
            if math.random(1,2) == 1 then
                ent:EmitSound("ba2_infectdamage")
            end
            if ent.BA2Infection * 3 > ent:Health() then
                --ent:SetColor(BA2_GetDefaultColor())
                ent:EmitSound("ba2_infectcry")
            -- elseif ent:GetColor() == BA2_GetDefaultColor() then
            --     ent:SetColor(Color(255,255,255))
            end
    
            ent.BA2Infection = math.max(0,ent.BA2Infection - 1)
        end)
    end
end


function BA2_InfectionManager()
    if not IsValid(BA2_InfManager) then
        BA2_InfManager = ents.Create("ba2_infection_manager")
        BA2_InfManager:Spawn()
        BA2_InfManager:Activate()
    end

    return BA2_InfManager
end

function BA2_RaiseZombie(ent)
    local zom = ents.Create("nb_ba2_infected")
    zom:SetPos(ent:GetPos())

    zom.InfBody = ent:GetModel()
    zom.InfSkin = ent:GetSkin()
    zom.InfBodyGroups = {}
    zom.InfVoice = ent.InfVoice or nil
    if GetConVar("ba2_zom_emergetime"):GetFloat() == 0 then
        zom.noRise = true
    end

    for i = 1,ent:GetNumBodyGroups() do
        table.insert(zom.InfBodyGroups, ent:GetBodygroup(i))
    end

    zom:Spawn()
    zom:Activate()
end
function BA2_InfectionDeath(ent,inflict,killer)
    --if ent.BA2Infection == 0 and not GetConVar("ba2_inf_romeromode"):GetBool() then return end
    if ent:IsNPC() and ((!GetConVar("ba2_inf_npcraise"):GetInt() or !BA2_ConvertibleNpcs[ent:GetClass()])) then return end
    if string.StartWith(ent:GetClass(),"nb_ba2_infected") then return end

    if GetConVar("ba2_inf_romeromode"):GetBool() or (!GetConVar("ba2_inf_killtoraise"):GetBool() and ent.BA2Infection > 0)
         or inflict == BA2_InfectionManager() or (IsValid(killer) and string.StartWith(killer:GetClass(),"nb_ba2_infected")) then
        local riseTime = GetConVar("ba2_zom_emergetime"):GetFloat()

        if riseTime == 0 then
            BA2_RaiseZombie(ent)
        else
            local body = ents.Create("prop_ragdoll")

            body:SetPos(ent:GetPos())
            body:SetAngles(ent:GetAngles())
            body:SetModel(ent:GetModel())
            body:SetColor(BA2_GetDefaultColor())
            body:SetSkin(ent:GetSkin())
            for i = 1,ent:GetNumBodyGroups() do
                body:SetBodygroup(i,ent:GetBodygroup(i))
            end
            body:SetCollisionGroup(COLLISION_GROUP_WEAPON)

            for id = 1,body:GetPhysicsObjectCount() do
                local bone = body:GetPhysicsObjectNum(id - 1)
                if IsValid(bone) then
                    local pos,angle = ent:GetBonePosition(body:TranslatePhysBoneToBone(id - 1))
                    bone:SetPos(pos)
                    bone:SetAngles(angle)
                    bone:AddVelocity(ent:GetVelocity())
        
                    body:ManipulateBoneScale(id - 1,ent:GetManipulateBoneScale(id - 1))
                end
            end

            if ent:IsPlayer() then
                local PlyVo = math.floor(ent:GetInfoNum("ba2_cl_playervoice",-1))
                if PlyVo ~= -1 then
                    body.InfVoice = PlyVo
                end
            end

            body:Spawn()

            timer.Simple(riseTime,function()
                if IsValid(body) then
                    BA2_RaiseZombie(body)
                    body:Remove()
                end
            end)
        end

        ent:Remove()
        if ent:IsPlayer() then
            ent:GetRagdollEntity():Remove()
        end
    end
end

function BA2_ZombieGrab(zom,ent)
    if ent:IsPlayer() then
        if ent.InitWalk == nil then
            ent.InitWalk = ent:GetWalkSpeed()
        end
        if ent.InitRun == nil then
            ent.InitRun = ent:GetRunSpeed()
        end

        ent:ViewPunch(Angle(10,0,0))
    else
        ent.GrabPos = ent:GetPos()
    end

    timer.Create(zom:EntIndex().."-grab",0,0,function()
        if !IsValid(zom) or !IsValid(ent) or (ent:IsPlayer() and !ent:Alive()) or !zom:GetAttacking() then
            if ent:IsPlayer() then
                ent.BA2Grabbed = nil
            end
            timer.Remove(zom:EntIndex().."-grab")
        else
            if ent:IsPlayer() then
                ent.BA2Grabbed = true
            else
                ent:SetPos(ent.GrabPos)
            end
        end
    end)
end

function BA2_GetDefaultColor()
    return Color(133,165,180)
end

function BA2_ToggleMaggotMode()
    if not IsMounted("tf") then
        print("Numbnuts! You need to mount Team Fortress 2!")
    elseif os.date("%m") == "05" then
        if BA2_MaggotMode == nil then
            BA2_MaggotMode = true
            print("Maggot Mode activated! Booyah!")
        else
            BA2_MaggotMode = nil
            print("Maggot Mode is off! You have dishonored this entire unit.")
        end
    else
        print("Come back the month of May, hippie!")
    end
end
function BA2_GetMaggotMode()
    return BA2_MaggotMode ~= nil
end

function BA2_DestroyHS()
    local hs = ents.FindByClass("ba2_hordespawner")
    if #hs >= 1 then
        hs[1]:Remove()
        print("BA2: Horde Spawner removed by console")
    else
        print("BA2: No Horde Spawner found!")
    end
end

function BA2_DropGasmask(p)
    local mask = ents.Create("ba2_gasmask")
    mask:SetPos(p:EyePos())
    mask:SetAngles(p:EyeAngles())
    mask.BA2_FilterPct = p:GetNWInt("BA2_GasmaskFilterPct",100)
    mask:Spawn()
    mask:Activate()
    mask:GetPhysicsObject():ApplyForceCenter(p:GetForward() * 90)

    BA2_GasmaskSound(p)
    p:SetNWBool("BA2_GasmaskOn",false)
    p:SetNWBool("BA2_GasmaskOwned",false)
end
function BA2_DropFilter(p)
    local filter = ents.Create("ba2_gasmask_filter")
    filter:SetPos(p:EyePos() + p:GetForward() * 9)
    filter:SetAngles(p:EyeAngles())
    filter:Spawn()
    filter:Activate()
    filter:GetPhysicsObject():ApplyForceCenter(p:GetForward() * 900)

    p:SetNWInt("BA2_GasmaskFilters",p:GetNWInt("BA2_GasmaskFilters",1) - 1)
end
function BA2_GetActiveMask(p)
    if p:IsPlayer() then
        return p:GetNWBool("BA2_GasmaskOn",false) and (!GetConVar("ba2_misc_maskfilters"):GetBool() or p:GetNWInt("BA2_GasmaskFilterPct",0) > 0)
    elseif p:IsNPC() then
        return BA2_GasmaskNpcs[p:GetClass()]
    end
end

function BA2_GasmaskSound(p,sound)
    if sound == nil then
        if p.BA2_MaskSound == nil then return end
        p.BA2_MaskSound:Stop()
        p.BA2_MaskSoundName = nil
    elseif p.BA2_MaskSound == nil then
        p.BA2_MaskSound = CreateSound(p,sound)
        p.BA2_MaskSoundName = sound
        p.BA2_MaskSound:Play()
    elseif sound ~= p.BA2_MaskSoundName then
        p.BA2_MaskSound:Stop()
        p.BA2_MaskSound = CreateSound(p,sound)
        p.BA2_MaskSoundName = sound
        p.BA2_MaskSound:Play()
    end
end


-- Hooks and timers
hook.Add("PlayerSpawn","ba2_initSpeed",function(p)
    p.BA2Infection = 0
end)

hook.Add("SetupMove","BA2_GrabSlow",function(p,mv,cmd)
    if p.BA2Grabbed == true then
        mv:SetMaxClientSpeed(20)
    end
end)

hook.Add("OnEntityCreated","ba2_npcZomRelation",function(npc)
    if npc:IsNPC() then
        for i,z in pairs(ents.FindByClass("nb_ba2_infected*")) do
            npc:AddEntityRelationship(z,D_HT,1)
        end
    end
end)

timer.Create("BA2_ServerTick",1.25,0,function()
    local entTable = table.Add(player.GetAll(),ents.FindByClass("npc_*"))

    for i,ent in pairs(entTable) do
        if ent.BA2Infection == nil then
            ent.BA2Infection = 0
        elseif ent.BA2Infection > 0 then
            BA2_InfectionTick(ent)
        end

        if ent:IsPlayer() then
            if ent.BA2_Exhaustion == nil then
                ent.BA2_Exhaustion = 0
            end

            local exhaustThres = 25 - (ent:GetMaxHealth() - ent:Health()) / 8
            if ((ent:IsSprinting() and ent:GetVelocity():Length() > 0) or ent:WaterLevel() == 3) and ent.BA2_Exhaustion < exhaustThres * 1.5 then
                ent.BA2_Exhaustion = ent.BA2_Exhaustion + 5
            elseif ent:GetVelocity():Length() > ent:GetWalkSpeed() then
                ent.BA2_Exhaustion = ent.BA2_Exhaustion - 1
            else
                ent.BA2_Exhaustion = math.max(ent.BA2_Exhaustion - 3,0)
            end

            --print(ent.BA2_Exhaustion)
            if ent:GetNWBool("BA2_GasmaskOn",false) then
                if ent:WaterLevel() == 3 then
                    BA2_GasmaskSound(ent)
                elseif ent.BA2_Exhaustion >= exhaustThres then
                    BA2_GasmaskSound(ent,"ba2/gasmask/mask_breathe_heavy.wav")
                elseif !BA2_GetActiveMask(ent) or ent:Health() < ent:GetMaxHealth() / 5 then
                    BA2_GasmaskSound(ent,"ba2/gasmask/mask_strained.wav")
                else
                    BA2_GasmaskSound(ent,"ba2/gasmask/mask_breathe_light.wav")
                end
            end
        end
    end
end)

timer.Start("BA2_ServerTick")


timer.Create("BA2_GasmaskTick",0.5,0,function()
    for i,ent in pairs(player.GetAll()) do
        if GetConVar("ba2_misc_maskfilters"):GetBool() and ent:GetNWBool("BA2_GasmaskOn",false) then
            ent:SetNWInt("BA2_GasmaskFilterPct",math.max(0,ent:GetNWBool("BA2_GasmaskFilterPct") - 0.25))
        end
    end
end)

timer.Start("BA2_GasmaskTick")

hook.Add("PostCleanupMap","BA2_PostCleanup",function()
    for i,p in pairs(player.GetAll()) do
        if p:GetNWBool("BA2_GasmaskOn",false) and p.BA2_MaskSoundName ~= nil then
            p.BA2_MaskSound = CreateSound(p,p.BA2_MaskSoundName)
            p.BA2_MaskSound:Play()
        end
    end
end)


hook.Add("PlayerDeath","BA2_PlayerDeath",function(p,inf,ent)
    BA2_InfectionDeath(p,inf,ent)

    p.BA2Infection = 0
    p.BA2_Exhaustion = 0

    p:SetNWBool("BA2_GasmaskOn",false)
    if p.BA2_MaskSound then
        p.BA2_MaskSound:Stop()
    end
    if GetConVar("ba2_misc_deathdropmask"):GetBool() and p:GetNWBool("BA2_GasmaskOwned",false) then
        BA2_DropGasmask(p)
    end

    if GetConVar("ba2_misc_deathdropfilter"):GetBool() then
        for i = 1,p:GetNWInt("BA2_GasmaskFilters",0) do
            BA2_DropFilter(p)
        end
    end
end)
hook.Add("OnNPCKilled","BA2_NPCDeath",function(npc,ent,inf)
    if string.StartWith(npc:GetClass(),"nb_ba2_infected") then return end
    BA2_InfectionDeath(npc,inf,ent)
end)
hook.Add("EntityTakeDamage","BA2_OnDamage",function(e,dmg)
    -- if dmg:GetDamageCustom() == DMG_BIOVIRUS and e:Health() <= dmg:GetDamage() then
    --     BA2_InfectionDeath(e,dmg:GetInflictor(),dmg:GetAttacker())
    -- end

    if e:IsPlayer() and e:GetNWBool("BA2_GasmaskOn",false) and dmg:GetDamage() < e:Health() and dmg:GetDamage() * math.random(0,20) / 10 >= e:Health() / 4  then
        BA2_GasmaskSound(e)
        e:EmitSound("ba2/gasmask/mask_pain"..math.random(1,2)..".wav",90,110)
    end
end)

hook.Add("PlayerSay","BA2_Chat",function(p,msg)
    if !p:Alive() then return end

    if msg == "!dgasmask" then
        if !p:GetNWBool("BA2_GasmaskOwned",false) then
            p:ChatPrint("You don't have a gas mask.")
        else
            p:EmitSound("npc/combine_soldier/zipline_hitground2.wav")
            BA2_DropGasmask(p)
        end

        return ""
    end
    if msg == "!gasmask" then
        if p:GetNWBool("BA2_GasmaskOwned",false) then
            local bool = p:GetNWBool("BA2_GasmaskOn",false)

            if bool then
                p:EmitSound("npc/combine_soldier/zipline_hitground2.wav")
                BA2_GasmaskSound(p)
                
            else
                p:EmitSound("npc/combine_soldier/zipline_hitground1.wav")
                BA2_GasmaskSound(p,"ba2/gasmask/mask_breathe_light.wav")
            end

            p:SetNWBool("BA2_GasmaskOn",not bool)
            p:ViewPunch(Angle(10,0,0))
        else
            p:ChatPrint("You don't have a gas mask.")
        end

        return ""
    elseif msg == "!cfilter" then
        if p:GetNWBool("BA2_GasmaskOwned",false) then
            p:ChatPrint("Gas Mask: "..math.ceil(p:GetNWInt("BA2_GasmaskFilterPct",0)).."%")
        else
            p:ChatPrint("Gas Mask: N/A")
        end

        p:ChatPrint("Reserve Filters: "..p:GetNWInt("BA2_GasmaskFilters",0))

        return ""
    elseif msg == "!ufilter" then
        if !p:GetNWBool("BA2_GasmaskOwned",false) then
            p:ChatPrint("You don't have a gas mask.")
        elseif !GetConVar("ba2_misc_maskfilters"):GetBool() then
            p:ChatPrint("These filters are perpetual. Swapping them out won't be necessary.")
        elseif p:GetNWBool("BA2_GasmaskOn",false) then
            p:ChatPrint("You will need to take off your gas mask first. (!gasmask)")
        elseif p:GetNWInt("BA2_GasmaskFilters",0) == 0 then
            p:ChatPrint("You don't have any reserve filters.")
        elseif p:GetNWInt("BA2_GasmaskFilterPct",0) == 100 then
            p:ChatPrint("Your gas mask already has a fresh filter.")
        else
            p:SetNWInt("BA2_GasmaskFilterPct",100)
            p:SetNWInt("BA2_GasmaskFilters",p:GetNWInt("BA2_GasmaskFilters",1) - 1)

            local prop = ents.Create("ba2_gasmask_filter")
            prop.BA2_Scenic = true

            prop:SetPos(p:EyePos() + p:GetForward() * 18)
            prop:Spawn()
            prop:Activate()
            prop:GetPhysicsObject():ApplyForceCenter(p:GetForward() * 900)

            SafeRemoveEntityDelayed(prop,6)

            p:EmitSound("physics/metal/weapon_footstep1.wav")
            p:ViewPunch(Angle(10,0,0))
        end

        return ""
    elseif msg == "!dfilter" then
        if p:GetNWInt("BA2_GasmaskFilters",0) == 0 then
            p:ChatPrint("You don't have any reserve filters.")
        else
            BA2_DropFilter(p)
            p:EmitSound("physics/metal/weapon_footstep2.wav")
        end

        return ""
    end
end)
hook.Add("PlayerSpawn","BA2_PlayerSpawn",function(p)
    if GetConVar("ba2_misc_startwithmask"):GetBool() then
        p:SetNWBool("BA2_GasmaskOwned",true)
        p:SetNWInt("BA2_GasmaskFilterPct",100)
    end
end)

-- Code by Sninctbur