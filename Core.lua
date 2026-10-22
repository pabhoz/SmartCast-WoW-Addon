-- Smart Cast - mouseover casting without macros for WoW 3.3.5a.
-- Copyright (C) 2026 pabhoz - https://github.com/pabhoz/SmartCast-WoW-Addon
-- Licensed under the GNU General Public License v3.0 or later. See LICENSE.

-- How it works. Action buttons are secure: in combat no addon may change what
-- they do. So the decision is taken by a secure snippet that runs on every
-- click, inside the game's restricted environment, with data prepared out of
-- combat:
--   MODE[slot]  "harm" / "help" for the slots whose spell is marked
--   the snippet reads the slot under the button, looks at the unit under the
--   mouse and sets the button's "unit" attribute just for that click.
-- Blizzard's keybindings (ACTIONBUTTON1...) don't click the button (they call
-- SecureActionButton_OnClick directly), so the same keys are overridden with
-- CLICK bindings to the buttons, swapped in combat by a state driver when the
-- stance bar or a vehicle takes over the main bar. Bartender4 buttons are
-- already clicked by their bindings and only need the snippet.

local L = SmartCast.L

local NUM_SLOTS = 120
SmartCast.NUM_SLOTS = NUM_SLOTS

function SmartCast.Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|cff66ddaaSmart Cast|r: " .. msg)
end
local Print = SmartCast.Print

function SmartCast.CharKey()
	return UnitName("player") .. "-" .. GetRealmName()
end

---------------------------------------------------------------- database

local MODIFIERS = { none = true, alt = true, ctrl = true, shift = true }
SmartCast.MODIFIERS = MODIFIERS

local function InitDB()
	SmartCastDB = SmartCastDB or {}
	local db = SmartCastDB
	db.chars = db.chars or {}
	if db.enabled == nil then db.enabled = true end
	if db.markers == nil then db.markers = true end
	if not MODIFIERS[db.selfMod or ""] then db.selfMod = "alt" end
	if not MODIFIERS[db.focusMod or ""] then db.focusMod = "none" end
	db.minimap = db.minimap or { angle = 220, hide = false }
end

-- Per character and per spec: spell name -> true (marked) / false (unmarked).
-- A spell that isn't there follows the automatic choice (SmartCast.Default).
function SmartCast.SpecConfig()
	local key, spec = SmartCast.CharKey(), GetActiveTalentGroup() or 1
	SmartCastDB.chars[key] = SmartCastDB.chars[key] or {}
	SmartCastDB.chars[key][spec] = SmartCastDB.chars[key][spec] or {}
	return SmartCastDB.chars[key][spec]
end

---------------------------------------------------------------- spells

-- Name and kind ("help" / "harm" / nil) of the spell in an action slot.
function SmartCast.SlotSpell(slot)
	if not slot then return end
	local kind, id, subType, spellID = GetActionInfo(slot)
	if kind ~= "spell" then return end
	local name
	if spellID then name = GetSpellInfo(spellID) end
	if not name and id then name = GetSpellName(id, subType or BOOKTYPE_SPELL) end
	if not name then return end
	if IsHelpfulSpell(name) then return name, "help" end
	if IsHarmfulSpell(name) then return name, "harm" end
	return name
end

-- The automatic choice: every harmful spell, and the helpful ones that can be
-- cast on someone else (a self-only buff has no range).
function SmartCast.Default(name, kind)
	if kind == "harm" then return true end
	if kind == "help" then return SpellHasRange(name) == 1 end
	return false
end

function SmartCast.IsMarked(name, kind)
	if not kind then return false end
	local explicit = SmartCast.SpecConfig()[name]
	if explicit ~= nil then return explicit end
	return SmartCast.Default(name, kind)
end

-- Marks or unmarks a spell. Storing only what differs from the automatic
-- choice keeps new spells automatic.
function SmartCast.SetMarked(name, kind, marked)
	local cfg = SmartCast.SpecConfig()
	if marked == SmartCast.Default(name, kind) then cfg[name] = nil else cfg[name] = marked end
	SmartCast.Refresh()
end

function SmartCast.ModeFor(slot)
	local name, kind = SmartCast.SlotSpell(slot)
	if name and SmartCast.IsMarked(name, kind) then return kind end
end

---------------------------------------------------------------- buttons

-- What the secure snippet needs to find the slot under each button:
--   main   ActionButton1-12: page of the main bar
--   bonus  BonusActionButton1-12: stance/stealth/form bar on page 1
--   fixed  the four extra bars: always the same slots
--   attr   Bartender4: the button keeps its slot in the "action" attribute
local BARS = {
	{ prefix = "ActionButton", kind = "main", command = "ACTIONBUTTON" },
	{ prefix = "BonusActionButton", kind = "bonus" },
	{ prefix = "MultiBarBottomLeftButton", kind = "fixed", page = "BOTTOMLEFT_ACTIONBAR_PAGE", command = "MULTIACTIONBAR1BUTTON" },
	{ prefix = "MultiBarBottomRightButton", kind = "fixed", page = "BOTTOMRIGHT_ACTIONBAR_PAGE", command = "MULTIACTIONBAR2BUTTON" },
	{ prefix = "MultiBarRightButton", kind = "fixed", page = "RIGHT_ACTIONBAR_PAGE", command = "MULTIACTIONBAR3BUTTON" },
	{ prefix = "MultiBarLeftButton", kind = "fixed", page = "LEFT_ACTIONBAR_PAGE", command = "MULTIACTIONBAR4BUTTON" },
}
SmartCast.BARS = BARS

local CLICK_PRE = [[
	local kind, slot = self:GetAttribute("smartcast-kind")
	if kind == "fixed" then
		slot = self:GetAttribute("smartcast-slot")
	elseif kind == "attr" then
		slot = self:GetAttribute("action")
	elseif kind then
		-- NUMBER maps "0".."6" to numbers, without relying on tonumber here
		local page = NUMBER[SecureCmdOptionParse("[actionbar:2]2;[actionbar:3]3;[actionbar:4]4;[actionbar:5]5;[actionbar:6]6;1")]
		local offset = NUMBER[SecureCmdOptionParse("[bonusbar:1]1;[bonusbar:2]2;[bonusbar:3]3;[bonusbar:4]4;0")]
		if kind == "bonus" and page == 1 and offset > 0 then
			slot = (NUM_PAGES + offset - 1) * 12 + self:GetID()
		else
			slot = (page - 1) * 12 + self:GetID()
		end
	end
	local mode = slot and MODE and MODE[slot]
	if not mode then return end
	local unit
	if FOCUS_MOD then unit = SecureCmdOptionParse(FOCUS_MOD) end
	if not unit then
		if mode == "help" then
			if button == "RightButton" or (SELF_MOD and SecureCmdOptionParse(SELF_MOD)) then
				unit = "player"
			else
				unit = SecureCmdOptionParse("[target=mouseover,help]mouseover")
			end
		else
			unit = SecureCmdOptionParse("[target=mouseover,harm,nodead]mouseover")
		end
	end
	if not unit or unit == "" then return end
	self:SetAttribute("smartcast-prev", self:GetAttribute("unit"))
	self:SetAttribute("unit", unit)
	return button, "restore"
]]

-- Puts back whatever unit the button had (Bartender4's auto-assist uses it).
local CLICK_POST = [[
	self:SetAttribute("unit", self:GetAttribute("smartcast-prev"))
]]

-- Rebinds the keys of the Blizzard bars to clicks on their buttons. STATE comes
-- from the state driver: on the stance bar the main keys go to the bonus
-- buttons, and in a vehicle the game's own bindings are left alone.
local BIND = [[
	self:ClearBindings()
	if STATE == "vehicle" or not ENABLED or not NKEYS then return end
	for i = 1, NKEYS do
		local target = TARGET[i]
		if target == "MAIN" then
			target = (STATE == "bonus" and "BonusActionButton" or "ActionButton") .. ID[i]
		end
		self:SetBindingClick(false, KEY[i], target)
	end
]]

local BAR_STATE = "[vehicleui][bonusbar:5] vehicle; [actionbar:1,bonusbar:1][actionbar:1,bonusbar:2][actionbar:1,bonusbar:3][actionbar:1,bonusbar:4] bonus; normal"

SmartCast.snippets = { CLICK_PRE = CLICK_PRE, CLICK_POST = CLICK_POST, BIND = BIND, BAR_STATE = BAR_STATE }

local header
local buttons = {} -- every wrapped button, in order
local wrapped = {}

local function Wrap(button, kind, slot)
	if not button or wrapped[button] then return end
	button:SetAttribute("smartcast-kind", kind)
	button:SetAttribute("smartcast-slot", slot)
	header:WrapScript(button, "OnClick", CLICK_PRE, CLICK_POST)
	wrapped[button] = true
	buttons[#buttons + 1] = button
end

local function WrapButtons()
	for _, bar in ipairs(BARS) do
		for i = 1, 12 do
			local page = bar.page and _G[bar.page]
			Wrap(_G[bar.prefix .. i], bar.kind, page and ((page - 1) * 12 + i))
		end
	end
	for i = 1, NUM_SLOTS do Wrap(_G["BT4Button" .. i], "attr") end
end

-- The wrapped buttons, for the markers and the selection mode.
function SmartCast.Buttons()
	return buttons
end

-- Slot shown by a button right now (insecure code, for the visuals).
function SmartCast.ButtonSlot(button)
	if button:GetAttribute("smartcast-kind") == "attr" then return button:GetAttribute("action") end
	return button.action or (ActionButton_CalculateAction and ActionButton_CalculateAction(button))
end

local function UsesBartender()
	return IsAddOnLoaded("Bartender4")
end

local function Modifier(mod, body)
	if mod == "none" then return "nil" end
	return ("%q"):format(body:format(mod))
end

-- Everything the snippets read, as one block of restricted code.
local function BuildEnvironment()
	local db = SmartCastDB
	local code = {
		"MODE = newtable()",
		"NUMBER = newtable()",
		'for i = 0, 6 do NUMBER["" .. i] = i end',
		("NUM_PAGES = %d"):format(NUM_ACTIONBAR_PAGES or 6),
		("ENABLED = %s"):format(db.enabled and "true" or "false"),
		"SELF_MOD = " .. Modifier(db.selfMod, "[mod:%s]1"),
		"FOCUS_MOD = " .. Modifier(db.focusMod, "[mod:%s,target=focus,exists,nodead]focus"),
	}
	if db.enabled then
		for slot = 1, NUM_SLOTS do
			local mode = SmartCast.ModeFor(slot)
			if mode then code[#code + 1] = ("MODE[%d] = %q"):format(slot, mode) end
		end
	end
	code[#code + 1] = "KEY, TARGET, ID = newtable(), newtable(), newtable()"
	local n = 0
	if not UsesBartender() then
		for _, bar in ipairs(BARS) do
			if bar.command then
				for i = 1, 12 do
					for _, key in ipairs({ GetBindingKey(bar.command .. i) }) do
						n = n + 1
						local target = bar.kind == "main" and "MAIN" or (bar.prefix .. i)
						code[#code + 1] = ("KEY[%d], TARGET[%d], ID[%d] = %q, %q, %d"):format(n, n, n, key, target, i)
					end
				end
			end
		end
	end
	code[#code + 1] = ("NKEYS = %d"):format(n)
	return table.concat(code, "\n")
end
SmartCast.BuildEnvironment = BuildEnvironment

---------------------------------------------------------------- refresh

local lastEnvironment
local pending

-- Recomputes the marked slots and the bindings. Out of combat only: in combat
-- it waits for the end of the fight (what is on the bars can't change then).
function SmartCast.Refresh()
	if not header then return end
	if InCombatLockdown() then pending = true return end
	pending = nil
	WrapButtons()
	local env = BuildEnvironment()
	-- our own override bindings fire UPDATE_BINDINGS: only redo real changes
	if env ~= lastEnvironment then
		header:Execute(env .. "\n" .. BIND)
		lastEnvironment = env
	end
	if SmartCast.UpdateMarkers then SmartCast.UpdateMarkers() end
end

-- Several events arrive together (a spec switch changes 100+ slots): refresh
-- once, a moment after the last one.
local throttle = CreateFrame("Frame")
throttle:Hide()
throttle:SetScript("OnUpdate", function(self, elapsed)
	self.wait = (self.wait or 0) - elapsed
	if self.wait > 0 then return end
	self:Hide()
	SmartCast.Refresh()
end)

function SmartCast.RefreshSoon()
	throttle.wait = 0.3
	throttle:Show()
end

function SmartCast.SetEnabled(on)
	SmartCastDB.enabled = on and true or false
	SmartCast.Refresh()
	Print(on and L["On: marked spells follow your mouse."] or L["Off: your bars work as usual."])
end

local function Setup()
	header = CreateFrame("Frame", "SmartCastHeader", UIParent, "SecureHandlerStateTemplate")
	header:SetAttribute("_onstate-bar", "STATE = newstate\n" .. BIND)
	RegisterStateDriver(header, "bar", BAR_STATE)
	SmartCast.header = header
	SmartCast.RefreshSoon()
end

local events = CreateFrame("Frame")
events:SetScript("OnEvent", function(self, event, arg1)
	if event == "ADDON_LOADED" then
		if arg1 ~= "SmartCast" then return end
		InitDB()
		self:UnregisterEvent("ADDON_LOADED")
		if SmartCast.CreateLauncher then SmartCast.CreateLauncher() end
	elseif event == "PLAYER_LOGIN" then
		-- a /reload in combat: secure frames can only be set up after the fight
		if InCombatLockdown() then self.setupPending = true else Setup() end
	elseif event == "PLAYER_REGEN_ENABLED" then
		if self.setupPending then self.setupPending = nil Setup() end
		if pending then SmartCast.Refresh() end
	else
		SmartCast.RefreshSoon()
	end
end)
for _, e in ipairs({ "ADDON_LOADED", "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_ENABLED",
	"ACTIONBAR_SLOT_CHANGED", "UPDATE_BINDINGS", "ACTIVE_TALENT_GROUP_CHANGED", "LEARNED_SPELL_IN_TAB" }) do
	events:RegisterEvent(e)
end
