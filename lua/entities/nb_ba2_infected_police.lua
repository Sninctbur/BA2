AddCSLuaFile()

ENT.PrintName = "Infected"
ENT.Base = "nb_ba2_infected"
ENT.Spawnable = false

ENT.InfBody = {
    "models/Police.mdl"
}

ENT.InfVoice = 2 -- combine muttering
--ENT.ColorOverride = Color(255,255,255)

ENT.InfBodyGroups = {}
ENT.noRise = true

list.Set( "NPC", "nb_ba2_infected_police", {
    Name = "Infected Metro Police",
    Class = "nb_ba2_infected_police",
    Category = "Bio-Annihilation II"
})