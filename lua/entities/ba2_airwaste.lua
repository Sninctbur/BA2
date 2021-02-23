AddCSLuaFile()
include("autorun/ba2_shared.lua")
if SERVER then
	include("autorun/server/ba2_master_init.lua")
end

ENT.PrintName = "Air Waste"
ENT.Base = "base_anim"
ENT.Type = "anim"
ENT.Category = "Bio-Annihilation II"
ENT.Spawnable = true
ENT.AdminOnly = true


function ENT:AirwasteVisuals()
    self.SkyEdit = ents.Create("edit_sky")
    self.SkyEdit:SetNoDraw(true)
    self.SkyEdit:SetPos(self:GetPos())
    self.SkyEdit:Spawn()
    self.SkyEdit:SetSolid(SOLID_NONE)

    self.FogEdit = ents.Create("edit_fog")
    self.FogEdit:SetNoDraw(true)
    self.FogEdit:SetPos(self:GetPos())
    self.FogEdit:Spawn()
    self.FogEdit:SetSolid(SOLID_NONE)

    self.FogEdit:SetFogStart(0)
    self.FogEdit:SetFogEnd(280)
    self.FogEdit:SetFogColor(Vector(0,70/255,0))
    self.FogEdit:SetDensity(.92)

    self.SkyEdit:SetTopColor(Vector(0,.02,0))
    self.SkyEdit:SetBottomColor(Vector(0,.05,0))
    self.SkyEdit:SetDuskIntensity(0)
    self.SkyEdit:SetDrawStars(false)
    self.SkyEdit:SetSunColor(Vector(.01,.01,.01))
    self.SkyEdit:SetSunSize(1)
end

function ENT:Initialize()
    if #ents.FindByClass(self.ClassName) > 1 then
        if IsValid(self:GetCreator()) then
            self:GetCreator():PrintMessage(HUD_PRINTCENTER,"Earth's atmosphere can't be ruined any further!")
        end
        print("BA2: There can only be one Air Waste entity at once!")
        self:Remove()
        return
    end

    self:SetNoDraw(true)
	self:DrawShadow(false)


    if SERVER then
        if GetConVar("ba2_misc_airwastevisuals"):GetBool() then
            self:AirwasteVisuals()
        end


        if IsValid(self:GetCreator()) then
            self:GetCreator():PrintMessage(HUD_PRINTCENTER,"Do you have any idea what you've just done?")
        end
    elseif CLIENT then
        self.AirWasteSound = CreateSound(LocalPlayer(),"ambient/wind/wasteland_wind.wav")
        self.AirWasteSound:Play()
    end
end


function ENT:Think()
    if SERVER then
        local entTable = table.Add(player.GetAll(),ents.FindByClass("npc_*"))

        for i,ent in pairs(entTable) do
            if !BA2_GetActiveMask(ent) then
                local trace = util.TraceLine({
                    start = ent:GetPos(),
                    endpos = ent:GetPos() + Vector(0,0,1000),
                    filter = ent
                })
        
                if !trace.HitWorld or trace.HitSky then
                    BA2_AddInfection(ent,math.random(1,5))

                    local dmg = DamageInfo()
                    dmg:SetDamage(math.random(0,2))
                    dmg:SetDamageType(DMG_DIRECT)
                    dmg:SetAttacker(BA2_InfectionManager())
                    dmg:SetInflictor(BA2_InfectionManager())
                    
                    ent:TakeDamageInfo(dmg)
                end
            elseif GetConVar("ba2_misc_maskfilters"):GetBool() and ent:IsPlayer() and BA2_GetActiveMask(ent) then
                ent:SetNWInt("BA2_GasmaskFilterPct",ent:GetNWInt("BA2_GasmaskFilterPct",0) - .0625)
            end
        end

        self:NextThink(CurTime() + .5)
    elseif CLIENT then
        local trace = util.TraceLine({
            start = LocalPlayer():GetPos(),
            endpos = LocalPlayer():GetPos() + Vector(0,0,1000),
            filter = LocalPlayer()
        })

        if trace.HitWorld or trace.HitSky then
            self.AirWasteSound:ChangeVolume(.15,.25)
        elseif self.AirWasteSound:GetVolume() < 1 then
            self.AirWasteSound:ChangeVolume(1,.25)
        end

        if math.random(100) <= 6 then
            surface.PlaySound("ambient/wind/wind_snippet"..math.random(1,5)..".wav")
            if GetConVar("ba2_misc_airwasteshake"):GetBool() and !trace.HitWorld then
                util.ScreenShake(Vector(0,0,0),math.random(12),5,6,0)
            end
        end

        self:SetNextClientThink(CurTime() + .5)
    end

    return true
end

function ENT:OnRemove()
    if SERVER then
        SafeRemoveEntity(self.FogEdit)
        SafeRemoveEntity(self.SkyEdit)
    elseif CLIENT then
        self.AirWasteSound:Stop()
    end
end