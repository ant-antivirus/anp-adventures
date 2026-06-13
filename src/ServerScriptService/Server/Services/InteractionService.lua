local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local InteractionDefinitions = require(Shared.Definitions.InteractionDefinitions)
local QuestDefinitions = require(Shared.Definitions.QuestDefinitions)
local Logger = require(script.Parent.Parent.Utils.Logger)

local InteractionService = {}

local VALID_TYPES = {
	NPCGuide = true,
	QuestStart = true,
	QuestComplete = true,
	QuestObjective = true,
	Discovery = true,
	ZoneTravel = true,
	Generic = true,
}

local playerDataService = nil
local worldRegistryService = nil
local questService = nil
local discoveryService = nil
local zoneService = nil
local guidanceService = nil
local interactionVisibilityService = nil
local playerFeedbackService = nil
local questTrackerService = nil
local refreshInteractionVisibility = nil
local cooldownsByPlayerInteraction = {}
local cooldownDurationSeconds = 1

local FALLBACK_HINTS = {
	QuestNotActive = "เบาะแสนี้มีประโยชน์ แต่ยังไม่ได้เริ่มการสำรวจ",
	ObjectiveDependencyMissing = "ทำขั้นตอนก่อนหน้าให้เสร็จก่อนนะ",
	QuestPrerequisiteMissing = "ภารกิจนี้ยังไม่พร้อม ทำขั้นตอนก่อนหน้าให้เสร็จก่อนนะ",
	QuestLocked = "ภารกิจนี้ยังไม่พร้อม ทำขั้นตอนก่อนหน้าให้เสร็จก่อนนะ",
	RequiredObjectiveIncomplete = "ยังส่งภารกิจไม่ได้ ทำเป้าหมายที่เหลือให้เสร็จก่อนนะ",
	DiscoveryAlreadyRecorded = "ค้นพบสิ่งนี้แล้ว",
	ObjectiveAlreadyCompleted = "ตรวจสิ่งนี้แล้ว",
	QuestAlreadyCompleted = "ภารกิจนี้เสร็จแล้ว",
	QuestAlreadyActive = "กำลังทำภารกิจนี้อยู่",
	ZoneLocked = "พื้นที่นี้ยังเข้าไม่ได้",
	InteractionDisabled = "ตอนนี้ยังใช้งานสิ่งนี้ไม่ได้",
}

local FOCUSED_OBJECT_STATE_DEBUG_INTERACTIONS = {
	interaction_ep01_main_003_003 = true,
	interaction_ep01_main_003_004 = true,
}

local function shouldHideAfterObjectiveComplete(definition)
	if not definition then
		return false
	end

	if definition.HidePromptAfterObjectiveComplete ~= nil then
		return definition.HidePromptAfterObjectiveComplete == true
	end

	return definition.ObjectBehaviorType == "CollectibleItem"
end

local function shouldLogObjectState(definition)
	return definition
		and (
			FOCUSED_OBJECT_STATE_DEBUG_INTERACTIONS[definition.InteractionId] == true
			or shouldHideAfterObjectiveComplete(definition)
		)
end

local function getPlayerName(player)
	return player and player.Name or "UnknownPlayer"
end

local function result(success, code, failureReason, data)
	local response = {
		Success = success,
		Code = code,
		Reason = failureReason,
		FailureReason = failureReason,
		GrantedQuestStart = false,
		GrantedQuestComplete = false,
		GrantedQuestProgress = false,
		GrantedDiscovery = false,
		GrantedZoneTravel = false,
		Data = data,
	}

	if data then
		if data.GrantedQuestStart ~= nil then
			response.GrantedQuestStart = data.GrantedQuestStart
		end
		if data.GrantedQuestComplete ~= nil then
			response.GrantedQuestComplete = data.GrantedQuestComplete
		end
		if data.GrantedQuestProgress ~= nil then
			response.GrantedQuestProgress = data.GrantedQuestProgress
		end
		if data.GrantedDiscovery ~= nil then
			response.GrantedDiscovery = data.GrantedDiscovery
		end
		if data.GrantedZoneTravel ~= nil then
			response.GrantedZoneTravel = data.GrantedZoneTravel
		end
	end

	return response
end

local function getHintText(definition, code)
	if not definition then
		return FALLBACK_HINTS[code]
	end

	if code == "QuestNotActive" then
		return definition.QuestNotActiveHintText or definition.UnavailableHintText or FALLBACK_HINTS[code]
	elseif code == "ObjectiveDependencyMissing" then
		return definition.DependencyMissingHintText or definition.UnavailableHintText or FALLBACK_HINTS[code]
	elseif code == "QuestPrerequisiteMissing" or code == "QuestLocked" then
		return definition.QuestPrerequisiteMissingHintText or definition.UnavailableHintText or FALLBACK_HINTS[code]
	elseif code == "RequiredObjectiveIncomplete" then
		return definition.RequiredObjectiveIncompleteHintText or definition.UnavailableHintText or FALLBACK_HINTS[code]
	elseif code == "DiscoveryAlreadyRecorded" then
		return definition.AlreadyDiscoveredHintText or definition.AlreadyCompletedHintText or definition.UnavailableHintText or FALLBACK_HINTS[code]
	elseif code == "ObjectiveAlreadyCompleted" then
		if definition.ObjectBehaviorType == "CollectibleItem" then
			return definition.AlreadyCollectedHintText or definition.AlreadyUsedHintText or definition.UnavailableHintText or "เก็บสิ่งนี้แล้ว"
		end
		return definition.AlreadyUsedHintText or definition.AlreadyCompletedHintText or definition.UnavailableHintText or FALLBACK_HINTS[code]
	elseif code == "QuestAlreadyCompleted" then
		return definition.AlreadyCompletedHintText or definition.UnavailableHintText or FALLBACK_HINTS[code]
	elseif code == "QuestAlreadyActive" then
		return definition.AlreadyActiveHintText or definition.UnavailableHintText or FALLBACK_HINTS[code]
	end

	return definition.UnavailableHintText or FALLBACK_HINTS[code]
end

local function withHint(definition, code, data)
	data = data or {}
	if data.HintText == nil then
		data.HintText = getHintText(definition, code)
	end

	return data
end

local function getInteractionDefinition(interactionId)
	local definition = InteractionDefinitions[interactionId]
	if not definition then
		return nil, result(false, "UnknownInteractionId", "UnknownInteractionId")
	end

	return definition, nil
end

local function buildSourceContext(interactionId)
	return {
		SourceType = "Interaction",
		SourceId = interactionId,
	}
end

local function getPlayerCooldownKey(player)
	if type(player) == "table" then
		return tostring(player.UserId or player.Name or player)
	end

	return tostring(player and player.UserId or player)
end

local function getCooldownKey(player, interactionId)
	return getPlayerCooldownKey(player) .. ":" .. tostring(interactionId)
end

local function checkInteractionCooldown(player, interactionId, metadata)
	if type(metadata) == "table" and metadata.BypassCooldownForTests == true then
		return nil
	end

	local cooldownKey = getCooldownKey(player, interactionId)
	local now = os.clock()
	local expiresAt = cooldownsByPlayerInteraction[cooldownKey]
	if expiresAt and expiresAt > now then
		return result(false, "InteractionCooldown", "InteractionCooldown", {
			InteractionId = interactionId,
			RetryAfterSeconds = expiresAt - now,
		})
	end

	return nil
end

local function markInteractionCooldown(player, interactionId, metadata)
	if type(metadata) == "table" and metadata.BypassCooldownForTests == true then
		return
	end

	cooldownsByPlayerInteraction[getCooldownKey(player, interactionId)] = os.clock() + cooldownDurationSeconds
end

local function validateWorldObject(definition)
	if definition.Type == "NPCGuide" then
		local npcMarkerResult = worldRegistryService.GetNPCMarker(definition.CharacterId)
		if not npcMarkerResult.Success then
			return result(false, "InteractionWorldObjectMissing", "InteractionWorldObjectMissing")
		end
		return nil
	end

	if definition.Type == "Discovery" then
		local discoveryPointResult = worldRegistryService.GetDiscoveryPoint(definition.DiscoveryId)
		if not discoveryPointResult.Success then
			return result(false, "InteractionWorldObjectMissing", "InteractionWorldObjectMissing")
		end
		return nil
	end

	local interactionObjectResult = worldRegistryService.GetInteraction(definition.InteractionId)
	if not interactionObjectResult.Success then
		return result(false, "InteractionWorldObjectMissing", "InteractionWorldObjectMissing")
	end

	return nil
end

local function findQuestIdForObjective(objectiveId)
	for questId, questDefinition in pairs(QuestDefinitions) do
		for _, questObjectiveId in ipairs(questDefinition.ObjectiveIds or {}) do
			if questObjectiveId == objectiveId then
				return questId
			end
		end
	end

	return nil
end

local function applyObjectiveProgressBridge(player, definition, sourceContext, metadata)
	local objectiveProgressResults = {}
	local skippedObjectiveProgressResults = {}

	for _, objectiveId in ipairs(definition.ObjectiveProgressIds or {}) do
		local questId = findQuestIdForObjective(objectiveId)
		if not questId then
			return result(false, "InvalidObjectiveProgressId", "InvalidObjectiveProgressId", {
				ObjectiveId = objectiveId,
			})
		end

		local questStateResult = questService.GetQuestState(player, questId)
		if not questStateResult.Success then
			return result(false, questStateResult.Code, questStateResult.Code, {
				ObjectiveId = objectiveId,
				QuestId = questId,
				ServiceResult = questStateResult,
			})
		end

		if questStateResult.Data.Status ~= questService.QuestStatus.Active then
			table.insert(skippedObjectiveProgressResults, {
				QuestId = questId,
				ObjectiveId = objectiveId,
				Code = questStateResult.Data.Status == questService.QuestStatus.Completed and "QuestAlreadyCompleted" or "QuestNotActive",
			})
			continue
		end

		local objectiveState = questStateResult.Data.ObjectiveStates and questStateResult.Data.ObjectiveStates[objectiveId]
		if objectiveState and objectiveState.Completed == true then
			table.insert(skippedObjectiveProgressResults, {
				QuestId = questId,
				ObjectiveId = objectiveId,
				Code = "ObjectiveAlreadyCompleted",
			})
			continue
		end

		local progressResult = questService.ApplyObjectiveProgress(
			player,
			questId,
			objectiveId,
			1,
			sourceContext,
			metadata
		)

		if not progressResult.Success then
			if progressResult.Code == "QuestNotActive" or progressResult.Code == "QuestAlreadyCompleted" then
				table.insert(skippedObjectiveProgressResults, {
					QuestId = questId,
					ObjectiveId = objectiveId,
					Code = progressResult.Code,
				})
				continue
			end

			return result(false, progressResult.Code, progressResult.Code, {
				ObjectiveId = objectiveId,
				QuestId = questId,
				ServiceResult = progressResult,
				HintText = getHintText(definition, progressResult.Code),
				MissingObjectiveId = progressResult.Data and progressResult.Data.MissingObjectiveId,
			})
		end

		table.insert(objectiveProgressResults, {
			QuestId = questId,
			ObjectiveId = objectiveId,
			ServiceResult = progressResult,
		})
	end

	return result(true, "ObjectiveProgressBridgeApplied", nil, {
		ObjectiveProgressResults = objectiveProgressResults,
		SkippedObjectiveProgressResults = skippedObjectiveProgressResults,
		GrantedQuestProgress = #objectiveProgressResults > 0,
	})
end

local function finishSuccessfulInteraction(player, definition, sourceContext, metadata, successCode, data)
	local bridgeResult = applyObjectiveProgressBridge(player, definition, sourceContext, metadata)
	if not bridgeResult.Success then
		return bridgeResult
	end

	data = data or {}
	data.ObjectiveProgressResults = bridgeResult.Data.ObjectiveProgressResults
	data.SkippedObjectiveProgressResults = bridgeResult.Data.SkippedObjectiveProgressResults
	if bridgeResult.Data.GrantedQuestProgress == true then
		data.GrantedQuestProgress = true
	elseif successCode == "InteractionDiscoveryRecorded" and #bridgeResult.Data.SkippedObjectiveProgressResults > 0 then
		for _, skippedObjectiveProgressResult in ipairs(bridgeResult.Data.SkippedObjectiveProgressResults) do
			if skippedObjectiveProgressResult.Code == "QuestNotActive" then
				data.HintText = getHintText(definition, "QuestNotActive")
				successCode = "DiscoveryRecordedQuestNotActive"
				break
			end
		end
	end

	markInteractionCooldown(player, definition.InteractionId, metadata)

	return refreshInteractionVisibility(player, result(true, successCode, nil, data))
end

local function finishDuplicateDiscoveryBridgeInteraction(player, definition, sourceContext, metadata, discoveryResult)
	local bridgeResult = applyObjectiveProgressBridge(player, definition, sourceContext, metadata)
	if not bridgeResult.Success then
		return bridgeResult
	end

	if bridgeResult.Data.GrantedQuestProgress ~= true then
		return result(false, "DiscoveryAlreadyRecorded", "DiscoveryAlreadyRecorded", {
			ServiceResult = discoveryResult,
			ObjectiveProgressResults = bridgeResult.Data.ObjectiveProgressResults,
			SkippedObjectiveProgressResults = bridgeResult.Data.SkippedObjectiveProgressResults,
			HintText = getHintText(definition, "DiscoveryAlreadyRecorded"),
		})
	end

	local data = {
		GrantedDiscovery = false,
		GrantedQuestProgress = true,
		ServiceResult = discoveryResult,
		ObjectiveProgressResults = bridgeResult.Data.ObjectiveProgressResults,
		SkippedObjectiveProgressResults = bridgeResult.Data.SkippedObjectiveProgressResults,
	}

	markInteractionCooldown(player, definition.InteractionId, metadata)

	return refreshInteractionVisibility(player, result(true, "DiscoveryObjectiveProgressApplied", nil, data))
end

function InteractionService.Init(dependencies)
	playerDataService = dependencies.PlayerDataService
	worldRegistryService = dependencies.WorldRegistryService
	questService = dependencies.QuestService
	discoveryService = dependencies.DiscoveryService
	zoneService = dependencies.ZoneService
	guidanceService = dependencies.GuidanceService
	interactionVisibilityService = dependencies.InteractionVisibilityService
	playerFeedbackService = dependencies.PlayerFeedbackService
	questTrackerService = dependencies.QuestTrackerService

	assert(playerDataService, "InteractionService requires PlayerDataService.")
	assert(worldRegistryService, "InteractionService requires WorldRegistryService.")
	assert(questService, "InteractionService requires QuestService.")
	assert(discoveryService, "InteractionService requires DiscoveryService.")
	assert(zoneService, "InteractionService requires ZoneService.")
	assert(guidanceService, "InteractionService requires GuidanceService.")
end

function InteractionService.SetInteractionVisibilityService(service)
	interactionVisibilityService = service
end

function InteractionService.SetQuestTrackerService(service)
	questTrackerService = service
end

local function sendQuestTrackerUpdate(player)
	if questTrackerService then
		questTrackerService.SendTrackerUpdate(player)
	end
end

refreshInteractionVisibility = function(player, interactionResult)
	if interactionResult.Success and interactionVisibilityService then
		interactionVisibilityService.RefreshPlayer(player)
	end

	return interactionResult
end

function InteractionService.GetInteractionDefinition(interactionId)
	local definition, errorResult = getInteractionDefinition(interactionId)
	if errorResult then
		return errorResult
	end

	return result(true, "InteractionDefinitionRead", nil, definition)
end

function InteractionService.GetInteractionCatalog()
	return result(true, "InteractionCatalogRead", nil, InteractionDefinitions)
end

function InteractionService.RegisterWorldInteractions()
	return worldRegistryService.Init()
end

function InteractionService.AttemptInteraction(player, interactionId, metadata)
	if not playerDataService.IsLoaded(player) then
		return result(false, "PlayerDataNotLoaded", "PlayerDataNotLoaded")
	end

	local definition, definitionError = getInteractionDefinition(interactionId)
	if definitionError then
		return definitionError
	end

	if definition.Enabled ~= true then
		return result(false, "InteractionDisabled", "InteractionDisabled", withHint(definition, "InteractionDisabled"))
	end

	local cooldownResult = checkInteractionCooldown(player, interactionId, metadata)
	if cooldownResult then
		return cooldownResult
	end

	if not VALID_TYPES[definition.Type] then
		return result(false, "InvalidInteractionType", "InvalidInteractionType")
	end

	local worldObjectError = validateWorldObject(definition)
	if worldObjectError then
		return worldObjectError
	end

	if definition.Type == "QuestStart" then
		local canStart, blockCode = questService.CanStartQuest(player, definition.QuestId)
		if not canStart then
			return result(false, blockCode, blockCode, {
				HintText = getHintText(definition, blockCode),
				QuestId = definition.QuestId,
			})
		end
	end

	if not zoneService.IsZoneUnlocked(player, definition.ZoneId) then
		return result(false, "ZoneLocked", "ZoneLocked", withHint(definition, "ZoneLocked"))
	end

	local sourceContext = buildSourceContext(interactionId)
	local safeMetadata = if type(metadata) == "table" then metadata else {}

	if definition.Type == "NPCGuide" then
		local guidanceResult = guidanceService.GetPlayerGuidance(player, definition.CharacterId)
		if not guidanceResult.Success then
			return result(false, guidanceResult.Code, guidanceResult.Code, {
				ServiceResult = guidanceResult,
			})
		end

		local speakerName = guidanceService.GetCharacterName(definition.CharacterId)
		Logger.Guidance(speakerName .. " -> " .. guidanceResult.Data.HintText)
		if playerFeedbackService then
			playerFeedbackService.SendHint(player, guidanceResult.Data.HintText, {
				Title = speakerName,
				CharacterId = definition.CharacterId,
			})
		end
		sendQuestTrackerUpdate(player)

		return finishSuccessfulInteraction(player, definition, sourceContext, safeMetadata, "InteractionGuidanceProvided", {
			Guidance = guidanceResult.Data,
			ServiceResult = guidanceResult,
		})
	elseif definition.Type == "QuestStart" then
		local startResult = questService.StartQuest(player, definition.QuestId, sourceContext)
		if not startResult.Success then
			return result(false, startResult.Code, startResult.Code, {
				ServiceResult = startResult,
				HintText = getHintText(definition, startResult.Code),
			})
		end

		return finishSuccessfulInteraction(player, definition, sourceContext, safeMetadata, "InteractionQuestStarted", {
			GrantedQuestStart = true,
			ServiceResult = startResult,
		})
	elseif definition.Type == "QuestComplete" then
		local completeResult = questService.CompleteQuest(player, definition.QuestId, sourceContext)
		if not completeResult.Success then
			local failureCode = completeResult.Code

			return result(false, failureCode, failureCode, {
				ServiceResult = completeResult,
				HintText = getHintText(definition, failureCode),
				MissingObjectiveId = completeResult.Data and completeResult.Data.MissingObjectiveId,
			})
		end

		return finishSuccessfulInteraction(player, definition, sourceContext, safeMetadata, "InteractionQuestCompleted", {
			GrantedQuestComplete = true,
			ServiceResult = completeResult,
		})
	elseif definition.Type == "QuestObjective" then
		local objectiveCompleted = questService.IsObjectiveCompleted(player, definition.QuestId, definition.ObjectiveId)
		if objectiveCompleted == true then
			if shouldLogObjectState(definition) then
				Logger.ObjectStateDebug(
					"ProcessedHiddenCompletedObject "
						.. tostring(interactionId)
						.. " player="
						.. getPlayerName(player)
						.. " code=ObjectiveAlreadyCompleted"
				)
			end

			return result(false, "ObjectiveAlreadyCompleted", "ObjectiveAlreadyCompleted", {
				HintText = getHintText(definition, "ObjectiveAlreadyCompleted"),
				QuestId = definition.QuestId,
				ObjectiveId = definition.ObjectiveId,
			})
		end

		local progressResult = questService.ApplyObjectiveProgress(
			player,
			definition.QuestId,
			definition.ObjectiveId,
			safeMetadata.Amount or 1,
			sourceContext,
			safeMetadata
		)

		if not progressResult.Success then
			return result(false, progressResult.Code, progressResult.Code, {
				ServiceResult = progressResult,
				HintText = getHintText(definition, progressResult.Code),
				MissingObjectiveId = progressResult.Data and progressResult.Data.MissingObjectiveId,
			})
		end

		return finishSuccessfulInteraction(player, definition, sourceContext, safeMetadata, "InteractionQuestProgressApplied", {
			GrantedQuestProgress = true,
			ServiceResult = progressResult,
		})
	elseif definition.Type == "Discovery" then
		local discoveryResult = discoveryService.RecordDiscovery(player, definition.DiscoveryId, sourceContext)
		if not discoveryResult.Success then
			if discoveryResult.Code == "DiscoveryAlreadyRecorded" and #(definition.ObjectiveProgressIds or {}) > 0 then
				return finishDuplicateDiscoveryBridgeInteraction(player, definition, sourceContext, safeMetadata, discoveryResult)
			end

			return result(false, discoveryResult.Code, discoveryResult.Code, {
				ServiceResult = discoveryResult,
				HintText = getHintText(definition, discoveryResult.Code),
			})
		end

		return finishSuccessfulInteraction(player, definition, sourceContext, safeMetadata, "InteractionDiscoveryRecorded", {
			GrantedDiscovery = true,
			ServiceResult = discoveryResult,
		})
	elseif definition.Type == "ZoneTravel" then
		local travelResult = zoneService.TravelToZone(
			player,
			definition.ZoneId,
			safeMetadata.SpawnPointId,
			safeMetadata.TravelMode or "Spawn",
			sourceContext
		)

		if not travelResult.Success then
			return result(false, travelResult.Code, travelResult.Code, {
				ServiceResult = travelResult,
				HintText = getHintText(definition, travelResult.Code),
			})
		end

		return finishSuccessfulInteraction(player, definition, sourceContext, safeMetadata, "InteractionZoneTravelRecorded", {
			GrantedZoneTravel = true,
			ServiceResult = travelResult,
		})
	end

	return finishSuccessfulInteraction(player, definition, sourceContext, safeMetadata, "InteractionGenericHandled", {})
end

function InteractionService.SetCooldownDurationForTests(seconds)
	if type(seconds) == "number" and seconds >= 0 then
		cooldownDurationSeconds = seconds
	end
end

function InteractionService.ResetCooldownsForTests()
	table.clear(cooldownsByPlayerInteraction)
	cooldownDurationSeconds = 1
end

return InteractionService
