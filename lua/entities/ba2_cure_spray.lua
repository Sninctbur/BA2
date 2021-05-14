AddCSLuaFile()

ENT.PrintName = "Cure Spray"
ENT.Base = "base_anim"
ENT.Type = "anim"
ENT.Category = "Bio-Annihilation II"
ENT.Spawnable = true
ENT.AdminOnly = true 

function ENT:Initialize()
    self:SetModel("models/ba2/objects/ba2_cure_spray.mdl")

    if SERVER then
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetUseType(SIMPLE_USE)
        self:PhysWake()
    end
end

function ENT:Use(p)
    if p.BA2Infection and p.BA2Infection > 0 then
        p.BA2Infection = 0
        p:EmitSound("ba2_cureuse")
        self:Remove()
    else
        p:PickupObject(self)
    end
end

function ENT:Touch(activator)
    if activator.BA2Infection and not activator:IsPlayer() and activator.BA2Infection > 0 then
        activator.BA2Infection = 0
        activator:EmitSound("ba2_cureuse")
        self:Remove()
    end
end

function ENT:PhysicsCollide(data, physobj)
	if (data.Speed <= 550 and data.DeltaTime > 0.3) then
		self:EmitSound("ba2_curephys_soft")
	elseif (data.Speed > 550 and data.DeltaTime > 0.3) then
		self:EmitSound("ba2_curephys_hard")
	end
end