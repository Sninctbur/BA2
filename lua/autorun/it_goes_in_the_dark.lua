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


eventStage = 0
local eventZoms = {}
local box = nil
local alarmSound = nil

local darkRoomPos = Vector(-4049,-1976,-80)

function event()
    alarmSound = box:StartLoopingSound("ambient/alarms/alarm_citizen_loop1.wav")

    if SERVER then
        timer.Create("ba2_event",4,5,function()
            if !IsValid(box) then return end
            local zoms = {}
            local navAreas = {}
            local dist = 0

            for i,v in pairs(navmesh.GetAllNavAreas()) do
                -- print("Processing nav area")
                dist = v:GetCenter():DistToSqr(darkRoomPos)
                if dist <= math.pow(900,2) and dist > math.pow(200,2) then
                    -- print("Inserting nav area")
                    table.insert(navAreas,v)
                end
            end
            -- print("Nav processing done")

            for i = 1,5 + math.min((player.GetCount() - 1),5) do
                if #navAreas == 0 then break end

                local ind = math.random(1,#navAreas)
                local center = navAreas[ind]:GetCenter()
                for i,v in pairs(ents.FindInSphere(center,100)) do
                    if v:GetClass() == "nb_ba2_infected" or v:IsPlayer() then 
                        break
                    end
                end

                -- print("Creating zombie")
                local zom = ents.Create("nb_ba2_infected")
                
                zom:SetPos(center + Vector(math.random(-60,60),math.random(-60,60),0))
                table.remove(navAreas,ind)
                zom.InfBody = "models/Humans/Group01/Male_Cheaple.mdl"
                --zom.noRise = true
                zom:SetMaxHealth(100)
                zom:SetHealth(100)
                zom.BA2_AutoSpawned = true
                zom.PursuitSpeedOverride = 1

                zom.HandleStuck = function()
                    zom:Remove()
                end

                zom:Spawn()
                zom:Activate()

                table.insert(eventZoms,zom)
            end

            eventStage = 2
            timer.Adjust("ba2_event",6,nil,nil)
        end)

        timer.Start("ba2_event")
    end
end

hook.Add("Think","ba2_event",function()
    if game.GetMap() == "gm_construct" and eventStage == 0 then
        if SERVER then
            for i,v in pairs(ents.FindByClass("it_goes_in_the_dark")) do
                if v:GetPos():DistToSqr(darkRoomPos) <= math.pow(900,2) then
                    local skyTrace = util.TraceLine({
                        start = v:GetPos(),
                        endpos = v:GetPos() + Vector(0,0,999999),
                        filter = v
                    })
                    if !skyTrace.HitSky then
                        eventStage = 1
                        box = v
                        event()
                        break
                    end
                end
            end
        end
    elseif IsValid(box) and eventStage == 2 then
        local varsToCheck = {"ai_ignoreplayers","ai_disabled"}
        for i,var in pairs(varsToCheck) do
            if GetConVar(var):GetBool() then
                RunConsoleCommand(var,"0")
            end
        end

        if #eventZoms == 0 then
            eventStage = 3
            box:StopLoopingSound(alarmSound)

            local ent = ents.Create("ba2_virus_sample")
            ent:SetPos(box:GetPos() + Vector(0,0,30))
            ent.ImmuneToBreakTime = CurTime() + 2
            ent:Spawn()
            ent:Activate()

            box:EmitSound("ambient/machines/teleport4.wav")
            box:EmitSound("ba2/infected/vo/it_goes_in_the_dark.wav") -- Like peeking around? I advise finishing the puzzle to find out what you'll hear :)
        else
            for i,v in pairs(eventZoms) do
                if !IsValid(v) then
                    table.remove(eventZoms,i)
                end
            end
        end
    end
end)

hook.Add("PostCleanupMap","ba2_event_reset",function()
    eventStage = 0
    timer.Remove("ba2_event")
end)