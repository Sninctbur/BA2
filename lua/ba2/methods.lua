-- This file is separated from the main init function to allow modders to use BA2's most useful functions without reloading the server code again


-- SHARED ------------------------------------------------------------------
function BA2_GetValidAppearances()
    local zomTypes = {}
    if GetConVar("ba2_hs_appearance_0"):GetBool() then
        table.insert(zomTypes,BA2_ZombieTypes[0])
    end
    if GetConVar("ba2_hs_appearance_1"):GetBool() then
        table.insert(zomTypes,BA2_ZombieTypes[1])
    end
    if GetConVar("ba2_hs_appearance_2"):GetBool() then
        table.insert(zomTypes,BA2_ZombieTypes[2])
    end
    if GetConVar("ba2_hs_appearance_3"):GetBool() then
        table.insert(zomTypes,BA2_ZombieTypes[3])
    end -- there's probably a shorter way to do this

    -- if GetConVar("ba2_hs_combine_chance"):GetInt() > math.random() then
    --     table.insert(zomTypes,BA2_ZombieTypes[4])
    -- end
    -- if GetConVar("ba2_hs_carmor_chance"):GetInt() > math.random() then
    --     table.insert(zomTypes,BA2_ZombieTypes[5])
    -- end

    if #zomTypes == 0 then
        zomTypes = table.Copy(BA2_ZombieTypes)
    end

    return zomTypes
end


if SERVER then -- SERVER ---------------------------------------------------

function BA2_AddInfection(ent,amnt)
    if amnt < 0 then return end
    if not IsValid(ent) or not (ent:IsNPC() or ent:IsPlayer()) then return end
    if ent:IsPlayer() and !ent:Alive() then return end
    if (ent:IsNPC() and (BA2_ConvertibleNpcs[ent:GetClass()] == nil and ent.IsVJBaseSNPC_Human ~= true)) then return end
    
    if ent:IsPlayer() then
        amnt = amnt * GetConVar("ba2_inf_plymult"):GetFloat()
    elseif ent:IsNPC() then
        amnt = amnt * GetConVar("ba2_inf_npcmult"):GetFloat()
    end

    amnt = math.floor(amnt)
    if amnt == 0 then return end

    if ent.BA2Infection == nil then
        ent.BA2Infection = amnt
    else
        ent.BA2Infection = ent.BA2Infection + amnt
    end
end

function BA2_CanConvert(ent)
    return (ent:IsPlayer() or BA2_ConvertibleNpcs[ent:GetClass()])
end

function BA2_GetActiveMask(p)
    if p:IsPlayer() then
        return p:GetNWBool("BA2_GasmaskOn",false) and (!GetConVar("ba2_misc_maskfilters"):GetBool() or p:GetNWInt("BA2_GasmaskFilterPct",0) > 0)
    elseif p:IsNPC() then
        return p:GetNWBool("BA2_GasmaskOn",false) or BA2_GasmaskNpcs[p:GetClass()]
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
    local maxZoms = GetConVar("ba2_inf_maxzoms"):GetInt()
    local armoredModels = table.Add({"models/combine_soldier.mdl","models/combine_super_soldier.mdl"},BA2_CustomArmInfs)

    if maxZoms > 0 and #ents.FindByClass("nb_ba2_infected*") >= maxZoms then
        return
    end

    local zom = ents.Create("nb_ba2_infected")
    zom:SetPos(ent:GetPos())

    zom.InfBody = ent:GetModel()
    zom.InfSkin = ent:GetSkin()
    zom.InfBodyGroups = {}
    zom.InfVoice = ent.InfVoice or nil
    if GetConVar("ba2_zom_emergetime"):GetFloat() == 0 then
        zom.noRise = true
    end
    if table.HasValue(armoredModels,zom.InfBody) then
        zom.BA2_ArmoredZom = true
    end
    if ent.BA2_HPInherit then
        zom.BA2_HPInherit = ent.BA2_HPInherit
    end

    for i = 1,ent:GetNumBodyGroups() do
        table.insert(zom.InfBodyGroups,ent:GetBodygroup(i))
    end

    zom:Spawn()
    zom:Activate()
    SafeRemoveEntity(ent)
end

end