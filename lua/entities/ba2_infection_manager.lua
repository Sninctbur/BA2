AddCSLuaFile()

ENT.Base = "base_anim"
ENT.Type = "anim"
ENT.PrintName = " " -- SpoOoOoOoOky kill feed

function ENT:Initialize()
    print("BA2: Infection manager created!")
    self:SetNoDraw(true)
end

-- This entity exists so that infection damage can be attributed to its own source