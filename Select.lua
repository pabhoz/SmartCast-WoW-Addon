-- Smart Cast - mouseover casting without macros for WoW 3.3.5a.
-- Copyright (C) 2026 pabhoz - https://github.com/pabhoz/SmartCast-WoW-Addon
-- Licensed under the GNU General Public License v3.0 or later. See LICENSE.

-- Selection mode (grey bars, click the spells that follow the mouse) and the
-- small corner markers on marked buttons. All of this is plain, insecure UI:
-- the overlays only exist out of combat and never touch the secure buttons.

local L = SmartCast.L
local Print = SmartCast.Print

local COLORS = { help = { 0.25, 1, 0.45 }, harm = { 1, 0.35, 0.25 } }

---------------------------------------------------------------- markers

local markers = {}

local function Marker(button)
	local m = markers[button]
	if not m then
		m = button:CreateTexture(nil, "OVERLAY")
		m:SetSize(6, 6)
		m:SetPoint("TOPRIGHT", -3, -3)
		markers[button] = m
	end
	return m
end

-- A green (helpful) or red (harmful) dot on every button whose spell is marked.
function SmartCast.UpdateMarkers()
	local show = SmartCastDB.markers and SmartCastDB.enabled
	for _, button in ipairs(SmartCast.Buttons()) do
		local mode = show and SmartCast.ModeFor(SmartCast.ButtonSlot(button))
		if mode then
			local m = Marker(button)
			m:SetTexture(COLORS[mode][1], COLORS[mode][2], COLORS[mode][3], 0.95)
			m:Show()
		elseif markers[button] then
			markers[button]:Hide()
		end
	end
end

-- Pages and stances change the spell under a button, in combat too: textures
-- may be updated then, so the markers follow.
local markerFrame = CreateFrame("Frame")
markerFrame:Hide()
markerFrame:SetScript("OnUpdate", function(self)
	self:Hide()
	SmartCast.UpdateMarkers()
end)
local function MarkersSoon() markerFrame:Show() end
markerFrame:SetScript("OnEvent", MarkersSoon)
for _, e in ipairs({ "ACTIONBAR_PAGE_CHANGED", "UPDATE_BONUS_ACTIONBAR", "UPDATE_SHAPESHIFT_FORM", "ACTIONBAR_SLOT_CHANGED" }) do
	markerFrame:RegisterEvent(e)
end
if ActionButton_Update then hooksecurefunc("ActionButton_Update", MarkersSoon) end

---------------------------------------------------------------- selection mode

local overlays, panel = {}, nil
local selecting = false

local function DescribeMode(kind)
	if kind == "help" then return L["Friend under the mouse; right-click on you"] end
	if kind == "harm" then return L["Enemy under the mouse"] end
	return L["Not a spell with a target: can't follow the mouse"]
end

local function UpdateOverlay(o)
	local name, kind = SmartCast.SlotSpell(SmartCast.ButtonSlot(o.button))
	o.name, o.kind = name, kind
	local marked = name and SmartCast.IsMarked(name, kind)
	if marked then
		local c = COLORS[kind]
		o.glow:SetVertexColor(c[1], c[2], c[3])
		o.glow:Show()
		o.shade:SetTexture(0, 0, 0, 0)
	else
		o.glow:Hide()
		o.shade:SetTexture(0, 0, 0, kind and 0.6 or 0.85)
	end
end

-- One overlay per visible button (the stance bar swaps which ones are visible).
local Overlay
local function ShowOverlays()
	for _, button in ipairs(SmartCast.Buttons()) do
		if button:IsVisible() then Overlay(button):Show() elseif overlays[button] then overlays[button]:Hide() end
	end
end

local function UpdateOverlays()
	for _, o in pairs(overlays) do
		if o:IsShown() then UpdateOverlay(o) end
	end
	if panel then
		local marked = 0
		for _, o in pairs(overlays) do
			if o:IsShown() and o.name and SmartCast.IsMarked(o.name, o.kind) then marked = marked + 1 end
		end
		panel.count:SetText(L["%d spells marked on your bars (spec %d)"]:format(marked, GetActiveTalentGroup() or 1))
	end
end

local function OverlayOnEnter(self)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	if self.name then
		GameTooltip:AddLine(self.name, 1, 1, 1)
		GameTooltip:AddLine(DescribeMode(self.kind), 0.8, 0.8, 0.8, true)
		if self.kind then
			local marked = SmartCast.IsMarked(self.name, self.kind)
			GameTooltip:AddLine(marked and L["Marked: follows the mouse"] or L["Not marked: works as usual"], marked and 0.3 or 0.6, marked and 1 or 0.6, marked and 0.4 or 0.6)
			local auto = SmartCast.Default(self.name, self.kind)
			GameTooltip:AddLine(L["Automatic choice: %s"]:format(auto and L["marked"] or L["not marked"]), 0.6, 0.6, 0.6)
			GameTooltip:AddLine(L["Click: mark / unmark.  Right-click: back to automatic."], 1, 0.82, 0, true)
		end
	else
		GameTooltip:AddLine(L["Empty or not a spell"], 0.7, 0.7, 0.7)
	end
	GameTooltip:Show()
end

local function OverlayOnClick(self, mouse)
	if not self.kind then return end
	if mouse == "RightButton" then
		SmartCast.SpecConfig()[self.name] = nil
		SmartCast.Refresh()
	else
		SmartCast.SetMarked(self.name, self.kind, not SmartCast.IsMarked(self.name, self.kind))
	end
	UpdateOverlays()
	OverlayOnEnter(self)
end

function Overlay(button)
	local o = overlays[button]
	if o then return o end
	o = CreateFrame("Button", nil, UIParent)
	o:SetFrameStrata("DIALOG")
	o:SetAllPoints(button)
	o:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	o.button = button
	o.shade = o:CreateTexture(nil, "ARTWORK")
	o.shade:SetAllPoints()
	o.glow = o:CreateTexture(nil, "OVERLAY")
	o.glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
	o.glow:SetBlendMode("ADD")
	o.glow:SetPoint("CENTER")
	o.glow:SetSize(button:GetWidth() * 1.9, button:GetHeight() * 1.9)
	o:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
	o:SetScript("OnEnter", OverlayOnEnter)
	o:SetScript("OnLeave", GameTooltip_Hide)
	o:SetScript("OnClick", OverlayOnClick)
	overlays[button] = o
	return o
end

local function MakeButton(parent, text, width)
	local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	b:SetSize(width, 22)
	b:SetText(text)
	return b
end

local function CreatePanel()
	panel = CreateFrame("Frame", "SmartCastSelectPanel", UIParent)
	panel:SetSize(420, 96)
	panel:SetPoint("TOP", 0, -120)
	panel:SetFrameStrata("DIALOG")
	panel:SetClampedToScreen(true)
	panel:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true, tileSize = 32, edgeSize = 32,
		insets = { left = 11, right = 12, top = 12, bottom = 11 },
	})
	panel:EnableMouse(true)
	panel:SetMovable(true)
	panel:RegisterForDrag("LeftButton")
	panel:SetScript("OnDragStart", panel.StartMoving)
	panel:SetScript("OnDragStop", panel.StopMovingOrSizing)

	local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	title:SetPoint("TOP", 0, -16)
	title:SetText(L["Smart Cast: choose your spells"])

	panel.count = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	panel.count:SetPoint("TOP", title, "BOTTOM", 0, -4)

	local auto = MakeButton(panel, L["All automatic"], 120)
	auto:SetPoint("BOTTOMLEFT", 18, 16)
	auto:SetScript("OnClick", function()
		local cfg = SmartCast.SpecConfig()
		for k in pairs(cfg) do cfg[k] = nil end
		SmartCast.Refresh()
		UpdateOverlays()
	end)

	local none = MakeButton(panel, L["None"], 120)
	none:SetPoint("LEFT", auto, "RIGHT", 6, 0)
	none:SetScript("OnClick", function()
		for _, o in pairs(overlays) do
			if o:IsShown() and o.kind then SmartCast.SpecConfig()[o.name] = false end
		end
		SmartCast.Refresh()
		UpdateOverlays()
	end)

	local done = MakeButton(panel, L["Done"], 120)
	done:SetPoint("LEFT", none, "RIGHT", 6, 0)
	done:SetScript("OnClick", function() SmartCast.StopSelection() end)
	panel:Hide()
end

function SmartCast.IsSelecting()
	return selecting
end

function SmartCast.StartSelection()
	if InCombatLockdown() then Print(L["Not possible in combat."]) return end
	if not SmartCast.header then return end
	SmartCast.Refresh()
	if not panel then CreatePanel() end
	selecting = true
	ShowOverlays()
	panel:Show()
	UpdateOverlays()
	if not SmartCastDB.enabled then Print(L["Smart Cast is off: what you mark applies when you turn it on (/smartcast on)."]) end
end

function SmartCast.StopSelection()
	selecting = false
	for _, o in pairs(overlays) do o:Hide() end
	if panel then panel:Hide() end
	GameTooltip:Hide()
end

function SmartCast.ToggleSelection()
	if selecting then SmartCast.StopSelection() else SmartCast.StartSelection() end
end

-- Entering combat closes the selection mode; a page change refreshes it.
local watcher = CreateFrame("Frame")
watcher:SetScript("OnEvent", function(self, event)
	if not selecting then return end
	if event == "PLAYER_REGEN_DISABLED" then
		SmartCast.StopSelection()
		Print(L["Selection mode closed: you entered combat."])
	else
		ShowOverlays()
		UpdateOverlays()
	end
end)
for _, e in ipairs({ "PLAYER_REGEN_DISABLED", "ACTIONBAR_PAGE_CHANGED", "UPDATE_BONUS_ACTIONBAR", "ACTIONBAR_SLOT_CHANGED", "ACTIVE_TALENT_GROUP_CHANGED" }) do
	watcher:RegisterEvent(e)
end
