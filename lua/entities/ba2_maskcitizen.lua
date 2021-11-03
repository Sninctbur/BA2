AddCSLuaFile()

ENT.PrintName = "Masked Citizen"
ENT.Base = "base_entity"
ENT.Type = "anim"

ENT.NPCType = 0

ENT.weps = {"weapon_pistol","weapon_smg1","weapon_shotgun","weapon_ar2"}

if SERVER then

function ENT:SpawnFunction( ply, tr, ClassName )

  if ( !tr.Hit ) then return end
  
  local SpawnPos = tr.HitPos + tr.HitNormal * 10
  local SpawnAng = ply:EyeAngles()
  SpawnAng.p = 0
  SpawnAng.y = SpawnAng.y + 180
  
  local ent = ents.Create( ClassName )
  ent:SetPos( SpawnPos )
  ent:SetAngles( SpawnAng )
  ent:SetCreator(ply)
  ent:Spawn()
  ent:Activate()
  
  return ent
  
end

function ENT:Initialize()
  --self:SetNoDraw(true)
  self:DrawShadow(false) -- as funny as the ERROR silhouette was, it had to go
  
  self.npc = ents.Create("npc_citizen")
  self.npc:SetPos(self:GetPos())
  self.npc:GetAngles(self:GetAngles())

  self.npc:SetKeyValue("squadname","resistance")
  if self.NPCType == 1 then
    self.npc:SetKeyValue("citizentype","3")
  elseif self.NPCType == 2 then
    self.npc:SetKeyValue("citizentype","3")
    self.npc:SetKeyValue("spawnflags","8" + "131072")
  else
    self.npc:SetKeyValue("citizentype",math.random(1,2))
    self.weps = {}
  end
  
  self.npc:Spawn()
  self.npc:Activate()
  self.npc:DropToFloor()
  self.npc:SetCreator(self:GetCreator())
  self.npc.BA2_MaskCitizen = true
  self.npc:SetNWBool("BA2_GasmaskOn",true)
  self:SetNWEntity("BA2_MaskCitizenNPC",self.npc)

  undo.Create("Masked Citizen")
  undo.AddEntity(self.npc)
  undo.SetPlayer(self:GetCreator())
  undo.Finish()
  
  self.wep = GetConVar("gmod_npcweapon"):GetString()
  
  if self.wep == "" then
    self.npc:Fire("GiveWeapon",self.weps[math.random(1,#self.weps)])
  elseif self.wep ~= "none" then
    self.npc:Fire("GiveWeapon",self.wep)
  end

  -- timer.Simple(0,function()
  --   print(self:GetCreator())
  --   if self:GetCreator():IsPlayer() then
  --     hook.Call("PlayerSpawnedNPC",self:GetCreator(),self.npc)
  --   end
  -- end) WHY DOESN'T THIS FUCKING WORK
end

function ENT:Think()
  if self.npc:IsValid() then
    self:SetPos(self.npc:GetPos())
    self:SetAngles(self.npc:GetAngles())
  else
    self:Remove()
  end
end

function ENT:OnRemove()
  if self.npc:IsValid() then
    self.npc:Remove()
  end
end

function ENT:Think()
  if !IsValid(self.npc) then SafeRemoveEntity(self) end
end

end

if CLIENT then

function ENT:Draw()
  local p = self:GetNWEntity("BA2_MaskCitizenNPC")
  if !IsValid(p) then return end
  local head = p:LookupBone("ValveBiped.Bip01_Head1")

  if self.mask then
      SafeRemoveEntity(self.mask)
  end

  self.mask = ClientsideModel("models/barneyhelmet_faceplate.mdl",RENDERGROUP_OPAQUE)
  self.mask:SetColor(Color(72,72,72))
  if self.mask then
      self.mask:DrawShadow(false)
      self.mask:FollowBone(p,head)
      self.mask:SetAngles(p:GetAngles() + Angle(180,90,90))
      self.mask:SetPos(p:GetPos() + self.mask:LocalToWorld(Vector(2.1,0,2.4)))

      SafeRemoveEntityDelayed(self.mask,0)
  end
end
function ENT:Think()
  local p = self:GetNWEntity("BA2_MaskCitizenNPC")
  if IsValid(p) then
    self:SetPos(p:GetPos())
  end
end

end


list.Set( "NPC", "ba2_maskcitizen", {
  Name = "Masked Citizen",
  Class = "ba2_maskcitizen",
  Category = "Bio-Annihilation II"
})