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
    if SERVER then self.navs = navmesh.GetAllNavAreas() end

    if CLIENT then
        EmitSound("ba2/infected/horde.wav",self:GetPos(),-1)
    end

    self:SpawnZoms(math.random(5,10))
    timer.Create("BA2_HordeSpawner",GetConVar("ba2_hs_interval"):GetFloat(),0,function()
        if IsValid(self) then
            self:SpawnZoms(math.random(5,10))
        end
    end)
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


function ENT:SpawnZoms(amnt)
    timer.Adjust("BA2_HordeSpawner",GetConVar("ba2_hs_interval"):GetFloat(),nil,nil)
    local zomThreshold = GetConVar("ba2_hs_max"):GetInt()
    local zomType = GetConVar("ba2_hs_appearance"):GetInt()
    if zomType == 4 then
        zomType = BA2_ZombieTypes[math.random(0,3)]
    elseif zomType == 5 then
        zomType = BA2_ZombieTypes[math.random(0,2)]
    else
        zomType = BA2_ZombieTypes[zomType]
    end 

    if SERVER then
        for i = 1,amnt do
            timer.Simple(i * .1,function() -- O P T I M I Z E D
                if IsValid(self) and self.zoms ~= nil and #self.zoms < zomThreshold then
                    local navArea = self.navs[math.random(1,#self.navs)]
                    while navArea:IsUnderwater() do
                        navArea = self.navs[math.random(1,#self.navs)]
                    end
                    
                    local spawnPos = navArea:GetCenter()

                    local zom = ents.Create(zomType)

                    for i,ent in pairs(ents.FindInSphere(spawnPos,GetConVar("ba2_hs_saferadius"):GetInt())) do
                        if zom:IsValidEnemy(ent) then
                            zom:Remove()
                            return
                        end
                    end

                    zom:SetPos(spawnPos)
                    zom.noRise = true
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

                    timer.Simple(6,function()
                        if IsValid(zom) and (zom:GetEnemy() == nil or !zom:IsInWorld()) then
                            zom:Remove()
                        end
                    end)
                else return end
            end)
        end
    end
end