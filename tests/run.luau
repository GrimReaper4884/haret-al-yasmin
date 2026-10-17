--!nocheck
-- Unit-test runner for pure modules (src/shared/Logic, src/shared/Config). Run from repo root:
--   lune run tests/run
-- Logic modules resolve siblings through _G.LogicRequire when running here.

local process = require("@lune/process")

local LOGIC = "../src/shared/Logic/"
local CONFIG = "../src/shared/Config/"

local cache = {}
_G.LogicRequire = function(name)
	if cache[name] == nil then
		cache[name] = require(LOGIC .. name)
	end
	return cache[name]
end

local function config(name)
	return require(CONFIG .. name)
end

-- Minimal test framework -------------------------------------------------------------------

local passed, failed = 0, 0
local failures = {}
local currentSuite = ""

local function fmt(v)
	if type(v) == "string" then
		return string.format("%q", v)
	end
	return tostring(v)
end

local t = {}

function t.describe(name, fn)
	currentSuite = name
	fn()
end

function t.it(name, fn)
	local ok, err = pcall(fn)
	if ok then
		passed += 1
	else
		failed += 1
		table.insert(failures, currentSuite .. " › " .. name .. "\n      " .. tostring(err))
	end
end

function t.eq(actual, expected, msg)
	if actual ~= expected then
		error((msg or "values differ") .. ": expected " .. fmt(expected) .. ", got " .. fmt(actual), 2)
	end
end

function t.truthy(v, msg)
	if not v then
		error(msg or ("expected truthy, got " .. fmt(v)), 2)
	end
end

function t.deepCopy(v)
	if type(v) ~= "table" then
		return v
	end
	local o = {}
	for k, x in pairs(v) do
		o[k] = t.deepCopy(x)
	end
	return o
end

function t.deepEq(a, b)
	if type(a) ~= type(b) then
		return false
	end
	if type(a) ~= "table" then
		return a == b
	end
	for k, v in pairs(a) do
		if not t.deepEq(v, b[k]) then
			return false
		end
	end
	for k in pairs(b) do
		if a[k] == nil then
			return false
		end
	end
	return true
end

t.logic = _G.LogicRequire
t.config = config

-- A full ProfileSchema context (overrides merged in), so specs don't repeat it.
function t.schemaCtx(over)
	local Economy, Items, Units, Traits, TD = config("Economy"), config("Items"), config("Units"), config("Traits"), config("TD")
	local ctx = {
		schemaVersion = Economy.SCHEMA_VERSION,
		maxQirsh = Economy.MAX_QIRSH,
		maxLira = TD.MAX_LIRA,
		maxStones = TD.MAX_TRAIT_STONES,
		receiptHistory = Economy.RECEIPT_HISTORY,
		ledgerSize = Economy.LEDGER_SIZE,
		items = Items,
		units = Units,
		traits = Traits.traits,
		starterUnit = TD.STARTER_UNIT,
		season = "s1",
	}
	for k, v in pairs(over or {}) do
		ctx[k] = v
	end
	return ctx
end

-- Specs ----------------------------------------------------------------------------------

local specs = {
	require("./logic.spec"),
	require("./profile.spec"),
	require("./config.spec"),
	require("./season1.spec"),
	require("./monetization.spec"),
	require("./td.spec"),
	require("./meta.spec"),
	require("./settings.spec"),
	require("./party.spec"),
	require("./event.spec"),
	require("./afk.spec"),
	require("./ledger.spec"),
}
for _, spec in specs do
	spec(t)
end

print(string.format("\n%d passed, %d failed", passed, failed))
for _, f in failures do
	print("  ✗ " .. f)
end
process.exit(if failed == 0 then 0 else 1)
