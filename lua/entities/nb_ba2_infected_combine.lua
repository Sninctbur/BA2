AddCSLuaFile()

ENT.PrintName = "Infected"
ENT.Base = "nb_ba2_infected"
ENT.Spawnable = false

ENT.InfBody = {
    "models/Combine_Soldier.mdl",
    "models/Combine_Super_Soldier.mdl",
    "models/Police.mdl"
}

ENT.InfVoice = 2 -- combine muttering
--ENT.ColorOverride = Color(255,255,255)

ENT.InfBodyGroups = {}
ENT.noRise = true

list.Set( "NPC", "nb_ba2_infected_combine", {
    Name = "Infected Combine",
    Class = "nb_ba2_infected_combine",
    Category = "Bio-Annihilation II"
})