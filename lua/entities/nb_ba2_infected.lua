AddCSLuaFile()

ENT.PrintName = "Infected"
ENT.Base = "base_nextbot"
ENT.Spawnable = false

include("autorun/ba2_shared.lua")
if SERVER then
	include("autorun/server/ba2_master_init.lua")
end


-- Initialization
function ENT:Initialize()
	self:SetModel("models/ba2/infected/ba2_handfix.mdl")
	self:AddFlags(FL_OBJECT)
    self.LoseTargetDist = 2000
	self.SearchRadius = 10000
	self.BA2_Attacking = false
	self.BA2_Stunned = false
	self.BA2_LArmDamage = 0
	self.BA2_RArmDamage = 0
	self.BA2_LLegDamage = 0
	self.BA2_RLegDamage = 0
	self.BA2_SpeedMult = math.random(90,100) / 100
	--self.InfBody = "models/Humans/Group01/male_02.mdl"

	if SERVER then
		local hp = GetConVar("ba2_zom_health"):GetInt()
		self:SetMaxHealth(hp)
		self:SetHealth(hp)
		self:SetCollisionBounds(self:OBBMins(),self:OBBMaxs())
		self:SetSolid(SOLID_BBOX)
		self:SetFriction(0)
		self:SetName("Infected")
		self.loco:SetStepHeight(36)
		self.loco:SetJumpHeight(80)
		
		for i,npc in pairs(ents.FindByClass("npc_*")) do
			if npc:IsNPC() then
				npc:AddEntityRelationship(self,D_HT,1)
			end
		end

		timer.Simple(0,function()
			if not IsValid(self) then return end

			-- if BA2_GetMaggotMode() then
			-- 	self:SetModel("models/player/soldier.mdl")
			-- 	self.InfBody = "models/player/soldier.mdl"
			-- 	self.InfVoice = 3
			-- 	self.InfSkin = math.random(4,5)
			-- 	self.ColorOverride = Color(255,255,255)
			-- end

			-- If you'd like to be chased by a horde of T-posing Soldiers this May, be my guest!

			if #navmesh.GetAllNavAreas() == 0 then
				print("BA2: There is no navmesh! Despawning...")
				self:Remove()
			end

			if self.InfBody == "CUSTOM" then
				local tbl = BA2_GetCustomInfs()
				if #tbl == 0 then
					tbl = BA2_ReloadCustoms()
				end

				self.InfBody = tbl[math.random(#tbl)]
			end

			if self.InfBody ~= nil then
				local model
				if istable(self.InfBody) then
					model = self.InfBody[math.random(1,#self.InfBody)]
				else
					model = self.InfBody
				end
		
				self.InfBody = ents.Create("ba2_infbody")
				self.InfBody:SetPos(self:GetPos())
				self.InfBody:SetModel(model)
				self.InfBody:SetOwner(self)
				self.InfBody:SetParent(self,0)
				self.InfBody:Spawn()
				self.InfBody:Activate()
		
				if self.InfBodyGroups and #self.InfBodyGroups > 0 then
					for i = 1,#self.InfBodyGroups do
						self.InfBody:SetBodygroup(i-1,self.InfBodyGroups[i])
					end
				else
					for i = 1,#self.InfBody:GetBodyGroups() do
						self.InfBody:SetBodygroup(i-1,math.random(0,self.InfBody:GetBodygroupCount(i-1)))
					end
				end
				self.InfBody:SetSkin(self.InfSkin or math.random(0,self.InfBody:SkinCount()-1))

				self:SetNoDraw(true)
				self.InfBody:AddEffects(EF_BONEMERGE)
				self.InfBody:SetColor(self.ColorOverride or BA2_GetDefaultColor())

				if BA2_GetMaggotMode() then
					self.InfVoice = 3
				elseif self.InfVoice == nil then
					if BA2_FemaleModels[model] or string.find(model,"female") ~= nil then
						self.InfVoice = 1
					elseif string.find(model,"combine") ~= nil or string.find(model,"police") ~= nil then
						self.InfVoice = 2
					else
						self.InfVoice = 0
					end
				end

				-- if BA2_GetMaggotMode() then
				-- 	local eff = ents.Create("prop_dynamic")
				-- 	eff:SetModel("models/player/items/soldier/soldier_zombie.mdl")
				-- 	eff:SetPos(self:GetPos())
				-- 	eff:SetParent(self.InfBody,0)
				-- 	eff:SetSkin(self.InfSkin - 4)
				-- 	eff:Spawn()
					
				-- 	eff:AddEffects(EF_BONEMERGE)
				-- end
			else
				print("BA2: Zombie spawned with no model! Despawning...")
				self:Remove()
			end
		end)
	end
	--self:CallOnRemove("KillSounds",function() self:KillSounds() end)
end

-- Getters and setters
function ENT:SetEnemy( ent )
	self.Enemy = ent
end
function ENT:GetEnemy()
	return self.Enemy
end
function ENT:IsValidEnemy(e)
	local ent = e or self:GetEnemy()
	return IsValid(ent) and ((ent:IsNPC() and ent:GetNoDraw() == false) or (not GetConVar("ai_ignoreplayers"):GetBool() and ent:IsPlayer() and ent:Alive()) or (ent:IsNextBot() and !string.StartWith(ent:GetClass(),"nb_ba2_infected")))
end
function ENT:GetAttacking()
	return self.BA2_Attacking
end
function ENT:SetAttacking(a)
	self.BA2_Attacking = a
end
function ENT:GetStunned()
	return self.BA2_Stunned
end
function ENT:SetStunned(a)
	self.BA2_Stunned = a
end


-- AI
function ENT:RunBehaviour() -- IT'S BEHAVIOUR NOT BEHAVIOR YOU DUMBASS
	--self:EmitSound("groan")
	if !self.noRise and self:WaterLevel() ~= 3 then
		self:EmitSound("npc/zombie/foot_slide"..math.random(1,3)..".wav")
		timer.Simple(2.25,function()
			if IsValid(self) then
				self:EmitSound("npc/zombie/foot_slide"..math.random(1,3)..".wav")
			end
		end)
		self:PlaySequenceAndWait("Infectionrise")
	end

	local path = Path( "Follow" )
	path:SetMinLookAheadDistance(100)
	path:SetGoalTolerance(15)

	local pathComplete = nil

	local traceEnts = {
		["prop_door_rotating"] = true,
		["func_door"] = true,
		["func_door_rotating"] = true,
		["func_breakable"] = true,
		["func_breakable_surf"] = true,
		["prop_physics"] = true
	}

	while true do
		if GetConVar("ai_disabled"):GetBool() then
			-- n o t h i n g
		elseif self:WaterLevel() == 3 then
			--self:SetSequence("Choked_Barnacle")
			self:ResetSequenceInfo()
			self:ResetSequence("fall_0"..math.random(1,9))

			self.loco:SetVelocity(Vector(0,0,-5))

			if self:Health() <= 20 then
				self:EmitSound("player/pl_drown1.wav")
			else
				self:EmitSound("player/pl_drown"..math.random(2,3)..".wav")
			end

			local dmg = DamageInfo()
			dmg:SetDamage(math.random(15,25))
			dmg:SetDamageType(DMG_DROWN)
			dmg:SetInflictor(game.GetWorld())
			self:TakeDamageInfo(dmg)
			coroutine.wait(1)
		-- elseif self.loco:IsClimbingOrJumping() then
			-- self:SwitchActivity(ACT_IDLE)
			-- self:SetSequence("fall_0"..math.random(1,9))
		elseif not self:GetAttacking() and not self:GetStunned() then
			-- Todo: End attacking animation if it's still going
			if self:IsValidEnemy() or IsValid(self:SearchForEnemy()) then -- Pursuit
				self:PursuitSpeed()

				--self:ChaseEnemy()
				self.NavTarget = self:GetEnemy():GetPos()
			elseif self:GetEnemy() ~= nil and !self:IsValidEnemy() then
				self:SetEnemy(nil)
				self.NavTarget = self:GetPos() + Vector( math.Rand( -1, 1 ), math.Rand( -1, 1 ), 0 ) * 200

			elseif IsValid(self:SearchForCorpse()) then -- Move to corpse
				local corpse = self:SearchForCorpse()
				local corpsePos = corpse:GetPos()

				if self:GetPos():Distance(corpsePos) <= 50 then
					self:ZombieEat(corpse)
				else
					self:SwitchActivity( ACT_WALK )			-- Walk anmimation
					self.loco:SetDesiredSpeed( 40 )		-- Walk speed
					self.loco:SetAcceleration(400)
					self.NavTarget = corpsePos
				end


			else -- Pacing
				self:SwitchActivity( ACT_WALK )			-- Walk anmimation
				self.loco:SetDesiredSpeed( 35 * self.BA2_SpeedMult )		-- Walk speed
				self.loco:SetAcceleration(400)
				--self:EmitSound("groan")
				if self.NavTarget == nil or self:GetPos():Distance(self.NavTarget) <= 20 then
					self:SwitchActivity( ACT_IDLE )
					coroutine.wait(math.Rand(25,200) / 100)

					self.NavTarget = self:GetPos() + Vector( math.Rand( -1, 1 ), math.Rand( -1, 1 ), 0 ) * 200
					pathComplete = nil
				end
			end

			if self.NavTarget ~= nil then -- ChaseEnemy code robbed shamelessly from the wiki, because fuck reinventing the wheel
				self.loco:FaceTowards(self.NavTarget)
				if path:GetAge() > .5 then
					pathComplete = path:Compute( self, self.NavTarget )	-- Compute the path towards the enemies position
				end
				--print(pathComplete)
	
				if pathComplete then
					if ( path:GetAge() > 0.5 ) then					-- Since we are following the player we have to constantly remake the path
						pathComplete = path:Compute(self, self.NavTarget) -- Compute the path towards the enemy's position again
					end							-- This function moves the bot along the path
				elseif self:IsValidEnemy() then
					--print(self:EntIndex(),"BA2: Pathfinding failed")
					--self:HandleStuck()
					local tr = util.TraceLine({
						start = self:EyePos(),
						endpos = self:GetEnemy():GetPos(),
						mask = MASK_BLOCKLOS
					})

					if tr.Hit and !traceEnts[tr.Entity] then
						self:SetEnemy(self:SearchForEnemy()) -- Pick a new enemy if we can't get to the current one
						self:HandleStuck()
					end
				end

				path:Update( self )	

				if self.loco:IsStuck() then
					--print(self:EntIndex(),"BA2: Pathfinding stuck")
					-- if (path:GetPositionOnPath(path:GetCursorPosition() + 25) - path:GetCursorData().pos).z > 0 then
					-- 	self.loco:JumpAcrossGap(path:GetCursorData().pos,path:GetPositionOnPath(path:GetCursorPosition() + 25))
					-- else
						self:HandleStuck()
					-- end
				end

				if self:IsValidEnemy() then
					local tr = nil
					local t2 = nil

					if !(self.BA2_LArmDown and self.BA2_RArmDown) then
						tr = util.TraceHull({
							start = self:EyePos(),
							endpos = self:EyePos() + self:GetForward() * 25,
							maxs = Vector(),
							mins = self:OBBMins(),
							filter = self
						})
						tr2 = util.TraceLine({
							start = self:EyePos(),
							endpos = self:GetEnemy():GetPos(),
							mask = MASK_NPCSOLID
						})
						debugoverlay.Line(tr.StartPos,tr.HitPos,.1)
					end

					if tr ~= nil and tr.Hit and tr2.Hit and not traceEnts[tr2.Hit] and traceEnts[tr.Entity:GetClass()] then
						self:ZombieSmash(tr.Entity)
					elseif self:GetEnemy():GetPos():Distance(self:GetPos()) < 60 and self:VisibleVec(self:GetEnemy():GetPos()) then
						self:ZombieAttack()
					end
				end
			end
		end

		coroutine.yield()
	end
end
function ENT:PursuitSpeed()
	local PursuitConfig = GetConVar("ba2_zom_pursuitspeed"):GetInt()
	if self.BA2_Crippled then
		self:SwitchActivity(ACT_WALK)
		self.loco:SetDesiredSpeed(45 * self.BA2_SpeedMult)
		self.loco:SetAcceleration(400)
	elseif PursuitConfig == 1 then
		self:SwitchActivity(ACT_RUN)
		self.loco:SetDesiredSpeed(120 * self.BA2_SpeedMult)
		self.loco:SetAcceleration(1600)
	elseif PursuitConfig == 2 then
		self:SwitchActivity(ACT_SPRINT)
		self.loco:SetDesiredSpeed(300 * self.BA2_SpeedMult)
		self.loco:SetAcceleration(3200)
	else
		self:SwitchActivity(ACT_WALK)
		self.loco:SetDesiredSpeed(45 * self.BA2_SpeedMult)
		self.loco:SetAcceleration(400)
	end
end

function ENT:SearchForEnemy()
	-- Don't bother looking for enemies if there are no enemies in the first place
	if #ents.FindByClass("npc_*") == 0 then
		if GetConVar("ai_ignoreplayers"):GetBool() then return
		else
			local foundPly = false
			for i,p in pairs(player.GetAll()) do
				if p:Alive() then
					foundPly = true
					break
				end
			end
			if !foundPly then return end
		end
	end

	local minEnt = nil
	local minDist = math.huge
	for i,ent in pairs(ents.FindInSphere(self:GetPos(),self.SearchRadius)) do
		if self:IsValidEnemy(ent) then
			local dist = ent:GetPos():Distance(self:GetPos())
			if dist < minDist then
				minEnt = ent
				minDist = dist
			end
		end
	end

	if minEnt then
		self:SetEnemy(minEnt)
	end
	return minEnt
end
function ENT:SearchForCorpse()
	if #ents.FindByClass("prop_ragdoll") == 0 then return end

	local minEnt = nil
	local minDist = math.huge
	for i,ent in pairs(ents.FindInSphere(self:GetPos(),self.SearchRadius / 8)) do
		if ent:GetClass() == "prop_ragdoll" and ent:GetNoDraw() == false and !ent.BA2_ZomCorpse then
			local dist = ent:GetPos():Distance(self:GetPos())
			if dist < minDist then
				minEnt = ent
				minDist = dist
			end
		end
	end

	if minEnt then
		self:SetEnemy(minEnt)
	end
	return minEnt
end

function ENT:HandleStuck()
	--print(self:EntIndex(),"BA2: Handling stuck")
	self.loco:ClearStuck()

	if self:IsValidEnemy() then
		self:PursuitSpeed()
	else
		self:SwitchActivity( ACT_WALK )			-- Walk anmimation
		self.loco:SetDesiredSpeed( 35 * self.BA2_SpeedMult )		-- Walk speed
		self.loco:SetAcceleration(400)
	end

	-- if (self.NavTarget - self:GetPos()).z > 0 then
	-- 	self.loco:Jump()
	-- else
	-- 	self.NavTarget = self:GetPos() + Vector( math.Rand( -1, 1 ), math.Rand( -1, 1 ), 0 ) * 200
	-- end -- Jump behavior is temporarily disabled on account of being garbo
	self.NavTarget = self:GetPos() + Vector( math.Rand( -1, 1 ), math.Rand( -1, 1 ), 0 ) * 200 
	--self:MoveToPos(self:GetPos() + Vector( math.Rand( -1, 1 ), math.Rand( -1, 1 ), 0 ) * 200,{maxage = 3}) -- Unoptimized, apparently
	for i = 1,125 do
		self.loco:FaceTowards(self.NavTarget)
		self.loco:Approach(self.NavTarget,1)
		-- if !self.loco:IsOnGround() then
		-- 	self.loco:SetVelocity(self:GetForward() * 6)
		-- end
		if self:GetPos():Distance(self.NavTarget) <= 20 then
			break
		end
		coroutine.yield()
	end
end

-- function ENT:OnUnStuck()
-- 	print(self:EntIndex(),"BA2: Stuck handled!")
-- end

function ENT:ZombieAttack()
	self:SetAttacking(true)

	if self.BA2_Crippled then
		self:SetSequence("crawlgrabloop")
	else
		self:SetSequence("nz_boardtear_blend_horizontal_m_hold")
	end

	local enemy = self:GetEnemy()
	local dmgMult = GetConVar("ba2_zom_dmgmult"):GetFloat()

	if !(self.BA2_LArmDown and self.BA2_RArmDown) then
		self:EmitSound("physics/flesh/flesh_impact_hard"..math.random(1,6)..".wav")
		BA2_ZombieGrab(self,enemy)
	end

	while self:IsValidEnemy() and self:GetAttacking() do
		coroutine.wait(.5)
		if not self:IsValidEnemy() or not self:GetAttacking() then break end
		if enemy:GetPos():Distance(self:GetPos()) > 60 then break end
		self.loco:FaceTowards(enemy:GetPos())

		BA2_AddInfection(enemy,math.random(1,7) * GetConVar("ba2_zom_infectionmult"):GetFloat())

		local dmg = DamageInfo()
		dmg:SetDamage(math.random(7,9) * dmgMult)
		dmg:SetDamageType(DMG_SLASH)
		dmg:SetDamageCustom(DMG_BIOVIRUS)
		dmg:SetAttacker(self)
		dmg:SetInflictor(BA2_InfectionManager())

		if self.BA2_LArmDown then
			dmg:SetDamage(dmg:GetDamage() * 0.5)
		end
		if self.BA2_RArmDown then
			dmg:SetDamage(dmg:GetDamage() * 0.5)
		end
		enemy:TakeDamageInfo(dmg)

		if enemy:IsPlayer() then
			enemy:ViewPunch(AngleRand(-1,1) * 5)
		end

		self:EmitSound("ba2_fleshtear") -- Nom
	end

	self:SetAttacking(false)
	if self:IsValidEnemy() and enemy:GetPos():Distance(self:GetPos()) > 60 then
		self:EmitSound("physics/body/body_medium_impact_soft"..math.random(1,7)..".wav")
		self:ZombieStun()
	end
end

function ENT:ZombieStun()
	if self:GetStunned() or self:WaterLevel() == 3 then return end

	self:ZombieVox("hurt")
	self:SwitchActivity(ACT_IDLE)
	self:ResetSequenceInfo()
	self:SetAttacking(false)
	self:SetStunned(true)

	if self.BA2_Crippled then
		self:ResetSequence("Crawlgrabshove")
	else
		self:ResetSequence("ShoveReact")
	end

	local timerName = self:EntIndex().."-stun"
	timer.Create(timerName,self:SequenceDuration("ShoveReact"),1,function()
		if IsValid(self) then
			self:SetStunned(false)
		end
	end)
	timer.Start(timerName)
end

function ENT:ZombieSmash(ent)
	self:SetAttacking(true)
	local attackAnims = {
		"nz_attack_stand_ad_2-2",
		"nz_attack_stand_ad_2-3"
	}

	timer.Simple(0.6,function()
		if IsValid(self) and IsValid(ent) then
			if ent:GetClass() ~= "prop_physics" or ent:GetPos():Distance(self:GetPos()) <= 60 then
				local propDmg = math.random(10,20) * GetConVar("ba2_zom_dmgmult"):GetFloat()

				if ent:GetClass() == "prop_door_rotating" then
					if ent.BA2_DoorHealth == nil then
						ent.BA2_DoorHealth = 200 - propDmg
					elseif ent.BA2_DoorHealth <= 0 then
						self:EmitSound("npc/zombie/claw_miss1.wav")
						return -- Prevent magic door duplication
					else
						ent.BA2_DoorHealth = ent.BA2_DoorHealth - propDmg
					end

					if ent.BA2_DoorHealth <= 0 then
						ent:EmitSound("ambient/materials/door_hit1.wav")

						local prop = ents.Create("prop_physics")
						prop:SetModel(ent:GetModel())
						prop:SetSkin(ent:GetSkin())
						prop:SetBodygroup(0,ent:GetBodygroup(0))
						prop:SetPos(ent:GetPos())
						prop:SetAngles(ent:GetAngles())
						prop:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
						prop:SetSolid(SOLID_NONE)

						prop:Spawn()
						prop:Activate()
						prop:GetPhysicsObject():ApplyForceCenter(self:GetForward() * 5000)

						ent:SetNoDraw(true)
						ent:SetSolid(SOLID_NONE)

						local doorRespawn = GetConVar("ba2_zom_doorrespawn"):GetFloat()
						if doorRespawn >= 0 then
							timer.Simple(doorRespawn,function()
								ent:SetNoDraw(false)
								ent:SetCollisionGroup(COLLISION_GROUP_NONE)
								ent:SetSolid(SOLID_OBB)
								ent.BA2_DoorHealth = 200

								SafeRemoveEntity(prop)
							end)
						end
					elseif math.random(1,100) >= ent.BA2_DoorHealth then
						ent:EmitSound("physics/wood/wood_strain"..math.random(2,4)..".wav")
					end
				else
					local dmg = DamageInfo()
					dmg:SetDamage(propDmg)
					dmg:SetAttacker(self)
					dmg:SetInflictor(self)
					dmg:SetDamageType(DMG_SLASH)
		
					ent:TakeDamageInfo(dmg)
				end
				
				if GetConVar("ba2_zom_breakphys"):GetBool() and #constraint.GetTable(ent) > 0 then
					constraint.RemoveAll(ent)
					ent:EmitSound("physics/metal/sawblade_stick"..math.random(1,3)..".wav")
				end
				local phys = ent:GetPhysicsObject()
				if IsValid(phys) then
					phys:ApplyForceCenter(self:GetForward() * 5000)
					if GetConVar("ba2_zom_breakphys"):GetBool() then
						phys:EnableMotion(true)
					end
				end

				if ent:GetClass() == "prop_physics" then
					ent:EmitSound("npc/zombie/zombie_pound_door.wav")
				elseif ent:GetClass() ~= "func_breakable_surf" then
					ent:EmitSound("physics/wood/wood_crate_impact_hard"..math.random(2,3)..".wav",75,math.random(80,110))
				end
			else
				self:EmitSound("npc/zombie/claw_miss1.wav")
			end
		end
	end)

	self:PlaySequenceAndWait(attackAnims[math.random(2)])
	self:SetAttacking(false)
end

function ENT:ZombieEat(corpse)
	self:SwitchActivity( ACT_IDLE )

	timer.Simple(.6,function()
		if IsValid(self) and IsValid(corpse) then
			self:EmitSound("ba2_corpsechomp",75,75,100)

			local mat = corpse:GetMaterialType()
			if mat == MAT_ANTLION or mat == MAT_ALIENFLESH then
				util.Decal("YellowBlood",self:EyePos(),corpse:GetPos(),self)
			else
				util.Decal("Blood",self:EyePos(),corpse:GetPos(),self)
			end
		end
	end)

	if self.BA2_Crippled then
		self:PlaySequenceAndWait("crawlgrabloop")
	else
		self:PlaySequenceAndWait("choke_eat")
	end
end


-- Damage/death handling
function ENT:BreakLArm(dmginfo)
	self.BA2_LArmDown = true
	self:EmitSound("npc/barnacle/barnacle_crunch"..math.random(2,3)..".wav",75)
			
	self:DeflateBones({
		"ValveBiped.Bip01_L_Forearm",
		"ValveBiped.Bip01_L_Hand",
		"ValveBiped.Bip01_L_Finger0",
		"ValveBiped.Bip01_L_Finger1",
		"ValveBiped.Bip01_L_Finger2",
		"ValveBiped.Bip01_L_Finger3",
		"ValveBiped.Bip01_L_Finger4",
	})
	self:CreateGib(self.InfBody:GetBonePosition(self.InfBody:LookupBone("ValveBiped.Bip01_L_Forearm")),"models/ba2/gibs/armlowerl.mdl",dmginfo:GetDamageForce():GetNormalized() * 100)
	self:CreateGib(self.InfBody:GetBonePosition(self.InfBody:LookupBone("ValveBiped.Bip01_L_Hand") or self.InfBody:LookupBone("ValveBiped.Bip01_L_Forearm")),"models/ba2/gibs/handl.mdl",dmginfo:GetDamageForce():GetNormalized() * 100)

	local eff = EffectData()
	eff:SetFlags(6)
	eff:SetColor(0)
	eff:SetScale(2)
	eff:SetEntity(self)
	local timer1 = self:EntIndex().."-larmshot"
	timer.Create(timer1,0.2,math.random(8,10),function()
		if IsValid(self) then
			eff:SetOrigin(self:GetBonePosition(self:LookupBone("ValveBiped.Bip01_L_Forearm")))
			util.Effect("BloodImpact",eff)
		else
			timer.Destroy(timer1)
		end
	end)
	
	timer.Start(timer1)
end
function ENT:BreakRArm(dmginfo)
	self.BA2_RArmDown = true
	self:EmitSound("npc/barnacle/barnacle_crunch"..math.random(2,3)..".wav",75)
	
	self:DeflateBones({
		"ValveBiped.Bip01_R_Forearm",
		"ValveBiped.Bip01_R_Hand",
		"ValveBiped.Bip01_R_Finger0",
		"ValveBiped.Bip01_R_Finger1",
		"ValveBiped.Bip01_R_Finger2",
		"ValveBiped.Bip01_R_Finger3",
		"ValveBiped.Bip01_R_Finger4",
	})
	self:CreateGib(self.InfBody:GetBonePosition(self.InfBody:LookupBone("ValveBiped.Bip01_R_Forearm")),"models/ba2/gibs/armlowerr2.mdl",dmginfo:GetDamageForce():GetNormalized() * 100)
	self:CreateGib(self.InfBody:GetBonePosition(self.InfBody:LookupBone("ValveBiped.Bip01_R_Hand") or self.InfBody:LookupBone("ValveBiped.Bip01_R_Forearm")),"models/ba2/gibs/handr.mdl",dmginfo:GetDamageForce():GetNormalized() * 100)

	local eff = EffectData()
	eff:SetFlags(6)
	eff:SetColor(0)
	eff:SetScale(2)
	eff:SetEntity(self)
	local timer1 = self:EntIndex().."-rarmshot"
	timer.Create(timer1,0.2,math.random(8,10),function()
		if IsValid(self) then
			eff:SetOrigin(self:GetBonePosition(self:LookupBone("ValveBiped.Bip01_R_Forearm")))
			util.Effect("BloodImpact",eff)
		else
			timer.Destroy(timer1)
		end
	end)

	timer.Start(timer1)
end
function ENT:BreakLLeg(dmginfo)
	self.BA2_LLegDown = true
	self.BA2_Crippled = true
	self:EmitSound("npc/barnacle/barnacle_crunch"..math.random(2,3)..".wav",75)
	
	self:DeflateBones({
		"ValveBiped.Bip01_L_Calf",
		"ValveBiped.Bip01_L_Foot",
		"ValveBiped.Bip01_L_Toe0",
	})
	self:CreateGib(self.InfBody:GetBonePosition(self.InfBody:LookupBone("ValveBiped.Bip01_L_Calf")),"models/ba2/gibs/legupperleft.mdl",dmginfo:GetDamageForce():GetNormalized() * 100)
	self:CreateGib(self.InfBody:GetBonePosition(self.InfBody:LookupBone("ValveBiped.Bip01_L_Foot")),"models/ba2/gibs/leglowerleft.mdl",dmginfo:GetDamageForce():GetNormalized() * 100)

	local eff = EffectData()
	eff:SetFlags(6)
	eff:SetColor(0)
	eff:SetScale(2)
	eff:SetEntity(self)
	local timer1 = self:EntIndex().."-llegshot"
	timer.Create(timer1,0.2,math.random(8,10),function()
		if IsValid(self) then
			eff:SetOrigin(self:GetBonePosition(self:LookupBone("ValveBiped.Bip01_L_Calf")))
			util.Effect("BloodImpact",eff)
		else
			timer.Destroy(timer1)
		end
	end)

	timer.Start(timer1)
end
function ENT:BreakRLeg(dmginfo)
	self.BA2_RLegDown = true
	self.BA2_Crippled = true
	self:EmitSound("npc/barnacle/barnacle_crunch"..math.random(2,3)..".wav",75)
	
	self:DeflateBones({
		"ValveBiped.Bip01_R_Calf",
		"ValveBiped.Bip01_R_Foot",
		"ValveBiped.Bip01_R_Toe0",
	})
	self:CreateGib(self.InfBody:GetBonePosition(self.InfBody:LookupBone("ValveBiped.Bip01_R_Calf")),"models/ba2/gibs/legupperright.mdl",dmginfo:GetDamageForce():GetNormalized() * 100)
	self:CreateGib(self.InfBody:GetBonePosition(self.InfBody:LookupBone("ValveBiped.Bip01_R_Foot")),"models/ba2/gibs/leglowerright.mdl",dmginfo:GetDamageForce():GetNormalized() * 100)

	local eff = EffectData()
	eff:SetFlags(6)
	eff:SetColor(0)
	eff:SetScale(2)
	eff:SetEntity(self)
	local timer1 = self:EntIndex().."-rlegshot"
	timer.Create(timer1,0.2,math.random(8,10),function()
		if IsValid(self) then
			eff:SetOrigin(self:GetBonePosition(self:LookupBone("ValveBiped.Bip01_R_Calf")))
			util.Effect("BloodImpact",eff)
		else
			timer.Destroy(timer1)
		end
	end)

	timer.Start(timer1)
end


function ENT:OnTraceAttack(dmginfo,dir,trace)
	if trace.HitGroup == HITGROUP_HEAD then
		dmginfo:SetDamage(dmginfo:GetDamage() * 4)

		if BA2_GetMaggotMode() then
			self:EmitSound("player/crit_hit"..math.random(2,6)..".wav",95)
		end

		if GetConVar("ba2_misc_headshoteff"):GetBool() and self:Health() - dmginfo:GetDamage() <= math.random(-60,-30) then
			self.BA2_HeadshotEffect = true
		end
	end

	if trace.HitGroup == HITGROUP_LEFTARM and self.BA2_LArmDown == nil then
		self.BA2_LArmDamage = self.BA2_LArmDamage + dmginfo:GetDamage()
		if GetConVar("ba2_zom_armdamage"):GetBool() and self.BA2_LArmDamage >= self:GetMaxHealth() * .5 then
			self:BreakLArm(dmginfo)
		end
		dmginfo:SetDamage(dmginfo:GetDamage() * 0.5)
	elseif trace.HitGroup == HITGROUP_RIGHTARM and self.BA2_RArmDown == nil then
		self.BA2_RArmDamage = self.BA2_RArmDamage + dmginfo:GetDamage()
		if GetConVar("ba2_zom_armdamage"):GetBool() and self.BA2_RArmDamage >= self:GetMaxHealth() * .5 then
			self:BreakRArm(dmginfo)
		end
		dmginfo:SetDamage(dmginfo:GetDamage() * 0.5)
	end

	if trace.HitGroup == HITGROUP_LEFTLEG and self.BA2_LLegDown == nil then
		self.BA2_LLegDamage = self.BA2_LLegDamage + dmginfo:GetDamage()
		if GetConVar("ba2_zom_legdamage"):GetBool() and self.BA2_LLegDamage >= self:GetMaxHealth() * .75 then
			self:BreakLLeg(dmginfo)
		end
		dmginfo:SetDamage(dmginfo:GetDamage() * 0.5)
	elseif trace.HitGroup == HITGROUP_RIGHTLEG and self.BA2_RLegDown == nil then
		self.BA2_RLegDamage = self.BA2_RLegDamage + dmginfo:GetDamage()
		if GetConVar("ba2_zom_legdamage"):GetBool() and self.BA2_RLegDamage >= self:GetMaxHealth() * .75 then
			self:BreakRLeg(dmginfo)
		end
		dmginfo:SetDamage(dmginfo:GetDamage() * 0.5)
	end

	if trace.HitGroup ~= HITGROUP_HEAD then
		dmginfo:SetDamage(dmginfo:GetDamage() * GetConVar("ba2_zom_nonheadshotmult"):GetFloat())
	end

	if self.BA2_Crippled and self:GetActivity() == ACT_IDLE then
		self:SetSequence("crawlidle")
	end
end

function ENT:OnInjured(dmginfo)
	if dmginfo:IsExplosionDamage() and math.random(1,100) <= dmginfo:GetDamage() then
		if math.random(self:Health()) <= dmginfo:GetDamage() then
			local randNum
			if self:Health() <= dmginfo:GetDamage() then
				randNum = math.random(5)
			else
				randNum = math.random(4)
			end
			
			if randNum == 1 then
				self:BreakLArm(dmginfo)
			elseif randNum == 2 then
				self:BreakRArm(dmginfo)
			elseif randNum == 3 then
				self:BreakLLeg(dmginfo)
			elseif randNum == 4 then
				self:BreakRLeg(dmginfo)
			else
				self.BA2_HeadshotEffect = true
			end
		end
	end

	if (self:GetAttacking() and (dmginfo:IsDamageType(DMG_SLASH) or dmginfo:IsDamageType(DMG_CRUSH) or dmginfo:IsDamageType(DMG_CLUB) or dmginfo:IsExplosionDamage())) 
	or (GetConVar("ba2_zom_damagestun"):GetBool() and dmginfo:GetDamage() > self:Health() / 2) then
		self:ZombieStun()
	end
end

function ENT:OnKilled(dmginfo)
	hook.Call("OnNPCKilled", GAMEMODE, self, dmginfo:GetAttacker(), dmginfo:GetInflictor())
	if not IsValid(self.InfBody) then self:Remove() return end
	
	self:ZombieVox("hurt")

	if string.find(self.InfBody:GetModel(),"group03m") and math.random(1,100) <= GetConVar("ba2_zom_medicdropchance"):GetInt() then
		local vial = ents.Create("item_healthvial")
		vial:SetPos(self:GetPos() + Vector(0,0,40))
		vial:SetVelocity(VectorRand() * 2)
		vial:Spawn()
		vial:Activate()
	end

	local body = ents.Create( "prop_ragdoll" )
	body:SetPos(self:GetPos())
	body:SetModel(self.InfBody:GetModel())
	body:SetColor(self.InfBody:GetColor())
	body:SetSkin(self.InfBody:GetSkin())

	for i = 1,#self.InfBody:GetBodyGroups() do
		body:SetBodygroup(i-1,self.InfBody:GetBodygroup(i-1))
	end
	body:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
	body.BA2_ZomCorpse = true
	
	body:Spawn()

	for id = 1,body:GetPhysicsObjectCount() do
		local bone = body:GetPhysicsObjectNum(id - 1)
		if IsValid(bone) then
			local pos,angle = self:GetBonePosition(body:TranslatePhysBoneToBone(id - 1))
			if pos ~= nil then
				bone:SetPos(pos)
			end
			if angle ~= nil then
				bone:SetAngles(angle)
			end
			bone:AddVelocity(self:GetVelocity())

			--body:ManipulateBoneScale(id - 1,self.InfBody:GetManipulateBoneScale(id - 1))
		end
	end

	if self.BA2_LArmDown then
		self:DeflateBones({
			"ValveBiped.Bip01_L_Forearm",
			"ValveBiped.Bip01_L_Hand",
			"ValveBiped.Bip01_L_Finger0",
			"ValveBiped.Bip01_L_Finger1",
			"ValveBiped.Bip01_L_Finger2",
			"ValveBiped.Bip01_L_Finger3",
			"ValveBiped.Bip01_L_Finger4",
		},body)
	end
	if self.BA2_RArmDown then
		self:DeflateBones({
			"ValveBiped.Bip01_R_Forearm",
			"ValveBiped.Bip01_R_Hand",
			"ValveBiped.Bip01_R_Finger0",
			"ValveBiped.Bip01_R_Finger1",
			"ValveBiped.Bip01_R_Finger2",
			"ValveBiped.Bip01_R_Finger3",
			"ValveBiped.Bip01_R_Finger4",
		},body)
	end
	if self.BA2_LLegDown then
		self:DeflateBones({
			"ValveBiped.Bip01_L_Calf",
			"ValveBiped.Bip01_L_Foot",
			"ValveBiped.Bip01_L_Toe0",
		},body)
	end
	if self.BA2_RLegDown then
		self:DeflateBones({
			"ValveBiped.Bip01_R_Calf",
			"ValveBiped.Bip01_R_Foot",
			"ValveBiped.Bip01_R_Toe0",
		},body)
	end
	if self.BA2_HeadshotEffect then
		self:KillSounds()
		self:EmitSound("npc/barnacle/barnacle_crunch"..math.random(2,3)..".wav",85)
		body:EmitSound("ba2_headlessbleed")

		self:DeflateBones({
			"ValveBiped.Bip01_Head1",
		},body)

		local headPos = body:GetBonePosition(body:LookupBone("ValveBiped.Bip01_Head1"))
		local gibs = {
			"models/ba2/gibs/eyel.mdl",
			"models/ba2/gibs/eyer.mdl",
			"models/ba2/gibs/headbackl.mdl",
			"models/ba2/gibs/headbackr.mdl",
			"models/ba2/gibs/headfrontl.mdl",
			"models/ba2/gibs/headfrontr.mdl",
			"models/ba2/gibs/headtop.mdl",
			"models/ba2/gibs/jaw.mdl"
		}

		for i,mdl in pairs(gibs) do
			self:CreateGib(headPos,mdl,dmginfo:GetDamageForce():GetNormalized() * 250)
		end

		local eff = EffectData()
		eff:SetFlags(6)
		eff:SetColor(0)
		eff:SetScale(10)
		eff:SetEntity(body)
		eff:SetAttachment(6)
		
		local timer1 = body:EntIndex().."-headshot1"
		timer.Create(timer1,0.1,math.random(17,20),function()
			if IsValid(body) then
				eff:SetOrigin(body:GetBonePosition(body:LookupBone("ValveBiped.Bip01_Head1")))
				util.Effect("BloodImpact",eff)
			else
				timer.Destroy(timer1)
			end
		end)

		timer.Start(timer1)
	end

	local phys = body:GetPhysicsObject()
	if IsValid(phys) then
		phys:ApplyForceCenter(dmginfo:GetDamageForce())
	end
	local corpseLife = GetConVar("ba2_misc_corpselife"):GetFloat()
	if corpseLife >= 0 then
		body:Fire("FadeAndRemove",0.5,corpseLife)
	end

	-- if BA2_GetMaggotMode() then
	-- 	local eff2 = ents.Create("prop_dynamic")
	-- 	eff2:SetModel("models/player/items/soldier/soldier_zombie.mdl")
	-- 	eff2:SetPos(body:GetPos())
	-- 	eff2:SetParent(body,0)
	-- 	eff2:SetOwner(body)
	-- 	eff2:SetSkin(self.InfSkin - 4)
	-- 	eff2:Spawn()
		
	-- 	eff2:AddEffects(EF_BONEMERGE)
	-- 	body:AddEffects(EF_BONEMERGE)

	-- 	if corpseLife >= 0 then
	-- 		timer.Simple(corpseLife,function()
	-- 			if IsValid(eff2) then
	-- 				eff2:Fire("FadeAndRemove",0.5)
	-- 			end
	-- 		end)
	-- 	end
	-- end
	
	self:Remove()
end


-- Pretty stuff
function ENT:KillSounds() -- Dev note: Might still murder performance
	if self.InfVoice == 0 then
		self:StopSound("ba2_inf_m_groan")
		self:StopSound("ba2_inf_m_hurt")
	elseif self.InfVoice == 1 then
		self:StopSound("ba2_inf_f_groan")
		self:StopSound("ba2_inf_f_hurt")
	elseif self.InfVoice == 2 then
		self:StopSound("ba2_inf_c_groan")
		self:StopSound("ba2_inf_c_hurt")
	else
		self:StopSound("ba2_inf_s_groan")
		self:StopSound("ba2_inf_s_hurt")
	end
end
-- function ENT:OnLandOnGround()
-- end
-- function ENT:OnRemove()
-- end
function ENT:ZombieVox(sound)
	if self:WaterLevel() == 3 then return end
	if self.BA2_HeadshotEffect then return end
	
	if SERVER then
			--self:KillSounds()
		if sound == "groan" then
			if self.InfVoice == 1 then
				self:EmitSound("ba2_inf_f_groan")
			elseif self.InfVoice == 2 then
				self:EmitSound("ba2_inf_c_groan")
			elseif self.InfVoice == 3 then
				self:EmitSound("ba2_inf_s_groan")
			else
				self:EmitSound("ba2_inf_m_groan")
			end
		elseif sound == "hurt" then
			if self.InfVoice == 1 then
				self:EmitSound("ba2_inf_f_hurt")
			elseif self.InfVoice == 2 then
				self:EmitSound("ba2_inf_c_hurt")
			elseif self.InfVoice == 3 then
				self:EmitSound("ba2_inf_s_hurt")
			else
				self:EmitSound("ba2_inf_m_hurt")
			end
		else
			error("Invalid zombie vox")
		end
	end
end
function ENT:SwitchActivity(act)
	if self.loco:GetVelocity():LengthSqr() < 20 and self:GetActivity() ~= ACT_IDLE then
		self:StartActivity(ACT_IDLE)
	elseif self:GetActivity() ~= act then
		self.NextStepTime = nil
		if act ~= ACT_IDLE and self.loco:GetVelocity():LengthSqr() > 20 then
			self:EmitSound("npc/zombie/foot_slide"..math.random(1,3)..".wav")
		end
		self:StartActivity(act)
		if self.BA2_Crippled then
			if act == ACT_IDLE then
				self:SetSequence("crawlidle")
			else
				self:SetSequence("crawl")
			end
		end
	end
end

function ENT:CreateGib(pos,mdl,force)
	force = force or Vector(0,0,0)

	local gib = ents.Create("ba2_gib")
	gib:SetPos(pos + VectorRand() * 0.5)
	gib:SetModel(mdl)
	gib:Spawn()
	gib:Initialize()
	gib:GetPhysicsObject():SetVelocity(force + VectorRand() * 125)
end

function ENT:DeflateBones(tbl,ent)
	ent = ent or self.InfBody
	if !IsValid(ent) then return end

	for i,b in pairs(tbl) do
		if ent:LookupBone(b) then
			ent:ManipulateBoneScale(ent:LookupBone(b),Vector(0,0,0))
		end
	end
end


function ENT:Think()
	if SERVER then
		if self.NextSoundTime == nil or self.NextSoundTime < CurTime() + .001 then
			self:ZombieVox("groan")
			self.NextSoundTime = CurTime() + math.random(4,8)
		end

		if self.NextStepTime == nil then
			local act = self:GetActivity()

			if act == ACT_WALK then
				self.NextStepTime = CurTime() + .8 / self.BA2_SpeedMult
			elseif act == ACT_RUN then
				self.NextStepTime = CurTime() + .33 / self.BA2_SpeedMult
			elseif act == ACT_SPRINT then
				self.NextStepTime = CurTime() + .27 / self.BA2_SpeedMult
			end
		elseif self:IsOnGround() and self.NextStepTime < CurTime() then
			if self.loco:GetVelocity():LengthSqr() >= 20 then
				if self.BA2_Crippled then
					self:EmitSound("npc/zombie/foot_slide"..math.random(1,3)..".wav")
				else
					self:EmitSound("npc/zombie/foot"..math.random(1,3)..".wav")
				end
			end
			self.NextStepTime = nil
		end
	end
end
-- Hello from the past -Sninctbur