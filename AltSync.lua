--Special thanks to sylvnaaar creator of Prat for whom this mod is inspired from

AltSync = {};
AltSync.version = GetAddOnMetadata("AltSync", "Version")

local _G = _G
local hooks = {}
local altList = {}

function AltSync:SetupDB()
	--database
	if not AltSyncDB or AltSyncDB == nil then
		AltSyncDB = {}
	end

	AltSyncDB[GetRealmName()] = AltSyncDB[GetRealmName()] or {}
	AltSyncDB[GetRealmName()]["alts"] = AltSyncDB[GetRealmName()]["alts"] or {}
	
	altList = AltSyncDB[GetRealmName()]["alts"]
		
end

function AltSync:Enable()
	
	--database setup (check for updates to db)
	AltSync:SetupDB()
	
	--show loading notification
	AltSync:Print("Version ["..AltSync.version.."] loaded. /altsync");
			
end

function AltSync:Print(msg)
	if not msg then return end
	if type(msg) == 'table' then

		local success,err = pcall(function(msg) return table.concat(msg, ", ") end, msg)
		
		if success then
			msg = "Table: "..table.concat(msg, ", ")
		else
			msg = "Table: Error, table cannot contain sub tables."
		end
	end
	
	msg = tostring(msg)
	msg = "|cFF80FF00AltSync|r: " .. msg
	DEFAULT_CHAT_FRAME:AddMessage(msg);
end

function AltSync:Capitalize(str)
	str = string.lower(str)
	str = str:gsub("^%l", string.upper)
	return str
end

function AltSync:AddAlt(altname, mainname)
	if not altname or not mainname then
		return nil;
	end
	
	altname = AltSync:Capitalize(strtrim(altname))
	mainname = AltSync:Capitalize(strtrim(mainname))

	if altList[altname] then
		AltSync:Print("Alt [|cffFF6666"..altname.."|r] is already linked to main [|cffFF6666"..altList[altname].."|r].");
	else
		--check if they are adding a main as an alt
		for k, v in pairs(altList) do
			if v == altname then
				AltSync:Print("You cannot set a main [|cffFF6666"..altname.."|r] as an alt! [|cffFF6666"..altname.."|r] is set for alt [|cffFF6666"..k.."|r].");
				return nil;
			end
		end

		altList[altname] = mainname
		
		AltSync:Print("Alt [|cffFF6666"..altname.."|r] has been linked to main [|cffFF6666"..altList[altname].."|r].");
	end
end

function AltSync:RemAlt(altname)
	if not altname then
		return nil;
	end
	
	altname = AltSync:Capitalize(strtrim(altname))

	if altList[altname] then
		altList[altname] = nil;
		AltSync:Print("Alt [|cffFF6666"..altname.."|r] has been removed from the database.");
	else
		AltSync:Print("Not alt with the name [|cffFF6666"..altname.."|r] is in the database.");
	end
end

--[[-------------------------------------------------------------------------
-- Ordered pair by key
-------------------------------------------------------------------------]]--

---http://lua-users.org/wiki/SortedIteration

local function __genOrderedIndex( t )
    local orderedIndex = {}
    for key in pairs(t) do
        table.insert( orderedIndex, key )
    end
    table.sort( orderedIndex )
    return orderedIndex
end

local function orderedNext(t, state)
    -- Equivalent of the next function, but returns the keys in the alphabetic
    -- order. We use a temporary ordered key table that is stored in the
    -- table being iterated.

    --print("orderedNext: state = "..tostring(state) )
    if state == nil then
        -- the first time, generate the index
        t.__orderedIndex = __genOrderedIndex( t )
        key = t.__orderedIndex[1]
        return key, t[key]
    end
    -- fetch the next value
    key = nil
    for i = 1,table.getn(t.__orderedIndex) do
        if t.__orderedIndex[i] == state then
            key = t.__orderedIndex[i+1]
        end
    end

    if key then
        return key, t[key]
    end

    -- no more value to return, cleanup
    t.__orderedIndex = nil
    return
end

local function orderedPairs(t)
    -- Equivalent of the pairs() function on tables. Allows to iterate
    -- in order
    return orderedNext, t, nil
end


--///////////////////////////////////////////////////////////////////////////////////////////////
--///////////////////////////////////////////////////////////////////////////////////////////////

local eventFrame = CreateFrame("Frame", "AltSyncEventFrame", UIParent)
eventFrame:RegisterEvent("ADDON_LOADED");

eventFrame:SetScript("OnEvent", function(self, event, ...)
	if event == "ADDON_LOADED" and arg1 == "AltSync" then
		AltSync:Enable();	
	end
end)

local PassedEvents = {
	CHAT_MSG_SAY = true,
	CHAT_MSG_YELL = true,
	CHAT_MSG_WHISPER = true,
	CHAT_MSG_WHISPER_INFORM = true,
	CHAT_MSG_GUILD = true,
	CHAT_MSG_OFFICER = true,
	CHAT_MSG_PARTY = true,
	CHAT_MSG_RAID = true,
	CHAT_MSG_RAID_LEADER = true,
	CHAT_MSG_RAID_WARNING = true,
	CHAT_MSG_BATTLEGROUND = true,
	CHAT_MSG_BATTLEGROUND_LEADER = true,
	CHAT_MSG_CHANNEL = true,
	CHAT_MSG_AFK = true,
	CHAT_MSG_DND = true,
	CHAT_MSG_SYSTEM = true,
	CHAT_MSG_ACHIEVEMENT = true,
	CHAT_MSG_GUILD_ACHIEVEMENT = true,
}

local function AddMessage(frame, text, ...)

	--only allow certain messages through
	if PassedEvents[event] then
		text = tostring(text) or ''

		-------------players
		--UIErrorsFrame:AddMessage((playerName or "none").."::"..(playerText or "none").."[]"..(playerF or "none"))
		
		local playerName, playerText, playerF = string.match(text, "|Hplayer:(.-)|h%[(.-)%]|h(.+)")
		
		if playerName ~= nil then
			local pN, msgNum = strsplit(':', playerName)  -- BOB:34345
			if pN ~= nil then
				if AltSync and AltSyncDB then
					--display alt information
					if pN and altList[AltSync:Capitalize(pN)] then
						text = text:gsub("|Hplayer:(.-)|h%[(.-)%]|h", "|Hplayer:%1|h%[%2]|h<"..altList[AltSync:Capitalize(pN)]..">")
					elseif playerName and altList[AltSync:Capitalize(playerName)] then
						text = text:gsub("|Hplayer:(.-)|h%[(.-)%]|h", "|Hplayer:%1|h%[%2]|h<"..altList[AltSync:Capitalize(playerName)]..">")
					end
				end
			end
		end
	end
	
	return hooks[frame](frame, text, ...)
end

local function SlashCommand(cmd)
	if not cmd then
		AltSync:Print("Add Alt = /AltSync addalt altname=mainname");
		AltSync:Print("Remove Alt = /AltSync remalt altname");
		AltSync:Print("--------------");
		AltSync:Print("List Alts = /AltSync list");
		return false;
	end

	local a,b,c=strfind(cmd, "(%S+)"); --contiguous string of non-space characters
	
	if a then
		if c and c:lower() == "addalt" then
			if b then
				local altname, mainname = strsplit("=", strsub(cmd, b+2))
				
				if altname and mainname then
					altname = string.gsub(strtrim(altname), " ", "");
					mainname = string.gsub(strtrim(mainname), " ", "");

					if altname and mainname then
						AltSync:AddAlt(altname, mainname);
					else
						AltSync:Print("Incorrect:  /AltSync addalt altname=mainname");
					end
					return true
				end
			end
		elseif c and c:lower() == "remalt" then
			if not altList or altList == nil then
				AltSync:Print("Your alt list is empty.")
				return
			end
			if b then
				local altname = strsub(cmd, b+2)
				if altname then
					altname = string.gsub(strtrim(altname), " ", "");

					if altname then
						altname = AltSync:Capitalize(altname)
						AltSync:RemAlt(altname);
					else
						AltSync:Print("Incorrect:  /AltSync remalt altname");
					end
					return true
				end
			end
		elseif c and c:lower() == "list" then
		
			InterfaceOptionsFrame_OpenToCategory(AltSyncConfigFrame)
			
			return true;
			
		end
	end
	
		AltSync:Print("Add Alt = /AltSync addalt altname=mainname");
		AltSync:Print("Remove Alt = /AltSync remalt altname");
		AltSync:Print("--------------");
		AltSync:Print("List Alts = /AltSync list");
 	
 	return false;
end

--[[-------------------------------------------------------------------------
-- Interface Options using tekConfig special thanks to Cladhaire
-------------------------------------------------------------------------]]--

local frame = CreateFrame("Frame", "AltSyncConfigFrame", InterfaceOptionsFramePanelContainer)
frame.name = "AltSync"
frame:Hide()
frame:SetScript("OnShow", function(frame)
	local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 16, -16)
	title:SetText("AltSync Configuration")

	local subtitle = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	--~ 	subtitle:SetHeight(32)
	subtitle:SetHeight(35)
	subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
	subtitle:SetPoint("RIGHT", frame, -32, 0)
	subtitle:SetNonSpaceWrap(true)
	subtitle:SetJustifyH("LEFT")
	subtitle:SetJustifyV("TOP")
	--~ 	subtitle:SetMaxLines(3)
	subtitle:SetText("This panel provides information regarding the mod AltSync.")

	local rows, anchor = {}
	local EDGEGAP, ROWHEIGHT, ROWGAP, GAP = 16, 20, 2, 4

	-- Create rows for each option
	for i=1,math.floor((305-22)/(ROWHEIGHT + ROWGAP)) do
		local row = CreateFrame("Button", nil, frame)
		if not anchor then row:SetPoint("TOP", subtitle, "BOTTOM", 0, -16)
		else row:SetPoint("TOP", anchor, "BOTTOM", 0, -ROWGAP) end
		row:SetPoint("LEFT", EDGEGAP, 0)
		row:SetPoint("RIGHT", -EDGEGAP*2-8, 0)
		row:SetHeight(ROWHEIGHT)
		anchor = row
		rows[i] = row

		local title = row:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
		title:SetPoint("LEFT")
		row.title = title

		local mainname = row:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall")
		mainname:SetPoint("RIGHT", row, "RIGHT", -4, 0)
		mainname:SetPoint("LEFT", title, "RIGHT")
		mainname:SetJustifyH("RIGHT")
		row.mainname = mainname
	end
	
	local tempList = {}
	for k, v in orderedPairs(altList) do
		if k and v then
			table.insert(tempList, k)
		end
	end

	local offset = 0
	Refresh = function()
		if not AltSyncConfigFrame:IsVisible() then return end
		--if not AltSyncDB then return end
		
		for i,row in ipairs(rows) do
			if (i + offset) <= #tempList then
				row.title:SetText(tempList[i + offset])
				row.mainname:SetText(altList[tempList[i + offset]])
				row.mainname:SetTextColor(0.1, 1.0, 0.1)
				row.name = tempList[i + offset]
				row:Show()
			else
				row:Hide()
			end
		end
	
	end
	
	frame:SetScript("OnEvent", Refresh)
	frame:RegisterEvent("ADDON_LOADED")
	frame:SetScript("OnShow", Refresh)
	Refresh()

	local scrollbar = LibStub("tekKonfig-Scroll").new(frame, nil, #rows/2)
	scrollbar:ClearAllPoints()
	scrollbar:SetPoint("TOP", rows[1], 0, -16)
	scrollbar:SetPoint("BOTTOM", rows[#rows], 0, 16)
	scrollbar:SetPoint("RIGHT", -16, 0)
	scrollbar:SetMinMaxValues(0, math.max(0, #tempList - #rows))
	scrollbar:SetValue(0)

	local f = scrollbar:GetScript("OnValueChanged")
	scrollbar:SetScript("OnValueChanged", function(self, value, ...)
		offset = math.floor(value)
		Refresh()
		return f(self, value, ...)
	end)

	frame:EnableMouseWheel()
	frame:SetScript("OnMouseWheel", function(self, val) scrollbar:SetValue(scrollbar:GetValue() - val*#rows/2) end)

end)

InterfaceOptions_AddCategory(frame)
LibStub("tekKonfig-AboutPanel").new("AltSync", "AltSync")

SLASH_AltSync1 = "/altsync";
SlashCmdList["AltSync"] = SlashCommand;

--Hook all the AddMessage ChatFrames
local f
for i=1, NUM_CHAT_WINDOWS do
	f = _G['ChatFrame'..i]
	
	hooks[f] = f.AddMessage
	f.AddMessage = AddMessage
end