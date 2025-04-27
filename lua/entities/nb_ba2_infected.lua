AddCSLuaFile()

ENT.PrintName = "Infected"
ENT.Base = "base_nextbot"
ENT.Spawnable = false

include("autorun/ba2_shared.lua")
if SERVER then
	include("autorun/server/ba2_master_init.lua")
end

-- Cache all relevant convars to avoid unnecessary re-querying while zombies are active
local convar_cache = {}
local convars = {
	"ba2_zom_range",
	"ba2_zom_range",
	"ba2_inf_inherithealth",
	"ba2_zom_health",
	"ba2_cos_tint",
	"ai_ignoreplayers",
	"ai_disabled",
	"ba2_zom_breakobjects",
	"ba2_zom_attackmode",
	"ba2_zom_retargeting",
	"ba2_zom_range",
	"ba2_zom_pursuitspeed",
	"ba2_zom_corpseeat",
	"ba2_zom_dmgmult",
	"ba2_zom_infectionmult",
	"ba2_zom_propdmgmult",
	"ba2_zom_doorrespawn",
	"ba2_zom_breakphys",
	"ba2_zom_armordamagemult",
	"ba2_zom_armdamage",
	"ba2_zom_limbdamagemult",
	"ba2_zom_legdamage",
	"ba2_misc_realistic",
	"ba2_zom_damagestun",
	"ba2_zom_medicdropchance",
	"ba2_zom_nonheadshotmult",
	"ba2_misc_corpselife",
	"ba2_misc_addscore",
	"ba2_misc_headshoteff"
}

for i,v in pairs(convars) do
	convar_cache[v] = GetConVar(v)
end

-- Initialization
function ENT:Initialize()
	self:SetModel("models/ba2/infected/ba2_handfix.mdl")
	self:AddFlags(FL_OBJECT)
	self.BA2_Attacking = false
	self.BA2_Stunned = false
	self.BA2_LArmDamage = 0
	self.BA2_RArmDamage = 0
	self.BA2_LLegDamage = 0
	self.BA2_RLegDamage = 0
	self.BA2_SpeedMult = math.random(90,100) / 100
	self.BA2_TimeToNextScan = 0
	self.BA2_CreationTime = CurTime()
	--self.InfBody = "models/Humans/Group01/male_02.mdl"

	if SERVER then
		local mins = Vector(-10,-10,-5.94)
		local maxs = Vector(10,10,72)
		-- min: -13,-13,-5.94
		-- max: 13,13,72

		self.SearchRadius = convar_cache["ba2_zom_range"]:GetInt() or 10000
		self.HullType = HULL_HUMAN
		local hp = 100
		if convar_cache["ba2_inf_inherithealth"]:GetBool() and self.BA2_HPInherit then
			hp = self.BA2_HPInherit
		else
			hp = convar_cache["ba2_zom_health"]:GetInt()
		end
		self:SetMaxHealth(hp)
		self:SetHealth(hp)

		self:SetCollisionBounds(mins,maxs)
		--self:SetSolid(SOLID_BBOX)
		--self:PhysicsInitBox(self:OBBMins(),self:OBBMaxs())
		--self:SetMoveType(MOVETYPE_STEP)
		-- self:PhysicsInitStatic(SOLID_VPHYSICS)
		-- self:SetSolidMask(MASK_NPCSOLID)
		-- --self:SetSolid(SOLID_VPHYSICS)
		-- self:EnableCustomCollisions(true)
		-- self:SetCustomCollisionCheck(true)
		self.loco:SetStepHeight(36)
		self.loco:SetJumpHeight(80)
		
		for i,npc in pairs(ents.FindByClass("npc_*")) do
			if IsValid(npc) and npc:IsNPC() then
				-- if npc.IsVJBaseSNPC then
				-- 	-- table.insert(npc.VJ_AddCertainEntityAsEnemy,z)
				-- 	-- table.insert(npc.CurrentPossibleEnemies,z)
				-- end
				npc:AddEntityRelationship(self,D_HT,1)
			end
		end

		-- Credit to GammaWhiskey for this block of code
		-- if GetConVar("ba2_misc_isnpc"):GetBool() and not BA2_CustomMetaTable then
		-- 	BA2_CustomMetaTable = table.Copy(getmetatable(self))
		-- 	BA2_CustomMetaTable.IsNPC = function() return true end
		-- 	debug.setmetatable(self, BA2_CustomMetaTable)
		-- end

		timer.Simple(0,function()
			if not IsValid(self) then return end

			--self:GetPhysicsObject():SetMass(90)

			-- if BA2_GetMaggotMode() then
			-- 	self:SetModel("models/player/soldier.mdl")
			-- 	self.InfBody = "models/player/soldier.mdl"
			-- 	self.InfVoice = 3
			-- 	self.InfSkin = math.random(4,5)
			-- 	self.ColorOverride = Color(255,255,255)
			-- end

			-- If you'd like to be chased by a horde of T-posing Soldiers this May, be my guest!

			if #navmesh.GetAllNavAreas() == 0 then
				for i,v in pairs(player.GetAll()) do
					v:PrintMessage(HUD_PRINTCENTER,"This map doesn't have a navmesh!")
				end
				print("BA2: There is no navmesh! Despawning...")
				self:Remove()
			end

			if self.InfBody == "CUSTOM" or self.InfBody == "CUSTOM_ARM" then
				local tbl1,tbl2 = BA2_GetCustomInfs()
				if #tbl1 == 0 or #tbl2 == 0 then
					tbl1,tbl2 = BA2_ReloadCustoms()
				end

				if self.InfBody == "CUSTOM" then
					self.InfBody = tbl1[math.random(#tbl1)]
				else
					self.InfBody = tbl2[math.random(#tbl2)]
				end

				if !convar_cache["ba2_cos_tint"]:GetBool() then
					self.ColorOverride = Color(255,255,255)
				end
			end

			if self.InfBody ~= nil then
				local model
				if self.cheapleEgg and math.random(1,666) <= 1 then
					model = "models/Humans/Group01/Male_Cheaple.mdl"
				elseif istable(self.InfBody) then
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
						self.InfBody:SetBodygroup(i,self.InfBodyGroups[i])
					end
				else
					for i = 1,#self.InfBody:GetBodyGroups() do
						self.InfBody:SetBodygroup(i,math.random(0,self.InfBody:GetBodygroupCount(i-1)))
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

				if self.BA2_ArmoredZom then
					self.BA2_SpeedMult = self.BA2_SpeedMult * .9
				end

			else
				print("BA2: Zombie spawned with no model! Despawning...")
				self:Remove()
			end
		end)
	end
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
	return IsValid(ent) and ent:GetNoDraw() == false and ((ent:IsNPC()) 
		or (not convar_cache["ai_ignoreplayers"]:GetBool() and ent:IsPlayer() and ent:Alive()) 
		or (ent:IsNextBot() and !string.StartWith(ent:GetClass(),"nb_ba2_infected")))
end
function ENT:GetAllEnemies()
	local list = {}

	for i,ent in pairs(ents.FindInSphere(self:GetPos(),self.SearchRadius or 10000)) do
		if self:IsValidEnemy(ent) and ent:GetMaterialType() ~= MAT_METAL then
			table.insert(list,ent)
		end
	end

	return list
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
function ENT:GetHullType()
	return self.HullType
end
function ENT:SetHullType(a)
	self.HullType = a
end
-- function ENT:IsNPC()
-- 	return GetConVar("ba2_zom_isnpc"):GetBool()
-- end



-- AI
function ENT:ZombieNav(path)
	return path:Compute(self,self.NavTarget,function( area, fromArea, ladder, elevator, length ) -- Mod of the default function because writing a pathfinding algorithm is the most horrific thing a programmer can do (for an amateur lol)
		if ( !IsValid( fromArea ) ) then
			-- first area in path, no cost
			return 0
		
		else
		
			if ( !self.loco:IsAreaTraversable( area ) ) then
				-- our locomotor says we can't move here
				return -1
			end
	
			-- compute distance traveled along path so far
			local dist = 0
	
			if ( IsValid( ladder ) ) then
				dist = ladder:GetLength()
			elseif ( length > 0 ) then
				-- optimization to avoid recomputing length
				dist = length
			else
				dist = ( area:GetCenter() - fromArea:GetCenter() ):GetLength()
			end
	
			local cost = dist + fromArea:GetCostSoFar()
	
			-- check height change
			local deltaZ = fromArea:ComputeAdjacentConnectionHeightChange( area )
			if ( deltaZ >= self.loco:GetStepHeight() ) then
				if ( deltaZ >= self.loco:GetMaxJumpHeight() ) then
					-- too high to reach
					return -1
				end
	
				-- jumping is slower than flat ground
				local jumpPenalty = 5
				cost = cost + jumpPenalty * dist
			elseif ( deltaZ < -self.loco:GetDeathDropHeight() ) then
				-- too far to drop
				return -1
			end

			if area:IsUnderwater() and (!IsValid(self.Enemy) or self.Enemy:WaterLevel() < 2) then
				-- only kill ourselves in water as a last resort
				cost = cost * 2
			end
	
			return cost
		end
	end )
end


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
		if convar_cache["ai_disabled"]:GetBool() then
			self:SwitchActivity( ACT_IDLE )
			-- n o t h i n g
		elseif self:WaterLevel() == 3 or (self.BA2_Crippled and self:WaterLevel() >= 1) then
			--self:SetSequence("Choked_Barnacle")
			self:ResetSequenceInfo()
			if (self.BA2_Crippled and self:WaterLevel() == 1) then
				self:ResetSequence("crawlgrabloop")
			else
				self:ResetSequence("fall_0"..math.random(1,9))
			end

			self.loco:SetVelocity(Vector(0,0,-5))

			local dmgVal = math.random(15,25)

			if self:Health() <= dmgVal then
				self:EmitSound("player/pl_drown1.wav")
			else
				self:EmitSound("player/pl_drown"..math.random(2,3)..".wav")
			end

			local dmg = DamageInfo()
			dmg:SetDamage(dmgVal)
			dmg:SetDamageType(DMG_DROWN)
			dmg:SetInflictor(game.GetWorld())
			self:TakeDamageInfo(dmg)
			coroutine.wait(1)
		elseif !self.loco:IsOnGround() then
			--self:SwitchActivity(ACT_IDLE)
			--self:SetSequence("fall_0"..math.random(1,9))
		elseif not self:GetAttacking() and not self:GetStunned() then
			-- Todo: End attacking animation if it's still going
			if self:IsValidEnemy() or IsValid(self:SearchForEnemy()) then -- Pursuit
				self:PursuitSpeed()
				local enemyPos = self:GetEnemy():GetPos()
				--local enemyVel = self:GetEnemy():GetVelocity()
				-- enemyVel = enemyVel * (self.loco:GetVelocity():Length() / enemyVel:Length())
				--local enemyVelPos = enemyPos + enemyVel

				--self:ChaseEnemy()
				-- if enemyVel:LengthSqr() > .001 and self:EyePos():Dot(self:EyePos() - enemyVelPos) / enemyVelPos:Length() < -1 then -- If readjusting for velocity wouldn't make me run backwards
				-- 	self.NavTarget = enemyVelPos
				-- else
				-- 	self.NavTarget = enemyPos
				-- end
				self.NavTarget = enemyPos
			elseif self:GetEnemy() ~= nil and !self:IsValidEnemy() then
				self:SetEnemy(nil)
				--self.NavTarget = self:GetPos() + Vector( math.Rand( -1, 1 ), math.Rand( -1, 1 ), 0 ) * 200

			elseif IsValid(self:SearchForCorpse()) then -- Move to corpse
				local corpse = self:SearchForCorpse()
				local corpsePos = corpse:GetPos()

				if self:GetPos():DistToSqr(corpsePos) <= 2500 then
					self:ZombieEat(corpse)
				else
					self:SwitchActivity( ACT_WALK )			-- Walk animation
					self.loco:SetDesiredSpeed( 40 * self.BA2_SpeedMult )		-- Walk speed
					self.loco:SetAcceleration(400)
					self.NavTarget = corpsePos
				end


			else -- Pacing
				self:SwitchActivity( ACT_WALK )			-- Walk animation
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
				--self.loco:FaceTowards(self.NavTarget)
				local distToTarget = self:GetPos():DistToSqr(self.NavTarget)

				--self.NavTarget = LerpVector(math.Clamp(500 / distToTarget,0,1),self:GetPos(),self.NavTarget) -- Set our goal position closer to ourselves if it gets really far away

				if path:GetAge() > math.Clamp(distToTarget / 1000000,3,10) then
					pathComplete = self:ZombieNav(path)	-- Compute the path towards the enemies position
				end
				--print(pathComplete)
	
				if pathComplete then
					if path:GetAge() > 0.5 and (distToTarget < 1000000) then -- Remake the path sooner if it's successful to keep up the chase
						pathComplete = self:ZombieNav(path) -- Compute the path towards the enemy's position again
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
						-- self:HandleStuck()
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

				-- Attack behavior
				if self:IsValidEnemy() then
					local tr = nil
					local tr2 = nil

					if convar_cache["ba2_zom_breakobjects"]:GetBool() and !(self.BA2_LArmDown and self.BA2_RArmDown) then
						tr = util.TraceHull({
							start = self:EyePos(),
							endpos = self:EyePos() + self:GetForward() * 25,
							maxs = Vector(8,8,16),
							mins = Vector(-8,-8,-16),
							filter = self
						})
						tr2 = util.TraceLine({
							start = self:EyePos(),
							endpos = self:GetEnemy():GetPos(),
							mask = MASK_NPCSOLID
						})
						debugoverlay.Line(tr.StartPos,tr.HitPos,.1)
					end

					if convar_cache["ba2_zom_breakobjects"]:GetBool() and tr ~= nil and tr.Hit and tr2.Hit and !traceEnts[tr2.Hit] and !self:VisibleVec(self:GetEnemy():GetPos()) and (tr.Entity:IsVehicle() or traceEnts[tr.Entity:GetClass()]) then
						path:Invalidate()
						self:ZombieSmash(tr.Entity)
					elseif self:GetEnemy():GetPos():Distance(self:GetPos()) <= 60 and self:VisibleVec(self:GetEnemy():GetPos()) and !(self:GetEnemy():IsPlayer() and self:GetEnemy():InVehicle()) then
						path:Invalidate()
						if convar_cache["ba2_zom_attackmode"]:GetBool() then
							self:ZombieAttackAlt(self:GetEnemy())
						else
							self:ZombieAttack()
						end
					end
				end

				if convar_cache["ba2_zom_retargeting"]:GetBool() and CurTime() >= self.BA2_TimeToNextScan then
					self:SearchForEnemy()
				end
			end
		end

		-- Refresh convars
		self.SearchRadius = convar_cache["ba2_zom_range"]:GetInt()
		coroutine.yield()
	end
end
function ENT:PursuitSpeed()
	local PursuitConfig = self.PursuitSpeedOverride or convar_cache["ba2_zom_pursuitspeed"]:GetInt()
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
	self.BA2_TimeToNextScan = CurTime() + math.random(10,20) / 10
	if #ents.FindByClass("npc_*") == 0 then
		if convar_cache["ai_ignoreplayers"]:GetBool() then return
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
	for i,ent in pairs(self:GetAllEnemies()) do
		local dist = ent:GetPos():Distance(self:GetPos())
		if dist < minDist then
			minEnt = ent
			minDist = dist
		end
	end

	if minEnt then
		self:SetEnemy(minEnt)
	end
	return minEnt
end
function ENT:SearchForCorpse()
	if !convar_cache["ba2_zom_corpseeat"]:GetBool() then return end
	if #ents.FindByClass("prop_ragdoll") == 0 then return end -- Don't iterate over anything if there are no ragdolls

	local minEnt = nil
	local minDist = math.huge
	if self.SearchRadius == nil then
		self.SearchRadius = 10000
	end
	
	for i,ent in pairs(ents.FindInSphere(self:GetPos(),self.SearchRadius / 4)) do
		if ent:GetClass() == "prop_ragdoll" and ent:GetNoDraw() == false and ent:GetMaterialType() ~= MAT_METAL and !ent.BA2_ZomCorpse then
			local dist = ent:GetPos():DistToSqr(self:GetPos())
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
	self:SetCollisionGroup(COLLISION_GROUP_WORLD)

	if self.BA2_AutoSpawned and self.BA2_CreationTime > CurTime() - 2 then
		self:Remove()
		return
	end

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
	for i = 1,25 do
		self:PursuitSpeed()
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

	self.loco:ClearStuck()
	self:SetCollisionGroup(COLLISION_GROUP_NONE)
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
	local dmgMult = convar_cache["ba2_zom_dmgmult"]:GetFloat()
	local attackMode = convar_cache["ba2_zom_attackmode"]:GetInt()

	if !(self.BA2_LArmDown and self.BA2_RArmDown) then
		self:EmitSound("physics/flesh/flesh_impact_hard"..math.random(1,6)..".wav")
		BA2_ZombieGrab(self,enemy)
	end

	local breakDist = 60
	if self.BA2_LArmDown or self.BA2_RArmDown then
		breakDist = 40
	end

	while self:IsValidEnemy() and self:GetAttacking() do
		coroutine.wait(.5)
		if not self:IsValidEnemy() or not self:GetAttacking() then break end
		if enemy:GetPos():Distance(self:GetPos()) > breakDist then break end
		self.loco:FaceTowards(enemy:GetPos())

		BA2_AddInfection(enemy,math.random(1,7) * convar_cache["ba2_zom_infectionmult"]:GetFloat())

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
	if self:IsValidEnemy() and enemy:GetPos():Distance(self:GetPos()) > breakDist then
		self:EmitSound("physics/body/body_medium_impact_soft"..math.random(1,7)..".wav")
		self:ZombieStun()
	end
end

function ENT:ZombieAttackAlt(ent)
	self.loco:FaceTowards(ent:GetPos())
	self:SetAttacking(true)
	local attackAnims = {
		"nz_attack_stand_ad_2-2",
		"nz_attack_stand_ad_2-3"
	}

	timer.Simple(.28,function()
		if IsValid(self) and not self:GetStunned() and IsValid(ent) then
			local tr = util.TraceHull({
				start = self:EyePos(),
				endpos = self:EyePos() + self:GetForward() * 25,
				maxs = Vector(16,16,16),
				mins = Vector(-16,-16,-16),
				filter = self
			})

			debugoverlay.Box(self:EyePos() + self:GetForward() * 25,Vector(16,16,16),Vector(-16,-16,-16),2)
			if tr.Entity == ent then
				BA2_AddInfection(ent,math.random(1,7) * convar_cache["ba2_zom_infectionmult"]:GetFloat())

				local dmg = DamageInfo()
				dmg:SetDamage(math.random(10,15) * convar_cache["ba2_zom_dmgmult"]:GetFloat())
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
				ent:TakeDamageInfo(dmg)

				if ent:IsPlayer() then
					ent:ViewPunch(AngleRand(-5,5) * 5)
				end

				self:EmitSound("ba2_fleshtear")
			else
				self:EmitSound("npc/zombie/claw_miss1.wav")
			end
		end
	end)

	self:EmitSound("npc/zombie/foot_slide"..math.random(1,3)..".wav")
	if self.BA2_Crippled then
		self:PlaySequenceAndWait("crawlgrabmiss",1.75)
	else
		self:PlaySequenceAndWait(attackAnims[math.random(2)],1.75)
	end

	self:SetAttacking(false)
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
		self:SetPlaybackRate(.5)
	else
		self:ResetSequence("ShoveReact")
	end

	local timerName = self:EntIndex().."-stun"
	timer.Create(timerName,self:SequenceDuration(self:LookupSequence("ShoveReact")),1,function()
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
		if IsValid(self) and not self:GetStunned() and IsValid(ent) then
			local class = ent:GetClass()

			local tr = util.TraceHull({
				start = self:EyePos(),
				endpos = self:EyePos() + self:GetForward() * 75,
				maxs = Vector(8,8,16),
				mins = Vector(-8,-8,-16),
				filter = self
			})

			if tr.Hit or string.StartWith(class,"func_breakable") then
				local propDmg = math.random(10,20) * convar_cache["ba2_zom_propdmgmult"]:GetFloat()
				if self.BA2_LArmDown or self.BA2_RArmDown then
					propDmg = propDmg * 0.5
				end

				if ent:GetClass() == "prop_door_rotating" or ent:GetClass() == "func_door_rotating" then
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

						if ent:GetClass() == "prop_door_rotating" then
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

							if IsValid(ent) then
								ent:SetNoDraw(true)
								ent:SetSolid(SOLID_NONE)
							end

							local doorRespawn = convar_cache["ba2_zom_doorrespawn"]:GetFloat()
							if doorRespawn > 0 then
								timer.Simple(doorRespawn,function()
									if IsValid(ent) then
										ent:SetNoDraw(false)
										ent:SetCollisionGroup(COLLISION_GROUP_NONE)
										ent:SetSolid(SOLID_OBB)
										ent.BA2_DoorHealth = 200
									end

									SafeRemoveEntity(prop)
								end)
							end
						else
							ent:Fire("SetSpeed",(ent:GetInternalVariable("Speed") * 2.5) .. "")
							ent:Fire("Open")
							ent:Fire("SetSpeed",ent:GetInternalVariable("Speed") .. "")
							ent.BA2_DoorHealth = 200
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

					if self.BA2_LArmDown or self.BA2_RArmDown then
						dmg:SetDamage(dmg:GetDamage() * 0.5)
					end
		
					ent:TakeDamageInfo(dmg)
				end
				
				if convar_cache["ba2_zom_breakphys"]:GetBool() and #constraint.GetTable(ent) > 0 then
					constraint.RemoveAll(ent)
					ent:EmitSound("physics/metal/sawblade_stick"..math.random(1,3)..".wav")
				end
				local phys = ent:GetPhysicsObject()
				if IsValid(phys) then
					phys:ApplyForceCenter(self:GetForward() * 5000)
					if convar_cache["ba2_zom_breakphys"]:GetBool() then
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

	if self.BA2_Crippled then
		self:PlaySequenceAndWait("crawlgrabmiss")
	else
		self:PlaySequenceAndWait(attackAnims[math.random(2)])
	end

	self:SetAttacking(false)
end

function ENT:ZombieEat(corpse)
	self:SwitchActivity( ACT_IDLE )

	timer.Simple(.6,function()
		if IsValid(self) and not self:GetStunned() and IsValid(corpse) then
			self:EmitSound("ba2_corpsechomp",75,75,100)

			local mat = corpse:GetMaterialType()
			if mat == MAT_ANTLION or mat == MAT_ALIENFLESH then
				util.Decal("YellowBlood",self:EyePos(),corpse:GetPos(),self)
			elseif mat == MAT_CONCRETE or mat == MAT_FLESH or mat == MAT_BLOODYFLESH then -- You tell me why human corpses have the concrete material
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
	self.HullType = HULL_TINY
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
	self.HullType = HULL_TINY
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
	if self.BA2_ArmoredZom and (trace.HitGroup == HITGROUP_HEAD or trace.HitGroup == HITGROUP_CHEST or trace.HitGroup == HITGROUP_STOMACH) then
		dmginfo:SetDamage(dmginfo:GetDamage() * convar_cache["ba2_zom_armordamagemult"]:GetFloat())

		local eff = EffectData()
		eff:SetOrigin(trace.HitPos)
		util.Effect("StunstickImpact",eff)

		self:EmitSound("physics/metal/metal_sheet_impact_bullet2.wav",80,math.random(90,110))
	end

	local dmgAmount = dmginfo:GetDamage()
	if dmginfo:IsDamageType(DMG_BUCKSHOT) and dmgAmount <= 50 and dmgAmount >= self:Health() then
		dmgAmount = dmgAmount * 5
	end
	if trace.HitGroup == HITGROUP_HEAD then
		dmginfo:SetDamage(dmginfo:GetDamage() * 3)
		dmgAmount = dmgAmount * 3

		if BA2_GetMaggotMode() then
			self:EmitSound("player/crit_hit"..math.random(2,6)..".wav",95)
		end

		if convar_cache["ba2_misc_headshoteff"]:GetBool() and dmgAmount >= math.random(100,180) then
			self.BA2_HeadshotEffect = true
		end
	elseif dmgAmount >= math.random(30,80) then
		if trace.HitGroup == HITGROUP_STOMACH then
			self.BA2_BodyshotEffect = true
		elseif trace.HitGroup == HITGROUP_CHEST then
			self.BA2_ChestshotEffect = true
		end
	end

	if trace.HitGroup == HITGROUP_LEFTARM and self.BA2_LArmDown == nil then
		self.BA2_LArmDamage = self.BA2_LArmDamage + dmginfo:GetDamage()
		if convar_cache["ba2_zom_armdamage"]:GetBool() and self.BA2_LArmDamage >= self:GetMaxHealth() * .75 then
			self:BreakLArm(dmginfo)
		end
		dmginfo:SetDamage(dmginfo:GetDamage() * convar_cache["ba2_zom_limbdamagemult"]:GetFloat() / 3)
	elseif trace.HitGroup == HITGROUP_RIGHTARM and self.BA2_RArmDown == nil then
		self.BA2_RArmDamage = self.BA2_RArmDamage + dmginfo:GetDamage()
		if convar_cache["ba2_zom_armdamage"]:GetBool() and self.BA2_RArmDamage >= self:GetMaxHealth() * .75 then
			self:BreakRArm(dmginfo)
		end
		dmginfo:SetDamage(dmginfo:GetDamage() * convar_cache["ba2_zom_limbdamagemult"]:GetFloat() / 3)
	end

	if trace.HitGroup == HITGROUP_LEFTLEG and self.BA2_LLegDown == nil then
		self.BA2_LLegDamage = self.BA2_LLegDamage + dmginfo:GetDamage()
		if convar_cache["ba2_zom_legdamage"]:GetBool() and self.BA2_LLegDamage >= self:GetMaxHealth() then
			self:BreakLLeg(dmginfo)
		end
		dmginfo:SetDamage(dmginfo:GetDamage() * convar_cache["ba2_zom_limbdamagemult"]:GetFloat() / 3)
	elseif trace.HitGroup == HITGROUP_RIGHTLEG and self.BA2_RLegDown == nil then
		self.BA2_RLegDamage = self.BA2_RLegDamage + dmginfo:GetDamage()
		if convar_cache["ba2_zom_legdamage"]:GetBool() and self.BA2_RLegDamage >= self:GetMaxHealth() then
			self:BreakRLeg(dmginfo)
		end
		dmginfo:SetDamage(dmginfo:GetDamage() * convar_cache["ba2_zom_limbdamagemult"]:GetFloat() / 3)
	end

	if trace.HitGroup ~= HITGROUP_HEAD then
		dmginfo:SetDamage(dmginfo:GetDamage() * convar_cache["ba2_zom_nonheadshotmult"]:GetFloat())
	end
	if convar_cache["ba2_misc_realistic"]:GetBool() and trace.HitGroup == HITGROUP_CHEST and dmgAmount >= self:Health() and dmginfo:GetAmmoType() == 3 then
		self.BA2_PoliticalJoke = true
	end

	if self.BA2_Crippled and self:GetActivity() == ACT_IDLE then
		self:SetSequence("crawlidle")
	end
end

function ENT:OnInjured(dmginfo)
	if dmginfo:IsExplosionDamage() and math.random(1,100) <= dmginfo:GetDamage() then
		if self.BA2_ArmoredZom then
			dmginfo:SetDamage(dmginfo:GetDamage() * convar_cache["ba2_zom_armordamagemult"]:GetFloat())
		end
		if math.random(self:GetMaxHealth()) <= dmginfo:GetDamage() then
			local randNum
			if self:Health() <= dmginfo:GetDamage() then
				randNum = math.random(6)
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
			elseif randNum == 5 then
				self.BA2_HeadshotEffect = true
			else
				self.BA2_BodyshotEffect = true
			end
		end
	end

	if (self:GetAttacking() and bit.bor(dmginfo:GetDamageType(),DMG_SLASH + DMG_CRUSH + DMG_CLUB + DMG_BLAST))
	or (convar_cache["ba2_zom_damagestun"]:GetBool() and dmginfo:GetDamage() > self:Health() / 2) then
		self:ZombieStun()
	end
end

function ENT:OnKilled(dmginfo)
	if not IsValid(self.InfBody) then self:Remove() return end

	hook.Run("BA2_OnZombieKilled", self, dmginfo)
	if engine.ActiveGamemode() == "horde" then
		gamemode.Call("OnNPCKilled",self,dmginfo:GetAttacker(),dmginfo:GetInflictor()) -- Hardcode to fix horde (I trust the players to debug this responsibly (big mistake))
	end

	net.Start("BA2ZomDeathNotice")
	net.WriteEntity(dmginfo:GetAttacker())
	net.WriteEntity(dmginfo:GetInflictor())
	net.Broadcast()
	
	self:ZombieVox("hurt")

	if string.find(self.InfBody:GetModel(),"group03m") and math.random(1,100) <= convar_cache["ba2_zom_medicdropchance"]:GetInt() then
		local vial = ents.Create("item_healthvial")
		vial:SetPos(self:GetPos() + Vector(0,0,40))
		vial:SetVelocity(VectorRand() * 2)
		vial:Spawn()
		vial:Activate()
	elseif self.cheapleEgg and self.InfBody:GetModel() == "models/humans/group01/male_cheaple.mdl" and #ents.FindByClass("ba2_radiobaby") == 0 then
		local vial = ents.Create("ba2_radiobaby")
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


	local function makeGibs(boneName,gibs,forceMult)
		local bone = body:LookupBone(boneName)
		if !bone then return end

		body:EmitSound("ba2_headlessbleed")

		for i,mdl in pairs(gibs) do
			self:CreateGib(body:GetBonePosition(bone),mdl,dmginfo:GetDamageForce():GetNormalized() * 250 * (forceMult or 1))
		end

		local eff = EffectData()
		eff:SetFlags(6)
		eff:SetColor(0)
		eff:SetScale(10)
		eff:SetEntity(body)
		eff:SetAttachment(6)
		
		local timer1 = body:EntIndex().."-headshot1"
		timer.Create(timer1,0.1,math.random(17,20),function()
			if !IsValid(body) then timer.Destroy(timer1) return end
			local headBone = body:LookupBone(boneName)
			if headBone ~= nil then
				eff:SetOrigin(body:GetBonePosition(headBone))
				util.Effect("BloodImpact",eff)
			else
				timer.Destroy(timer1)
			end
		end)

		timer.Start(timer1)
	end

	if self.BA2_HeadshotEffect then
		self:KillSounds()
		self:EmitSound("npc/barnacle/barnacle_crunch"..math.random(2,3)..".wav",85)

		local headBone = body:LookupBone("ValveBiped.Bip01_Head1")
		if headBone ~= nil then
			self:DeflateBones({
				"ValveBiped.Bip01_Head1",
			},body)
			makeGibs("ValveBiped.Bip01_Head1",{
				-- "models/ba2/gibs/eyel.mdl",
				-- "models/ba2/gibs/eyer.mdl",
				"models/ba2/gibs/headbackl.mdl",
				"models/ba2/gibs/headbackr.mdl",
				"models/ba2/gibs/headfrontl.mdl",
				"models/ba2/gibs/headfrontr.mdl",
				"models/ba2/gibs/headtop.mdl",
				"models/ba2/gibs/jaw.mdl"
			})
		end
	end

	if self.BA2_BodyshotEffect then
		self:EmitSound("npc/barnacle/barnacle_crunch"..math.random(2,3)..".wav",85)

		local bodyBone = body:LookupBone("ValveBiped.Bip01_Spine")
		if bodyBone ~= nil then
			makeGibs("ValveBiped.Bip01_Spine",{
				"models/ba2/gibs/organs.mdl",
				"models/ba2/gibs/midorgans.mdl",
				"models/ba2/gibs/headbackl.mdl",
				"models/ba2/gibs/headbackr.mdl",
				"models/ba2/gibs/headfrontl.mdl",
			},-.35)
		end
	end

	if self.BA2_ChestshotEffect then
		self:EmitSound("npc/barnacle/barnacle_crunch"..math.random(2,3)..".wav",85)

		local bodyBone = body:LookupBone("ValveBiped.Bip01_Spine2")
		if bodyBone ~= nil then
			makeGibs("ValveBiped.Bip01_Spine2",{
				"models/ba2/gibs/headbackl.mdl",
				"models/ba2/gibs/headbackr.mdl",
				"models/ba2/gibs/headfrontl.mdl",
				"models/ba2/gibs/headbackl.mdl",
			},-.5)
		end
	end

	if self.BA2_PoliticalJoke then
		self:EmitSound("npc/barnacle/barnacle_crunch"..math.random(2,3)..".wav",85)

		local bodyBone = body:LookupBone("ValveBiped.Bip01_Spine2")
		if bodyBone ~= nil then
			makeGibs("ValveBiped.Bip01_Spine2",{
				"models/ba2/gibs/lungright.mdl"
			},.35)
		end
	end


	local phys = body:GetPhysicsObject()
	if IsValid(phys) then
		phys:ApplyForceCenter(dmginfo:GetDamageForce())
	end
	local corpseLife = convar_cache["ba2_misc_corpselife"]:GetFloat()
	if corpseLife >= 0 then
		body:Fire("FadeAndRemove","0.5",corpseLife)
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
	
	if convar_cache["ba2_misc_addscore"]:GetBool() then
		local att = dmginfo:GetAttacker()
		if IsValid(att) and att:IsPlayer() then
			att:AddFrags(1)
		end
	end

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
	if self.loco:GetVelocity():LengthSqr() < 1 then
		if self:GetActivity() ~= ACT_IDLE then
			self:StartActivity(ACT_IDLE)
		end
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


function ENT:OnContact(ent)
	local class = ent:GetClass()
	local IsVehicle = ent:IsVehicle()

	if IsVehicle or class == "prop_physics" then
		local dmg = DamageInfo()
		dmg:SetDamageType(DMG_BLAST + DMG_CRUSH)
		if IsVehicle then
			dmg:SetDamage(math.max((ent:GetVelocity():Length() - 200) * ent:GetPhysicsObject():GetMass() / 5000,0))
		else
			dmg:SetDamage(math.max((ent:GetVelocity():Length() - 200) * ent:GetPhysicsObject():GetMass() / 100,0))
		end
		--dmg:SetDamageForce(ent:GetVelocity() * ent:GetPhysicsObject():GetMass() * 0.75)
		if IsVehicle then
			if IsValid(ent:GetDriver()) then
				dmg:SetAttacker(ent:GetDriver())
			else
				dmg:SetAttacker(ent)
			end
		else
			dmg:SetAttacker(ent)
			ent:TakeDamage(dmg:GetDamage(),ent,ent)
		end
		dmg:SetInflictor(ent)

		if dmg:GetDamage() > 0 then
			self:TakeDamageInfo(dmg)
		end
	elseif class == "prop_combine_ball" then
		local dmg = DamageInfo()
		dmg:SetDamageType(DMG_DISSOLVE)
		dmg:SetDamage(self:Health())
		self:TakeDamageInfo(dmg)
	-- elseif string.StartWith(class,"nb_ba2_infected") and self.loco:IsStuck() then
	-- 	constraint.NoCollide(self,ent,0,0)
	end
end

-- Error handling
function ENT:GetActiveWeapon()
	return NULL
end

function ENT:Disposition(ent)
	return D_HT
end

function ENT:AddEntityRelationship(t,d,p)
end

-- Credit to GammaWhiskey for going through the trouble of adding these dummy functions
function ENT:AddRelationship(relationstring)

end

function ENT:AlertSound()

end

function ENT:AutoMovement(interval, target)

end

function ENT:CapabilitiesAdd(capabilities)

end

function ENT:CapabilitiesClear()

end

function ENT:CapabilitiesGet()
	return 0
end

function ENT:CapabilitiesRemove(capabilities)

end

function ENT:Classify()
	return 0
end

function ENT:GetNPCState()
	return 0
end

function ENT:SetNPCState(state)

end

function ENT:SetCondition(condition)

end

function ENT:ClearCondition(condition)

end

function ENT:HasCondition(condition)
	return false 
end

-- Hello from the past -Sninctbur

--[[ Animations to delete:
	Ad11
	Ad7
	Ad8
	Au5
]]