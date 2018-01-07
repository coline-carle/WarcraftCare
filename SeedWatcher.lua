local SeedWatcher = LibStub("AceAddon-3.0"):NewAddon("SeedWatcher", "AceConsole-3.0")

-- local libwindow = LibStub("LibWindow-1.1")

local _DEFAULT_CHAT_FRAME = DEFAULT_CHAT_FRAME
local LOOT_ITEM_SELF_MULTIPLE = _G.LOOT_ITEM_SELF_MULTIPLE:gsub("%%s", "(.+)"):gsub("%%d", "(.+)")
local LOOT_ITEM_SELF = _G.LOOT_ITEM_SELF:gsub("%%s", "(.+)")
local LOOT_ITEM_MULTIPLE = _G.LOOT_ITEM_MULTIPLE:gsub("%%s", "(.+)"):gsub("%%d", "(.+)")
local LOOT_ITEM = _G.LOOT_ITEM:gsub("%%s", "(.+)")
local UNKNOWNBEING = _G.UNKNOWNBEING
local UNKNOWNOBJECT = _G.UNKNOWNOBJECT
local LOOT_ACTION = 1
local SEED_ACTION = 2

local filtered = {
  [124101] = true,  -- aethril
  [124102] = true,  -- dreamleaf
  [124103] = true,  -- foxflower
  [124104] = true,  -- fjarnskaggl
  [124105] = true,  -- starlight rose
  [129284] = true,  -- aethril seed
  [129285] = true,  -- dreamleaf seed
  [129286] = true,  -- foxflower seed
  [129287] = true,  -- fjarnskaggl seed
  [129288] = true,  -- starlight rose seed
  [124124] = true,  -- blood of sargeras
  [128304] = true   -- yseraline seed
}

local planting = {
  [193795] = true, -- Aethril
  [193797] = true, -- Dreamleaf
  [193799] = true, -- Fjarnskaggl
  [193798] = true, -- Foxflower
  [193800] = true  -- Starlight Rose
}

local plantingSubzones = {
  -- Azsuna - Farondale
  ["Farondale"] = true,
  ["Faronau"] = true,
  ["Faroncombe"] = true,
  ["Valfaron"] = true,
  ["파론데일"] = true,
  ["Фарондаль"] = true,
  ["法隆戴尔"] = true,
  ["法隆谷地"] = true
}


function SeedWatcher:ParseLootMessage(message)
	local player = self.player.name
	local itemLink, quantity = message:match(LOOT_ITEM_SELF_MULTIPLE)

	if itemLink and quantity then
		return player, itemLink, tonumber(quantity)
	end
	quantity = 1
	itemLink = message:match(LOOT_ITEM_SELF)

	if itemLink then
		return player, itemLink, tonumber(quantity)
	end

	player, itemLink, quantity = message:match(LOOT_ITEM_MULTIPLE)

	if player and itemLink and quantity then
		return player, itemLink, tonumber(quantity)
	end
	quantity = 1
	player, itemLink = message:match(LOOT_ITEM)

	return player, itemLink, tonumber(quantity)
end

function SeedWatcher:GetItemID(link)
  local _, _, itemid = string.find(link, "Hitem:(%d+):")
  return tonumber(itemid)
end

function SeedWatcher:UNIT_SPELLCAST_SUCCEEDED(...)
  local unit = select(1, ...)
  local lineID = select(4, ...)
  local spellID = select(5, ...)

  local guid = UnitGUID(unit)

  if not string.find(unit, "party")  and
     not string.find(unit, "player") and
     not string.find(unit, "raid")   or
         string.find(unit, "pet")    then
    return false
  end

  -- Ignore duplicate player events
  if self.player.guid == guid and unit ~= "player" then
    return false
  end

  if self.roster[guid] and planting[spellID] and not self.castLogged[lineID] then
    self.unit[guid].castsSucceded[lineID] = true
    self.unit[guid].planted[spellID] = self.unit[guid].planted[spellID] + 1
    self.unit[guid].lastCastSucceded = GetTime()
  end
end

function SeedWatcher:CHAT_MSG_LOOT(msg, _, _, _, target)
  local _, itemLink, quantity  = self:ParseLootMessage(msg)
  local guid = UnitGUID(target)
  if itemLink and guid and self.roster[guid] then
    local itemid = self:GetItemID(itemLink)
    if filtered[itemid] then
      if (GetTime() - self.unit[guid].lastCast) < 2.0 then
        self.roster[guid].loots[itemid] = self.roster[guid].loots[itemid] + quantity
      end
    end
  end
end

function SeedWatcher:GetFullname(unit)
  if not UnitExists(unit) then
    return nil
  end
  local name, realm = UnitName(unit)

  if name and name ~= UNKNOWNOBJECT and name ~= UNKNOWNBEING then
    if realm == nil then
      realm = self.player.realm
    end

    return name .. '-' .. realm
  end
end

function SeedWatcher:InitUnit()
  local unit = {}
  unit['planted'] = {}
  for spellid in pairs(planting) do
    unit.planted[spellid] = 0
  end

  unit['loots'] = {}
  for itemid in pairs(filtered) do
    unit.loots[itemid] = 0
  end

  unit["castsSucceded"] = {}
  unit["lastCastSucceded"] = 0.0
  return unit
end

function SeedWatcher:UpdateUnit(unit)

  local guid = UnitGUID(unit)

  if guid then
    local name = self:GetFullname(unit)
    if self.units_to_remove[guid] then
       self.units_to_remove[guid] = SeedWatcher:InitUnit()
    end
    if not self.roster[guid] then self.roster[guid] = {} end
    self.roster[guid].name = name
  end
end

function SeedWatcher:UpdateRoster()
  local num = GetNumGroupMembers(LE_PARTY_CATEGORY_HOME)

  self.units_to_remove = {}

  for guid, unit in pairs(self.roster) do
    if not unit["active"] then
      self.units_to_remove[guid] = true
    end
  end

  for guid in pairs(self.units_to_remove) do
    self.roster[guid] = nil
    self.units_to_remove[guid] = nil
  end

  for i = 1, num do
    local unit = ("raid%d"):format(i)
    if UnitExists(unit) then
      self:UpdateUnit(unit)
    end
  end
end

function SeedWatcher:CheckZone()
  local subzone = GetSubZoneText()

  if plantingSubzones[subzone] then
      self:RegisterEvent("GROUP_ROSTER_UPDATE")
      self:RegisterEvent("UNIT_NAME_UPDATE")
      self:RegisterEvent("CHAT_MSG_LOOT")
      self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")

      self.inPlantingSubzone = true
      self:UpdateRoster()
    elseif self.inPlantingSubzone then
      -- we are no more in planting subzone unregister event triggers
      self:UnregisterEvent("GROUP_ROSTER_UPDATE")
      self:UnregisterEvent("UNIT_NAME_UPDATE")
      self:UnregisterEvent("CHAT_MSG_LOOT")
      self:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    end
end

function SeedWatcher:OnInitialize()

  self.player = {}
  self.player.name = UnitName("player")
  self.player.realm = GetRealmName()
  self.player.guid = UnitGUID("player")
  self.roster = {}
  self.logs = {}
  self.castLogged = {}
  -- initialize to false but check subzone immediatlly after
  self.inPlantingSubzone = false

  self:CheckZone()
  self:RegisterEvent("ZONE_CHANGED")
end

function SeedWatcher:GROUP_ROSTER_UPDATE()
  self:UpdateRoster()
end

function SeedWatcher:UNIT_NAME_UPDATE()
  self:UpdateRoster()
end

function SeedWatcher:ZONE_CHANGED()
  self:CheckZone()
end
