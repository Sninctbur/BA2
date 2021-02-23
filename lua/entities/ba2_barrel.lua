AddCSLuaFile()
include("autorun/ba2_shared.lua")
if SERVER then
	include("autorun/server/ba2_master_init.lua")
end

ENT.PrintName = "Contaminant Barrel"
ENT.Base = "base_anim"
ENT.Type = "anim"
ENT.Category = "Bio-Annihilation II"
ENT.Spawnable = true

function ENT:Initialize()
    self:SetModel("models/props_c17/oildrum001.mdl")
    self:SetMaterial("models/ba2/objects/virus_barrel"..math.random(1,4))

    if SERVER then
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetUseType(SIMPLE_USE)
        self:PhysWake()
        self:GetPhysicsObject():SetMaterial("metal_barrel")

        self:SetMaxHealth(100)
        self:SetHealth(100)

        self.barrelSmoke = ents.Create("env_smoketrail")

        self.barrelSmoke:SetKeyValue("lifetime",1.5)
        self.barrelSmoke:SetKeyValue("startcolor","0 96 0")
        self.barrelSmoke:SetKeyValue("endcolor","0 96 0")

        self.barrelSmoke:SetKeyValue("opacity",0)
        self.barrelSmoke:Spawn()
        self.barrelSmoke:Activate()
    end
end

if SERVER then

function ENT:BA2_BarrelRecalc()
    local hp = self:Health()

    if hp <= 0 then
        self:BA2_BarrelExplode()
    elseif hp <= 33 then
        self:StartLoopingSound("ambient/gas/cannister_loop.wav")
        self.barrelSmoke:SetKeyValue("opacity",1)
        self.barrelSmoke:SetKeyValue("spawnrate",600)
        self.barrelSmoke:SetKeyValue("startsize",10)
        self.barrelSmoke:SetKeyValue("endsize",15)
        self.barrelSmoke:SetKeyValue("minspeed",100)
        self.barrelSmoke:SetKeyValue("maxspeed",200)
    elseif hp <= 80 then
        self.barrelSmoke:SetKeyValue("opacity",.5)
        self.barrelSmoke:SetKeyValue("startsize",20 * (self:GetMaxHealth() / self:Health()))
        self.barrelSmoke:SetKeyValue("endsize",40 * (self:GetMaxHealth() / self:Health()))
        self.barrelSmoke:SetKeyValue("minspeed",10)
    end
end
function ENT:BA2_BarrelExplode()
    if self.Exploded then return end

    self.Exploded = true

    local exp = ents.Create("env_explosion")
    exp:SetKeyValue("origin",tostring(self:GetPos()))
    --exp:SetKeyValue("iMagnitude",200)

    exp:Spawn()
    exp:Activate()

    local dmg = DamageInfo()
    dmg:SetDamage(300)

    for i,ent in pairs(ents.FindInSphere(self:GetPos(),400)) do
        if (ent:IsPlayer() and !BA2_GetActiveMask(ent)) or (ent:IsNPC() and !BA2_GasmaskNpcs[ent]) then
            BA2_AddInfection(ent,(dmg:GetDamage() - self:GetPos():Distance(ent:GetPos())) / 2)
        end
    end
    dmg:SetDamageType(DMG_BLAST)

    local att = self.BA2_LastAttacker or self
    dmg:SetAttacker(att)
    dmg:SetInflictor(BA2_InfectionManager())

    util.BlastDamageInfo(dmg,self:GetPos(),400)

    exp:Fire("Explode")

    local cloud = ents.Create("ba2_virus_cloud")
    cloud:SetPos(self:GetPos())
    cloud:Spawn()
    cloud:Activate()
    SafeRemoveEntityDelayed(cloud,30)

    local props = {
        "models/props_c17/oildrumchunk01a.mdl",
        "models/props_c17/oildrumchunk01b.mdl",
        "models/props_c17/oildrumchunk01c.mdl",
        "models/props_c17/oildrumchunk01d.mdl",
        "models/props_c17/oildrumchunk01e.mdl",
    }

    for i,mdl in pairs(props) do
        local prop = ents.Create("prop_physics")
        prop:SetModel(mdl)
        prop:SetPos(self:GetPos() + Vector(0,0,50) + VectorRand() * 2)
        --prop:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
        
        prop:Spawn()
        prop:Activate()
        prop:PhysWake()
        prop:GetPhysicsObject():ApplyForceCenter(VectorRand() * 2500)
        prop:SetLocalAngularVelocity(AngleRand())
        SafeRemoveEntityDelayed(prop,6)
    end

    self:EmitSound("weapons/flaregun/fire.wav",95)
    self:EmitSound("physics/metal/metal_box_break2.wav",75,math.random(90,100))
    self:Remove()
end


function ENT:Think()
    local hp = self:Health()

    if hp <= 33 then
        self:SetHealth(self:Health() - 4)
        if self:Health() <= 0 then
            self:BA2_BarrelExplode()
        end
    end
    if hp <= 80 then
        for i,ent in pairs(ents.FindInSphere(self:GetPos(),(self:GetMaxHealth() - self:Health()) * 2)) do
            if !BA2_GetActiveMask(ent) then
                BA2_AddInfection(ent,math.random(3,5))
            end
            if GetConVar("ba2_misc_maskfilters"):GetBool() and ent:IsPlayer() and BA2_GetActiveMask(ent) then
                ent:SetNWInt("BA2_GasmaskFilterPct",ent:GetNWInt("BA2_GasmaskFilterPct",0) - .125)
            end
        end

        debugoverlay.Sphere(self:GetPos(),(self:GetMaxHealth() - self:Health()) * 2,.5)
    end

    self.barrelSmoke:SetPos(self:LocalToWorld(Vector(0,0,30)))
    self:NextThink(CurTime() + .5)
    return true
end
function ENT:OnRemove()
    self:StopSound("ambient/gas/cannister_loop.wav")
    self.barrelSmoke:Remove()
end


function ENT:Use(p)
    if !self:IsPlayerHolding() and self:GetPos():Distance(p:GetPos()) <= 120 then
        p:PickupObject(self)
    end
end

function ENT:OnTakeDamage(dmg)
    self.BA2_LastAttacker = dmg:GetAttacker()
    if self:Health() - dmg:GetDamage() <= 0 then
        self:BA2_BarrelExplode()
    else
        self:SetHealth(self:Health() - dmg:GetDamage())
        self:BA2_BarrelRecalc()
    end
end

function ENT:GravGunPunt(p)
    self.BA2_LastAttacker = p
    self.GravGunPunted = true

    return true
end
function ENT:PhysicsCollide(data,col)
    if self.GravGunPunted == true then
        self:BA2_BarrelExplode()
    end
end

end