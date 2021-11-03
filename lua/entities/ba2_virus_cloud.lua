AddCSLuaFile()
include("autorun/ba2_shared.lua")
if SERVER then
	include("autorun/server/ba2_master_init.lua")
end

ENT.PrintName = "Contaminant Cloud"
ENT.Base = "base_anim"
ENT.Type = "anim"
ENT.Category = "Bio-Annihilation II"
ENT.Spawnable = true

if SERVER then

function ENT:Initialize()
	self:SetNoDraw(true)
	self:DrawShadow(false)

	self.smoke = ents.Create("env_smoketrail")
	self.smoke:SetPos(self:GetPos())

	self.smoke:SetKeyValue("lifetime",1.5)
	self.smoke:SetKeyValue("startcolor","0 96 0")
	self.smoke:SetKeyValue("endcolor","0 96 0")
	self.smoke:SetKeyValue("startsize","4000")
	self.smoke:SetKeyValue("endsize","6000")
	self.smoke:SetKeyValue("spawnradius","200")
	self.smoke:SetKeyValue("spawnrate","120")
	self.smoke:SetKeyValue("minspeed",50)
	self.smoke:SetKeyValue("maxspeed",100)

	self.smoke:SetKeyValue("opacity",.5)
	self.smoke:Spawn()
	self.smoke:Activate()
end

function ENT:Think()
	for i,ent in pairs(ents.FindInSphere(self:GetPos(),400)) do
		if BA2_JMod and ent:IsPlayer() and JMod_GetArmorBiologicalResistance(ent,DMG_NERVEGAS) > 0 then
			JMod_DepleteArmorChemicalCharge(ent,.0125)
			continue
		end

		if !BA2_GetActiveMask(ent) then
			BA2_AddInfection(ent,math.random(3,4))
		end
		if GetConVar("ba2_misc_maskfilters"):GetBool() and ent:IsPlayer() and BA2_GetActiveMask(ent) then
			ent:SetNWInt("BA2_GasmaskFilterPct",ent:GetNWInt("BA2_GasmaskFilterPct",0) - .0125)
		end
	end

	debugoverlay.Sphere(self:GetPos(),400,.5)

	self:NextThink(CurTime() + .5)
	return true
end

function ENT:OnRemove()
    self.smoke:Remove()
end
end