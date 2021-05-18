TOOL.Category = "Bio-Annihilation II"
TOOL.Name = "#tool.ba2_tool_virus_cloud.name"

function TOOL:LeftClick( trace )
    if trace.Hit then
        for i,ent in pairs(ents.FindInSphere(trace.HitPos,300)) do
            if ent:GetClass() == "ba2_virus_cloud" then
                if SERVER then
                    ent:Remove()
                end
                return true
            end
        end
    end
end

if CLIENT then
    language.Add("tool.ba2_tool_virus_cloud.name", "Contaminant Cloud Remover")
    language.Add("tool.ba2_tool_virus_cloud.desc", "Clean up your clouds of zombifying gas with this dandy tool!")
    language.Add("tool.ba2_tool_virus_cloud.0", "Left click to remove. Right click to spawn the Bio-Virus somewhere in the continental United States.")
end