local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage.Shared
local EpisodeDefinitions = require(Shared.Definitions.EpisodeDefinitions)
local InteractionDefinitions = require(Shared.Definitions.InteractionDefinitions)
local QuestDefinitions = require(Shared.Definitions.QuestDefinitions)
local WorldBuildConfig = require(Shared.Config.WorldBuildConfig)
local ZoneDefinitions = require(Shared.Definitions.ZoneDefinitions)

local Phase7BManualMapBindingSmokeTest = {}

local EP1_ID = "ep01_lost_star_core"
local WORLD_ROOT_NAME = "ANP_World"

local function assertCondition(condition, message)
	if not condition then
		error("[ANP Phase7BManualMapBindingSmokeTest] " .. message, 2)
	end
end

local function assertResultSuccess(serviceResult, message)
	assertCondition(serviceResult and serviceResult.Success == true, message .. " Code: " .. tostring(serviceResult and serviceResult.Code))
end

local function assertValid(validationResult, message)
	assertCondition(validationResult and validationResult.Success == true, message .. " Errors: " .. table.concat(validationResult and validationResult.Errors or {}, " | "))
end

local function assertInvalidCode(validationResult, expectedCode, message)
	assertCondition(validationResult and validationResult.Success == false, message)
	for _, detail in ipairs(validationResult.ErrorDetails or {}) do
		if detail.Code == expectedCode then
			return
		end
	end
	error("[ANP Phase7BManualMapBindingSmokeTest] " .. message .. " Expected code `" .. expectedCode .. "`.", 2)
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

local function applyInteractionAttributes(object, interactionId, interactionDefinition)
	object:SetAttribute("InteractionId", interactionId)
	object:SetAttribute("ZoneId", interactionDefinition.ZoneId)
	object:SetAttribute("ObjectType", interactionDefinition.Type)
	object:SetAttribute("DisplayName", "Manual " .. interactionId)
	if interactionDefinition.QuestId then
		object:SetAttribute("QuestId", interactionDefinition.QuestId)
	end
	if interactionDefinition.ObjectiveId then
		object:SetAttribute("ObjectiveId", interactionDefinition.ObjectiveId)
	end
	if interactionDefinition.DiscoveryId then
		object:SetAttribute("DiscoveryId", interactionDefinition.DiscoveryId)
	end
	if interactionDefinition.TargetZoneId then
		object:SetAttribute("TargetZoneId", interactionDefinition.TargetZoneId)
	end
	if interactionDefinition.CharacterId then
		object:SetAttribute("CharacterId", interactionDefinition.CharacterId)
	end
end

local function makePromptPart(parent, name)
	local promptPart = Instance.new("Part")
	promptPart.Name = name or "PromptPart"
	promptPart.Anchored = true
	promptPart.Size = Vector3.new(2, 1, 2)
	promptPart.Parent = parent
	return promptPart
end

local function addManualObject(gameplayFolder, interactionId, interactionDefinition)
	if interactionId == "interaction_start_ep01_main_001" then
		local model = Instance.new("Model")
		model.Name = "Manual_Q1_Start_ModelPrimaryPart"
		applyInteractionAttributes(model, interactionId, interactionDefinition)
		local primaryPart = makePromptPart(model, "PrimaryPromptPart")
		model.PrimaryPart = primaryPart
		model.Parent = gameplayFolder
		return model
	end

	local marker = Instance.new("Folder")
	marker.Name = "Manual_" .. interactionId
	applyInteractionAttributes(marker, interactionId, interactionDefinition)
	makePromptPart(marker)
	marker.Parent = gameplayFolder
	return marker
end

local function createManualFixture()
	local worldRoot = Instance.new("Folder")
	worldRoot.Name = WORLD_ROOT_NAME

	local zonesFolder = Instance.new("Folder")
	zonesFolder.Name = "Zones"
	zonesFolder.Parent = worldRoot

	local gameplayByZone = {}
	for _, zoneId in ipairs(getActiveEp1ZoneIds()) do
		local zoneFolder = Instance.new("Folder")
		zoneFolder.Name = "Manual_" .. zoneId
		zoneFolder:SetAttribute("ZoneId", zoneId)
		zoneFolder.Parent = zonesFolder

		local gameplayFolder = Instance.new("Folder")
		gameplayFolder.Name = "Gameplay"
		gameplayFolder.Parent = zoneFolder
		gameplayByZone[zoneId] = gameplayFolder

		local decorFolder = Instance.new("Folder")
		decorFolder.Name = "Decor"
		decorFolder.Parent = zoneFolder

		local safeDecor = Instance.new("Part")
		safeDecor.Name = "SafeDecor"
		safeDecor.Anchored = true
		safeDecor.Parent = decorFolder
	end

	for interactionId, interactionDefinition in pairs(InteractionDefinitions) do
		if interactionDefinition.Enabled ~= false and interactionDefinition.EnabledInWorld ~= false and isEp1Interaction(interactionDefinition) then
			local gameplayFolder = gameplayByZone[interactionDefinition.ZoneId]
			if gameplayFolder then
				addManualObject(gameplayFolder, interactionId, interactionDefinition)
			end
		end
	end

	return worldRoot
end

local function findInteractionObject(worldRoot, interactionId)
	for _, descendant in ipairs(worldRoot:GetDescendants()) do
		if descendant:GetAttribute("InteractionId") == interactionId then
			return descendant
		end
	end
	return nil
end

local function removeInteractionObject(worldRoot, interactionId)
	local object = findInteractionObject(worldRoot, interactionId)
	if object then
		object:Destroy()
	end
end

local function countPrompts(worldRoot)
	local promptCount = 0
	for _, descendant in ipairs(worldRoot:GetDescendants()) do
		if descendant:IsA("ProximityPrompt") then
			promptCount += 1
		end
	end
	return promptCount
end

local function withTemporaryWorldRoot(callback)
	local existingWorld = Workspace:FindFirstChild(WORLD_ROOT_NAME)
	local existingParent = existingWorld and existingWorld.Parent
	if existingWorld then
		existingWorld.Parent = nil
	end

	local fixture = createManualFixture()
	fixture.Parent = Workspace

	local ok, err = pcall(callback, fixture)

	fixture:Destroy()
	if existingWorld then
		existingWorld.Parent = existingParent
	end

	if not ok then
		error(err, 0)
	end
end

local function assertManualPromptBinding(services)
	local MapAuthoringValidator = services.MapAuthoringValidator
	local PromptBindingService = services.PromptBindingService
	local WorldRegistryService = services.WorldRegistryService

	withTemporaryWorldRoot(function(worldRoot)
		PromptBindingService.ResetForTests()
		assertValid(MapAuthoringValidator.ValidateWorldRoot(worldRoot), "Manual fixture should validate before binding.")
		assertResultSuccess(WorldRegistryService.Init(), "World registry should initialize against manual fixture.")
		assertCondition(#(WorldRegistryService.GetDuplicates().Data or {}) == 0, "Manual fixture should not register duplicate IDs.")

		local bindResult = PromptBindingService.BindAllPrompts()
		assertResultSuccess(bindResult, "Prompt binding should succeed against manual fixture.")
		local firstPromptCount = countPrompts(worldRoot)
		assertCondition(firstPromptCount > 0, "Manual prompt binding should create prompts.")

		local q1Prompt = PromptBindingService.GetPromptForInteraction("interaction_start_ep01_main_001")
		assertResultSuccess(q1Prompt, "Q1 start prompt should bind.")
		assertCondition(q1Prompt.Data.Parent.Name == "PrimaryPromptPart", "Model manual object should bind to PrimaryPart when no PromptPart exists.")

		local q8Prompt = PromptBindingService.GetPromptForInteraction("interaction_ep01_main_008_005")
		assertResultSuccess(q8Prompt, "Q8 fifth objective prompt should bind.")
		assertCondition(q8Prompt.Data.Parent.Name == "PromptPart", "Folder manual object should bind to child PromptPart.")

		assertResultSuccess(PromptBindingService.BindAllPrompts(), "Prompt binding should be idempotent on second run.")
		assertCondition(countPrompts(worldRoot) == firstPromptCount, "Second bind should not create duplicate prompts.")
	end)
end

local function assertValidationFailures(MapAuthoringValidator)
	local duplicateFixture = createManualFixture()
	local duplicateSource = findInteractionObject(duplicateFixture, "interaction_start_ep01_main_001")
	local duplicate = duplicateSource:Clone()
	duplicate.Name = "DuplicateManualQ1Start"
	duplicate.Parent = duplicateSource.Parent
	assertInvalidCode(MapAuthoringValidator.ValidateWorldRoot(duplicateFixture), "DuplicateInteractionId", "Duplicate InteractionId should fail.")

	local unknownInteractionFixture = createManualFixture()
	findInteractionObject(unknownInteractionFixture, "interaction_start_ep01_main_001"):SetAttribute("InteractionId", "interaction_manual_unknown")
	assertInvalidCode(MapAuthoringValidator.ValidateWorldRoot(unknownInteractionFixture), "UnknownInteractionId", "Unknown InteractionId should fail.")

	local missingPromptFixture = createManualFixture()
	local missingPromptObject = findInteractionObject(missingPromptFixture, "interaction_ep01_main_001_001")
	missingPromptObject.PromptPart:Destroy()
	assertInvalidCode(MapAuthoringValidator.ValidateWorldRoot(missingPromptFixture), "MissingPromptPart", "Missing PromptPart/BasePart should fail.")

	local decorFixture = createManualFixture()
	local decorLeak = Instance.new("Part")
	decorLeak.Name = "DecorGameplayLeak"
	decorLeak:SetAttribute("InteractionId", "interaction_start_ep01_main_001")
	decorLeak.Parent = decorFixture.Zones:GetChildren()[1].Decor
	assertInvalidCode(MapAuthoringValidator.ValidateWorldRoot(decorFixture), "DecorContainsGameplayAttribute", "Decor with InteractionId should fail.")

	local zoneMismatchFixture = createManualFixture()
	findInteractionObject(zoneMismatchFixture, "interaction_start_ep01_main_001"):SetAttribute("ZoneId", "zone_ep01_moon_walk")
	assertInvalidCode(MapAuthoringValidator.ValidateWorldRoot(zoneMismatchFixture), "ZoneMismatch", "Zone mismatch should fail.")

	local missingCompleteFixture = createManualFixture()
	removeInteractionObject(missingCompleteFixture, "interaction_complete_ep01_main_001")
	assertInvalidCode(MapAuthoringValidator.ValidateWorldRoot(missingCompleteFixture), "MissingQuestCompleteObject", "Missing QuestComplete should fail.")

	local missingQ8Fixture = createManualFixture()
	removeInteractionObject(missingQ8Fixture, "interaction_ep01_main_008_005")
	assertInvalidCode(MapAuthoringValidator.ValidateWorldRoot(missingQ8Fixture), "Q8RequiredObjectiveMissing", "Missing Q8 fifth objective should fail.")
end

function Phase7BManualMapBindingSmokeTest.Run(services)
	print("[ANP Phase7BManualMapBindingSmokeTest] Starting Phase 7B manual map binding smoke test.")

	assertCondition(WorldBuildConfig.BuildMode == "Skeleton", "WorldBuildConfig should default to Skeleton mode.")
	assertCondition(WorldBuildConfig.AllowSkeletonBuildInManualMode == false, "Manual mode should not auto-build skeleton world by default.")

	assertManualPromptBinding(services)
	assertValidationFailures(services.MapAuthoringValidator)

	services.PromptBindingService.ResetForTests()
	assertResultSuccess(services.SkeletonWorldBuilder.BuildIfMissing(), "Skeleton mode should still build existing dev world.")
	assertResultSuccess(services.WorldRegistryService.Init(), "World registry should restore skeleton world after manual fixture.")
	assertResultSuccess(services.PromptBindingService.BindAllPrompts(), "Skeleton prompt binding should still work.")
	assertResultSuccess(services.PromptBindingService.GetPromptForInteraction("interaction_start_ep01_main_001"), "Skeleton Q1 prompt should still bind.")

	for _, descendant in ipairs(ReplicatedStorage:GetDescendants()) do
		assertCondition(not descendant:IsA("Remote" .. "Function"), "Phase 7B should not add request/response remotes.")
	end

	print("[ANP Phase7BManualMapBindingSmokeTest] Phase 7B manual map binding smoke test passed.")
end

return Phase7BManualMapBindingSmokeTest
