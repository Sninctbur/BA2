AddCSLuaFile()

ENT.PrintName = "Gas Mask"
ENT.Base = "base_anim"
ENT.Type = "anim"
ENT.Category = "Bio-Annihilation II"
ENT.Spawnable = true

function ENT:Initialize()
    self:SetModel("models/ba2/objects/generic_gasmask.mdl")
    
    if SERVER then
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
        self:SetUseType(SIMPLE_USE)
        self:SetColor(Color(72,72,72))
        self:PhysWake()

        timer.Simple(0,function()
            if not self.BA2_FilterPct then
                self.BA2_FilterPct = 100
            end
        end)
    end
end

function ENT:Use(p)
    if !p:GetNWBool("BA2_GasmaskOwned",false) then
        p:SetNWBool("BA2_GasmaskOwned",true)
        p:SetNWInt("BA2_GasmaskFilterPct",self.BA2_FilterPct)

            if p:GetInfoNum("ba2_cl_maskhelp",1) == 1 then
            p:ChatPrint([[
You found a gas mask! It's now stored on your person.
Type "!gasmask" in chat to put it on or take it off.
Type "!dgasmask" to drop it.]])

            if GetConVar("ba2_misc_maskfilters"):GetBool() then
                p:ChatPrint([[
Type "!ufilter" to change out your mask's filter.
Type "!cfilter" to check on your current filter and see how many you have.
Type "!dfilter" to drop one of your filters.]])
            end
            p:ChatPrint("\nDisable \"Gas Mask Help Text\" under Client settings to turn off this chat spam.")
        end
        
        self:EmitSound("npc/combine_soldier/zipline_hitground1.wav")
        self:Remove()
    else
        p:PickupObject(self)
    end
end