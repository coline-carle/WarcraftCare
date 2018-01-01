local SeedReporter = CreateFrame("FRAME", "SeedReporterFrame")

local _DEFAULT_CHAT_FRAME = DEFAULT_CHAT_FRAME
local LOOT_ITEM_SELF_MULTIPLE = _G.LOOT_ITEM_SELF_MULTIPLE:gsub("%%s", "(.+)"):gsub("%%d", "(.+)")
local LOOT_ITEM_SELF = _G.LOOT_ITEM_SELF:gsub("%%s", "(.+)")
local LOOT_ITEM_MULTIPLE = _G.LOOT_ITEM_MULTIPLE:gsub("%%s", "(.+)"):gsub("%%d", "(.+)")
local LOOT_ITEM = _G.LOOT_ITEM:gsub("%%s", "(.+)")
local UNKNOWNBEING = _G.UNKNOWNBEING
local UNKNOWNOBJECT = _G.UNKNOWNOBJECT


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
  return table.concat(self.loots, '\n')
end


function SeedReporter:UNIT_SPELLCAST_SUCCEEDED(...)
  local unitId = select(1, ...)
  local lineId = select(4, ...)
  local spellId = select(5, ...)

  local guid = UnitGUID(unitId)

  if not string.find(unitId, "party")  and
     not string.find(unitId, "player") and
     not string.find(unitId, "raid")   or
         string.find(unitId, "pet")    then
    return false
  end

  -- Ignore duplicate player events
  if self.player.guid == guid and unitId ~= "player" then
    return false
  end

  if self.roster[guid] then
    self:Print(unitId)
    self:Print(lineId)
    self:Print(spellId)
    self:Print(guid)
  end
end



function SeedReporter:GetFullname(unit)
  if not UnitExists(unit) then
    return nil
  end
  local name, realm = UnitName(unit)

  if name and name ~= UNKNOWNOBJECT and name ~= UNKNOWNBEING then
    if realm == nil then
      realm = self.realm
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

function SeedReporter:OnRosterUpdate()
  self:Print("OnRosterUpdate")
  local num = GetNumGroupMembers(LE_PARTY_CATEGORY_HOME)
  self:Print(num)

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

  for guid, unit in pairs(self.roster) do
    self:Print(guid)
    self:Print(unit["name"])
  end
end

function SeedReporter:ADDON_LOADED()
  self:Print("SeedReporter Loaded")
  self:UnregisterEvent("ADDON_LOADED")
  self.roster = {}
  self.realm = GetRealmName()
  self:RegisterEvent("GROUP_ROSTER_UPDATE")
  self:RegisterEvent("UNIT_NAME_UPDATE")

end

function SeedReporter:OnEvent(event, ...)
  if event == "ADDON_LOADED" then
    self:ADDON_LOADED(...)
  end

  if event == "GROUP_ROSTER_UPDATE" or
     event == "UNIT_NAME_UPDATE" then
    self:OnRosterUpdate(...)
  end
end


SeedReporter:SetScript("OnEvent", SeedReporter.OnEvent)
SeedReporter:RegisterEvent("ADDON_LOADED")
