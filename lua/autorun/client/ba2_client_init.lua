-- Net messages
net.Receive("BA2NoNavmeshWarn",function()
    local DFrame = vgui.Create( "DFrame" ) 	-- The name of the panel we don't have to parent it.
    DFrame:SetPos( 100, 100 )
    DFrame:SetSize( 300, 200 )
    DFrame:SetTitle( "Navmesh Missing!" )
    DFrame:MakePopup()

    local text1 = vgui.Create("DLabel",DFrame)
    text1:SetPos(50,50)
    if LocalPlayer():IsAdmin() then
        text1:SetText(
            [[Bio-Annihilation II's zombies require a Navmesh to be loaded on the map to function.
            You can create one by running nav_generate in the developer console, or by pressing the button below.
            Be warned that the process to generate a navmesh will SIGNIFICANTLY reduce FPS for a while, and then RESTART THE MAP when it's done.
            Only start if nobody's actively playing and nobody will lose anything if the map restarts.
            Generate the navmesh now?]]
        )
    else
        text1:SetText(
            [[Bio-Annihilation II's zombies require a Navmesh to be loaded on the map to function.
            Ask the host or another server admin to consider generating one for this map.]]
        )
    end
end)


-- Kill icons
killicon.Add("nb_ba2_infected","vgui/infect_killicon.vtf", Color( 255, 0, 0, 255 ) )
killicon.Add("nb_ba2_infected_citizen","vgui/infect_killicon.vtf", Color( 255, 0, 0, 255 ) )
killicon.Add("nb_ba2_infected_rebel","vgui/infect_killicon.vtf", Color( 255, 0, 0, 255 ) )
killicon.Add("nb_ba2_infected_combine","vgui/infect_killicon.vtf", Color( 255, 0, 0, 255 ) )
killicon.Add("ba2_infection_manager","vgui/infect_killicon.vtf", Color( 255, 0, 0, 255 ) )


-- Clientside convars
CreateClientConVar("ba2_cl_infdmgeff",1,true,true,"If enabled, your screen will flash green when you take damage from the Bio-Virus.")
CreateClientConVar("ba2_cl_playervoice",-1,true,true,[[The voice your zombie will use when raised.
    -1: Automatic
    0: Male
    1: Female
    2: Combine]],-1,2
)
CreateClientConVar("ba2_cl_mcorewarn",1,true,true,"If enabled, Zambo the Helper Zombie will notify you if gmod_mcore_test is disabled when you load in.")
CreateClientConVar("ba2_cl_maskhelp",1,true,true,"If enabled, you will see a help message with chat commands when you pick up a gas mask.")



-- Gasmask effects
local mask = nil
hook.Add("PostPlayerDraw","BA2_GasmaskDraw",function(p)
    local hasMask = p:GetNWBool("BA2_GasmaskOn",false)

    if hasMask then
        local head = p:LookupBone("ValveBiped.Bip01_Head1")

        if mask then
            SafeRemoveEntity(mask)
        end

        mask = ClientsideModel("models/barneyhelmet_faceplate.mdl")
        mask:SetColor(Color(72,72,72))
        if mask then
            mask:FollowBone(p,head)
            mask:SetAngles(p:GetAngles() + Angle(180,90,90))
            mask:SetPos(p:GetPos() + mask:LocalToWorld(Vector(2.1,0,2.4)))

            SafeRemoveEntityDelayed(mask,0)
        end
    end
end)

hook.Add("HUDPaintBackground","BA2_GamaskOverlay",function()
    if LocalPlayer():GetNWBool("BA2_GasmaskOn",false) and LocalPlayer():GetViewEntity() == LocalPlayer() then
        DrawMaterialOverlay("overlay/ba2_gasmask",0)

    end
end)
hook.Add("HUDPaint","BA2_GasmaskHUD",function()
    if GetConVar("cl_drawhud"):GetBool() and LocalPlayer():GetNWBool("BA2_GasmaskOn",false) and GetConVar("ba2_misc_maskfilters"):GetBool() then
        local filterPct = math.ceil(LocalPlayer():GetNWInt("BA2_GasmaskFilterPct",0))
        local textColor

        if filterPct > 20 or CurTime() % 2 >= 1 then
            textColor = Color(255,255,255)
        else
            textColor = Color(255,0,0)
        end

        draw.DrawText("FILTER: "..filterPct.."%","DermaLarge",ScrW() * .01,ScrH() * .01,textColor)
        draw.DrawText("RESERVE: "..LocalPlayer():GetNWInt("BA2_GasmaskFilters",0),"Trebuchet24",ScrW() * .01,ScrH() * .035,textColor)
    end
end)


-- Air waste effects


-- Q-menu options
local adminString = "You must be a server admin to modify these settings. You're still allowed to look, though.\n"

hook.Add("PopulateToolMenu","ba2_options",function(panel)
    -- ABOUT
    spawnmenu.AddToolMenuOption("Options","Bio-Annihilation II","ba2_config_abt","About","","",function(panel)
        panel:Help("Sninctbur presents:")
    end)

    -- CLIENT
    spawnmenu.AddToolMenuOption("Options","Bio-Annihilation II","ba2_config_cl","Client","","",function(panel)
        panel:Help("You can type \"find ba2_cl\" in the developer console for more information about these settings.")
        panel:Help("These settings change various cosmetic, arbitrary parts of the mod. They only affect you.")

        panel:CheckBox("Infection Damage Effect","ba2_cl_infdmgeff")
        panel:CheckBox("No Multi-Core Warning (NYI)","ba2_cl_mcorewarn")
        panel:CheckBox("Gas Mask Help Text","ba2_cl_maskhelp")

        local comboBox = panel:ComboBox("Player Voice","ba2_cl_playervoice")
        comboBox:AddChoice("-1. Automatic",-1)
        comboBox:AddChoice("0. Male",0)
        comboBox:AddChoice("1. Female",1)
        comboBox:AddChoice("2. Combine",2)
    end)

    -- COSMETIC
    spawnmenu.AddToolMenuOption("Options","Bio-Annihilation II","ba2_config_cos","Cosmetic","","",function(panel)
        panel:Help("You can type \"find ba2_cos\" in the developer console for more information about these settings.")
        panel:Help("These settings change the appearance of zombies. You can set Custom Infected models here.")

        -- panel:Help("Default Infected Color:")
        -- local mixer = vgui.Create("DColorMixer",panel)
        -- mixer:Dock(FILL)					-- Make Mixer fill place of Frame
        -- mixer:SetPalette(true)  			-- Show/hide the palette 				DEF:true
        -- mixer:SetAlphaBar(true) 			-- Show/hide the alpha bar 				DEF:true
        -- mixer:SetWangs(true) 				-- Show/hide the R G B A indicators 	DEF:true
        -- mixer:SetColor(Color(133,165,180)) 	-- Set the default color

        panel:Help("Custom Models:")
        panel:ControlHelp("Press Help key (F1) to keep the spawnmenu open")
        local tBox = vgui.Create("DTextEntry",panel)
        tBox:SetMultiline(true)
        tBox:SetPos(25,135)
        tBox:SetSize(400,300)
        tBox:SetVerticalScrollbarEnabled(true)

        local defText = ""
        local tbl = BA2_GetAltModels(true)

        for i,str in pairs(tbl) do
            defText = defText..str.."\n"
        end

        tBox:SetValue(defText)

        local rButton = vgui.Create("DButton",panel)
        rButton:SetText("Reload Custom Models")
        rButton:SetPos(25,460)
        rButton:SetSize(200,50)
        rButton.DoClick = function()
            BA2_WriteToAltModels(string.Split(tBox:GetValue(),"\n"))
            if LocalPlayer():IsAdmin() then
                net.Start("BA2ReloadCustoms")
                net.WriteTable(string.Split(tBox:GetValue(),"\n"))
                net.SendToServer()
            end
        end
    end)

    -- HORDE SPAWNER
    spawnmenu.AddToolMenuOption("Options","Bio-Annihilation II","ba2_config_hs","Horde Spawner","","",function(panel)
        if(LocalPlayer():IsAdmin() == false) then
            panel:ControlHelp(adminString)
        end
        panel:Help("You can type \"find ba2_hs\" in the developer console for more information about these settings.")
        panel:Help("These settings change the behavior of the Horde Spawner and Point Spawner entities.")
        
        panel:CheckBox("Clean Up on Remove","ba2_hs_cleanup")
        panel:NumSlider("Maximum Zombies","ba2_hs_max",1,100,0)
        panel:NumSlider("Spawn Interval","ba2_hs_interval",0.1,30,1)
        panel:NumSlider("Safe Radius","ba2_hs_saferadius",0,10000,0)

        local comboBox = panel:ComboBox("Zombie Appearance","ba2_hs_appearance")
        comboBox:AddChoice("0. Citizens",0)
        comboBox:AddChoice("1. Rebels",1)
        comboBox:AddChoice("2. Combine",2)
        comboBox:AddChoice("3. Custom",3)
        comboBox:AddChoice("4. Any of the above",4)
        comboBox:AddChoice("5. Any except Custom Infected",5)

        panel:Button("Delete Active Horde Spawner","ba2_hs_delete")
    end)

    -- INFECTION
    spawnmenu.AddToolMenuOption("Options","Bio-Annihilation II","ba2_config_inf","Infection","","",function(panel)
        if(LocalPlayer():IsAdmin() == false) then
            panel:ControlHelp(adminString)
        end
        panel:Help("You can type \"find ba2_inf\" in the developer console for more information about these settings.")
        panel:Help("These settings modify the titular Bio-Virus: its contagiousness, persistence, lethality, and ability to convert.")

        panel:CheckBox("Zombify Players","ba2_inf_plyraise")
        panel:CheckBox("Zombify NPCs","ba2_inf_npcraise")

        panel:CheckBox("Virus Must Kill to Raise","ba2_inf_killtoraise")
        panel:ControlHelp("The Bio-Virus or one of its hosts must directly kill the victim to raise them into a zombie")
        panel:CheckBox("Romero Mode","ba2_inf_romeromode")
        panel:ControlHelp("All dead players and NPCs raise as zombies, regardless of infection")

        panel:NumSlider("Contagion Radius","ba2_inf_contagionmult",0,10,2)
        panel:NumSlider("Player Infection","ba2_inf_plymult",0,10,2)
        panel:NumSlider("NPC Infection","ba2_inf_npcmult",0,10,2)
        panel:NumSlider("Infection Damage","ba2_inf_dmgmult",0,10,2)
        panel:ControlHelp("Set multipliers to 0 to disable their respective features")
    end)

    -- ZOMBIES
    spawnmenu.AddToolMenuOption("Options","Bio-Annihilation II","ba2_config_zom","Zombies","","",function(panel)
        if(LocalPlayer():IsAdmin() == false) then
            panel:ControlHelp(adminString)
        end
        panel:Help("You can type \"find ba2_zom\" in the developer console for more information about these settings.")
        panel:Help("These settings change the attributes of zombies, allowing you to make them easier or harder to kill.")

        panel:CheckBox("Stun by Damage","ba2_zom_damagestun")
        panel:CheckBox("Arm Damage/Disarming","ba2_zom_armdamage")
        panel:CheckBox("Leg Damage/Crippling","ba2_zom_legdamage")

        panel:NumSlider("Health","ba2_zom_health",1,500,0)
        panel:NumSlider("Damage Multiplier","ba2_zom_dmgmult",0,10,2)
        panel:NumSlider("Infection Multiplier","ba2_zom_infectionmult",0,10,2)
        panel:NumSlider("Non-Headshot Damage Multiplier","ba2_zom_nonheadshotmult",0,1,2)
        panel:NumSlider("Infected Raise Time","ba2_zom_emergetime",0,300,0)
        panel:NumSlider("Medic Vial Drop Chance","ba2_zom_medicdropchance",0,100,0)

        local comboBox = panel:ComboBox("Pursuit Speed","ba2_zom_pursuitspeed")
        comboBox:AddChoice("0. Pacing Speed (\"*yawn* Let me get a drink...\")",0)
        comboBox:AddChoice("1. Running Speed (\"Give me some space, will you?\")",1)
        comboBox:AddChoice("2. Full Sprint (\"OH GOD RUN\")",2)

        panel:CheckBox("Attack Props","ba2_zom_breakphys")
        panel:ControlHelp("The next options require Attack Props")
        panel:CheckBox("Unfreeze/Unconstrain","ba2_zom_breakphys")
        panel:CheckBox("Break Down Doors","ba2_zom_breakdoors")

        panel:NumSlider("Door Respawn Time","ba2_zom_doorrespawn",0,300,0)
        panel:ControlHelp("Set to 0 to not respawn doors until map cleanup")
    end)

    -- MISCELLANEOUS
    spawnmenu.AddToolMenuOption("Options","Bio-Annihilation II","ba2_config_misc","Miscellaneous","","",function(panel)
        if(LocalPlayer():IsAdmin() == false) then
            panel:ControlHelp(adminString)
        end
        panel:Help("You can type \"find ba2_misc\" in the developer console for more information about these settings.")
        panel:Help("These settings don't have a category in common, and can therefore change a variety of things.")

        panel:NumSlider("Zombie Corpse Lifetime","ba2_misc_corpselife",-1,300,0)
        panel:ControlHelp("Set to -1 for infinite lifetime (not recommended)")

        panel:CheckBox("Degradable Gas Mask Filters","ba2_misc_maskfilters")
        panel:CheckBox("Spawn with Gas Mask","ba2_misc_startwithmask")
        panel:CheckBox("Drop Gas Mask on Death","ba2_misc_deathdropmask")
        panel:CheckBox("Drop Filters on Death","ba2_misc_deathdropfilter")

        panel:Help("")

        panel:CheckBox("Air Waste Visuals","ba2_misc_airwastevisuals")
        panel:CheckBox("Air Waste Wind Shake","ba2_misc_airwasteshake")
        panel:CheckBox("No Navmesh Warning (NYI)","ba2_misc_navmeshwarn")
    end)
end)