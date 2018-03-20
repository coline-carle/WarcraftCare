local WarcraftCare = LibStub("AceAddon-3.0"):NewAddon("WarcraftCare", "AceConsole-3.0", "AceEvent-3.0")

-- local libwindow = LibStub("LibWindow-1.1")



local COMBATLOG_XPGAIN_FIRSTPERSON, COMBATLOG_XPGAIN_FIRSTPERSON_UNNAMED = _G.COMBATLOG_XPGAIN_FIRSTPERSON, _G.COMBATLOG_XPGAIN_FIRSTPERSON_UNNAMED
local COMBATLOG_XPGAIN_EXHAUSTION1, COMBATLOG_XPGAIN_EXHAUSTION2, COMBATLOG_XPGAIN_EXHAUSTION4, COMBATLOG_XPGAIN_EXHAUSTION5 = _G.COMBATLOG_XPGAIN_EXHAUSTION1, _G.COMBATLOG_XPGAIN_EXHAUSTION2, _G.COMBATLOG_XPGAIN_EXHAUSTION4, _G.COMBATLOG_XPGAIN_EXHAUSTION5
local COMBATLOG_XPGAIN_EXHAUSTION1_GROUP, COMBATLOG_XPGAIN_EXHAUSTION2_GROUP, COMBATLOG_XPGAIN_EXHAUSTION4_GROUP, COMBATLOG_XPGAIN_EXHAUSTION5_GROUP = _G.COMBATLOG_XPGAIN_EXHAUSTION1_GROUP, _G.COMBATLOG_XPGAIN_EXHAUSTION2_GROUP, _G.COMBATLOG_XPGAIN_EXHAUSTION4_GROUP, _G.COMBATLOG_XPGAIN_EXHAUSTION5_GROUP
local COMBATLOG_XPGAIN_EXHAUSTION1_RAID, COMBATLOG_XPGAIN_EXHAUSTION2_RAID, COMBATLOG_XPGAIN_EXHAUSTION4_RAID, COMBATLOG_XPGAIN_EXHAUSTION5_RAID = _G.COMBATLOG_XPGAIN_EXHAUSTION1_RAID, _G.COMBATLOG_XPGAIN_EXHAUSTION2_RAID, _G.COMBATLOG_XPGAIN_EXHAUSTION4_RAID, _G.COMBATLOG_XPGAIN_EXHAUSTION5_RAID
local COMBATLOG_XPGAIN_FIRSTPERSON_GROUP, COMBATLOG_XPGAIN_FIRSTPERSON_RAID = _G.COMBATLOG_XPGAIN_FIRSTPERSON_GROUP, _G.COMBATLOG_XPGAIN_FIRSTPERSON_RAID
local ERR_QUEST_REWARD_EXP_I =  _G.ERR_QUEST_REWARD_EXP_I
local ERR_ZONE_EXPLORED_XP = _G.ERR_ZONE_EXPLORED_XP
local MAX_PLAYER_LEVEL = _G.MAX_PLAYER_LEVEL
local BUCKET_SIZE = 60


local defaultDB = {
  char = {
    ["experienceDB"] = {}
  }
}



local function transformPattern(patterns, global)
  for pattern, replacement in pairs(patterns) do
    global = string.gsub(global, pattern, replacement)
  end
  return '^' .. global .. '$'
end

function WarcraftCare:PopulatePatterns()
  local patterns = {
    ['%('] = '%%(',
    ['%)'] = '%%)',
    ['%%d'] = '(%%d+)',
    ['%%s'] = '(.+)'
  }

  self.Exp = {
    ["Strings"] = {
      ["Normal"] = {},
      ["NormalGroup"] = {},
      ["NormalRaid"] = {},
      ["Unnamed"] = {},
      ["Bonus"] = {},
      ["Penality"] = {},
      ["GroupBonus"] = {},
      ["GroupPenality"] = {},
      ["RaidBonus"] = {},
      ["RaidPenality"] = {}
    },
    ["Patterns"] = {
      ["Normal"] = { "unit", "experience"},
      ["NormalGroup"] = { "unit", "experience", "groupPenality"},
      ["NormalRaid"] = { "unit", "experience", "raidPenality"},
      ["Unnamed"] = { "experience" },
      ["Bonus"] = {"unit", "experience", "bonusExperience", "bonus"},
      ["Penality"] =  {"unit", "experience", "bonusExperience", "penality"},
      ["GroupBonus"] = {"unit", "experience", "bonusExperience", "bonus", "groupBonus"},
      ["GroupPenality"] = {"unit", "experience", "bonusExperience", "penality", "groupBonus"},
      ["RaidBonus"] =  {"unit", "experience", "bonusExperience", "bonus", "raidPenality"},
      ["RaidPenality"] ={"unit", "experience", "bonusExperience", "penality", "raidPenality"}
    }
  }

  self.otherXPGainPatterns = {}
  local pattern;

  pattern = transformPattern(patterns, COMBATLOG_XPGAIN_FIRSTPERSON)
  table.insert(self.Exp.Strings.Normal, pattern)

  pattern = transformPattern(patterns, COMBATLOG_XPGAIN_FIRSTPERSON_UNNAMED)
  table.insert(self.Exp.Strings.Unnamed, pattern)

  pattern = transformPattern(patterns, COMBATLOG_XPGAIN_FIRSTPERSON_GROUP)
  table.insert(self.Exp.Strings.NormalGroup, pattern)

  pattern = transformPattern(patterns, COMBATLOG_XPGAIN_FIRSTPERSON_RAID)
  table.insert(self.Exp.Strings.NormalRaid, pattern)

  pattern = transformPattern(patterns, COMBATLOG_XPGAIN_EXHAUSTION1)
  table.insert(self.Exp.Strings.Bonus, pattern)

  pattern = transformPattern(patterns, COMBATLOG_XPGAIN_EXHAUSTION2)
  table.insert(self.Exp.Strings.Bonus, pattern)

  pattern = transformPattern(patterns, COMBATLOG_XPGAIN_EXHAUSTION4)
  table.insert(self.Exp.Strings.Penality, pattern)

  pattern = transformPattern(patterns, COMBATLOG_XPGAIN_EXHAUSTION5)
  table.insert(self.Exp.Strings.Penality, pattern)

  pattern = transformPattern(patterns, COMBATLOG_XPGAIN_EXHAUSTION1_GROUP)
  table.insert(self.Exp.Strings.GroupBonus, pattern)

  pattern = transformPattern(patterns, COMBATLOG_XPGAIN_EXHAUSTION2_GROUP)
  table.insert(self.Exp.Strings.GroupBonus, pattern)

  pattern = transformPattern(patterns, COMBATLOG_XPGAIN_EXHAUSTION4_GROUP)
  table.insert(self.Exp.Strings.GroupPenality, pattern)

  pattern = transformPattern(patterns, COMBATLOG_XPGAIN_EXHAUSTION5_GROUP)
  table.insert(self.Exp.Strings.GroupPenality, pattern)

  pattern = transformPattern(patterns, COMBATLOG_XPGAIN_EXHAUSTION1_RAID)
  table.insert(self.Exp.Strings.RaidBonus, pattern)

  pattern = transformPattern(patterns, COMBATLOG_XPGAIN_EXHAUSTION2_RAID)
  table.insert(self.Exp.Strings.RaidBonus, pattern)

  pattern = transformPattern(patterns, COMBATLOG_XPGAIN_EXHAUSTION4_RAID)
  table.insert(self.Exp.Strings.RaidPenality, pattern)

  pattern = transformPattern(patterns, COMBATLOG_XPGAIN_EXHAUSTION5_GROUP)
  table.insert(self.Exp.Strings.RaidPenality, pattern)



  self.exploreXPPattern = transformPattern(patterns, ERR_ZONE_EXPLORED_XP)
  self.questRewardXPPattern  = transformPattern(patterns, ERR_QUEST_REWARD_EXP_I)
end


function WarcraftCare:OnInitialize()
  if UnitLevel("player") == MAX_PLAYER_LEVEL then return end

  self.db = LibStub("AceDB-3.0"):New("WarcraftCareDB", defaultDB)

  self:PopulatePatterns()

  self:RegisterEvent("CHAT_MSG_COMBAT_XP_GAIN")
  self:RegisterEvent("CHAT_MSG_SYSTEM")
end

local function convertBonus(bonus)
  local prefix = string.byte(bonus)
  local numberString = string.sub(bonus, 2)
  local number = tonumber(numberString)
  if prefix == string.byte('-') then
    return (- number)
  end
  return number
end

function WarcraftCare:AddToBucket(experienceGain)
  local entryIndex = #self.db.char.experienceDB
  local lastEntry = self.db.char.experienceDB[entryIndex]

  if not(lastEntry) or ( GetTime() - lastEntry.startTime) > BUCKET_SIZE then
    lastEntry = {
      ["startTime"] = GetTime(),
      ["experience"] = 0,
      ["bonusExperience"] = 0,
      ["partyBonus"] = 0
    }
    entryIndex  = entryIndex + 1
  end

  lastEntry.experience = lastEntry.experience + experienceGain.experience

  if experienceGain.bonusExperience then
    lastEntry.bonusExperience = lastEntry.bonusExperience + convertBonus(experienceGain.bonusExperience)
  end

  if experienceGain.partyBonus then
    lastEntry.partyBonus = convertBonus(experienceGain.partyBonus)
  end

  self.db.char.experienceDB[entryIndex] = lastEntry
end

function WarcraftCare:CHAT_MSG_COMBAT_XP_GAIN(_, msg)
  local match
  for name, patterns in pairs(self.Exp.Strings) do
    for _, pattern in ipairs(patterns) do
      match = { string.match(msg, pattern) }
      if #match == #self.Exp.Patterns[name] then
        local entry = {}
        for i, key in ipairs(self.Exp.Patterns[name]) do
          entry[key] = match[i]
        end
        self:AddToBucket(entry)
        return
      end
    end
  end
end

function WarcraftCare:CHAT_MSG_SYSTEM(_, msg)
  local xp, zone
  xp = string.match(msg, self.questRewardXPPattern)
  if xp then
    self:Print(xp)
  end

  zone, xp = string.match(msg, self.exploreXPPattern)
  if zone then
    self:Print(xp)
  end
end
--
-- function WarcraftCare:PLAYER_XP_UPDATE()
-- end
-- function WarcraftCare:ZONE_CHANGED()
--   self:CheckZone()
-- end
