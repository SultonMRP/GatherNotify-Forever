-- GatherNotify for WoW Forever (Classic gather ranks + modern profession APIs).
-- /gn  /gathernotify  /gnotify

local ADDON_NAME = ...

GatherNotify = {}
GatherNotify.Frame = CreateFrame("Frame")

local function Secret(value)
	return issecretvalue ~= nil and issecretvalue(value)
end

local function AddonMeta(field)
	if C_AddOns and C_AddOns.GetAddOnMetadata then
		return C_AddOns.GetAddOnMetadata(ADDON_NAME, field)
	end
end

local function SafeText(fontString)
	if not fontString or not fontString.GetText then
		return nil
	end
	local ok, text = pcall(fontString.GetText, fontString)
	if not ok or type(text) ~= "string" or Secret(text) or text == "" then
		return nil
	end
	return text
end

-- Table format: {level, prettyName, objectName}
-- prettyName nil = tooltip only (no chat unlock line)
-- objectName missing = same as prettyName
GatherNotify.levels = {
	mining = {
		{1,   "Copper", 		"Copper Vein"},
		{65,  "Tin",			"Tin Vein"},
		{65,  nil,				"Incendicite Mineral Vein"},
		{75,  "Silver",			"Silver Vein"},
		{125, "Iron",			"Iron Deposit"},
		{125, nil,				"Cold Iron Deposit"},
		{150, nil,              "Indurium Mineral Vein"},
		{155, nil, 				"Lesser Bloodstone Deposit"},
		{155, "Gold",			"Gold Vein"},
		{175, "Mithril",		"Mithril Deposit"},
		{175, nil,				"Ooze Covered Mithril Deposit"},
		{230, "Truesilver",		"Truesilver Deposit"},
		{230, nil,				"Ooze Covered Truesilver Deposit"},
		{230, "Dark Iron",		"Dark Iron Deposit"},
		{175, nil,				"Fool's Gold Vein"},
		{245, "Small Thorium",	"Small Thorium Vein"},
		{245, nil,				"Ooze Covered Thorium Vein"},
		{245, nil,				"Starsilver Vein"},
		{245, nil,				"Greater Moonstone Formation"},
		{275, "Rich Thorium",	"Rich Thorium Vein"},
		{275, nil,				"Ooze Covered Rich Thorium Vein"},
		{275, nil,				"Hakkari Thorium Vein"},
		{300, nil,				"Heavy Thorium Vein"},
		{305, nil,				"Small Obsidian Chunk"},
		{305, nil,				"Large Obsidian Chunk"},
		{275, "Fel Iron",		"Fel Iron Deposit"},
		{325, "Adamantite",		"Adamantite Deposit"},
		{350, "Rich Adamantite","Rich Adamantite Deposit"},
		{350, "Nethercite",		"Nethercite Deposit"},
		{375, "Khorium",		"Khorium Vein"},
		{350, "Cobalt",			"Cobalt Deposit"},
		{375, "Rich Cobalt",	"Rich Cobalt Deposit"},
		{400, "Saronite",		"Saronite Deposit"},
		{425, "Rich Saronite",	"Rich Saronite Deposit"},
		{450, "Titanium",		"Titanium Vein"},
		{425, "Obsidium",		"Obsidium Deposit"},
		{450, "Rich Obsidium",	"Rich Obsidium Deposit"},
		{475, "Elementium",		"Elementium Vein"},
		{500, "Rich Elementium","Rich Elementium Vein"},
		{525, "Pyrite",			"Pyrite Deposit"},
		{525, "Rich Pyrite",	"Rich Pyrite Deposit"},
		{500, "Ghost Iron",		"Ghost Iron Deposit"},
		{550, "Rich Ghost Iron","Rich Ghost Iron Deposit"},
		{550, "Kyparite",		"Kyparite Deposit"},
		{575, "Rich Kyparite",	"Rich Kyparite Deposit"},
		{600, "Trillium",		"Trillium Vein"},
		{600, "Rich Trillium",	"Rich Trillium Vein"},
	},

	herbalism = {
		{1,   "Peacebloom"},
		{1,   nil,				"Wilted Peacebloom"},
		{1,   "Silverleaf"},
		{1,   nil,				"Stunted Silverleaf"},
		{15,  "Earthroot"},
		{50,  "Mageroyal"},
		{70,  "Briarthorn"},
		{85,  "Stranglekelp"},
		{100, "Bruiseweed"},
		{115, "Wild Steelbloom"},
		{120, "Grave Moss"},
		{125, "Kingsblood"},
		{125, nil,				"Nightmare Moss"},
		{150, "Liferoot"},
		{160, "Fadeleaf"},
		{170, "Goldthorn"},
		{185, "Khadgar's Whisker"},
		{195, "Wintersbite"},
		{205, "Firebloom"},
		{205, nil,				"Dreamroot"},
		{210, "Purple Lotus"},
		{220, "Arthas' Tears"},
		{230, "Sungrass"},
		{235, "Blindweed"},
		{245, "Ghost Mushroom"},
		{250, "Gromsblood"},
		{250, nil,				"Moonroot"},
		{250, nil,				"Star Lotus"},
		{260, "Golden Sansam"},
		{270, "Dreamfoil"},
		{280, "Mountain Silversage"},
		{285, "Plaguebloom"},
		{290, "Icecap"},
		{300, "Black Lotus"},
		{300, "Felweed"},
		{315, "Dreaming Glory"},
		{325, "Ragveil"},
		{325, "Terocone"},
		{335, "Flame Cap"},
		{340, "Ancient Lichen"},
		{350, "Netherbloom"},
		{350, "Netherdust"},
		{365, "Nightmare Vine"},
		{375, "Mana Thistle"},
		{350, "Goldclover"},
		{360, "Talandra's Rose"},
		{365, "Tiger Lily"},
		{375, "Frozen Herb"},
		{385, "Adder's Tongue"},
		{400, "Lichbloom"},
		{400, "Icethorn"},
		{425, "Frost Lotus"},
		{425, "Cinderbloom"},
		{425, "Stormvine"},
		{425, "Azshara's Veil"},
		{475, "Heartblossom"},
		{500, "Whiptail"},
		{525, "Twilight Jasmine"},
		{500, "Green Tea Leaf"},
		{525, "Silkweed"},
		{525, "Rain Poppy"},
		{545, "Snow Lily"},
		{550, "Fool's Cap"},
		{550, "Golden Lotus"},
	},
}

local NODE_REQ = {}
local NODE_MATCH = {}

local function StripTooltipCodes(text)
	return (text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|T.-|t", ""))
end

local function IndexGatherNodes()
	wipe(NODE_REQ)
	wipe(NODE_MATCH)
	for skill, list in pairs(GatherNotify.levels) do
		if skill == "mining" or skill == "herbalism" then
			for _, v in ipairs(list) do
				local object = v[3] or v[2]
				if type(object) == "string" and object ~= "" then
					local key = object:lower()
					NODE_REQ[key] = { skill = skill, req = v[1], label = object }
					NODE_MATCH[#NODE_MATCH + 1] = key
				end
			end
		end
	end
	local aliases = {
		["thorium vein"] = "small thorium vein",
		["ooze covered silver vein"] = "silver vein",
		["ooze covered gold vein"] = "gold vein",
	}
	for alias, target in pairs(aliases) do
		if NODE_REQ[target] and not NODE_REQ[alias] then
			NODE_REQ[alias] = NODE_REQ[target]
			NODE_MATCH[#NODE_MATCH + 1] = alias
		end
	end
	table.sort(NODE_MATCH, function(a, b)
		return #a > #b
	end)
end

IndexGatherNodes()

local function WordMatch(haystack, needle, at)
	local before = at == 1 or not haystack:sub(at - 1, at - 1):find("%a")
	local afterAt = at + #needle
	local after = afterAt > #haystack or not haystack:sub(afterAt, afterAt):find("%a")
	return before and after
end

local function MatchNodes(title)
	title = strlower(strtrim(StripTooltipCodes(title)))
	if title == "" then
		return
	end
	local found, seen = {}, {}
	for _, needle in ipairs(NODE_MATCH) do
		local at = 1
		while true do
			local i = title:find(needle, at, true)
			if not i then
				break
			end
			if WordMatch(title, needle, i) then
				local info = NODE_REQ[needle]
				local id = info.skill .. ":" .. info.req .. ":" .. info.label
				if not seen[id] then
					seen[id] = true
					found[#found + 1] = info
				end
				break
			end
			at = i + 1
		end
	end
	if #found > 0 then
		return found
	end
end

local function NodesFromTitle(title)
	if type(title) ~= "string" or Secret(title) or title == "" then
		return
	end
	return MatchNodes(title)
end

local SKILL_LINE = {
	mining = 186,
	herbalism = 182,
	skinning = 393,
}

local SKILL_ALIAS = {
	mining = { mining = true },
	herbalism = { herbalism = true, ["herb gathering"] = true },
	skinning = { skinning = true },
}

local function CanonicalSkill(name)
	if type(name) ~= "string" or Secret(name) then
		return nil
	end
	local lower = name:lower()
	for key, aliases in pairs(SKILL_ALIAS) do
		if aliases[lower] then
			return key
		end
	end
end

local function SkinningRequired(mobLevel)
	mobLevel = tonumber(mobLevel)
	if not mobLevel or mobLevel < 1 then
		return nil
	end
	if mobLevel <= 10 then
		return 1
	end
	if mobLevel <= 20 then
		return (mobLevel - 10) * 10
	end
	return 100 + (mobLevel - 20) * 5
end

local lastRank = {}
local tipState = setmetatable({}, { __mode = "k" })

local function State(tooltip)
	local s = tipState[tooltip]
	if not s then
		s = {}
		tipState[tooltip] = s
	end
	return s
end

--- Events ---

function GatherNotify.OnEvent(self, event, ...)
	if event == "ADDON_LOADED" then
		local addon_name = ...
		if addon_name == ADDON_NAME then
			GatherNotify.InstallHooks()
			GatherNotify.SnapshotRanks()
		end
	elseif event == "SKILL_LINES_CHANGED" or event == "TRADE_SKILL_LIST_UPDATE" then
		GatherNotify.CheckSkillUps()
	elseif event == "CHAT_MSG_SKILL" then
		local msg = ...
		if type(msg) == "string" and not Secret(msg) then
			if C_Timer and C_Timer.After then
				C_Timer.After(0.1, function()
					GatherNotify.OnSkillUpMessage(msg)
				end)
			else
				GatherNotify.OnSkillUpMessage(msg)
			end
		end
		GatherNotify.CheckSkillUps()
	elseif event == "PLAYER_ENTERING_WORLD" then
		GatherNotify.SnapshotRanks()
	elseif event == "UI_ERROR_MESSAGE" then
		local a, b = ...
		local err, errtype = b, a
		if type(a) == "string" and type(b) ~= "string" then
			err, errtype = a, b
		end
		pcall(GatherNotify.HandleUIError, errtype, err)
	end
end

function GatherNotify.OnCommand(cmd)
	cmd = tostring(cmd or ""):lower()

	if #cmd > 0 then
		for i = 0, 8 do
			if cmd == string.sub("skinning", 1, -i - 1) then
				GatherNotify.PrintHighestNode("skinning")
				return
			elseif cmd == string.sub("mining", 1, -i - 1) then
				GatherNotify.PrintHighestNode("mining")
				return
			elseif cmd == string.sub("herbalism", 1, -i - 1) then
				GatherNotify.PrintHighestNode("herbalism")
				return
			elseif cmd == string.sub("version", 1, -i - 1) then
				GatherNotify.Msg(format("GatherNotify version: |cff1aff1a%s|cffFFC300 (%s)", AddonMeta("Version") or "?", AddonMeta("X-Date") or "?"), true)
				return
			end
		end
	end

	GatherNotify.Msg("/gn skinning - Print highest level creature you can skin", true)
	GatherNotify.Msg("/gn mining - Print highest node you can mine", true)
	GatherNotify.Msg("/gn herbalism - Print highest herb you can pick", true)
	GatherNotify.Msg("/gn version - Prints addon version", true)
end

function GatherNotify.HandleUIError(errtype, err)
	if type(err) ~= "string" or Secret(err) then
		return false
	end
	local skill = strmatch(err, "Requires (%a[%a%s]*?)%s+%d")
	local rlevel = tonumber(strmatch(err, "Requires .- (%d+)"))
	if not skill or not rlevel then
		return false
	end
	local canon = CanonicalSkill(skill) or skill
	local level, temp = GatherNotify.GetProfessionLevel(canon)
	if not level then
		return false
	end
	GatherNotify.AddError(skill, rlevel, level, temp or 0)
	return true
end

function GatherNotify.OnSkillUpMessage(msg)
	if type(msg) ~= "string" or Secret(msg) then
		return
	end
	local skill = strmatch(msg, "Your skill in ([%a%s]+) has increased to")
		or strmatch(msg, "You have gained %d+ skill in ([%a%s]+)")
	if not skill then
		return
	end
	skill = strtrim(skill)
	local canon = CanonicalSkill(skill)
	if not canon then
		return
	end
	local pretty = canon:gsub("^%l", string.upper)
	local level, temp = GatherNotify.GetProfessionLevel(canon)
	if not level then
		return
	end
	GatherNotify.AnnounceUnlocks(pretty, level, temp or 0)
end

function GatherNotify.SnapshotRanks()
	for _, skill in ipairs({ "Mining", "Herbalism", "Skinning" }) do
		local level = GatherNotify.GetProfessionLevel(skill)
		if level then
			lastRank[skill] = level
		end
	end
end

function GatherNotify.CheckSkillUps()
	for _, skill in ipairs({ "Mining", "Herbalism", "Skinning" }) do
		local level, temp = GatherNotify.GetProfessionLevel(skill)
		local prev = lastRank[skill]
		if level and prev and level > prev then
			GatherNotify.AnnounceUnlocks(skill, level, temp or 0)
		end
		if level then
			lastRank[skill] = level
		end
	end
end

function GatherNotify.AnnounceUnlocks(skill, level, temp)
	temp = temp or 0
	local new = GatherNotify.GetAllGatherable(skill, level)
	if new then
		local tempmsg = ""
		if temp > 0 then
			tempmsg = " (without current |cff1aff1a+" .. temp .. "|cffFFC300 bonus)"
		end
		if skill == "Skinning" then
			GatherNotify.Msg("Now able to skin level " .. new .. " creatures" .. tempmsg, false)
		elseif skill == "Mining" then
			GatherNotify.Msg("Now able to mine " .. new .. tempmsg, false)
		elseif skill == "Herbalism" then
			GatherNotify.Msg("Now able to pick " .. new .. tempmsg, false)
		end
	end

	local newtemp = GatherNotify.GetAllGatherable(skill, level + temp)
	if newtemp and newtemp ~= new then
		local tempmsg = ""
		if temp > 0 then
			tempmsg = " (with current |cff1aff1a+" .. temp .. "|cffFFC300 bonus)"
		end
		if skill == "Skinning" then
			GatherNotify.Msg("Now able to skin level " .. newtemp .. " creatures" .. tempmsg, false)
		elseif skill == "Mining" then
			GatherNotify.Msg("Now able to mine " .. newtemp .. tempmsg, false)
		elseif skill == "Herbalism" then
			GatherNotify.Msg("Now able to pick " .. newtemp .. tempmsg, false)
		end
	end
end

--- Functions ---

function GatherNotify.Msg(msg, printname, color)
	if not color then
		color = "FFC300"
	end
	if printname then
		DEFAULT_CHAT_FRAME:AddMessage("|cffd2b48c[GatherNotify]|r |cff" .. color .. msg)
	else
		DEFAULT_CHAT_FRAME:AddMessage("|cff" .. color .. msg)
	end
end

function GatherNotify.GetChatColor(chattype)
	local chatinfo = ChatTypeInfo[chattype]
	if not chatinfo then
		return "ffffff"
	end
	return format("%02x%02x%02x", chatinfo.r * 255, chatinfo.g * 255, chatinfo.b * 255)
end

function GatherNotify.AddError(skill, rlevel, current, temp)
	if temp == 0 then
		UIErrorsFrame:AddMessage(string.format("Requires %s %s (currently %s)", skill, rlevel, current), 1.0, 0.1, 0.1, 1.0)
	else
		UIErrorsFrame:AddMessage(string.format("Requires %s %s (currently %s|cff1aff1a+%s|r)", skill, rlevel, current, temp), 1.0, 0.1, 0.1, 1.0)
	end
end

function GatherNotify.GetHighestNode(skill, level)
	skill = skill:lower()
	if skill == "skinning" then
		local highest = 1
		for mob = 1, 120 do
			local req = SkinningRequired(mob)
			if req and req <= level then
				highest = mob
			end
		end
		return tostring(highest)
	end
	if skill ~= "herbalism" and skill ~= "mining" then
		return
	end

	local highest = 1
	for _, v in pairs(GatherNotify.levels[skill]) do
		if v[1] <= level and v[2] then
			highest = v[1]
		end
	end
	return GatherNotify.GetAllGatherable(skill, highest)
end

function GatherNotify.PrintHighestNode(skill)
	local level, temp = GatherNotify.GetProfessionLevel(skill)
	temp = temp or 0

	if level then
		local tempmsg = ""
		if temp > 0 and GatherNotify.GetHighestNode(skill, level + temp) ~= GatherNotify.GetHighestNode(skill, level) then
			tempmsg = " (without current |cff1aff1a+" .. temp .. "|cffFFC300 bonus)"
		end

		if skill == "skinning" then
			GatherNotify.Msg("Skinning " .. level .. ": level " .. GatherNotify.GetHighestNode("skinning", level) .. " creatures" .. tempmsg, true)
		end
		if skill == "mining" then
			GatherNotify.Msg("Mining " .. level .. ": " .. (GatherNotify.GetHighestNode("mining", level) or "?") .. tempmsg, true)
		end
		if skill == "herbalism" then
			GatherNotify.Msg("Herbalism " .. level .. ": " .. (GatherNotify.GetHighestNode("herbalism", level) or "?") .. tempmsg, true)
		end

		if GatherNotify.GetHighestNode(skill, level + temp) ~= GatherNotify.GetHighestNode(skill, level) then
			tempmsg = ""
			if temp > 0 then
				tempmsg = " (with current |cff1aff1a+" .. temp .. "|cffFFC300 bonus)"
			end
			if skill == "skinning" then
				GatherNotify.Msg("Skinning |cff1aff1a" .. (level + temp) .. "|cffFFC300: level " .. GatherNotify.GetHighestNode("skinning", level + temp) .. " creatures" .. tempmsg, true)
			end
			if skill == "mining" then
				GatherNotify.Msg("Mining |cff1aff1a" .. (level + temp) .. "|cffFFC300: " .. (GatherNotify.GetHighestNode("mining", level + temp) or "?") .. tempmsg, true)
			end
			if skill == "herbalism" then
				GatherNotify.Msg("Herbalism |cff1aff1a" .. (level + temp) .. "|cffFFC300: " .. (GatherNotify.GetHighestNode("herbalism", level + temp) or "?") .. tempmsg, true)
			end
		end
	else
		GatherNotify.Msg("You don't have " .. skill, true)
	end
end

function GatherNotify.GetAllGatherable(skill, level)
	skill = skill:lower()
	if skill == "skinning" then
		local highest = GatherNotify.GetHighestNode("skinning", level)
		if highest then
			return highest
		end
		return nil
	end
	if skill ~= "herbalism" and skill ~= "mining" then
		return
	end

	local ret = {}
	for _, v in pairs(GatherNotify.levels[skill]) do
		if v[1] == level and v[2] then
			ret[#ret + 1] = v[2]
		end
	end
	if #ret == 0 then
		return nil
	end
	return table.concat(ret, ", ")
end

function GatherNotify.GetRequiredLevel(skill, name)
	skill = skill:lower()
	if skill == "skinning" then
		return SkinningRequired(name)
	end
	if skill ~= "herbalism" and skill ~= "mining" then
		return
	end
	local nodes = NodesFromTitle(name)
	if nodes then
		for _, info in ipairs(nodes) do
			if info.skill == skill then
				return info.req
			end
		end
	end
	name = strlower(tostring(name or ""))
	local found
	for _, v in pairs(GatherNotify.levels[skill]) do
		local object = v[3] or v[2]
		if type(object) == "string" and object:lower() == name then
			found = v[1]
		end
	end
	return found
end

function GatherNotify.GetProfessionLevel(name)
	local canon = CanonicalSkill(name) or (type(name) == "string" and name:lower())
	if not canon then
		return
	end
	local wantLine = SKILL_LINE[canon]

	if type(GetProfessions) == "function" and type(GetProfessionInfo) == "function" then
		local p1, p2, archaeology, fishing, cooking, firstAid = GetProfessions()
		for _, index in ipairs({ p1, p2, archaeology, fishing, cooking, firstAid }) do
			if index then
				local ok, profName, _, skill, _, _, _, skillLine, bonus = pcall(GetProfessionInfo, index)
				if ok and not Secret(profName) then
					local matchName = type(profName) == "string" and CanonicalSkill(profName) == canon
					local matchLine = wantLine and skillLine == wantLine
					if matchName or matchLine then
						return tonumber(skill) or 0, tonumber(bonus) or 0
					end
				end
			end
		end
	end

	if C_TradeSkillUI and C_TradeSkillUI.GetProfessionInfoBySkillLineID and wantLine then
		local ok, info = pcall(C_TradeSkillUI.GetProfessionInfoBySkillLineID, wantLine)
		if ok and type(info) == "table" then
			local skill = tonumber(info.skillLevel)
			local bonus = tonumber(info.skillModifier) or 0
			if skill and skill > 0 then
				return skill, bonus
			end
		end
	end

	if type(GetNumSkillLines) == "function" and type(GetSkillLineInfo) == "function" then
		local n = GetNumSkillLines() or 0
		for i = 1, n do
			local ok, skillname, isHeader, _, skillrank, _, skillmodifier = pcall(GetSkillLineInfo, i)
			if ok and not isHeader and type(skillname) == "string" and not Secret(skillname) then
				if CanonicalSkill(skillname) == canon then
					return tonumber(skillrank) or 0, tonumber(skillmodifier) or 0
				end
			end
		end
	end
end

local function Surface(tbl)
	if type(tbl) == "table" and TooltipUtil and TooltipUtil.SurfaceArgs then
		pcall(TooltipUtil.SurfaceArgs, tbl)
	end
end

local function LeftFontString(tooltip, i)
	if tooltip.GetLeftLine then
		local ok, fs = pcall(tooltip.GetLeftLine, tooltip, i)
		if ok and fs then
			return fs
		end
	end
	local name = tooltip.GetName and tooltip:GetName()
	return name and _G[name .. "TextLeft" .. i]
end

local function RestoreWrap(tooltip)
	local n = tooltip.NumLines and tooltip:NumLines() or 0
	for i = 1, n do
		local fs = LeftFontString(tooltip, i)
		if fs then
			fs:SetWordWrap(true)
			if fs.SetNonSpaceWrap then
				fs:SetNonSpaceWrap(true)
			end
			if fs.SetMaxLines then
				fs:SetMaxLines(8)
			end
		end
	end
end

local function TooltipLine(tooltip, i)
	return SafeText(LeftFontString(tooltip, i))
end

local function LineLeftText(line)
	if type(line) ~= "table" or Secret(line) then
		return
	end
	Surface(line)
	for _, key in ipairs({ "leftText", "text", "left" }) do
		local ok, text = pcall(function()
			return line[key]
		end)
		if ok and type(text) == "string" and not Secret(text) and text ~= "" then
			return StripTooltipCodes(text)
		end
	end
end

local function TitleFromData(data)
	if type(data) ~= "table" or Secret(data) then
		return
	end
	Surface(data)
	local ok, lines = pcall(function()
		return data.lines
	end)
	if not ok or type(lines) ~= "table" or Secret(lines) then
		return
	end
	Surface(lines)
	for i = 1, 8 do
		local okLine, line = pcall(function()
			return lines[i]
		end)
		if okLine then
			local text = LineLeftText(line)
			if text then
				return text
			end
		end
	end
end

local function DataTypeOf(data)
	if type(data) ~= "table" then
		return
	end
	local ok, value = pcall(function()
		return data.type
	end)
	if ok then
		return value
	end
end

local function IsMinimapDataType(dataType)
	local types = Enum and Enum.TooltipDataType
	if not types or not dataType then
		return false
	end
	return dataType == types.MinimapMouseover or dataType == types.Minimap
end

local function PlainLine(text)
	return strlower(strtrim(StripTooltipCodes(text)))
end

local function MapIconNodeName(tooltip)
	if not tooltip or not tooltip.ShownAsMapIcon then
		return
	end
	local owner = tooltip._owner
	if type(owner) ~= "table" or type(owner.data) ~= "table" then
		if tooltip.GetOwner then
			local ok, value = pcall(tooltip.GetOwner, tooltip)
			if ok then
				owner = value
			end
		end
	end
	local name = type(owner) == "table" and owner.data and owner.data.Name
	if type(name) == "string" and not Secret(name) then
		return name
	end
end

local function ProfessionLabel(skill)
	if skill == "mining" then
		return "Mining"
	end
	if skill == "herbalism" then
		return "Herbalism"
	end
	if skill == "skinning" then
		return "Skinning"
	end
end

local function HasRequireLine(tooltip, skill, req)
	local label = ProfessionLabel(skill)
	if not label then
		return false
	end
	local n = tooltip.NumLines and tooltip:NumLines() or 0
	for i = 1, n do
		local text = TooltipLine(tooltip, i)
		if text and text:find(label, 1, true) and text:find(tostring(req), 1, true) then
			return true
		end
	end
	return false
end

local function HexColor(color)
	if type(color) == "table" then
		local r = color.r or color[1] or 1
		local g = color.g or color[2] or 1
		local b = color.b or color[3] or 1
		return format("%02x%02x%02x", r * 255, g * 255, b * 255), r, g, b
	end
	return "ffffd100", 1, 0.82, 0
end

local function SkillBandColor(skillname, req)
	local skill, tempboost = GatherNotify.GetProfessionLevel(skillname)
	tempboost = tempboost or 0
	if not skill then
		return HexColor(NORMAL_FONT_COLOR)
	end
	if skill + tempboost < req then
		return HexColor(RED_FONT_COLOR or { 1, 0.1, 0.1 })
	end
	local over = skill - (req > 1 and req or 0)
	if over < 25 then
		return HexColor(DIFFICULT_DIFFICULTY_COLOR or { 1, 0.5, 0.25 })
	end
	if over < 50 then
		return HexColor(FAIR_DIFFICULTY_COLOR or { 1, 1, 0 })
	end
	if over < 100 then
		return HexColor(EASY_DIFFICULTY_COLOR or { 0.25, 0.75, 0.25 })
	end
	return HexColor(TRIVIAL_DIFFICULTY_COLOR or { 0.5, 0.5, 0.5 })
end

local function RequireText(skillname, req)
	local newstr = "Requires " .. skillname .. " " .. req
	local skill, tempboost = GatherNotify.GetProfessionLevel(skillname)
	tempboost = tempboost or 0
	local tooLow = skill and req > skill + tempboost
	if tooLow then
		if tempboost > 0 then
			newstr = newstr .. format(" (currently %s|cff1aff1a+%s|r)", skill, tempboost)
		else
			newstr = newstr .. " (currently " .. skill .. ")"
		end
	end
	local hex, r, g, b = SkillBandColor(skillname, req)
	return "|cff" .. hex .. newstr .. "|r", tooLow, r, g, b
end

local function GetKit()
	if LibStub then
		local ok, lib = pcall(LibStub.GetLibrary, LibStub, "TooltipKit-1.0", true)
		if ok and lib then
			return lib
		end
	end
	return TooltipKit
end

local function IsItemDataType(dataType)
	local types = Enum and Enum.TooltipDataType
	return types and dataType == types.Item
end

-- Bag herbs share a name with world nodes. A link, a secret item link, or an item
-- data type means this tip is the item, not the node.
local function IsOwnedItemTip(tooltip, data)
	local kit = GetKit()
	if kit then
		return kit:IsItem(tooltip, data) or kit:IsSpell(tooltip, data) or kit:IsAura(tooltip, data)
	end
	local types = Enum and Enum.TooltipDataType
	local dataType = DataTypeOf(data)
	if types and dataType and (dataType == types.Item or dataType == types.Spell or dataType == types.UnitAura) then
		return true
	end
	if tooltip and tooltip.GetItem then
		local ok, _, link = pcall(tooltip.GetItem, tooltip)
		if ok and (Secret(link) or (type(link) == "string" and link:find("item:", 1, true))) then
			return true
		end
	end
end

local function ProfessionFromLine(plain)
	if plain == "mining" or plain == "requires mining" then
		return "Mining"
	end
	if plain == "herbalism" or plain == "requires herbalism" or plain == "herb gathering" or plain == "requires herb gathering" then
		return "Herbalism"
	end
	if plain == "skinnable" or plain == "requires skinning" then
		return "Skinning"
	end
end

local function CollectNodeNames(tooltip, title)
	local names = NodesFromTitle(title)
	if names then
		return names
	end
	names = NodesFromTitle(MapIconNodeName(tooltip))
	if names then
		return names
	end
	local n = tooltip.NumLines and tooltip:NumLines() or 0
	for i = 1, n do
		names = NodesFromTitle(TooltipLine(tooltip, i))
		if names then
			return names
		end
	end
end

local function ApplyTooltip(tooltip, data, opts, s)
	local hasLines
	if type(data) == "table" then
		Surface(data)
		local okLines, lines = pcall(function()
			return data.lines
		end)
		hasLines = okLines and type(lines) == "table"
	end
	if not hasLines and tooltip.GetPrimaryTooltipData then
		local ok, primary = pcall(tooltip.GetPrimaryTooltipData, tooltip)
		if ok and type(primary) == "table" then
			data = data or primary
		end
	end
	local dataType = DataTypeOf(data)
	if IsMinimapDataType(dataType) then
		return
	end
	-- Item/spell/aura tips belong to Auctionworthy / ToolTip IDs / PetTraining. Do not scan them.
	if IsOwnedItemTip(tooltip, data) then
		return
	end

	local title = TitleFromData(data) or TooltipLine(tooltip, 1) or s.line1Hint or MapIconNodeName(tooltip)

	local skillname, objname, linenum
	local n = tooltip.NumLines and tooltip:NumLines() or 0
	for i = 1, n do
		local text = TooltipLine(tooltip, i)
		if text then
			local prof = ProfessionFromLine(PlainLine(text))
			if prof then
				skillname = prof
				objname = title
				linenum = i
				if prof == "Skinning" and UnitExists and UnitExists("mouseover") and UnitLevel then
					objname = UnitLevel("mouseover")
				end
				break
			end
		end
	end

	local rewritten
	if skillname then
		local req = GatherNotify.GetRequiredLevel(skillname, objname)
		if req then
			local line = LeftFontString(tooltip, linenum)
			local current = SafeText(line)
			if current and not (current:find("%d") and current:find(tostring(req), 1, true)) then
				local text, _, r, g, b = RequireText(skillname, req)
				pcall(line.SetText, line, text)
				pcall(line.SetTextColor, line, r, g, b)
				rewritten = true
			end
		end
	end

	local added
	local names = CollectNodeNames(tooltip, title)
	-- OnShow and the follow-up timer may recolor a line already on the tip.
	-- Adding a line there draws it outside the backdrop.
	if names and not IsItemDataType(dataType) and not (opts and opts.rewriteOnly) then
		s.busy = true
		for _, info in ipairs(names) do
			if not HasRequireLine(tooltip, info.skill, info.req) then
				local label = ProfessionLabel(info.skill)
				local text, _, r, g, b = RequireText(label, info.req)
				pcall(tooltip.AddLine, tooltip, text, r, g, b, true)
				local last = tooltip.NumLines and tooltip:NumLines()
				local fs = last and LeftFontString(tooltip, last)
				if fs and fs.SetTextColor then
					pcall(fs.SetTextColor, fs, r, g, b)
				end
				added = true
			end
		end
		s.busy = nil
	end

	if rewritten or added then
		RestoreWrap(tooltip)
	end
	-- Never GameTooltip:Show() from this path. Blizzard/CurseForge already Show after post-calls.
end

function GatherNotify.ModifyTooltip(tooltip, data, opts)
	tooltip = tooltip or GameTooltip
	opts = opts or {}
	if tooltip ~= GameTooltip then
		return
	end
	if not tooltip or (tooltip.IsForbidden and tooltip:IsForbidden()) then
		return
	end
	local s = State(tooltip)
	if s.busy or s.inModify then
		return
	end
	s.inModify = true
	pcall(ApplyTooltip, tooltip, data, opts, s)
	s.busy = nil
	s.inModify = nil
end

function GatherNotify.InstallHooks()
	if GatherNotify.hooked then
		return
	end
	GatherNotify.hooked = true

	GameTooltip:HookScript("OnShow", function(self)
		GatherNotify.ModifyTooltip(self, nil, { skipShow = true, rewriteOnly = true })
		if C_Timer and C_Timer.After then
			C_Timer.After(0, function()
				if self:IsShown() then
					GatherNotify.ModifyTooltip(self, nil, { skipShow = true, rewriteOnly = true })
				end
			end)
		end
	end)
	local function post(tt, data)
		if tt ~= GameTooltip then
			return
		end
		if IsMinimapDataType(DataTypeOf(data)) then
			return
		end
		GatherNotify.ModifyTooltip(tt, data, { skipShow = true })
	end
	local kit = GetKit()
	if kit then
		kit:On("unit", post)
		kit:On("object", post)
		kit:On("corpse", post)
	elseif TooltipDataProcessor and Enum and Enum.TooltipDataType then
		local types = Enum.TooltipDataType
		for _, key in ipairs({ "Unit", "Object", "Corpse" }) do
			if types[key] then
				pcall(TooltipDataProcessor.AddTooltipPostCall, types[key], post)
			end
		end
	else
		pcall(function()
			GameTooltip:HookScript("OnTooltipSetUnit", function(self)
				GatherNotify.ModifyTooltip(self, nil, { skipShow = true })
			end)
		end)
	end
	if GameTooltip.ProcessInfo then
		pcall(hooksecurefunc, GameTooltip, "ProcessInfo", function(self, info)
			if self ~= GameTooltip then
				return
			end
			if IsMinimapDataType(DataTypeOf(info)) then
				return
			end
			GatherNotify.ModifyTooltip(self, info, { skipShow = true })
		end)
	end
	pcall(hooksecurefunc, GameTooltip, "SetText", function(self, text)
		if self ~= GameTooltip then
			return
		end
		if type(text) == "string" and not Secret(text) and text ~= "" then
			State(self).line1Hint = StripTooltipCodes(text)
		end
	end)
	pcall(GameTooltip.HookScript, GameTooltip, "OnTooltipCleared", function(self)
		local st = tipState[self]
		if st then
			st.line1Hint = nil
		end
	end)
end

SLASH_GN1, SLASH_GN2, SLASH_GN3 = "/gn", "/gathernotify", "/gnotify"
SlashCmdList["GN"] = GatherNotify.OnCommand

GatherNotify.Frame:SetScript("OnEvent", GatherNotify.OnEvent)
GatherNotify.Frame:RegisterEvent("CHAT_MSG_SKILL")
GatherNotify.Frame:RegisterEvent("ADDON_LOADED")
GatherNotify.Frame:RegisterEvent("SKILL_LINES_CHANGED")
GatherNotify.Frame:RegisterEvent("PLAYER_ENTERING_WORLD")
pcall(GatherNotify.Frame.RegisterEvent, GatherNotify.Frame, "TRADE_SKILL_LIST_UPDATE")
pcall(GatherNotify.Frame.RegisterEvent, GatherNotify.Frame, "UI_ERROR_MESSAGE")
