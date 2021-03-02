-- This file is separated from the main init function to allow modders to use BA2's most useful functions without reloading the server code again

if SERVER then

function BA2_AddInfection(ent,amnt)
    if amnt < 0 then return end
    if not IsValid(ent) or not (ent:IsNPC() or ent:IsPlayer()) then return end
    if ent:IsPlayer() and !ent:Alive() then return end
    if (ent:IsNPC() and (BA2_ConvertibleNpcs[ent:GetClass()] == nil and ent.IsVJBaseSNPC_Human ~= true)) then return end
    
    amnt = math.floor(amnt)
    if ent:IsPlayer() then
        amnt = amnt * GetConVar("ba2_inf_plymult"):GetFloat()
    elseif ent:IsNPC() then
        amnt = amnt * GetConVar("ba2_inf_npcmult"):GetFloat()
    end

    if amnt == 0 then return end

    if ent.BA2Infection == nil then
        ent.BA2Infection = amnt
    else
        ent.BA2Infection = ent.BA2Infection + amnt
    end
end


function BA2_InfectionManager()
    if not IsValid(BA2_InfManager) then
        BA2_InfManager = ents.Create("ba2_infection_manager")
        BA2_InfManager:Spawn()
        BA2_InfManager:Activate()
    end

    return BA2_InfManager
end

function BA2_RaiseZombie(ent)
    local zom = ents.Create("nb_ba2_infected")
    zom:SetPos(ent:GetPos())

    zom.InfBody = ent:GetModel()
    zom.InfSkin = ent:GetSkin()
    zom.InfBodyGroups = {}
    zom.InfVoice = ent.InfVoice or nil
    if GetConVar("ba2_zom_emergetime"):GetFloat() == 0 then
        zom.noRise = true
    end

    for i = 1,ent:GetNumBodyGroups() do
        table.insert(zom.InfBodyGroups, ent:GetBodygroup(i))
    end

    zom:Spawn()
    zom:Activate()
    SafeRemoveEntity(ent)
end

end