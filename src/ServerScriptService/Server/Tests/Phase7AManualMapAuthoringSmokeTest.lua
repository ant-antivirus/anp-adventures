local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local EpisodeDefinitions = require(Shared.Definitions.EpisodeDefinitions)
local InteractionDefinitions = require(Shared.Definitions.InteractionDefinitions)
local QuestDefinitions = require(Shared.Definitions.QuestDefinitions)
local ZoneDefinitions = require(Shared.Definitions.ZoneDefinitions)
local WorldBuildConfig = require(Shared.Config.WorldBuildConfig)

local Phase7AManualMapAuthoringSmokeTest = {}

local EP1_ID = "ep01_lost_star_core"

local function assertCondition(condition, message)
	if not condition then
		error("[ANP Phase7AManualMapAuthoringSmokeTest] " .. message, 2)
	end
end

local function assertValid(result, message)
	assertCondition(result and result.Success == true, message .. " Errors: " .. table.concat(result and result.Errors or {}, " | "))
end

local function assertInvalid(result, expectedText, message)
	assertCondition(result and result.Success == false, message)
	local combinedErrors = table.concat(result.Errors or {}, " | ")
	assertCondition(string.find(combinedErrors, expectedText, 1, true) ~= nil, message .. " Expected error containing `" .. expectedText .. "`, got `" .. combinedErrors .. "`.")
end

local function getActiveEp1ZoneIds()
	local zoneIds = {}
	local episodeDefinition = EpisodeDefinitions[EP1_ID] or {}
	for _, zoneId in ipairs(episodeDefinition.ZoneIds or episodeDefinition.Zones or {}) do
		local zoneDefinition = ZoneDefinitions[zoneId]
		if zoneDefinition and zoneDefinition.Enabled ~= false and zoneDefinition.Reserved ~= true then
			table.insert(zoneIds, zoneId)
		end
	end
	return zoneIds
end

local function isEp1Interaction(interactionDefinition)
	local zoneDefinition = ZoneDefinitions[interactionDefinition.ZoneId]
	if zoneDefinition and zoneDefinition.EpisodeId == EP1_ID then
		return true
	end

	local questId = interactionDefinition.QuestId
	return questId ~= nil and QuestDefinitions[questId] and QuestDefinitions[questId].EpisodeId == EP1_ID
end

local function makePromptPart(parent)
	local promptPart = Instance.new("Part")
	promptPart.Name = "PromptPart"
	promptPart.Anchored = true
	promptPart.Size = Vector3.new(2, 1, 2)
	promptPart.Parent = parent
	return promptPart
end

local function addInteractionObject(gameplayFolder, interactionId, interactionDefinition)
	local marker = Instance.new("Folder")
	marker.Name = interactionId
	marker:SetAttribute("InteractionId", interactionId)
	marker:SetAttribute("ZoneId", interactionDefinition.ZoneId)
	marker:SetAttribute("ObjectType", interactionDefinition.Type)
	if interactionDefinition.QuestId then
		marker:SetAttribute("QuestId", interactionDefinition.QuestId)
	end
	if interactionDefinition.ObjectiveId then
		marker:SetAttribute("ObjectiveId", interactionDefinition.ObjectiveId)
	end
	if interactionDefinition.DiscoveryId then
		marker:SetAttribute("DiscoveryId", interactionDefinition.DiscoveryId)
	end
	if interactionDefinition.TargetZoneId then
		marker:SetAttribute("TargetZoneId", interactionDefinition.TargetZoneId)
	end
	if interactionDefinition.CharacterId then
		marker:SetAttribute("CharacterId", interactionDefinition.CharacterId)
	end
	makePromptPart(marker)
	marker.Parent = gameplayFolder
	return marker
end

local function createValidMapFixture()
	local worldRoot = Instance.new("Folder")
	worldRoot.Name = "ANP_World"

	local zonesFolder = Instance.new("Folder")
	zonesFolder.Name = "Zones"
	zonesFolder.Parent = worldRoot

	local gameplayByZone = {}
	for _, zoneId in ipairs(getActiveEp1ZoneIds()) do
		local zoneFolder = Instance.new("Folder")
		zoneFolder.Name = zoneId
		zoneFolder:SetAttribute("ZoneId", zoneId)
		zoneFolder.Parent = zonesFolder

		local gameplayFolder = Instance.new("Folder")
		gameplayFolder.Name = "Gameplay"
		gameplayFolder.Parent = zoneFolder
		gameplayByZone[zoneId] = gameplayFolder

		local decorFolder = Instance.new("Folder")
		decorFolder.Name = "Decor"
		decorFolder.Parent = zoneFolder

		local lightingFolder = Instance.new("Folder")
		lightingFolder.Name = "Lighting"
		lightingFolder.Parent = zoneFolder
	end

	for interactionId, interactionDefinition in pairs(InteractionDefinitions) do
		if interactionDefinition.Enabled ~= false and interactionDefinition.EnabledInWorld ~= false and isEp1Interaction(interactionDefinition) then
			local gameplayFolder = gameplayByZone[interactionDefinition.ZoneId]
			if gameplayFolder then
				addInteractionObject(gameplayFolder, interactionId, interactionDefinition)
			end
		end
	end

	return worldRoot
end

local function countDescendants(instance)
	return #instance:GetDescendants()
end

local function findInteractionObject(worldRoot, interactionId)
	for _, descendant in ipairs(worldRoot:GetDescendants()) do
		if descendant:GetAttribute("InteractionId") == interactionId then
			return descendant
		end
	end
	return nil
end

local function removeObjectWithInteractionId(worldRoot, interactionId)
	local object = findInteractionObject(worldRoot, interactionId)
	if object then
		object:Destroy()
	end
end

local function makeStudioRunService(isStudio)
	local fakeRunService = {}
	function fakeRunService:IsStudio()
		return isStudio
	end
	return fakeRunService
end

function Phase7AManualMapAuthoringSmokeTest.Run(dependencies)
	print("[ANP Phase7AManualMapAuthoringSmokeTest] Starting Phase 7A manual map authoring smoke test.")

	local MapAuthoringValidator = dependencies.MapAuthoringValidator
	local WorldBootstrapConfig = dependencies.WorldBootstrapConfig

	assertCondition(WorldBuildConfig.BuildMode == "Skeleton", "WorldBuildConfig should default to Skeleton mode.")
	assertCondition(WorldBuildConfig.BuildSkeletonWhenMissingInStudio == true, "Skeleton mode should allow Studio skeleton build when missing.")
	assertCondition(WorldBuildConfig.AllowSkeletonBuildInManualMode == false, "Manual mode must not allow skeleton overwrite by default.")
	assertCondition(WorldBuildConfig.ValidateManualMapInStudio == true, "Manual map validation should default on in Studio.")

	local missingWorldResult = {
		Success = false,
		Code = "WorldRootMissing",
	}
	local studioPilotConfig = {
		EnableRealDataStore = true,
	}
	local shouldBuild, buildReason = WorldBootstrapConfig.ShouldBuildSkeletonWorld(makeStudioRunService(true), studioPilotConfig, missingWorldResult)
	assertCondition(shouldBuild == true and buildReason == "BuildAllowed", "Skeleton dev flow should still allow Studio pilot world bootstrap when missing.")
	shouldBuild, buildReason = WorldBootstrapConfig.ShouldBuildSkeletonWorld(makeStudioRunService(false), studioPilotConfig, missingWorldResult)
	assertCondition(shouldBuild == false and buildReason == "NotStudio", "Non-Studio must not auto-build skeleton world.")

	local validFixture = createValidMapFixture()
	local beforeDescendantCount = countDescendants(validFixture)
	assertValid(MapAuthoringValidator.ValidateWorldRoot(validFixture), "Valid manual fixture should pass validation.")
	assertCondition(beforeDescendantCount == countDescendants(validFixture), "Map validation should not mutate the world fixture.")

	assertInvalid(MapAuthoringValidator.ValidateWorldRoot(nil), "ANP_World", "Missing world root should fail.")

	local missingZoneFixture = createValidMapFixture()
	local missingZone = missingZoneFixture.Zones:FindFirstChild("zone_ep01_moon_walk")
	missingZone:Destroy()
	assertInvalid(MapAuthoringValidator.ValidateWorldRoot(missingZoneFixture), "zone_ep01_moon_walk", "Missing active EP1 zone should fail.")

	local missingGameplayFixture = createValidMapFixture()
	missingGameplayFixture.Zones.zone_ep01_command_center.Gameplay:Destroy()
	assertInvalid(MapAuthoringValidator.ValidateWorldRoot(missingGameplayFixture), "Gameplay folder", "Missing Gameplay folder should fail.")

	local duplicateFixture = createValidMapFixture()
	local duplicateSource = findInteractionObject(duplicateFixture, "interaction_start_ep01_main_001")
	local duplicate = duplicateSource:Clone()
	duplicate.Name = "DuplicateStart001"
	duplicate.Parent = duplicateSource.Parent
	assertInvalid(MapAuthoringValidator.ValidateWorldRoot(duplicateFixture), "Duplicate InteractionId", "Duplicate InteractionId should fail.")

	local unknownInteractionFixture = createValidMapFixture()
	local unknownInteraction = findInteractionObject(unknownInteractionFixture, "interaction_start_ep01_main_001")
	unknownInteraction:SetAttribute("InteractionId", "interaction_unknown_manual_map")
	assertInvalid(MapAuthoringValidator.ValidateWorldRoot(unknownInteractionFixture), "unknown InteractionId", "Unknown InteractionId should fail.")

	local unknownZoneFixture = createValidMapFixture()
	local unknownZoneObject = findInteractionObject(unknownZoneFixture, "interaction_start_ep01_main_001")
	unknownZoneObject:SetAttribute("ZoneId", "zone_unknown_manual_map")
	assertInvalid(MapAuthoringValidator.ValidateWorldRoot(unknownZoneFixture), "unknown ZoneId", "Unknown ZoneId should fail.")

	local missingStartFixture = createValidMapFixture()
	removeObjectWithInteractionId(missingStartFixture, "interaction_start_ep01_main_001")
	assertInvalid(MapAuthoringValidator.ValidateWorldRoot(missingStartFixture), "interaction_start_ep01_main_001", "Missing QuestStart should fail.")

	local missingCompleteFixture = createValidMapFixture()
	removeObjectWithInteractionId(missingCompleteFixture, "interaction_complete_ep01_main_001")
	assertInvalid(MapAuthoringValidator.ValidateWorldRoot(missingCompleteFixture), "interaction_complete_ep01_main_001", "Missing QuestComplete should fail.")

	local missingQ8ObjectiveFixture = createValidMapFixture()
	removeObjectWithInteractionId(missingQ8ObjectiveFixture, "interaction_ep01_main_008_005")
	assertInvalid(MapAuthoringValidator.ValidateWorldRoot(missingQ8ObjectiveFixture), "obj_ep01_main_008_005", "Missing Q8 fifth objective route should fail.")

	local decorFixture = createValidMapFixture()
	local decorGameplayLeak = Instance.new("Part")
	decorGameplayLeak.Name = "DecorWithGameplayId"
	decorGameplayLeak:SetAttribute("InteractionId", "interaction_start_ep01_main_001")
	decorGameplayLeak.Parent = decorFixture.Zones.zone_ep01_command_center.Decor
	assertInvalid(MapAuthoringValidator.ValidateWorldRoot(decorFixture), "Decor object", "Decor gameplay attributes should fail validation.")

	assertCondition(#QuestDefinitions.quest_ep01_main_008.RequiredObjectiveIds == 5, "Quest 008 should keep five required objectives.")
	assertValid(MapAuthoringValidator.ValidateWorldRoot(createValidMapFixture()), "Prompt binding-compatible fixture should remain valid.")

	print("[ANP Phase7AManualMapAuthoringSmokeTest] Phase 7A manual map authoring smoke test passed.")
end

return Phase7AManualMapAuthoringSmokeTest
