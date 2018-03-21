local WarcraftCare = LibStub("AceAddon-3.0"):NewAddon("WarcraftCare", "AceConsole-3.0", "AceEvent-3.0")

-- local libwindow = LibStub("LibWindow-1.1")



local COMBATLOG_XPGAIN_FIRSTPERSON =  _G.COMBATLOG_XPGAIN_FIRSTPERSON
local COMBATLOG_XPGAIN_FIRSTPERSON_UNNAMED = _G.COMBATLOG_XPGAIN_FIRSTPERSON_UNNAMED
local COMBATLOG_XPGAIN_EXHAUSTION1 = _G.COMBATLOG_XPGAIN_EXHAUSTION1
local COMBATLOG_XPGAIN_EXHAUSTION2 = _G.COMBATLOG_XPGAIN_EXHAUSTION2
local COMBATLOG_XPGAIN_EXHAUSTION4 =  _G.COMBATLOG_XPGAIN_EXHAUSTION4
local  COMBATLOG_XPGAIN_EXHAUSTION5 = _G.COMBATLOG_XPGAIN_EXHAUSTION5
local COMBATLOG_XPGAIN_EXHAUSTION1_GROUP = _G.COMBATLOG_XPGAIN_EXHAUSTION1_GROUP
local COMBATLOG_XPGAIN_EXHAUSTION2_GROUP = _G.COMBATLOG_XPGAIN_EXHAUSTION2_GROUP
local COMBATLOG_XPGAIN_EXHAUSTION4_GROUP = _G.COMBATLOG_XPGAIN_EXHAUSTION4_GROUP
local COMBATLOG_XPGAIN_EXHAUSTION5_GROUP = _G.COMBATLOG_XPGAIN_EXHAUSTION5_GROUP
local COMBATLOG_XPGAIN_EXHAUSTION1_RAID = _G.COMBATLOG_XPGAIN_EXHAUSTION1_RAID
local COMBATLOG_XPGAIN_EXHAUSTION2_RAID = _G.COMBATLOG_XPGAIN_EXHAUSTION2_RAID
local COMBATLOG_XPGAIN_EXHAUSTION4_RAID = _G.COMBATLOG_XPGAIN_EXHAUSTION4_RAID
local COMBATLOG_XPGAIN_EXHAUSTION5_RAID = _G.COMBATLOG_XPGAIN_EXHAUSTION5_RAID
local COMBATLOG_XPGAIN_FIRSTPERSON_GROUP = _G.COMBATLOG_XPGAIN_FIRSTPERSON_GROUP
local COMBATLOG_XPGAIN_FIRSTPERSON_RAID = _G.COMBATLOG_XPGAIN_FIRSTPERSON_RAID
local ERR_QUEST_REWARD_EXP_I =  _G.ERR_QUEST_REWARD_EXP_I
local ERR_ZONE_EXPLORED_XP = _G.ERR_ZONE_EXPLORED_XP
local MAX_PLAYER_LEVEL = _G.MAX_PLAYER_LEVEL
local BUCKET_SIZE = 60

local XP_ALTERATIONS = { "bonusExperience", "bonusGroup", "bonusRaid", "raidPenality", "groupPenality"}


local defaultDB = {
  char = {
    ["experienceDB"] = {}
  }
}



local function transformPattern(patterns, global)
  local pattern, replacement
  for _, patternPair in ipairs(patterns) do
    pattern, replacement = unpack(patternPair)
    global = string.gsub(global, pattern, replacement)
  end
  return '^' .. global .. '$'
end

function WarcraftCare:PopulatePatterns()
  local patterns = {
    {'%(', '%%('},
    {'%)', '%%)'},
    {'%.', '%%.'},
    {'%+', '%%+'},
    {'%-', '%%-'},
    {'%%d', '(%%d+)'},
    {'%%s', '(.+)'},
  }

  self.Exp = {
    ["PatternOrder"] = {
      "RaidPenality", "RaidBonus", "GroupBonus", "GroupPenality", "Penality", "Bonus", "NormalGroup",
      "NormalRaid", "Normal", "Unnamed"
    },
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
      ["Bonus"] = {"unit", "experience", "bonusExperience", "bonusName"},
      ["Penality"] =  {"unit", "experience", "bonusExperience", "penalityName"},
      ["GroupBonus"] = {"unit", "experience", "bonusExperience", "bonusName", "groupBonus"},
      ["GroupPenality"] = {"unit", "experience", "bonusExperience", "penalityName", "groupBonus"},
      ["RaidBonus"] =  {"unit", "experience", "bonusExperience", "bonusName", "raidPenality"},
      ["RaidPenality"] ={"unit", "experience", "bonusExperience", "penalityName", "raidPenality"}
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

  pattern = transformPattern(patterns, COMBATLOG_XPGAIN_EXHAUSTION5_RAID)
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
  if type(bonus) == "number" then
    return bonus
  end

  local prefix = string.byte(bonus)

  if prefix == string.byte('-') then
    local numberPart = string.sub(bonus, 2)
    return (- tonumber(numberPart))
  elseif prefix == string.byte('+') then
    local numberPart = string.sub(bonus, 2)
    return tonumber(numberPart)
  end

  return tonumber(bonus)
end

local function increment(entry, key, incrementValue)
  if not(entry[key]) then
    entry[key] = 0
  end
  entry[key] = entry[key] + incrementValue
end

function WarcraftCare:AddToBucket(experienceGain)
  local entryIndex = #self.db.char.experienceDB
  local currentEntry = self.db.char.experienceDB[entryIndex]


  if not(currentEntry) or ( GetTime() - currentEntry.startTime) > BUCKET_SIZE then
    currentEntry = {
      ["startTime"] = GetTime(),
      ["experience"] = 0
    }
    entryIndex  = entryIndex + 1
  end

  currentEntry.experience = currentEntry.experience + experienceGain.experience

  for _, alteration in ipairs(XP_ALTERATIONS) do
    if experienceGain[alteration] then
      local alterationValue = convertBonus(experienceGain[alteration])
      increment(currentEntry, alteration, alterationValue)
    end
  end

  self.db.char.experienceDB[entryIndex] = currentEntry
end

function WarcraftCare:CHAT_MSG_COMBAT_XP_GAIN(_, msg)
  local match, patterns
  for _, name in ipairs(self.Exp.PatternOrder) do
    patterns = self.Exp.Strings[name]
    for _, pattern in ipairs(patterns) do
      match = { string.match(msg, pattern) }
      if #match == #self.Exp.Patterns[name] then
        local entry = {}
        for i, key in ipairs(self.Exp.Patterns[name]) do
          entry[key] = match[i]
          self:Print(key, ": ", match[i])
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
