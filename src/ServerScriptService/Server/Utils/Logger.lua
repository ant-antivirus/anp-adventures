local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local LogConfig = require(Shared.Config.LogConfig)

local Logger = {}

local VALID_LEVELS = {
	Silent = true,
	Normal = true,
	Verbose = true,
}

local function getLevel()
	if VALID_LEVELS[LogConfig.Level] then
		return LogConfig.Level
	end

	return "Normal"
end

local function isSilent()
	return getLevel() == "Silent"
end

local function isVerbose()
	return getLevel() == "Verbose"
end

local function shouldLog(flagName)
	if isSilent() then
		return false
	end

	if isVerbose() then
		return true
	end

	return LogConfig[flagName] == true
end

function Logger.Info(category, message)
	if isSilent() then
		return
	end

	print("[ANP " .. tostring(category) .. "] " .. tostring(message))
end

function Logger.Warn(category, message)
	warn("[ANP " .. tostring(category) .. "] " .. tostring(message))
end

function Logger.Debug(category, message)
	if shouldLog("EnableVisibilityDebugLogs") then
		print("[ANP " .. tostring(category) .. "] " .. tostring(message))
	end
end

function Logger.Analytics(message)
	if shouldLog("EnableAnalyticsLogs") then
		print("[ANP Analytics] " .. tostring(message))
	end
end

function Logger.PromptSuccess(message)
	if shouldLog("EnablePromptSuccessLogs") then
		print("[ANP PromptBindingService] " .. tostring(message))
	end
end

function Logger.PromptFailure(message)
	if LogConfig.EnablePromptFailureLogs ~= false then
		warn("[ANP PromptBindingService] " .. tostring(message))
	end
end

function Logger.Smoke(message)
	if LogConfig.EnableSmokeTestLogs ~= false then
		print(tostring(message))
	end
end

function Logger.Guidance(message)
	if shouldLog("EnableGuidanceLogs") then
		print("[ANP Guidance] " .. tostring(message))
	end
end

function Logger.ObjectStateDebug(message)
	if shouldLog("EnableObjectStateDebugLogs") then
		print("[ANP ObjectStateDebug] " .. tostring(message))
	end
end

function Logger.Bootstrap(message)
	if isSilent() then
		return
	end

	if LogConfig.EnableBootstrapSummary ~= false then
		print("[ANP] " .. tostring(message))
	end
end

return Logger
