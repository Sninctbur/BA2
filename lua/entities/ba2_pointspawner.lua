AddCSLuaFile()

ENT.PrintName = "Point Spawner"
ENT.Base = "base_anim"
ENT.Type = "anim"
ENT.Spawnable = true
ENT.AdminOnly = false
ENT.Category = "Bio-Annihilation II"

function ENT:Initialize()
    self:SetNoDraw(true)
    self:DrawShadow(false)

    if SERVER then
        if #navmesh.GetAllNavAreas() == 0 then
            if IsValid(self:GetCreator()) then
                self:GetCreator():PrintMessage(HUD_PRINTCENTER,"This map doesn't have a navmesh!")
            end
            print("BA2: There is no navmesh! Despawning point spawner...")
            self:Remove()
        end

        timer.Simple(0.1,function()
            if IsValid(self) then
                self.zom = SpawnZom(self)
            end
        end)
    end
end

function ENT:OnRemove()
    if SERVER then
        if GetConVar("ba2_hs_cleanup"):GetBool() and IsValid(self.zom) then
            self.zom:Remove()
        end
    end
end

function SpawnZom(s) -- This is just a neutered Horde Spawner
    local zomTypes = BA2_GetValidAppearances()

    if SERVER then
        local zom = ents.Create(zomTypes[math.random(1,#zomTypes)])
        zom:SetPos(s:GetPos())
        zom:SetAngles(s:GetAngles())
        zom.noRise = true
        zom:Spawn()
        zom:Activate()

        zom:CallOnRemove("BA2_PS_Respawn",function()
            timer.Simple(GetConVar("ba2_hs_interval"):GetFloat(),function()
                if IsValid(s) then
                    s.zom = SpawnZom(s)
                end
            end)
        end)

        return zom
    end

    return nil
end