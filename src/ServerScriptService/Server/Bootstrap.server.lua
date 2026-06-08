local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Definitions = Shared:WaitForChild("Definitions")
local Config = Shared:WaitForChild("Config")

local DefinitionValidator = require(script.Parent.Validators.DefinitionValidator)
local PlayerDataService = require(script.Parent.Services.PlayerDataService)
local ProgressionService = require(script.Parent.Services.ProgressionService)
local InventoryService = require(script.Parent.Services.InventoryService)
local RewardService = require(script.Parent.Services.RewardService)
local EpisodeService = require(script.Parent.Services.EpisodeService)
local ZoneService = require(script.Parent.Services.ZoneService)
local DiscoveryService = require(script.Parent.Services.DiscoveryService)
local QuestService = require(script.Parent.Services.QuestService)
local WorldRegistryService = require(script.Parent.Services.WorldRegistryService)
local InteractionService = require(script.Parent.Services.InteractionService)
local PromptBindingService = require(script.Parent.Services.PromptBindingService)
local WorldObjectValidator = require(script.Parent.Validators.WorldObjectValidator)
local InteractionValidator = require(script.Parent.Validators.InteractionValidator)
local SkeletonWorldBuilder = require(script.Parent.Tools.SkeletonWorldBuilder)
local Phase2SmokeTest = require(script.Parent.Tests.Phase2SmokeTest)
local Phase3ASmokeTest = require(script.Parent.Tests.Phase3ASmokeTest)
local Phase3BSmokeTest = require(script.Parent.Tests.Phase3BSmokeTest)
local Phase3CSmokeTest = require(script.Parent.Tests.Phase3CSmokeTest)
local Phase3DSmokeTest = require(script.Parent.Tests.Phase3DSmokeTest)
local Phase3ESmokeTest = require(script.Parent.Tests.Phase3ESmokeTest)

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

if RunService:IsStudio() then
	PlayerDataService.ResetForTests()
end

ProgressionService.Init({
	PlayerDataService = PlayerDataService,
})

InventoryService.Init({
	PlayerDataService = PlayerDataService,
})

RewardService.Init({
	PlayerDataService = PlayerDataService,
	ProgressionService = ProgressionService,
	InventoryService = InventoryService,
})

EpisodeService.Init({
	PlayerDataService = PlayerDataService,
})

ZoneService.Init({
	PlayerDataService = PlayerDataService,
})

DiscoveryService.Init({
	PlayerDataService = PlayerDataService,
	RewardService = RewardService,
	ZoneService = ZoneService,
})

QuestService.Init({
	PlayerDataService = PlayerDataService,
	RewardService = RewardService,
	EpisodeService = EpisodeService,
})

local worldRegistryResult = WorldRegistryService.Init()
if not worldRegistryResult.Success then
	if RunService:IsStudio() then
		warn("[ANP] World registry init warning: " .. worldRegistryResult.Code .. ". Studio smoke test may build the skeleton world.")
	else
		error("[ANP] World registry initialization failed: " .. worldRegistryResult.Code)
	end
end

InteractionService.Init({
	PlayerDataService = PlayerDataService,
	WorldRegistryService = WorldRegistryService,
	QuestService = QuestService,
	DiscoveryService = DiscoveryService,
	ZoneService = ZoneService,
})

PromptBindingService.Init({
	WorldRegistryService = WorldRegistryService,
	InteractionService = InteractionService,
})

if worldRegistryResult.Success then
	local promptBindingResult = PromptBindingService.BindAllPrompts()
	if not promptBindingResult.Success then
		for _, promptError in ipairs(promptBindingResult.Data.Errors or {}) do
			warn("[ANP] Prompt binding failed for " .. promptError.InteractionId .. ": " .. promptError.Code)
		end

		if not RunService:IsStudio() then
			error("[ANP] Prompt binding failed in production server bootstrap.")
		end
	end
end

print("[ANP] Phase 2, Phase 3A, Phase 3B, Phase 3C, Phase 3D, and Phase 3E services initialized.")

if RunService:IsStudio() then
	Phase2SmokeTest.Run({
		PlayerDataService = PlayerDataService,
		ProgressionService = ProgressionService,
		InventoryService = InventoryService,
		RewardService = RewardService,
	})

	Phase3ASmokeTest.Run({
		PlayerDataService = PlayerDataService,
		ProgressionService = ProgressionService,
		EpisodeService = EpisodeService,
		ZoneService = ZoneService,
		DiscoveryService = DiscoveryService,
	})

	Phase3BSmokeTest.Run({
		PlayerDataService = PlayerDataService,
		ProgressionService = ProgressionService,
		InventoryService = InventoryService,
		QuestService = QuestService,
	})

	Phase3CSmokeTest.Run({
		SkeletonWorldBuilder = SkeletonWorldBuilder,
		WorldRegistryService = WorldRegistryService,
		WorldObjectValidator = WorldObjectValidator,
	})

	Phase3DSmokeTest.Run({
		PlayerDataService = PlayerDataService,
		QuestService = QuestService,
		ZoneService = ZoneService,
		InteractionService = InteractionService,
		InteractionValidator = InteractionValidator,
		SkeletonWorldBuilder = SkeletonWorldBuilder,
		WorldRegistryService = WorldRegistryService,
	})

	Phase3ESmokeTest.Run({
		PlayerDataService = PlayerDataService,
		QuestService = QuestService,
		ZoneService = ZoneService,
		PromptBindingService = PromptBindingService,
		SkeletonWorldBuilder = SkeletonWorldBuilder,
		WorldRegistryService = WorldRegistryService,
	})
end

local function onPlayerAdded(player)
	local initResult = PlayerDataService.InitPlayer(player)

	if not initResult.Success then
		warn("[ANP] Player data init failed for " .. player.Name .. ": " .. initResult.Code)
		return
	end

	print("[ANP] Player data initialized for " .. player.Name)
end

local function onPlayerRemoving(player)
	local releaseResult = PlayerDataService.ReleasePlayer(player)

	if not releaseResult.Success then
		warn("[ANP] Player data release failed for " .. player.Name .. ": " .. releaseResult.Code)
		return
	end

	print("[ANP] Player data released for " .. player.Name)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end
