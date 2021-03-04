-- Precaching
print("BA2: Precaching gib models and sounds...")
local tbl = {
        "models/ba2/gibs/eyel.mdl",
        "models/ba2/gibs/eyer.mdl",
        "models/ba2/gibs/headbackl.mdl",
        "models/ba2/gibs/headbackr.mdl",
        "models/ba2/gibs/headfrontl.mdl",
        "models/ba2/gibs/headfrontr.mdl",
        "models/ba2/gibs/headtop.mdl",
        "models/ba2/gibs/jaw.mdl",
        "models/ba2/gibs/armlowerr2.mdl",
        "models/ba2/gibs/handr.mdl",
        "models/ba2/gibs/armlowerl.mdl",
        "models/ba2/gibs/handl.mdl",
        "models/ba2/gibs/legupperleft.mdl",
        "models/ba2/gibs/legupperright.mdl",
        "models/ba2/gibs/leglowerleft.mdl",
        "models/ba2/gibs/leglowerright.mdl"
}

for i,mdl in pairs(tbl) do
    util.PrecacheModel(mdl)
end

local tbl = {
    "ba2_headlessbleed",
    "ba2_fleshtear",
    "ba2_gibsplat",
    "ba2_infectcry"
}

for i,mdl in pairs(tbl) do
    util.PrecacheSound(mdl)
end