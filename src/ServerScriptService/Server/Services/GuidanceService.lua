local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local QuestDefinitions = require(Shared.Definitions.QuestDefinitions)
local CharacterConfig = require(Shared.Config.CharacterConfig)

local GuidanceService = {}

local playerDataService = nil
local questService = nil
local analyticsService = nil

local CHARACTER_NAMES = {
	[CharacterConfig.Ids.Atom] = "Atom",
	[CharacterConfig.Ids.Neutron] = "Neutron",
	[CharacterConfig.Ids.Proton] = "Proton",
}

local function result(success, code, message, data)
	return {
		Success = success,
		Code = code,
		Message = message,
		Data = data,
	}
end

local function characterName(characterId)
	return CHARACTER_NAMES[characterId] or "Guide"
end

local function getObjectiveText(questDefinition, objectiveId)
	local objectiveDefinition = questDefinition.ObjectiveDefinitions and questDefinition.ObjectiveDefinitions[objectiveId]
	if objectiveDefinition and objectiveDefinition.ObjectiveText then
		return objectiveDefinition.ObjectiveText
	end

	return objectiveId
end

local function buildCharacterHint(characterId, guidanceType, objectiveText)
	if guidanceType == "StartQuest001" then
		if characterId == CharacterConfig.Ids.Proton then
			return "Look for the green Quest Start marker in the Command Center."
		elseif characterId == CharacterConfig.Ids.Neutron then
			return "We need to begin the expedition before analyzing clues."
		end

		return "Start your first ANP expedition at the Quest 001 start point."
	elseif guidanceType == "NextObjective" then
		if characterId == CharacterConfig.Ids.Proton then
			return "Next step: " .. objectiveText
		elseif characterId == CharacterConfig.Ids.Neutron then
			return "Let's investigate this next clue: " .. objectiveText
		end

		return "Keep moving. Your next objective is: " .. objectiveText
	elseif guidanceType == "CompleteQuest" then
		if characterId == CharacterConfig.Ids.Proton then
			return "All objectives are complete. Look for the cyan Quest Complete marker."
		elseif characterId == CharacterConfig.Ids.Neutron then
			return "The required data is complete. Finish the quest at the Quest Complete marker."
		end

		return "Great work. Return to the cyan Quest Complete marker to finish this mission."
	elseif guidanceType == "CompleteQuest002" then
		if characterId == CharacterConfig.Ids.Neutron then
			return "All signal data is mapped. Finish the quest at the cyan Quest Complete marker."
		elseif characterId == CharacterConfig.Ids.Atom then
			return "The signal map is complete. Use the cyan Quest Complete marker to finish strong."
		end

		return "All signal data is mapped. Look for the cyan Quest Complete marker."
	elseif guidanceType == "Quest002Available" then
		if characterId == CharacterConfig.Ids.Neutron then
			return "Quest 002 is available. The next signal trace begins in the Universe Explorer area."
		elseif characterId == CharacterConfig.Ids.Atom then
			return "Quest 002 is ready. Head for the green Quest Start marker in Universe Explorer."
		end

		return "Quest 002 is available. Look for the green Quest Start marker in the Universe Explorer area."
	elseif guidanceType == "Quest003Available" then
		if characterId == CharacterConfig.Ids.Neutron then
			return "The broken signal is mapped. Future route analysis can continue when the next quest marker is ready."
		elseif characterId == CharacterConfig.Ids.Atom then
			return "Great mapping work. The next expedition step will open from the Universe Explorer path."
		end

		return "Quest 002 is complete. Continue exploring Universe Explorer until the next quest marker is available."
	end

	return "Explore nearby discoveries or return to the Command Center."
end

local QUEST_002_OBJECTIVE_HINTS = {
	obj_ep01_main_002_001 = {
		Atom = "Move out. Travel to the Universe Explorer zone and enter the mission area.",
		Neutron = "We need fresh signal context. Enter the Universe Explorer zone first.",
		Proton = "Travel to the Universe Explorer zone and enter the mission area.",
	},
	obj_ep01_main_002_002 = {
		Atom = "Track the signal. Find the first signal marker in Universe Explorer.",
		Neutron = "The signal source should be nearby. Locate the first signal marker.",
		Proton = "Find the first signal marker in the Universe Explorer zone.",
	},
	obj_ep01_main_002_003 = {
		Atom = "Scan the marker and secure that data.",
		Neutron = "Scan the signal marker so we can study its pattern.",
		Proton = "Scan the signal marker to collect signal data.",
	},
	obj_ep01_main_002_004 = {
		Atom = "Bring the signal data back for analysis.",
		Neutron = "Return the signal data to my analysis station.",
		Proton = "Return the signal data to Neutron's analysis station.",
	},
}

local function getCharacterToneKey(characterId)
	if characterId == CharacterConfig.Ids.Atom then
		return "Atom"
	elseif characterId == CharacterConfig.Ids.Neutron then
		return "Neutron"
	elseif characterId == CharacterConfig.Ids.Proton then
		return "Proton"
	end

	return "Proton"
end

local function buildQuestObjectiveHint(characterId, questId, objectiveId, objectiveText)
	if questId == "quest_ep01_main_002" then
		local objectiveHints = QUEST_002_OBJECTIVE_HINTS[objectiveId]
		if objectiveHints then
			return objectiveHints[getCharacterToneKey(characterId)] or objectiveHints.Proton
		end
	end

	return buildCharacterHint(characterId, "NextObjective", objectiveText)
end

local function getActiveQuestId(questSnapshot)
	local activeQuestIds = {}
	for questId in pairs(questSnapshot.ActiveQuestIds or {}) do
		table.insert(activeQuestIds, questId)
	end
	table.sort(activeQuestIds)

	return activeQuestIds[1]
end

local function getNextIncompleteRequiredObjective(questDefinition, questState)
	for _, objectiveId in ipairs(questDefinition.RequiredObjectiveIds or {}) do
		local objectiveState = questState.ObjectiveStates and questState.ObjectiveStates[objectiveId]
		if not objectiveState or objectiveState.Completed ~= true then
			return objectiveId
		end
	end

	return nil
end

function GuidanceService.Init(dependencies)
	playerDataService = dependencies.PlayerDataService
	questService = dependencies.QuestService
	analyticsService = dependencies.AnalyticsService

	assert(playerDataService, "GuidanceService requires PlayerDataService.")
	assert(questService, "GuidanceService requires QuestService.")
end

local function recordGuidanceUse(player, characterId, activeQuestId, nextObjectiveId, hintText)
	playerDataService.Mutate(player, "IncrementSessionStat", {
		SourceType = "SessionStats",
		SourceId = "NPCInteractions",
	}, function(playerData)
		playerData.SessionStats = playerData.SessionStats or {}
		playerData.SessionStats.NPCInteractions = (playerData.SessionStats.NPCInteractions or 0) + 1
		return true
	end)

	if analyticsService then
		analyticsService.Track(player, "NPCGuidanceUsed", {
			CharacterId = characterId,
			ActiveQuestId = activeQuestId,
			NextObjectiveId = nextObjectiveId,
			HintText = hintText,
		})
	end
end

local function guidanceReady(player, data)
	recordGuidanceUse(player, data.CharacterId, data.ActiveQuestId, data.NextObjectiveId, data.HintText)
	return result(true, "GuidanceReady", nil, data)
end

function GuidanceService.GetPlayerGuidance(player, characterId)
	local questSnapshot = playerDataService.GetSnapshot(player, "Quests")
	if not questSnapshot.Success then
		return questSnapshot
	end

	local guideCharacterId = characterId
	local activeQuestId = getActiveQuestId(questSnapshot.Data)

	if activeQuestId then
		local questDefinition = QuestDefinitions[activeQuestId]
		local questStateResult = questService.GetQuestState(player, activeQuestId)
		if not questStateResult.Success then
			return questStateResult
		end

		local nextObjectiveId = getNextIncompleteRequiredObjective(questDefinition, questStateResult.Data)
		if nextObjectiveId then
			local objectiveText = getObjectiveText(questDefinition, nextObjectiveId)
			return guidanceReady(player, {
				CharacterId = guideCharacterId,
				ActiveQuestId = activeQuestId,
				ActiveQuestTitle = questDefinition.Title or activeQuestId,
				NextObjectiveId = nextObjectiveId,
				NextObjectiveText = objectiveText,
				HintText = buildQuestObjectiveHint(guideCharacterId, activeQuestId, nextObjectiveId, objectiveText),
			})
		end

		return guidanceReady(player, {
			CharacterId = guideCharacterId,
			ActiveQuestId = activeQuestId,
			ActiveQuestTitle = questDefinition.Title or activeQuestId,
			NextObjectiveId = nil,
			NextObjectiveText = nil,
			HintText = buildCharacterHint(
				guideCharacterId,
				if activeQuestId == "quest_ep01_main_002" then "CompleteQuest002" else "CompleteQuest"
			),
		})
	end

	local canStartQuest001 = questService.CanStartQuest(player, "quest_ep01_main_001")
	if canStartQuest001 then
		return guidanceReady(player, {
			CharacterId = guideCharacterId,
			ActiveQuestId = nil,
			ActiveQuestTitle = nil,
			NextObjectiveId = nil,
			NextObjectiveText = nil,
			HintText = buildCharacterHint(guideCharacterId, "StartQuest001"),
		})
	end

	local canStartQuest002 = questService.CanStartQuest(player, "quest_ep01_main_002")
	if canStartQuest002 then
		return guidanceReady(player, {
			CharacterId = guideCharacterId,
			ActiveQuestId = nil,
			ActiveQuestTitle = nil,
			NextObjectiveId = nil,
			NextObjectiveText = nil,
			HintText = buildCharacterHint(guideCharacterId, "Quest002Available"),
		})
	end

	local canStartQuest003 = questService.CanStartQuest(player, "quest_ep01_main_003")
	if canStartQuest003 then
		return guidanceReady(player, {
			CharacterId = guideCharacterId,
			ActiveQuestId = nil,
			ActiveQuestTitle = nil,
			NextObjectiveId = nil,
			NextObjectiveText = nil,
			HintText = buildCharacterHint(guideCharacterId, "Quest003Available"),
		})
	end

	return guidanceReady(player, {
		CharacterId = guideCharacterId,
		ActiveQuestId = nil,
		ActiveQuestTitle = nil,
		NextObjectiveId = nil,
		NextObjectiveText = nil,
		HintText = buildCharacterHint(guideCharacterId, "Explore"),
	})
end

function GuidanceService.GetCharacterName(characterId)
	return characterName(characterId)
end

return GuidanceService
