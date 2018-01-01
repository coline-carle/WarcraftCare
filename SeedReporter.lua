local SeedReporter = CreateFrame("FRAME", "SeedReporterFrame")

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

SLASH_SEEDREPORT1 = "/seedreport"
SlashCmdList["SEEDREPORT"] = function(msg)
  local export_text = SeedReporter:Export()
  SeedReporterCopyFrame:Show()
  SeedReporterCopyFrameScroll:Show()
  SeedReporterCopyFrameScrollText:Show()
  SeedReporterCopyFrameScrollText:SetText(export_text)
  SeedReporterCopyFrameScrollText:HighlightText()
end

function SeedReporter:Print(msg)
  _DEFAULT_CHAT_FRAME:AddMessage(msg)
end



function SeedReporter:ParseLootMessage(message)
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

function SeedReporter:GetItemID(link)
  local _, _, itemid = string.find(link, "Hitem:(%d+):")
  return tonumber(itemid)
end

function SeedReporter:Export()
  return table.concat(self.logs, '\n')
end


function SeedReporter:UNIT_SPELLCAST_SUCCEEDED(...)
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
    self.castLogged[lineID] = true
    log = { self.roster[guid].name, SEED_ACTION, spellID, 1}
    table.insert(self.logs, table.concat(log, ','))
  end
end


function SeedReporter:CHAT_MSG_LOOT(msg)
  local player, itemLink, quantity  = self:ParseLootMessage(msg)
  local guid = UnitGUID(player)
  if itemLink and guid and self.roster[guid] then
    itemid = self:GetItemID(itemLink)
    if filtered[itemid] then
      log = { self.roster[guid].name, LOOT_ACTION, itemid, quantity}
      table.insert(self.logs, table.concat(log, ','))
    end
  end
end

function SeedReporter:GetFullname(unit)
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

function SeedReporter:UpdateUnit(unit)

  local guid = UnitGUID(unit)

  if guid then
    local name = self:GetFullname(unit)
    if self.units_to_remove[guid] then
       self.units_to_remove[guid] = nil
    end
    if not self.roster[guid] then self.roster[guid] = {} end
    self.roster[guid].name = name
  end
end

function SeedReporter:UpdateRoster()
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

function SeedReporter:CheckZone()
  subzone = GetSubZoneText()

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

function SeedReporter:ADDON_LOADED()
  self:UnregisterEvent("ADDON_LOADED")

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

function SeedReporter:OnEvent(event, ...)
  if event == "ADDON_LOADED" then
    self:ADDON_LOADED(...)
  end

  if event == "GROUP_ROSTER_UPDATE" or
     event == "UNIT_NAME_UPDATE" then
    self:UpdateRoster()
  end

  if IsInRaid() then

    if event == "ZONE_CHANGED" then
      self:CheckZone()
    end

    if event == "CHAT_MSG_LOOT" then
      self:CHAT_MSG_LOOT(...)
    end


    if event == "UNIT_SPELLCAST_SUCCEEDED" then
      self:UNIT_SPELLCAST_SUCCEEDED(...)
    end
  end


end


SeedReporter:SetScript("OnEvent", SeedReporter.OnEvent)
SeedReporter:RegisterEvent("ADDON_LOADED")
