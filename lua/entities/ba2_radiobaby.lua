AddCSLuaFile()

ENT.Base = "base_anim"
ENT.Type = "anim"

function ENT:Initialize()
    self:SetModel("models/props_c17/doll01.mdl")

    self.sstv = CreateSound(self,"ba2/sstv.ogg")

    if SERVER then
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetUseType(SIMPLE_USE)
        self:PhysWake()
    end
end


function ENT:Use(p)
    if !self:IsPlayerHolding() and self:GetPos():Distance(p:GetPos()) <= 120 then
        if self.sstv:IsPlaying() then
            self.sstv:Stop()
        end
        self.sstv:Play()
        p:PickupObject(self)
    end
end

function ENT:OnRemove()
    self.sstv:Stop()
end