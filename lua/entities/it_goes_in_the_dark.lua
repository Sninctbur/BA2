-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK
-- IT GOES IN THE DARK

AddCSLuaFile()

ENT.PrintName = "IT GOES IN THE DARK"
ENT.Description = "IT GOES IN THE DARK IT GOES IN THE DARK IT GOES IN THE DARK IT GOES IN THE DARK IT GOES IN THE DARK IT GOES IN THE DARK IT GOES IN THE DARK IT GOES IN THE DARK IT GOES IN THE DARK IT GOES IN THE DARK IT GOES IN THE DARK IT GOES IN THE DARK"
ENT.Base = "base_anim"
ENT.Type = "anim"

function ENT:Initialize()
    self:SetModel("models/props_lab/citizenradio.mdl")

    if SERVER then
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetUseType(SIMPLE_USE)
        self:PhysWake()

        -- self.zoms = {}
    end
end

function ENT:Use(p)
    if !self:IsPlayerHolding() and self:GetPos():Distance(p:GetPos()) <= 120 then
        p:PickupObject(self)
    end
end

-- local darkRoomPos = Vector(-4049,-1976,-80)


-- if SERVER then

-- eventStage = 0

-- function ENT:event()
--     self.alarmSound = self:StartLoopingSound("ambient/alarms/alarm_citizen_loop1.wav")

--     -- timer.Simple(2,function()
--     --     ReadSound("ba2/infected/horde.wav")
--     -- end)

--     timer.Simple(4,function()
--         local zoms = {}
--         local navAreas = {}
--         local dist = 0

--         -- print("Event triggered")

--         for i,v in pairs(navmesh.GetAllNavAreas()) do
--             -- print("Processing nav area")
--             dist = v:GetCenter():DistToSqr(darkRoomPos)
--             if dist <= math.pow(800,2) and dist > math.pow(400,2) then
--                 local skyTrace = util.TraceLine({
--                     start = self:GetPos(),
--                     endpos = self:GetPos() + Vector(0,0,999999),
--                     filter = self
--                 })
--                 if !skyTrace.HitSky then
--                     -- print("Inserting nav area")
--                     table.insert(navAreas,v)
--                 end
--             end
--         end
--         -- print("Nav processing done")

--         for i = 1,20 + math.min((player.GetCount() - 1) * 3,15) do
--             if #navAreas == 0 then break end
--             -- print("Creating zombie")
--             local zom = ents.Create("nb_ba2_infected")

--             local ind = math.random(1,#navAreas)
--             zom:SetPos(navAreas[ind]:GetCenter())
--             table.remove(navAreas,ind)
--             zom.InfBody = "models/Humans/Group01/Male_Cheaple.mdl"
--             --zom.noRise = true
--             zom:SetMaxHealth(100)
--             zom:SetHealth(100)

--             zom:Spawn()
--             zom:Activate()

--             table.insert(self.zoms,zom)
--         end
--         -- print("Zombie creation done")

--         -- while #zoms > 0 do
--         --     for i,v in pairs(zoms) do
--         --         if !IsValid(v) then
--         --             table.remove(zoms,i)
--         --         end
--         --     end
--         --     coroutine.yield()
--         -- end

--         eventStage = 2
--     end)
-- end

-- function ENT:Think()
--     if game.GetMap() == "gm_construct" and eventStage == 0 then
--         if self:GetPos():DistToSqr(darkRoomPos) <= math.pow(900,2) then
--             local skyTrace = util.TraceLine({
--                 start = self:GetPos(),
--                 endpos = self:GetPos() + Vector(0,0,999999),
--                 filter = self
--             })
--             if !skyTrace.HitSky then
--                 eventStage = 1
--                 self:event()
--             end
--         end
--     elseif eventStage == 2 then
--         if #self.zoms == 0 then
--             eventStage = 3
--             self:StopLoopingSound(self.alarmSound)

--             local ent = ents.Create("ba2_virus_sample")
--             ent:SetPos(self:GetPos() + Vector(0,0,8))
--             ent.ImmuneToBreakTime = CurTime() + 2
--             ent:Spawn()
--             ent:Activate()

--             self:EmitSound("ambient/machines/teleport4.wav")
--             self:EmitSound("ba2/infected/vo/it_goes_in_the_dark.wav") -- Like peeking around? I advise finishing the puzzle to find out what you'll hear :)
--         else
--             for i,v in pairs(self.zoms) do
--                 if !IsValid(v) then
--                     table.remove(self.zoms,i)
--                 end
--             end
--         end
--     end
-- end

-- end