AddCSLuaFile()

ENT.PrintName = "Horde Spawner"
ENT.Base = "base_anim"
ENT.Type = "anim"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.Category = "Bio-Annihilation II"

function ENT:Initialize()
    self:SetNoDraw(true)
    self:DrawShadow(false)

    if SERVER then
        if #navmesh.GetAllNavAreas() == 0 then
            if IsValid(self:GetCreator()) then
                self:GetCreator():PrintMessage(HUD_PRINTCENTER,"This map doesn't have a navmesh!")
            end
            print("BA2: There is no navmesh! Despawning horde spawner...")
            self:Remove()
        end
        if #ents.FindByClass(self.ClassName) > 1 then
            if IsValid(self:GetCreator()) then
                self:GetCreator():PrintMessage(HUD_PRINTCENTER,"There can only be one Horde Spawner at once!")
            end
            print("BA2: There can only be one Horde Spawner at once!")
            self:Remove()
            return
        end
    end

    self.zoms = {}
    self.numberOfZoms = 0
    self.entList = {}

    if SERVER then
        local function attemptAddEntityToList(ent)
            if ent:IsValid() 
                and not string.StartWith(ent:GetClass(), "nb_ba2") 
                and (ent:IsNPC() or ent:IsNextBot() or (ent:IsPlayer() and not GetConVar("ai_ignoreplayers"):GetBool())) 
            then
                local entIndex = ent:EntIndex()
                self.entList[entIndex] = ent
                ent:CallOnRemove(entIndex.."-HordeSpawnerList",function()
                    timer.Simple(0,function()
                        if self.entList then
                            self.entList[entIndex] = nil 
                        end
                    end)
                end)
            end
        end
    
        for i, ent in pairs(ents.GetAll()) do
            attemptAddEntityToList(ent)
        end
    
        hook.Add("OnEntityCreated", "BA2_HordeSpawner_EntList", function(ent)
            attemptAddEntityToList(ent)
        end)
        
        cvars.AddChangeCallback("ai_ignoreplayers", function (convar, oldValue, newValue)
            -- this seems like an excessive amount of comparison but it ensures that if someone changes ai_ignoreplayers from 1 to 2 it wont break stuff
            -- extremely edge case? yes. better safe than sorry? also yes.
            if tonumber(newValue) > 0 and tonumber(oldValue) == 0 then -- if ignore players is being turned on
                for i, ent in pairs(self.entList) do
                    if ent:IsPlayer() then
                        self.entList[i] = nil  
                    end
                end
            elseif tonumber(oldValue) > 0 and tonumber(newValue) == 0 then -- if ignore players is being turned off
                for i, ent in pairs(player.GetAll()) do
                    self.entList[ent:EntIndex()] = ent
                end
            end
    
        end, "BA2_HordeSpawner_IgnorePlayers")

        self.navs = navmesh.GetAllNavAreas() 

        self:SpawnZoms(math.random(5,10))
        timer.Create("BA2_HordeSpawner",GetConVar("ba2_hs_interval"):GetFloat(),0,function()
            if IsValid(self) then
                self:SpawnZoms(math.random(5,10))
            end
        end)
    end

    if CLIENT then
        EmitSound("ba2/infected/horde.wav",self:GetPos(),-1)
    end
end

function ENT:OnRemove()
    if SERVER then
        hook.Remove("OnEntityCreated", "BA2_HordeSpawner_EntList")
        cvars.RemoveChangeCallback("ai_ignoreplayers", "BA2_HordeSpawner_IgnorePlayers")

        if #ents.FindByClass(self.ClassName) == 0 then -- I am the one and only *guitar riff*
            timer.Remove("BA2_HordeSpawner")
        end
        if GetConVar("ba2_hs_cleanup"):GetBool() and self.zoms then
            for i,z in pairs(self.zoms) do
                if IsValid(z) then
                    z:Remove()
                end
            end
        end
    end
end


if SERVER then

function ENT:SpawnZoms(amnt)
    timer.Adjust("BA2_HordeSpawner",GetConVar("ba2_hs_interval"):GetFloat(),nil,nil)
    local zomThreshold = GetConVar("ba2_hs_max"):GetInt()
    -- local zomType = GetConVar("ba2_hs_appearance"):GetInt()
    -- if zomType == 4 then
    --     zomType = BA2_ZombieTypes[math.random(0,3)]
    -- elseif zomType == 5 then
    --     zomType = BA2_ZombieTypes[math.random(0,2)]
    -- else
    --     zomType = BA2_ZombieTypes[zomType]
    -- end

    local zomTypes = {}
    if GetConVar("ba2_hs_combine_chance"):GetFloat() / 100 > math.random() then
        zomTypes = {"nb_ba2_infected_combine"}
    elseif GetConVar("ba2_hs_carmor_chance"):GetFloat() / 100 > math.random() then
        zomTypes = {"nb_ba2_infected_custom_armored"}
    else
        zomTypes = BA2_GetValidAppearances()
    end

    if SERVER then
        for i = 1,amnt do
            timer.Simple(i * .2,function() -- O P T I M I Z E D
                if IsValid(self) and self.zoms ~= nil and self.numberOfZoms < zomThreshold then
                    local navArea
                    
                    if GetConVar("ba2_hs_proximityspawns"):GetBool() then   
                        local randomEnt = table.Random(self.entList) -- yes, i'm well aware that using math.random is preferred, but this table isn't sequential
                        
                        if randomEnt and randomEnt:IsValid() then
                            local randomEntPosition = randomEnt:GetPos()
                            
                            local safeRadius = GetConVar("ba2_hs_saferadius"):GetInt()
    
                            local randomAngle = math.random() * math.pi * 2
                            local randomX = math.cos(randomAngle) * (safeRadius + math.Rand(0, 0.1 * safeRadius))
                            local randomY = math.sin(randomAngle) * (safeRadius + math.Rand(0, 0.1 * safeRadius))

                            local areaNearRandomEnt = navmesh.GetNearestNavArea(Vector(randomX, randomY, 0) + randomEntPosition)
                            
                            if areaNearRandomEnt and areaNearRandomEnt:IsValid() and not areaNearRandomEnt:IsUnderwater() then
                                navArea = areaNearRandomEnt
                            else
                                return 
                            end
                        else
                            return
                        end
                    else
                        navArea = self.navs[math.random(1,#self.navs)]
                        while navArea:IsUnderwater() do
                            navArea = self.navs[math.random(1,#self.navs)]
                        end
                    end

                    -- while navArea:IsUnderwater() do
                    --     navArea = self.navs[math.random(1,#self.navs)]
                    -- end
                    
                    local spawnPos = navArea:GetCenter()

                    if GetConVar("ba2_hs_morespawnlocations"):GetBool() then
                        local extent = navArea:GetExtentInfo()
                        
                        if extent["SizeX"] > 128 and extent["SizeY"] > 128 then -- is our selected navmesh area pretty big?
                            local randomSpot = math.random(0,8)
                            if randomSpot < 4 then
                                -- let's spawn a zombie at a corner!
                                -- instead of spawning directly at the corner, we move the zombie 20% closer to the center before spawning it
                                local cornerPos = navArea:GetCorner(randomSpot)
                                spawnPos = 0.8 * (cornerPos - spawnPos) + spawnPos
                            elseif randomSpot < 8 then
                                -- let's spawn a zombie inbetween two corners!
                                local firstCorner = randomSpot - 4
                                local secondCorner = firstCorner + 1
                                if secondCorner == 4 then secondCorner = 0 end
    
                                local firstCornerPos = navArea:GetCorner(firstCorner)
                                local secondCornerPos = navArea:GetCorner(secondCorner)
                                
                                -- first, we get the midpoint
                                local midpoint = (firstCornerPos + secondCornerPos) / 2
                                -- now same as before
                                spawnPos = 0.8 * (midpoint - spawnPos) + spawnPos
                            end
                        end 
                    end

                    local zom = ents.Create(zomTypes[math.random(1,#zomTypes)])

                    zom:SetPos(spawnPos)
                    zom.noRise = true
                    if not GetConVar("ba2_hs_proximityspawns"):GetBool() then
                        zom.SearchRadius = math.huge -- Can't have a horde if they don't actually chase people
                    end
                    zom.BA2_CreatedByHordeSpawner = true
                    if GetConVar("ba2_hs_stuckclean"):GetBool() then
                        zom.BA2_RemoveIfStuck = true 
                    end 
                    if GetConVar("ba2_hs_stoptargetingoutsidedetectionrange"):GetBool() then
                        zom.BA2_StopTargetingOutsideDetectionRange = true
                    end
                    zom.BA2_AutoSpawned = true
                    zom:Spawn()
                    zom:Activate()

                    local entIndex = zom:EntIndex()
                    self.zoms[entIndex] = zom
                    self.numberOfZoms = self.numberOfZoms + 1
                    zom:CallOnRemove(entIndex.."-ZomRemove",function()
                        timer.Simple(0,function()
                            if self.numberOfZoms ~= nil then
                                self.numberOfZoms = self.numberOfZoms - 1
                            end
                            if self.zoms ~= nil then
                                self.zoms[entIndex] = nil 
                            end
                        end)
                    end)

                    if GetConVar("ba2_hs_notargetclean"):GetBool() then
                        timer.Simple(6,function()
                            if IsValid(zom) and (zom:GetEnemy() == nil or !zom:IsInWorld()) then
                                zom:Remove()
                            elseif IsValid(zom) then
                                zom.BA2_RemoveNoTarget = true 
                            end
                        end)
                    end
                else return end
            end)
        end
    end
end

end