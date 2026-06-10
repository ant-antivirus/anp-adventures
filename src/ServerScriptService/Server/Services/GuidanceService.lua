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
			return "Quest 003 is available. The mapped signal can guide us deeper into Universe Explorer."
		elseif characterId == CharacterConfig.Ids.Atom then
			return "Quest 003 is available. Follow the next green Quest Start marker in Universe Explorer."
		end

		return "Quest 003 is available. Follow the next green Quest Start marker in Universe Explorer."
	elseif guidanceType == "CompleteQuest003" then
		if characterId == CharacterConfig.Ids.Neutron then
			return "The Universe Fragment is stable. Finish the quest at the cyan Quest Complete marker."
		elseif characterId == CharacterConfig.Ids.Atom then
			return "The Universe Fragment is secure. Use the cyan Quest Complete marker to finish this step."
		end

		return "The Universe Fragment is secure. Look for the cyan Quest Complete marker."
	elseif guidanceType == "Quest004Available" then
		if characterId == CharacterConfig.Ids.Neutron then
			return "Quest 004 is available. The next evidence points toward the Terrain Sandbox."
		elseif characterId == CharacterConfig.Ids.Atom then
			return "Quest 004 is available. Head toward the Terrain Sandbox path."
		end

		return "Quest 004 is available. Look for the green Quest Start marker near the Terrain Sandbox."
	elseif guidanceType == "CompleteQuest004" then
		if characterId == CharacterConfig.Ids.Neutron then
			return "The Earth Fragment data is complete. Finish at the cyan Quest Complete marker."
		elseif characterId == CharacterConfig.Ids.Atom then
			return "The Earth Fragment is ready. Finish strong at the cyan Quest Complete marker."
		end

		return "The Earth Fragment is ready. Look for the cyan Quest Complete marker."
	elseif guidanceType == "Quest005Available" then
		if characterId == CharacterConfig.Ids.Neutron then
			return "The Earth Fragment is secure. The next expedition step will open from the satellite path."
		elseif characterId == CharacterConfig.Ids.Atom then
			return "The Earth Fragment is secure. Prepare for the satellite path ahead."
		end

		return "The Earth Fragment is secure. The next expedition step will open from the satellite path."
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

local QUEST_003_OBJECTIVE_HINTS = {
	obj_ep01_main_003_001 = {
		Atom = "Follow the star signal trail deeper into Universe Explorer.",
		Neutron = "The mapped signal is extending. Follow the star signal trail.",
		Proton = "Follow the star signal trail deeper into Universe Explorer.",
	},
	obj_ep01_main_003_002 = {
		Atom = "Inspect the unstable signal echo and stay steady.",
		Neutron = "Inspect the unstable signal echo so we can understand the distortion.",
		Proton = "Inspect the unstable signal echo.",
	},
	obj_ep01_main_003_003 = {
		Atom = "Stabilize the Universe Fragment before it fades.",
		Neutron = "Stabilize the Universe Fragment before its signal collapses.",
		Proton = "Stabilize the Universe Fragment before it fades.",
	},
	obj_ep01_main_003_004 = {
		Atom = "Recover the Universe Fragment.",
		Neutron = "Recover the Universe Fragment for the Star Core record.",
		Proton = "Recover the Universe Fragment.",
	},
}

local QUEST_004_OBJECTIVE_HINTS = {
	obj_ep01_main_004_001 = {
		Atom = "Travel to the Terrain Sandbox.",
		Neutron = "Move to the Terrain Sandbox so we can compare the terrain memory.",
		Proton = "Travel to the Terrain Sandbox.",
	},
	obj_ep01_main_004_002 = {
		Atom = "Find the Earth memory marker.",
		Neutron = "Find the Earth memory marker. It should reveal the terrain pattern.",
		Proton = "Find the Earth memory marker.",
	},
	obj_ep01_main_004_003 = {
		Atom = "Rebuild the terrain memory path.",
		Neutron = "Rebuild the terrain memory path so the Earth Fragment can stabilize.",
		Proton = "Rebuild the terrain memory path.",
	},
	obj_ep01_main_004_004 = {
		Atom = "Recover the Earth Fragment.",
		Neutron = "Recover the Earth Fragment once the terrain memory is stable.",
		Proton = "Recover the Earth Fragment.",
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
	elseif questId == "quest_ep01_main_003" then
		local objectiveHints = QUEST_003_OBJECTIVE_HINTS[objectiveId]
		if objectiveHints then
			return objectiveHints[getCharacterToneKey(characterId)] or objectiveHints.Proton
		end
	elseif questId == "quest_ep01_main_004" then
		local objectiveHints = QUEST_004_OBJECTIVE_HINTS[objectiveId]
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
				if activeQuestId == "quest_ep01_main_002" then "CompleteQuest002"
				elseif activeQuestId == "quest_ep01_main_003" then "CompleteQuest003"
				elseif activeQuestId == "quest_ep01_main_004" then "CompleteQuest004"
				else "CompleteQuest"
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

	local canStartQuest004 = questService.CanStartQuest(player, "quest_ep01_main_004")
	if canStartQuest004 then
		return guidanceReady(player, {
			CharacterId = guideCharacterId,
			ActiveQuestId = nil,
			ActiveQuestTitle = nil,
			NextObjectiveId = nil,
			NextObjectiveText = nil,
			HintText = buildCharacterHint(guideCharacterId, "Quest004Available"),
		})
	end

	local canStartQuest005 = questService.CanStartQuest(player, "quest_ep01_main_005")
	if canStartQuest005 then
		return guidanceReady(player, {
			CharacterId = guideCharacterId,
			ActiveQuestId = nil,
			ActiveQuestTitle = nil,
			NextObjectiveId = nil,
			NextObjectiveText = nil,
			HintText = buildCharacterHint(guideCharacterId, "Quest005Available"),
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
