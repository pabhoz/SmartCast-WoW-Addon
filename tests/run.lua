-- Smart Cast tests: a simulated 3.3.5a client with a small restricted
-- environment (secure snippets, state driver, override bindings). Run from the
-- addon folder with Lua 5.1:  lua5.1 tests/run.lua   (tests/run.sh does it in Docker)

local passed = 0
local function check(cond, msg)
	if not cond then error("FAIL: " .. msg, 2) end
	passed = passed + 1
	print("ok  " .. msg)
end

---------------------------------------------------------------- world state

local world = { mouseover = nil, focus = nil, mods = {}, page = 1, bonus = 0, vehicle = false, combat = false }
local spells = {
	Fireball = { kind = "harm", range = 1 },
	Polymorph = { kind = "harm", range = 1 },
	["Heroic Strike"] = { kind = "harm", range = 1 },
	["Flash Heal"] = { kind = "help", range = 1 },
	["Ice Barrier"] = { kind = "help" }, -- self only: no range
	Resurrection = { kind = "help", range = 1 },
}
local slots = { [1] = "Fireball", [2] = "Flash Heal", [3] = "Ice Barrier", [13] = "Polymorph", [61] = "Polymorph", [73] = "Heroic Strike" }
local bindings = { ACTIONBUTTON1 = { "1" }, ACTIONBUTTON2 = { "2" }, ACTIONBUTTON3 = { "3" }, MULTIACTIONBAR1BUTTON1 = { "F", "SHIFT-F" } }

---------------------------------------------------------------- stubs

local noop = function() end
local function Stub(t)
	return setmetatable(t or {}, { __index = function() return noop end })
end

local frames = {}
local function NewFrame(name)
	local f = Stub({ attrs = {}, scripts = {}, events = {}, shown = true, name = name, id = 0 })
	function f:SetAttribute(k, v) self.attrs[k] = v end
	function f:GetAttribute(k) return self.attrs[k] end
	function f:SetScript(k, fn) self.scripts[k] = fn end
	function f:RegisterEvent(e) self.events[e] = true end
	function f:UnregisterEvent(e) self.events[e] = nil end
	function f:Hide() self.shown = false end
	function f:Show() self.shown = true end
	function f:IsShown() return self.shown end
	function f:IsVisible() return self.shown end
	function f:GetID() return self.id end
	function f:GetName() return self.name end
	function f:CreateTexture() return Stub({}) end
	function f:CreateFontString() return Stub({}) end
	function f:GetWidth() return 36 end
	function f:GetHeight() return 36 end
	frames[#frames + 1] = f
	if name then _G[name] = f end
	return f
end

-- restricted environment shared by the header's snippets
local env, header, executes, wraps = {}, nil, 0, {}
local overrides = {}

local function UnitIs(unit, cond)
	local who = (unit == "mouseover" and world.mouseover) or (unit == "focus" and world.focus) or (unit == "player" and "self") or nil
	if cond == "exists" then return who ~= nil end
	if cond == "help" then return who == "friend" or who == "deadfriend" or who == "self" end
	if cond == "harm" then return who == "enemy" end
	if cond == "nodead" then return who ~= "deadfriend" end
	error("unknown unit condition " .. cond)
end

local function Condition(c, unit)
	local k, v = c:match("^(%a+):(.+)$")
	if k == "actionbar" then return world.page == tonumber(v) end
	if k == "bonusbar" then return world.bonus == tonumber(v) end
	if k == "mod" then return world.mods[v] == true end
	if c == "vehicleui" then return world.vehicle end
	return UnitIs(unit, c)
end

function env.SecureCmdOptionParse(s)
	for clause in (s .. ";"):gmatch("([^;]*);") do
		local groups = {}
		local value = clause:gsub("%b[]", function(g) groups[#groups + 1] = g:sub(2, -2) return "" end)
		value = value:match("^%s*(.-)%s*$")
		local ok = #groups == 0
		for _, g in ipairs(groups) do
			local unit, all = "target", true
			for c in g:gmatch("[^,]+") do
				c = c:match("^%s*(.-)%s*$")
				local u = c:match("^target=(.+)$")
				if u then unit = u elseif not Condition(c, unit) then all = false end
			end
			if all then ok = true break end
		end
		if ok then return value ~= "" and value or nil end
	end
end
env.newtable = function() return {} end

local function Run(body, ...)
	local fn = assert(loadstring("local self, a1, a2 = ...\n" .. body))
	setfenv(fn, env)
	return fn(...)
end

local function HeaderMethods(h)
	function h:Execute(body) executes = executes + 1 Run(body, self) end
	function h:WrapScript(button, script, pre, post) wraps[button] = { pre = pre, post = post } end
	function h:ClearBindings() overrides = {} end
	function h:SetBindingClick(priority, key, target) overrides[key] = target end
end

local function SetState(state)
	local fn = assert(loadstring("local self, stateid, newstate = ...\n" .. header.attrs["_onstate-bar"]))
	setfenv(fn, env)
	fn(header, "bar", state)
end

local function BarState()
	local s = SmartCast.snippets.BAR_STATE
	return env.SecureCmdOptionParse(s)
end

-- A click as the game does it: the wrapped pre-body, the button resolves its
-- unit, then the post-body. Returns the unit the spell would be cast on.
local function Click(button, mouse)
	local w = assert(wraps[button], "button not wrapped")
	local fn = assert(loadstring("local self, button, down = ...\n" .. w.pre))
	setfenv(fn, env)
	local _, message = fn(button, mouse or "LeftButton")
	local unit = button:GetAttribute("unit")
	if message then
		local post = assert(loadstring("local self, message, button = ...\n" .. w.post))
		setfenv(post, env)
		post(button, message, mouse)
	end
	return unit
end

function CreateFrame(kind, name, parent, template)
	local f = NewFrame(name)
	if template == "SecureHandlerStateTemplate" then HeaderMethods(f) header = f end
	return f
end
function RegisterStateDriver(frame, id, cond) end
function GetLocale() return "enUS" end
function UnitName() return "Tester" end
function GetRealmName() return "Stormrage" end
function GetActiveTalentGroup() return 1 end
function InCombatLockdown() return world.combat end
function IsAddOnLoaded() return false end
function GetActionInfo(slot)
	local name = slots[slot]
	if name then return "spell", 1, "spell", 1000 + slot end
end
function GetSpellInfo(id) return slots[id - 1000] end
function GetSpellName() end
function IsHelpfulSpell(name) return spells[name] and spells[name].kind == "help" and 1 or nil end
function IsHarmfulSpell(name) return spells[name] and spells[name].kind == "harm" and 1 or nil end
function SpellHasRange(name) return spells[name] and spells[name].range end
function GetBindingKey(cmd) return unpack(bindings[cmd] or {}) end
function hooksecurefunc() end
NUM_ACTIONBAR_PAGES, BOTTOMLEFT_ACTIONBAR_PAGE, BOTTOMRIGHT_ACTIONBAR_PAGE, RIGHT_ACTIONBAR_PAGE, LEFT_ACTIONBAR_PAGE = 6, 6, 5, 3, 4
BOOKTYPE_SPELL = "spell"
DEFAULT_CHAT_FRAME = { AddMessage = function(_, m) end }
SlashCmdList = {}
Minimap = Stub({ GetCenter = function() return 0, 0 end })
GameTooltip = Stub({})

for _, bar in ipairs({ "ActionButton", "BonusActionButton", "MultiBarBottomLeftButton", "MultiBarBottomRightButton", "MultiBarRightButton", "MultiBarLeftButton" }) do
	for i = 1, 12 do NewFrame(bar .. i).id = i end
end

for _, file in ipairs({ "Locales.lua", "Core.lua", "Select.lua", "UI.lua" }) do dofile(file) end

local function fire(event, ...)
	for _, f in ipairs(frames) do
		if f.events[event] and f.scripts.OnEvent then f.scripts.OnEvent(f, event, ...) end
	end
end
local function tick()
	for _ = 1, 5 do
		for _, f in ipairs(frames) do
			if f.shown and f.scripts.OnUpdate then f.scripts.OnUpdate(f, 0.1) end
		end
	end
end

fire("ADDON_LOADED", "SmartCast")
fire("PLAYER_LOGIN")
tick()
SetState(BarState())

---------------------------------------------------------------- tests

check(env.MODE[1] == "harm" and env.MODE[2] == "help", "harmful and ranged helpful spells are marked automatically")
check(env.MODE[3] == nil, "self-only buff is not marked")
check(overrides["1"] == "ActionButton1" and overrides["F"] == "MultiBarBottomLeftButton1" and overrides["SHIFT-F"] == "MultiBarBottomLeftButton1", "bar keys rebound to clicks on the buttons")

world.mouseover = "enemy"
check(Click(ActionButton1) == "mouseover", "harmful spell goes to the enemy under the mouse")
check(ActionButton1:GetAttribute("unit") == nil, "unit is restored after the click")
world.mouseover = "friend"
check(Click(ActionButton1) == nil, "harmful spell over a friend keeps the normal target")
check(Click(ActionButton2) == "mouseover", "heal goes to the friend under the mouse")
check(Click(ActionButton2, "RightButton") == "player", "right-click casts the heal on yourself")
world.mods.alt = true
check(Click(ActionButton2) == "player", "self cast key casts the heal on yourself")
world.mods.alt = nil
world.mouseover = "enemy"
check(Click(ActionButton2) == nil, "heal over an enemy keeps the normal target")
world.mouseover = "deadfriend"
check(Click(ActionButton2) == "mouseover", "helpful spells also reach dead friends (resurrections)")
world.mouseover = nil
check(Click(ActionButton1) == nil and Click(ActionButton2) == nil, "without a mouseover the game decides as usual")
check(Click(ActionButton3) == nil, "unmarked spell is untouched")

world.mouseover = "enemy"
check(Click(MultiBarBottomLeftButton1) == "mouseover", "fixed bars use their own slots (61)")

world.page = 2
check(Click(ActionButton1) == "mouseover", "page 2 reads slot 13 (Polymorph)")
world.page = 1

world.bonus = 1
SetState(BarState())
check(overrides["1"] == "BonusActionButton1", "on the stance bar the keys go to the bonus buttons")
check(Click(BonusActionButton1) == "mouseover", "stance bar reads slot 73 (Heroic Strike)")
world.vehicle = true
SetState(BarState())
check(next(overrides) == nil, "in a vehicle the game's own bindings are left alone")
world.vehicle, world.bonus = false, 0
SetState(BarState())
check(overrides["1"] == "ActionButton1", "back on the normal bar after the vehicle")

SmartCastDB.focusMod = "shift"
SmartCast.Refresh()
world.mods.shift, world.focus = true, "enemy"
check(Click(ActionButton1) == "focus", "focus key casts on the focus")
world.mods.shift, world.focus = nil, nil

SmartCast.SetMarked("Fireball", "harm", false)
check(env.MODE[1] == nil and Click(ActionButton1) == nil, "unmarking a spell turns it off")
check(SmartCast.SpecConfig().Fireball == false, "unmarked spell stored")
SmartCast.SetMarked("Fireball", "harm", true)
check(SmartCast.SpecConfig().Fireball == nil and env.MODE[1] == "harm", "marking it again goes back to automatic")

local before = executes
SmartCast.Refresh()
check(executes == before, "nothing changed: no new Execute (no UPDATE_BINDINGS loop)")

world.combat = true
SmartCast.SetMarked("Ice Barrier", "help", true)
check(env.MODE[3] == nil, "in combat the change waits")
world.combat = false
fire("PLAYER_REGEN_ENABLED")
check(env.MODE[3] == "help", "applied after combat")

SmartCast.SetEnabled(false)
check(next(overrides) == nil and env.MODE[1] == nil, "turned off: no bindings, no marked slots")
SmartCast.SetEnabled(true)
check(overrides["1"] == "ActionButton1", "turned on again")

print(("all %d passed"):format(passed))
