AddCSLuaFile()

ENT.PrintName = "Gas Mask Filter"
ENT.Base = "base_anim"
ENT.Type = "anim"
ENT.Category = "Bio-Annihilation II"
ENT.Spawnable = true

function ENT:Initialize()
    self:SetModel("models/props_phx/wheels/drugster_front.mdl")
    self:SetModelScale(0.25)

    if SERVER then
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
        self:SetUseType(SIMPLE_USE)
        self:PhysWake()
    end
end

function ENT:Use(p)
    if self.BA2_Scenic == nil then
        local maxFilters = GetConVar("ba2_misc_maxfilters"):GetInt()
        if maxFilters >= 0 and p:GetNWInt("BA2_GasmaskFilters",0) >= maxFilters then
            p:ChatPrint("You can't carry any more filters.")
            return
        end

        p:SetNWInt("BA2_GasmaskFilters",p:GetNWInt("BA2_GasmaskFilters",0) + 1)
        --p:ChatPrint("You've found a gas mask filter!")

        self:EmitSound("items/gunpickup2.wav")
        self:Remove()
    end
end

function ENT:Think()
    self:SetModelScale(.25)
end