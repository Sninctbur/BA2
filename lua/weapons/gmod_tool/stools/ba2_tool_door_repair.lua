TOOL.Category = "Bio-Annihilation II"
TOOL.Name = "#tool.ba2_tool_door_repair.name"

function TOOL:LeftClick( trace )
    if trace.Hit then
        local doorRepaired = false
        for i,ent in pairs(ents.FindInSphere(trace.HitPos,50)) do
            if ent.BA2_DoorBroken then
                if SERVER then
                    BA2_RepairDoor(ent)
                end
                doorRepaired = true
            end
        end
        return doorRepaired
    end
end

if CLIENT then
    language.Add("tool.ba2_tool_door_repair.name", "Door Repairer")
    language.Add("tool.ba2_tool_door_repair.desc", "Are your doors strewn across the floor because of the apocalypse? No worries!")
    language.Add("tool.ba2_tool_door_repair.0", "Left click to fix doors. Only works for doors broken by zombies.")
end