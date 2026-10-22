-- Smart Cast - mouseover casting without macros for WoW 3.3.5a.
-- Copyright (C) 2026 pabhoz - https://github.com/pabhoz/SmartCast-WoW-Addon
-- Licensed under the GNU General Public License v3.0 or later. See LICENSE.

-- Launcher: an entry in the Stormrage menu when that addon is installed, or a
-- minimap button of its own when it isn't. Plus the slash command.

local L = SmartCast.L
local Print = SmartCast.Print

local ICON = "Interface\\Icons\\Spell_Holy_SealOfSacrifice"

local function StatusText()
	local db = SmartCastDB
	local lines = { db.enabled and ("|cff33ff66" .. L["On"] .. "|r") or ("|cffff5555" .. L["Off"] .. "|r") }
	lines[#lines + 1] = L["Self cast key: %s"]:format(db.selfMod == "none" and L["none"] or db.selfMod:upper())
	lines[#lines + 1] = L["Focus cast key: %s"]:format(db.focusMod == "none" and L["none"] or db.focusMod:upper())
	return table.concat(lines, "\n")
end

local function AddTooltip(tt)
	tt:AddLine(StatusText(), 0.8, 0.8, 0.8)
	tt:AddLine(L["Left-click: choose spells\nRight-click: turn on/off"], 1, 0.82, 0)
end

---------------------------------------------------------------- minimap button

local mm

local function PositionMinimapButton()
	local angle = math.rad(SmartCastDB.minimap.angle)
	mm:SetPoint("CENTER", Minimap, "CENTER", 80 * math.cos(angle), 80 * math.sin(angle))
end

function SmartCast.UpdateMinimapButton()
	if not mm then return end
	if SmartCastDB.minimap.hide then mm:Hide() else mm:Show() end
end

local function CreateMinimapButton()
	mm = CreateFrame("Button", "SmartCastMinimapButton", Minimap)
	mm:SetSize(31, 31)
	mm:SetFrameStrata("MEDIUM")
	mm:SetFrameLevel(8)
	mm:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
	local icon = mm:CreateTexture(nil, "BACKGROUND")
	icon:SetTexture(ICON)
	icon:SetSize(20, 20)
	icon:SetPoint("TOPLEFT", 7, -5)
	icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	local border = mm:CreateTexture(nil, "OVERLAY")
	border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
	border:SetSize(53, 53)
	border:SetPoint("TOPLEFT")
	mm:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	mm:RegisterForDrag("LeftButton")
	mm:SetScript("OnClick", function(self, button)
		if button == "RightButton" then SmartCast.SetEnabled(not SmartCastDB.enabled) else SmartCast.ToggleSelection() end
	end)
	mm:SetScript("OnDragStart", function(self)
		self:SetScript("OnUpdate", function()
			local mx, my = Minimap:GetCenter()
			local cx, cy = GetCursorPosition()
			local scale = Minimap:GetEffectiveScale()
			SmartCastDB.minimap.angle = math.deg(math.atan2(cy / scale - my, cx / scale - mx))
			PositionMinimapButton()
		end)
	end)
	mm:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
	mm:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		GameTooltip:AddLine("Smart Cast")
		AddTooltip(GameTooltip)
		GameTooltip:Show()
	end)
	mm:SetScript("OnLeave", GameTooltip_Hide)
	PositionMinimapButton()
	SmartCast.UpdateMinimapButton()
end

-- Called from Core.lua once the saved variables are loaded.
function SmartCast.CreateLauncher()
	local hub = type(Stormrage) == "table" and Stormrage.Register and Stormrage.Register({
		name = "Smart Cast",
		icon = ICON,
		description = L["Mouseover casting without macros"],
		onClick = function(button)
			if button == "RightButton" then SmartCast.SetEnabled(not SmartCastDB.enabled) else SmartCast.ToggleSelection() end
		end,
		tooltip = AddTooltip,
		actions = {
			{ text = L["Choose spells"], func = function() SmartCast.StartSelection() end },
			{ text = L["Turn on/off"], func = function() SmartCast.SetEnabled(not SmartCastDB.enabled) end },
		},
	})
	if not hub then CreateMinimapButton() end
end

---------------------------------------------------------------- slash command

local function SetModifier(field, value, label)
	value = value and value:lower()
	if value == "off" then value = "none" end
	if not (value and SmartCast.MODIFIERS[value]) then
		Print(L["Use: alt, ctrl, shift or off."])
		return
	end
	SmartCastDB[field] = value
	SmartCast.Refresh()
	Print(label:format(value == "none" and L["none"] or value:upper()))
end

SLASH_SMARTCAST1 = "/smartcast"
SLASH_SMARTCAST2 = "/scast"
SlashCmdList.SMARTCAST = function(msg)
	local cmd, arg = msg:match("^%s*(%S*)%s*(.-)%s*$")
	cmd = cmd:lower()
	if arg == "" then arg = nil end
	if cmd == "" or cmd == "select" then
		SmartCast.ToggleSelection()
	elseif cmd == "on" then
		SmartCast.SetEnabled(true)
	elseif cmd == "off" then
		SmartCast.SetEnabled(false)
	elseif cmd == "self" then
		SetModifier("selfMod", arg, L["Self cast key: %s"])
	elseif cmd == "focus" then
		SetModifier("focusMod", arg, L["Focus cast key: %s"])
	elseif cmd == "markers" then
		SmartCastDB.markers = not SmartCastDB.markers
		SmartCast.UpdateMarkers()
		Print(SmartCastDB.markers and L["Markers shown."] or L["Markers hidden."])
	elseif cmd == "reset" then
		local cfg = SmartCast.SpecConfig()
		for k in pairs(cfg) do cfg[k] = nil end
		SmartCast.Refresh()
		Print(L["Every spell of this spec is back to the automatic choice."])
	elseif cmd == "minimap" then
		SmartCastDB.minimap.hide = not SmartCastDB.minimap.hide
		SmartCast.UpdateMinimapButton()
	else
		Print(L["Commands:"])
		Print("  /smartcast - " .. L["choose which spells follow the mouse"])
		Print("  /smartcast on | off - " .. L["turn Smart Cast on or off"])
		Print("  /smartcast self alt|ctrl|shift|off - " .. L["key + spell = on you"])
		Print("  /smartcast focus alt|ctrl|shift|off - " .. L["key + spell = on your focus"])
		Print("  /smartcast markers - " .. L["show / hide the dots on marked buttons"])
		Print("  /smartcast reset - " .. L["back to the automatic choice"])
		Print("  /smartcast minimap - " .. L["show / hide the minimap button"])
		Print(StatusText():gsub("\n", "  |  "))
	end
end
