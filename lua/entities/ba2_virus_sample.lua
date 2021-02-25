AddCSLuaFile()

include("autorun/ba2_shared.lua")
if SERVER then include("autorun/server/ba2_master_init.lua") end

ENT.PrintName = "Viral Sample"
ENT.Base = "base_anim"
ENT.Type = "anim"
ENT.Category = "Bio-Annihilation II"
ENT.Spawnable = true

function ENT:Initialize()
    self:SetModel("models/ba2/objects/ba2_virus_sample.mdl")
    
    if SERVER then
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetUseType(SIMPLE_USE)
        self:PhysWake()

        self.dmg = DamageInfo()
        self.dmg:SetDamage(5)
        self.dmg:SetDamageType(DMG_CRUSH)
        self.dmg:SetDamageCustom(DMG_BIOVIRUS)
        self.dmg:SetAttacker(self)
        self.dmg:SetInflictor(self)
    end
end

function ENT:VialBreak(ent)
    self:PhysicsDestroy() -- Prevents double collisions
    self:EmitSound("weapons/jar_explode.wav")

    if IsValid(ent) then
        if (ent:IsPlayer() or ent:IsNPC()) then
            BA2_AddInfection(ent,18000) -- Good luck surviving 6 1/4 hours of infection
        end
        
        --ent:TakeDamageInfo(self.dmg)
    end

    local eff = EffectData()
    eff:SetOrigin(self:GetPos())
    eff:SetColor(0)
    eff:SetScale(25)
    util.Effect("GlassImpact",eff)
    util.Effect("BloodImpact",eff)

    for i,e in pairs(ents.FindInSphere(self:GetPos(),260)) do
        if BA2_GasmaskNpcs[e:GetClass()] or !BA2_GetActiveMask(e) then
            BA2_AddInfection(e,(65 - (self:GetPos():Distance(e:GetPos())) / 4))
        end
    end

    self:Remove()
end


function ENT:Use(p)
    if !self:IsPlayerHolding() and self:GetPos():Distance(p:GetPos()) <= 120 then
        p:PickupObject(self)
    end
end

function ENT:PhysicsCollide(data,col)
    local l = self:GetVelocity():Length()
    if data.HitEntity:GetClass() ~= "func_breakable_surf" and l >= 100 then -- It's fun to throw it through windows
        util.Decal("BA2_VirusBloodStain",data.HitPos - data.HitNormal,data.HitPos + data.HitNormal)
        self:VialBreak(data.HitEntity)
    elseif l >= 25 then
        self:EmitSound("physics/cardboard/cardboard_cup_impact_hard"..math.random(1,4)..".wav")
    end
end

function ENT:OnTakeDamage()
    util.Decal("BA2_VirusBloodStain",self:GetPos(),self:GetPos() + Vector(0,0,-750))
    self:VialBreak(nil)
end