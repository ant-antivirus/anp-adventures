local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Definitions = Shared:WaitForChild("Definitions")
local Config = Shared:WaitForChild("Config")

local Logger = require(script.Parent.Utils.Logger)
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
local InteractionVisibilityService = require(script.Parent.Services.InteractionVisibilityService)
local GuidanceService = require(script.Parent.Services.GuidanceService)
local AnalyticsService = require(script.Parent.Services.AnalyticsService)
local PlayerFeedbackService = require(script.Parent.Services.PlayerFeedbackService)
local QuestTrackerService = require(script.Parent.Services.QuestTrackerService)
local WorldObjectValidator = require(script.Parent.Validators.WorldObjectValidator)
local InteractionValidator = require(script.Parent.Validators.InteractionValidator)
local SkeletonWorldBuilder = require(script.Parent.Tools.SkeletonWorldBuilder)
local Phase2SmokeTest = require(script.Parent.Tests.Phase2SmokeTest)
local Phase3ASmokeTest = require(script.Parent.Tests.Phase3ASmokeTest)
local Phase3BSmokeTest = require(script.Parent.Tests.Phase3BSmokeTest)
local Phase3CSmokeTest = require(script.Parent.Tests.Phase3CSmokeTest)
local Phase3DSmokeTest = require(script.Parent.Tests.Phase3DSmokeTest)
local Phase3ESmokeTest = require(script.Parent.Tests.Phase3ESmokeTest)
local Phase3FSmokeTest = require(script.Parent.Tests.Phase3FSmokeTest)
local Phase3FBSmokeTest = require(script.Parent.Tests.Phase3FBSmokeTest)
local Phase3FBBugfixSmokeTest = require(script.Parent.Tests.Phase3FBBugfixSmokeTest)
local DeveloperWorldUXSmokeTest = require(script.Parent.Tests.DeveloperWorldUXSmokeTest)
local Phase3FCSmokeTest = require(script.Parent.Tests.Phase3FCSmokeTest)
local Phase3FDSmokeTest = require(script.Parent.Tests.Phase3FDSmokeTest)
local DiscoveryBridgeRegressionSmokeTest = require(script.Parent.Tests.DiscoveryBridgeRegressionSmokeTest)
local Phase3G1SmokeTest = require(script.Parent.Tests.Phase3G1SmokeTest)
local FutureProofSmokeTest = require(script.Parent.Tests.FutureProofSmokeTest)
local Phase3G2SmokeTest = require(script.Parent.Tests.Phase3G2SmokeTest)
local Phase3G3SmokeTest = require(script.Parent.Tests.Phase3G3SmokeTest)
local Phase3G4SmokeTest = require(script.Parent.Tests.Phase3G4SmokeTest)
local Phase3HPlaytestPolishSmokeTest = require(script.Parent.Tests.Phase3HPlaytestPolishSmokeTest)
local Phase4AFeedbackSmokeTest = require(script.Parent.Tests.Phase4AFeedbackSmokeTest)
local Phase4BObjectStateSmokeTest = require(script.Parent.Tests.Phase4BObjectStateSmokeTest)
local Phase4CQuestTrackerSmokeTest = require(script.Parent.Tests.Phase4CQuestTrackerSmokeTest)

local EpisodeDefinitions = require(Definitions.EpisodeDefinitions)
local ZoneDefinitions = require(Definitions.ZoneDefinitions)
local QuestDefinitions = require(Definitions.QuestDefinitions)
local RewardDefinitions = require(Definitions.RewardDefinitions)
local ItemDefinitions = require(Definitions.ItemDefinitions)
local DiscoveryDefinitions = require(Definitions.DiscoveryDefinitions)
local LoreDefinitions = require(Definitions.LoreDefinitions)
local JournalDefinitions = require(Definitions.JournalDefinitions)
local InteractionDefinitions = require(Definitions.InteractionDefinitions)

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
	Interactions = InteractionDefinitions,
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

PlayerFeedbackService.Init()

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
	PlayerFeedbackService = PlayerFeedbackService,
})

EpisodeService.Init({
	PlayerDataService = PlayerDataService,
})

ZoneService.Init({
	PlayerDataService = PlayerDataService,
	AnalyticsService = AnalyticsService,
})

DiscoveryService.Init({
	PlayerDataService = PlayerDataService,
	RewardService = RewardService,
	ZoneService = ZoneService,
	AnalyticsService = AnalyticsService,
})

QuestService.Init({
	PlayerDataService = PlayerDataService,
	RewardService = RewardService,
	EpisodeService = EpisodeService,
	AnalyticsService = AnalyticsService,
	PlayerFeedbackService = PlayerFeedbackService,
})

QuestTrackerService.Init({
	PlayerDataService = PlayerDataService,
	QuestService = QuestService,
	EpisodeService = EpisodeService,
	PlayerFeedbackService = PlayerFeedbackService,
})

GuidanceService.Init({
	PlayerDataService = PlayerDataService,
	QuestService = QuestService,
	AnalyticsService = AnalyticsService,
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
	GuidanceService = GuidanceService,
	PlayerFeedbackService = PlayerFeedbackService,
})

PromptBindingService.Init({
	WorldRegistryService = WorldRegistryService,
	InteractionService = InteractionService,
	PlayerFeedbackService = PlayerFeedbackService,
})

InteractionVisibilityService.Initialize({
	PlayerDataService = PlayerDataService,
	QuestService = QuestService,
	DiscoveryService = DiscoveryService,
	ZoneService = ZoneService,
	PromptBindingService = PromptBindingService,
})

PromptBindingService.SetInteractionVisibilityService(InteractionVisibilityService)
InteractionService.SetInteractionVisibilityService(InteractionVisibilityService)
InteractionService.SetQuestTrackerService(QuestTrackerService)
QuestService.SetInteractionVisibilityService(InteractionVisibilityService)
QuestService.SetQuestTrackerService(QuestTrackerService)
DiscoveryService.SetInteractionVisibilityService(InteractionVisibilityService)
ZoneService.SetInteractionVisibilityService(InteractionVisibilityService)
ZoneService.SetQuestTrackerService(QuestTrackerService)

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

print("[ANP] Phase 2, Phase 3A, Phase 3B, Phase 3C, Phase 3D, Phase 3E, Phase 3F-A, Phase 3F-B, Phase 3F-C, Phase 3F-D, Phase 3G-1, Phase 3G-2, Phase 3G-3, Phase 3G-4, Phase 3H, Phase 4A, Phase 4B, and Phase 4C services initialized.")

if RunService:IsStudio() then
	local passedSmokeTests = {}

	Phase2SmokeTest.Run({
		PlayerDataService = PlayerDataService,
		ProgressionService = ProgressionService,
		InventoryService = InventoryService,
		RewardService = RewardService,
	})
	table.insert(passedSmokeTests, "Phase2SmokeTest")

	Phase3ASmokeTest.Run({
		PlayerDataService = PlayerDataService,
		ProgressionService = ProgressionService,
		EpisodeService = EpisodeService,
		ZoneService = ZoneService,
		DiscoveryService = DiscoveryService,
	})
	table.insert(passedSmokeTests, "Phase3ASmokeTest")

	Phase3BSmokeTest.Run({
		PlayerDataService = PlayerDataService,
		ProgressionService = ProgressionService,
		InventoryService = InventoryService,
		QuestService = QuestService,
	})
	table.insert(passedSmokeTests, "Phase3BSmokeTest")

	Phase3CSmokeTest.Run({
		SkeletonWorldBuilder = SkeletonWorldBuilder,
		WorldRegistryService = WorldRegistryService,
		WorldObjectValidator = WorldObjectValidator,
	})
	table.insert(passedSmokeTests, "Phase3CSmokeTest")

	Phase3DSmokeTest.Run({
		PlayerDataService = PlayerDataService,
		QuestService = QuestService,
		ZoneService = ZoneService,
		InteractionService = InteractionService,
		InteractionValidator = InteractionValidator,
		SkeletonWorldBuilder = SkeletonWorldBuilder,
		WorldRegistryService = WorldRegistryService,
	})
	table.insert(passedSmokeTests, "Phase3DSmokeTest")

	Phase3ESmokeTest.Run({
		PlayerDataService = PlayerDataService,
		QuestService = QuestService,
		ZoneService = ZoneService,
		PromptBindingService = PromptBindingService,
		SkeletonWorldBuilder = SkeletonWorldBuilder,
		WorldRegistryService = WorldRegistryService,
	})
	table.insert(passedSmokeTests, "Phase3ESmokeTest")

	Phase3FSmokeTest.Run({
		PlayerDataService = PlayerDataService,
		QuestService = QuestService,
		PromptBindingService = PromptBindingService,
		SkeletonWorldBuilder = SkeletonWorldBuilder,
		WorldRegistryService = WorldRegistryService,
	})
	table.insert(passedSmokeTests, "Phase3FSmokeTest")

	Phase3FBSmokeTest.Run({
		PlayerDataService = PlayerDataService,
		QuestService = QuestService,
		DiscoveryService = DiscoveryService,
		ZoneService = ZoneService,
		InteractionVisibilityService = InteractionVisibilityService,
		PromptBindingService = PromptBindingService,
		SkeletonWorldBuilder = SkeletonWorldBuilder,
		WorldRegistryService = WorldRegistryService,
	})
	table.insert(passedSmokeTests, "Phase3FBSmokeTest")

	Phase3FBBugfixSmokeTest.Run({
		PlayerDataService = PlayerDataService,
		QuestService = QuestService,
		InteractionVisibilityService = InteractionVisibilityService,
		PromptBindingService = PromptBindingService,
		SkeletonWorldBuilder = SkeletonWorldBuilder,
		WorldRegistryService = WorldRegistryService,
	})
	table.insert(passedSmokeTests, "Phase3FBBugfixSmokeTest")

	DeveloperWorldUXSmokeTest.Run({
		PlayerDataService = PlayerDataService,
		QuestService = QuestService,
		PromptBindingService = PromptBindingService,
		SkeletonWorldBuilder = SkeletonWorldBuilder,
		WorldRegistryService = WorldRegistryService,
	})
	table.insert(passedSmokeTests, "DeveloperWorldUXSmokeTest")

	Phase3FCSmokeTest.Run({
		PlayerDataService = PlayerDataService,
		QuestService = QuestService,
		GuidanceService = GuidanceService,
		InteractionService = InteractionService,
		InteractionValidator = InteractionValidator,
		PromptBindingService = PromptBindingService,
		SkeletonWorldBuilder = SkeletonWorldBuilder,
		WorldRegistryService = WorldRegistryService,
	})
	table.insert(passedSmokeTests, "Phase3FCSmokeTest")

	Phase3FDSmokeTest.Run({
		PlayerDataService = PlayerDataService,
		QuestService = QuestService,
		InteractionValidator = InteractionValidator,
		InteractionVisibilityService = InteractionVisibilityService,
		PromptBindingService = PromptBindingService,
		SkeletonWorldBuilder = SkeletonWorldBuilder,
		WorldRegistryService = WorldRegistryService,
	})
	table.insert(passedSmokeTests, "Phase3FDSmokeTest")

	DiscoveryBridgeRegressionSmokeTest.Run({
		PlayerDataService = PlayerDataService,
		QuestService = QuestService,
		DiscoveryService = DiscoveryService,
		InteractionService = InteractionService,
		InteractionVisibilityService = InteractionVisibilityService,
		PromptBindingService = PromptBindingService,
		SkeletonWorldBuilder = SkeletonWorldBuilder,
		WorldRegistryService = WorldRegistryService,
	})
	table.insert(passedSmokeTests, "DiscoveryBridgeRegressionSmokeTest")

	Phase3G1SmokeTest.Run({
		PlayerDataService = PlayerDataService,
		QuestService = QuestService,
		InteractionValidator = InteractionValidator,
		InteractionVisibilityService = InteractionVisibilityService,
		PromptBindingService = PromptBindingService,
		SkeletonWorldBuilder = SkeletonWorldBuilder,
		WorldRegistryService = WorldRegistryService,
	})
	table.insert(passedSmokeTests, "Phase3G1SmokeTest")

	FutureProofSmokeTest.Run({
		AnalyticsService = AnalyticsService,
		PlayerDataService = PlayerDataService,
		QuestService = QuestService,
		DiscoveryService = DiscoveryService,
		ZoneService = ZoneService,
		GuidanceService = GuidanceService,
		InteractionService = InteractionService,
		DefinitionValidator = DefinitionValidator,
		SkeletonWorldBuilder = SkeletonWorldBuilder,
		WorldRegistryService = WorldRegistryService,
		BadgeConfig = BadgeConfig,
		CompanionConfig = CompanionConfig,
	})
	table.insert(passedSmokeTests, "FutureProofSmokeTest")

	Phase3G2SmokeTest.Run({
		AnalyticsService = AnalyticsService,
		PlayerDataService = PlayerDataService,
		QuestService = QuestService,
		InventoryService = InventoryService,
		ZoneService = ZoneService,
		InteractionValidator = InteractionValidator,
		InteractionVisibilityService = InteractionVisibilityService,
		PromptBindingService = PromptBindingService,
		SkeletonWorldBuilder = SkeletonWorldBuilder,
		WorldRegistryService = WorldRegistryService,
	})
	table.insert(passedSmokeTests, "Phase3G2SmokeTest")

	Phase3G3SmokeTest.Run({
		AnalyticsService = AnalyticsService,
		PlayerDataService = PlayerDataService,
		QuestService = QuestService,
		InventoryService = InventoryService,
		ZoneService = ZoneService,
		InteractionValidator = InteractionValidator,
		InteractionVisibilityService = InteractionVisibilityService,
		PromptBindingService = PromptBindingService,
		SkeletonWorldBuilder = SkeletonWorldBuilder,
		WorldRegistryService = WorldRegistryService,
	})
	table.insert(passedSmokeTests, "Phase3G3SmokeTest")

	Phase3G4SmokeTest.Run({
		AnalyticsService = AnalyticsService,
		PlayerDataService = PlayerDataService,
		QuestService = QuestService,
		InventoryService = InventoryService,
		ZoneService = ZoneService,
		EpisodeService = EpisodeService,
		InteractionValidator = InteractionValidator,
		InteractionVisibilityService = InteractionVisibilityService,
		PromptBindingService = PromptBindingService,
		SkeletonWorldBuilder = SkeletonWorldBuilder,
		WorldRegistryService = WorldRegistryService,
	})
	table.insert(passedSmokeTests, "Phase3G4SmokeTest")

	Phase3HPlaytestPolishSmokeTest.Run({
		PlayerDataService = PlayerDataService,
		InventoryService = InventoryService,
		EpisodeService = EpisodeService,
		ZoneService = ZoneService,
		InteractionVisibilityService = InteractionVisibilityService,
		PromptBindingService = PromptBindingService,
		SkeletonWorldBuilder = SkeletonWorldBuilder,
		WorldRegistryService = WorldRegistryService,
	})
	table.insert(passedSmokeTests, "Phase3HPlaytestPolishSmokeTest")

	Phase4AFeedbackSmokeTest.Run({
		PlayerDataService = PlayerDataService,
		InventoryService = InventoryService,
		PlayerFeedbackService = PlayerFeedbackService,
		PromptBindingService = PromptBindingService,
		InteractionService = InteractionService,
		SkeletonWorldBuilder = SkeletonWorldBuilder,
		WorldRegistryService = WorldRegistryService,
	})
	table.insert(passedSmokeTests, "Phase4AFeedbackSmokeTest")

	Phase4BObjectStateSmokeTest.Run({
		PlayerDataService = PlayerDataService,
		PlayerFeedbackService = PlayerFeedbackService,
		InteractionService = InteractionService,
		InteractionVisibilityService = InteractionVisibilityService,
		PromptBindingService = PromptBindingService,
		SkeletonWorldBuilder = SkeletonWorldBuilder,
		WorldRegistryService = WorldRegistryService,
	})
	table.insert(passedSmokeTests, "Phase4BObjectStateSmokeTest")

	Phase4CQuestTrackerSmokeTest.Run({
		PlayerDataService = PlayerDataService,
		PlayerFeedbackService = PlayerFeedbackService,
		QuestTrackerService = QuestTrackerService,
		PromptBindingService = PromptBindingService,
		InteractionVisibilityService = InteractionVisibilityService,
		SkeletonWorldBuilder = SkeletonWorldBuilder,
		WorldRegistryService = WorldRegistryService,
	})
	table.insert(passedSmokeTests, "Phase4CQuestTrackerSmokeTest")

	Logger.Smoke("[ANP SmokeTestSummary]")
	Logger.Smoke("Passed:")
	for _, smokeTestName in ipairs(passedSmokeTests) do
		Logger.Smoke("* " .. smokeTestName)
	end
	Logger.Smoke("All Studio smoke tests passed.")
end

local function onPlayerAdded(player)
	local initResult = PlayerDataService.InitPlayer(player)

	if not initResult.Success then
		warn("[ANP] Player data init failed for " .. player.Name .. ": " .. initResult.Code)
		return
	end

	local visibilityResult = InteractionVisibilityService.RefreshPlayer(player)
	if not visibilityResult.Success then
		warn("[ANP] Player interaction visibility refresh failed for " .. player.Name .. ": " .. visibilityResult.Code)
	end

	local trackerResult = QuestTrackerService.SendTrackerUpdate(player)
	if not trackerResult.Success then
		warn("[ANP] Quest tracker update failed for " .. player.Name .. ": " .. trackerResult.Code)
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
