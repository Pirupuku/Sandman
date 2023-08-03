local _G = getfenv()
--local select = _G.select
local UnitClass = _G.UnitClass

local pairs = _G.pairs
local print = _G.print
local error = _G.error
local tonumber = _G.tonumber
local fmod = _G.math.fmod
local floor = _G.math.floor
local gsub = _G.string.gsub
local upper = _G.string.upper
local lower = _G.string.lower
local match = _G.string.match
local format = _G.string.format

local UnitName = _G.UnitName
local IsInGuild = _G.IsInGuild
local UnitInRaid = _G.UnitInRaid
local CancelTrade = _G.CancelTrade
local AcceptTrade = _G.AcceptTrade
local UnitInParty = _G.UnitInParty
local TargetByName = _G.TargetByName
local GetItemCount = _G.GetItemCount
local GetGuildInfo = _G.GetGuildInfo
local InitiateTrade = _G.InitiateTrade
local GetNumFriends = _G.GetNumFriends
local GetFriendInfo = _G.GetFriendInfo
local CursorHasItem = _G.CursorHasItem
local SendChatMessage = _G.SendChatMessage
local ClickTradeButton = _G.ClickTradeButton
local GetContainerItemID = _G.GetContainerItemID
local PickupContainerItem = _G.PickupContainerItem
local GetContainerNumSlots = _G.GetContainerNumSlots
local GetContainerItemInfo = _G.GetContainerItemInfo


--SandmanFrame = CreateFrame("Frame", "SandmanFrame")
SandmanFrame = CreateFrame("Frame",nil)
SandmanFrame:RegisterEvent("ADDON_LOADED")
SandmanFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
SandmanFrame:RegisterEvent("PLAYER_LOGIN")
SandmanFrame:RegisterEvent('TRADE_SHOW')
SandmanFrame:RegisterEvent('TRADE_ACCEPT_UPDATE')
SandmanFrame:RegisterEvent('CHAT_MSG_WHISPER')
SandmanFrame:RegisterEvent('BAG_UPDATE')

sandmanTradeCount = {
	['DRUID']   = {2},
	['HUNTER']  = {4},
	['PALADIN'] = {2},
	['PRIEST']  = {2},
	['ROGUE']   = {1},
	['SHAMAN']  = {2},
	['WARLOCK'] = {1},
	['WARRIOR'] = {1},
	['MAGE']    = {1},
}

sandmanBeingTraded = 0
sandmanGlobalCount = 0

function SandmanLoadHandler()
	DEFAULT_CHAT_FRAME:AddMessage("enters load handler")
	
	if (event == "ADDON_LOADED") and (arg1 == "Sandman") then
		if (event == "PLAYER_LOGIN") then
			DEFAULT_CHAT_FRAME:AddMessage("Sandman v0.1 loaded")
		end
	end
end

function SandmanEventHandler()
	
	if (sandmanStatus == "off") then return end
	
	
	
	if (event == "TRADE_SHOW") then
		local performTrade = SandmanCheckTheTrade()
		if not performTrade then return end
		
		local NPCName = UnitName('NPC')
		local NPCClass = UnitClass('NPC')
		local count
		if NPCClass == "Druid" then
			count = 1
			sandmanGlobalCount = count
		elseif NPCClass == "Hunter" then
			count = 5
			sandmanGlobalCount = count
		elseif NPCClass == "Paladin" then
			count = 1
			sandmanGlobalCount = count
		elseif NPCClass == "Priest" then
			count = 1
			sandmanGlobalCount = count
		elseif NPCClass == "Rogue" then
			count = 1
			sandmanGlobalCount = count
		elseif NPCClass == "Shaman" then
			count = 1
			sandmanGlobalCount = count
		elseif NPCClass == "Warlock" then
			count = 1
			sandmanGlobalCount = count
		elseif NPCClass == "Warrior" then
			count = 1
			sandmanGlobalCount = count
		elseif NPCClass == "Mage" then
			count = 2
			sandmanGlobalCount = count
		end
		
		SandmanDoTheTrade(19183, count, itemType, NPCName)
		-- 17056 = Light Feather
		-- 19183 = Hourglass Sand
		--self:DoTheTrade(19183, count, itemType)
		sandmanBeingTraded = 1
	end
	
	if (event == "TRADE_ACCEPT_UPDATE") then
		SandmanTradeUpdate(arg1, arg2)
	end
	
	if (event == "BAG_UPDATE" and sandmanBeingTraded == 1) then
		local myItem = string.lower(gsub("Hourglass Sand","^.*%[(.*)%].*$","%1"))
		-- Original API function
		--PickupContainerItem(myBag, mySlot)
		if not CursorHasItem() then
			
			for i = 0, NUM_BAG_FRAMES do
				local slotNrs = GetContainerNumSlots(i)
				for j = 1, slotNrs do
					myLink = GetContainerItemLink(i, j);
					if ( myLink ) then
						
						if ( myItem == string.lower(gsub(myLink,"^.*%[(.*)%].*$","%1"))) then
							local _, myCount = GetContainerItemInfo(i, j)
							--DEFAULT_CHAT_FRAME:AddMessage("DEBUG myCount = "..myCount)
							--DEFAULT_CHAT_FRAME:AddMessage("DEBUG myGlobalCount = "..myGlobalCount)
							if myCount == sandmanGlobalCount then
								--DEFAULT_CHAT_FRAME:AddMessage("DEBUG i = "..i..", j = "..j)
								--DEFAULT_CHAT_FRAME:AddMessage("DEBUG myCount = "..myCount)
								PickupContainerItem(i, j)
							end
						end
					end
				end
			end
		end
		local tradeSlot = TradeFrame_GetAvailableSlot() -- Blizzard function
		ClickTradeButton(tradeSlot)
	end
end

function SandmanTradeUpdate(arg1, arg2)
	-- arg1 - Player has agreed to the trade (1) or not (0)
	-- arg2 - Target has agreed to the trade (1) or not (0)
	if arg2 then
		AcceptTrade()
	end
end

function SandmanCheckTheTrade()
	-- Check to see whether or not we should execute the trade.
	
	if UnitInRaid('NPC') then
		return true
	else
		DEFAULT_CHAT_FRAME:AddMessage("Not in raid group.")
		return false
	end
end

function SandmanDoTheTrade(itemID, count, itemType, NPCName)
	if not TradeFrame:IsShown() or count == 0 then return end
	
	local myBag, mySlot, myTexture, myTotalcount = GetItemLocalization("Hourglass Sand")
	local bagCount = myTotalcount
	if bagCount < count then
		
		local itemName, hyperLink = GetItemInfo(itemID)
		if not itemName then
			hyperLink = 'item:'..itemID..':0:0:0'
			itemName = 'Hourglass Sand'
		end
		local link = '|cffffffff'..'|H'..hyperLink..'|h['..itemName..']|h|r'		
		SendChatMessage("I can't complete the trade right now. I'm out of "..link..".", "WHISPER", GetDefaultLanguage("player"), NPCName)
		return CancelTrade()
	else
		SplitContainerItem(myBag, mySlot, count)
		local myItem = string.lower(gsub("Hourglass Sand","^.*%[(.*)%].*$","%1"))
		local myLink, emptyBag
		local helperCounter = 0
		local freeSlot = 0
		for i = 0, NUM_BAG_FRAMES do
			local slotNrs = GetContainerNumSlots(i)
			for j = 1, slotNrs do
				myLink = GetContainerItemLink(i,j);
				if ( myLink ) then
					if ( myItem == string.lower(gsub(myLink,"^.*%[(.*)%].*$","%1"))) then
						helperCounter = helperCounter + 1
					end
					if helperCounter == 0 and j == slotNrs and CursorHasItem() then
						if i == 0 and freeSlot > 0 then
							PutItemInBackpack()
						elseif freeSlot > 0 then
							emptyBag = i + 19
							PutItemInBag(emptyBag)
						end
						--break
					end
				else
					freeSlot = freeSlot + 1
				end
			end
			freeSlot = 0
			helperCounter = 0
		end
		--[[
		waitForSplit()
		-- Original API function
		--PickupContainerItem(myBag, mySlot)
		if not CursorHasItem() then
			return error('|cffff9966'..L["Had a problem picking things up!"]..'|r')
		end
		local tradeSlot = TradeFrame_GetAvailableSlot() -- Blizzard function
		ClickTradeButton(tradeSlot)
		--]]
	end
end
--[[
function waitForSplit()
	for i = 0, NUM_BAG_FRAMES do
		local slotNrs = GetContainerNumSlots(i)
		for j = 1, slotNrs do
			myLink = GetContainerItemLink(i, j);
			if ( myLink ) then
				if ( myItem == string.lower(gsub(myLink,"^.*%[(.*)%].*$","%1"))) then
					local _, myCount = GetContainerItemInfo(i, j)
					if myCount == count then
						DEFAULT_CHAT_FRAME:AddMessage("DEBUG i = "..i..", j = "..j)
						DEFAULT_CHAT_FRAME:AddMessage("DEBUG myCount = "..myCount)
						PickupContainerItem(i, j)
					end
				end
			end
		end
	end
	if not CursorHasItem() then
		waitForSplit()
	end
end
--]]
--[[
function ItemLinkToName(link)
	if ( link ) then
		return gsub(link,"^.*%[(.*)%].*$","%1");
	end
end
--]]
function GetItemLocalization(item)
	if ( not item ) then return; end
	item = string.lower(gsub(item,"^.*%[(.*)%].*$","%1"))
	local link;
	for i = 1,23 do
		link = GetInventoryItemLink("player",i);
		if ( link ) then
			if ( item == string.lower(gsub(link,"^.*%[(.*)%].*$","%1")) )then
				return i, nil, GetInventoryItemTexture('player', i), GetInventoryItemCount('player', i);
			end
		end
	end
	local count, bag, slot, texture;
	local totalcount = 0;
	for i = 0,NUM_BAG_FRAMES do
		for j = 1,MAX_CONTAINER_ITEMS do
			link = GetContainerItemLink(i,j);
			if ( link ) then
				if ( item == string.lower(gsub(link,"^.*%[(.*)%].*$","%1"))) then
					bag, slot = i, j;
					texture, count = GetContainerItemInfo(i,j);
					totalcount = totalcount + count;
				end
			end
		end
	end
	return bag, slot, texture, totalcount;
end

function SandmanAddonStatus(command)
	sandmanStatus = command
end

SandmanFrame:SetScript("OnLoad", SandmanLoadHandler)
SandmanFrame:SetScript("OnEvent", SandmanEventHandler)

SlashCmdList["SLASH_SANDMAN"] = function(flag) end
SLASH_SANDMAN1 = "/sandman"
function SlashCmdList.SANDMAN(args)
	command = string.lower(args)
	if (not command) then 
		DEFAULT_CHAT_FRAME:AddMessage("Use the following commands:")
		DEFAULT_CHAT_FRAME:AddMessage("/sandman on")
		DEFAULT_CHAT_FRAME:AddMessage("/sandman off")
	else
		if (command == "on" or command == "off") then
			SandmanAddonStatus(command)
			DEFAULT_CHAT_FRAME:AddMessage("Sandman is turned "..string.upper(command))
		else 	
			DEFAULT_CHAT_FRAME:AddMessage("Use the following commands:")
			DEFAULT_CHAT_FRAME:AddMessage("/sandman on")
			DEFAULT_CHAT_FRAME:AddMessage("/sandman off")
		end		-- no correct command was found
	end
end