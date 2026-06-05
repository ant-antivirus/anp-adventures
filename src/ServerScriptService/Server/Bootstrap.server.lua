local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Definitions = Shared:WaitForChild("Definitions")
local Config = Shared:WaitForChild("Config")

local DefinitionValidator = require(script.Parent.Validators.DefinitionValidator)

local EpisodeDefinitions = require(Definitions.EpisodeDefinitions)
local ZoneDefinitions = require(Definitions.ZoneDefinitions)
local QuestDefinitions = require(Definitions.QuestDefinitions)
local RewardDefinitions = require(Definitions.RewardDefinitions)
local ItemDefinitions = require(Definitions.ItemDefinitions)
local DiscoveryDefinitions = require(Definitions.DiscoveryDefinitions)
local LoreDefinitions = require(Definitions.LoreDefinitions)
local JournalDefinitions = require(Definitions.JournalDefinitions)

local BadgeConfig = require(Config.BadgeConfig)
local CompanionConfig = require(Config.CompanionConfig)

local catalog = {
	Episodes = EpisodeDefinitions,
	Zones = ZoneDefinitions,
	Quests = QuestDefinitions,
	Rewards = RewardDefinitions,
	Items = ItemDefinitions,
	Discoveries = DiscoveryDefinitions,
	Lore = LoreDefinitions,
	Journal = JournalDefinitions,
}

local validationResult = DefinitionValidator.Validate(catalog, {
	BadgeConfig = BadgeConfig,
	CompanionConfig = CompanionConfig,
})

print("[ANP] Server bootstrap loaded.")
print("[ANP] Definition validation summary:")

for category, count in pairs(validationResult.Summary) do
	print(string.format("[ANP]   %s: %d", category, count))
end

if #validationResult.Warnings > 0 then
	warn("[ANP] Definition validation warnings:")
	for _, warningMessage in ipairs(validationResult.Warnings) do
		warn("[ANP]   " .. warningMessage)
	end
end

if not validationResult.Success then
	warn("[ANP] Definition validation errors:")
	for _, errorMessage in ipairs(validationResult.Errors) do
		warn("[ANP]   " .. errorMessage)
	end

	error("[ANP] Definition validation failed. Server bootstrap stopped.")
end

print("[ANP] Definition validation passed.")
