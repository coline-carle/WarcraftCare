local SeedReporter = CreateFrame("FRAME", "SeedReporterFrame")

local _DEFAULT_CHAT_FRAME = DEFAULT_CHAT_FRAME
local LOOT_ITEM_SELF_MULTIPLE = _G.LOOT_ITEM_SELF_MULTIPLE:gsub("%%s", "(.+)"):gsub("%%d", "(.+)")
local LOOT_ITEM_SELF = _G.LOOT_ITEM_SELF:gsub("%%s", "(.+)")
local LOOT_ITEM_MULTIPLE = _G.LOOT_ITEM_MULTIPLE:gsub("%%s", "(.+)"):gsub("%%d", "(.+)")
local LOOT_ITEM = _G.LOOT_ITEM:gsub("%%s", "(.+)")

local filtered = {
  [124103] = true,  -- foxflower
  [128304] = true   -- yseraline seed
}

function SeedReporter:Print(msg)
  _DEFAULT_CHAT_FRAME:AddMessage(msg)
end



function SeedReporter:ParseLootMessage(message)
	local player = self.player
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

function SeedReporter:CHAT_MSG_LOOT(message)
  local player, link, quantity = self:ParseLootMessage(message)
  if link == nil or link == "" then
    return nil
  end
  local itemid = self:GetItemID(link)
  if filtered[itemid] then
    loot = { time(), player, itemid, quantity }
    table.insert(self.loots, table.concat(loot, ','))
  end
end

SLASH_SEEDREPORT1 = "/seedreport"
SlashCmdList["SEEDREPORT"] = function(msg)
  local export_text = SeedReporter:Export()
  SeedReporterCopyFrame:Show()
  SeedReporterCopyFrameScroll:Show()
  SeedReporterCopyFrameScrollText:Show()
  SeedReporterCopyFrameScrollText:SetText(export_text)
  SeedReporterCopyFrameScrollText:HighlightText()
end


function SeedReporter:ADDON_LOADED()
    self:UnregisterEvent("ADDON_LOADED")
    self.player = UnitName("player")
    self.loots = {}
    self:RegisterEvent("CHAT_MSG_LOOT")
    self:Print("Seed Reporter Loaded")
end

SeedReporter:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)
SeedReporter:RegisterEvent("ADDON_LOADED")
