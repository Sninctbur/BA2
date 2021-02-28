include("autorun/ba2_shared.lua")

AddCSLuaFile()

ENT.PrintName = "Infected"
ENT.Base = "nb_ba2_infected"
ENT.Spawnable = false

ENT.InfBody = "CUSTOM"
--ENT.ColorOverride = Color(255,255,255)

list.Set( "NPC", "nb_ba2_infected_custom", {
    Name = "Custom Infected",
    Class = "nb_ba2_infected_custom",
    Category = "Bio-Annihilation II"
})