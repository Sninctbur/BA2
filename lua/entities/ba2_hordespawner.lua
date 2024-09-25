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
            -- print("BA2: There is no navmesh! Despawning horde spawner...")
            self:Remove()
        end
        if #ents.FindByClass(self.ClassName) > 1 then
            if IsValid(self:GetCreator()) then
                self:GetCreator():PrintMessage(HUD_PRINTCENTER,"There can only be one Horde Spawner at once!")
            end
            -- print("BA2: There can only be one Horde Spawner at once!")
            self:Remove()
            return
        end
    end

    self.zoms = {}
    if SERVER then
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
                if IsValid(self) and self.zoms ~= nil and #self.zoms < zomThreshold then
                    local maxDist = GetConVar("ba2_hs_maxradius"):GetInt()
                    local minDist = GetConVar("ba2_hs_saferadius"):GetInt()
                    local validNavs = {}
                    if maxDist > 0 or minDist > 0 then
                        if maxDist == 0 then
                            maxDist = math.huge
                        end
                        local navsInRange = {}
                        local spawnEnts = ents.FindByClass("npc_*")
                        if !GetConVar("ai_ignoreplayers"):GetBool() then
                            table.Add(spawnEnts,player.GetAll())
                        end

                        for i,nav in pairs(self.navs) do
                            if nav:IsUnderwater() then continue end

                            for i,ent in pairs(spawnEnts) do
                                local dist = nav:GetCenter():Distance(ent:GetPos())
                                if dist <= maxDist and dist > minDist then
                                    local tr = util.TraceHull({
                                        start = nav:GetCenter(),
                                        endpos = nav:GetCenter(),
                                        mins = Vector( -16, -16, 0 ),
	                                    maxs = Vector( 16, 16, 71 )
                                    })

                                    if !tr.Hit then
                                        table.insert(navsInRange,nav)
                                    end
                                end
                            end
                        end

                        validNavs = navsInRange
                    else
                        validNavs = self.navs
                    end
                    local navArea = validNavs[math.random(1,#validNavs)]
                    if navArea == nil then
                        print("BA2: No valid nav areas to spawn in!")
                        return
                    end

                    -- while navArea:IsUnderwater() do -- Can't spawnkill our zombies
                    --     navArea = self.navs[math.random(1,#self.navs)]
                    -- end
                    
                    local spawnPos = navArea:GetCenter()

                    local zom = ents.Create(zomTypes[math.random(1,#zomTypes)])

                    zom:SetPos(spawnPos)
                    zom.noRise = true
                    zom.BA2_AutoSpawned = true
                    zom.SearchRadius = math.huge -- Can't have a horde if they don't actually chase people
                    zom:Spawn()
                    zom:Activate()
                    
                    table.insert(self.zoms,zom)
                    zom:CallOnRemove(zom:EntIndex().."-ZomRemove",function()
                        timer.Simple(0,function()
                            if self.zoms ~= nil then
                                table.RemoveByValue(self.zoms,zom)
                            end
                        end)
                    end)

                    if GetConVar("ba2_hs_notargetclean"):GetBool() then
                        timer.Simple(6,function()
                            if IsValid(zom) and (zom:GetEnemy() == nil or !zom:IsInWorld()) then
                                zom:Remove()
                            end
                        end)
                    end
                else return end
            end)
        end
    end
end

end