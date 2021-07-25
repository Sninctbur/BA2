-- To use: gmod_toolmode ba2_tool_developer

TOOL.Category = "Bio-Annihilation II"
TOOL.Name = "#tool.ba2_tool_developer.name"
TOOL.AddToMenu = false

function TOOL:LeftClick( trace )
    if IsValid(trace.Entity) and (string.StartWith(trace.Entity:GetClass(),"func_door") or string.StartWith(trace.Entity:GetClass(),"prop_door")) then
        if SERVER then
            BA2_BreakDoor(trace.Entity, self:GetOwner():GetForward() * 5000)
        end
        return true
    end
end

function TOOL:Allowed()
    if SERVER then
        return self:GetOwner():IsAdmin() and self.AllowedCVar:GetBool()
    end
end