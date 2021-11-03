include("autorun/ba2_shared.lua")

AddCSLuaFile()

ENT.PrintName = "Infected"
ENT.Base = "nb_ba2_infected"
ENT.Spawnable = false

ENT.InfBody = "CUSTOM_ARM"
--ENT.ColorOverride = Color(255,255,255)
ENT.noRise = true
ENT.BA2_ArmoredZom = true

list.Set( "NPC", "nb_ba2_infected_custom_armored", {
    Name = "Custom Armor Infected",
    Class = "nb_ba2_infected_custom_armored",
    Category = "Bio-Annihilation II"
})