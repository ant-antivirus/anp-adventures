local Phase3BSmokeTest = {}

local function assertCondition(condition, message)
	if not condition then
		error("[ANP Phase3BSmokeTest] " .. message, 2)
	end
end

local function assertResultSuccess(serviceResult, message)
	assertCondition(serviceResult and serviceResult.Success == true, message .. " Code: " .. tostring(serviceResult and serviceResult.Code))
end

local function assertResultFailure(serviceResult, expectedCode, message)
	assertCondition(serviceResult and serviceResult.Success == false, message)
	assertCondition(serviceResult.Code == expectedCode, message .. " Expected `" .. expectedCode .. "`, got `" .. tostring(serviceResult.Code) .. "`.")
end

local function makeFakePlayer(userId, name)
	return {
		UserId = userId,
		Name = name,
	}
end

local function progressObjectives(QuestService, player, questId, objectiveIds, sourceId)
	for _, objectiveId in ipairs(objectiveIds) do
		assertResultSuccess(QuestService.ApplyObjectiveProgress(player, questId, objectiveId, 1, {
			SourceType = "SmokeTest",
			SourceId = sourceId .. "_" .. objectiveId,
		}), "Objective should progress: " .. objectiveId)
	end
end

local function markPreviousQuestsCompleted(PlayerDataService, player, questIds)
	assertResultSuccess(PlayerDataService.Mutate(player, "SmokeMarkPreviousQuestsCompleted", {
		SourceType = "SmokeTest",
		SourceId = "phase3b_previous_quests",
	}, function(playerData)
		for _, questId in ipairs(questIds) do
			playerData.Quests.CompletedQuestIds[questId] = true
			playerData.Quests.QuestStates[questId] = playerData.Quests.QuestStates[questId] or {
				QuestId = questId,
				Status = "Completed",
				ObjectiveStates = {},
				CompletedAt = os.time(),
			}
		end
		return true
	end), "Previous quest setup should persist.")
end

function Phase3BSmokeTest.Run(services)
	local PlayerDataService = services.PlayerDataService
	local ProgressionService = services.ProgressionService
	local InventoryService = services.InventoryService
	local QuestService = services.QuestService

	print("[ANP Phase3BSmokeTest] Starting Phase 3B smoke test.")

	PlayerDataService.ResetForTests()

	local quest001Player = makeFakePlayer(931001, "Phase3BQuest001")
	assertResultSuccess(PlayerDataService.InitPlayer(quest001Player), "Quest 001 smoke player should initialize.")

	assertCondition(QuestService.CanStartQuest(quest001Player, "quest_ep01_main_001") == true, "Quest 001 should be startable.")
	assertResultSuccess(QuestService.StartQuest(quest001Player, "quest_ep01_main_001", {
		SourceType = "SmokeTest",
		SourceId = "phase3b_start_001",
	}), "Quest 001 should start.")

	assertResultFailure(QuestService.StartQuest(quest001Player, "quest_ep01_main_001", {
		SourceType = "SmokeTest",
		SourceId = "phase3b_start_001_duplicate",
	}), "QuestAlreadyActive", "Duplicate StartQuest should be blocked.")

	assertResultSuccess(QuestService.ApplyObjectiveProgress(quest001Player, "quest_ep01_main_001", "obj_ep01_main_001_001", 1, {
		SourceType = "SmokeTest",
		SourceId = "phase3b_progress_001_001",
	}, {
		CompanionAssisted = true,
		CoopParticipantUserIds = { 931001, 931777 },
	}), "Quest 001 first objective should progress with metadata.")

	assertResultFailure(QuestService.CompleteQuest(quest001Player, "quest_ep01_main_001", {
		SourceType = "QuestCompletion",
		SourceId = "quest_ep01_main_001",
	}), "RequiredObjectiveIncomplete", "Quest 001 should reject completion before all required objectives are complete.")

	progressObjectives(QuestService, quest001Player, "quest_ep01_main_001", {
		"obj_ep01_main_001_002",
		"obj_ep01_main_001_003",
		"obj_ep01_main_001_004",
	}, "phase3b_progress_001")

	local completion001 = QuestService.CompleteQuest(quest001Player, "quest_ep01_main_001", {
		SourceType = "QuestCompletion",
		SourceId = "quest_ep01_main_001",
	})
	assertResultSuccess(completion001, "Quest 001 should complete successfully.")
	assertCondition(completion001.Data.NextQuestId == "quest_ep01_main_002", "Quest 001 completion should expose quest 002 as next quest.")

	local progression = ProgressionService.GetProgression(quest001Player)
	assertResultSuccess(progression, "Progression should read after quest reward.")
	assertCondition(progression.Data.ExplorerScore == 125, "Quest 001 reward should grant 125 Explorer Score.")

	assertResultFailure(QuestService.CompleteQuest(quest001Player, "quest_ep01_main_001", {
		SourceType = "QuestCompletion",
		SourceId = "quest_ep01_main_001_duplicate",
	}), "QuestAlreadyCompleted", "Duplicate quest completion should be blocked.")

	assertCondition(QuestService.CanStartQuest(quest001Player, "quest_ep01_main_002") == true, "Quest 002 should be available after quest 001 completion.")

	local quest001Snapshot = PlayerDataService.GetSnapshot(quest001Player)
	assertResultSuccess(quest001Snapshot, "Quest 001 player snapshot should read.")
	local quest001State = quest001Snapshot.Data.Quests.QuestStates.quest_ep01_main_001
	assertCondition(quest001State.Status == "Completed", "Quest 001 state should persist as completed.")
	assertCondition(quest001State.ObjectiveStates.obj_ep01_main_001_001.Current == 1, "Objective state should persist current progress.")
	assertCondition(quest001State.ObjectiveStates.obj_ep01_main_001_001.Required == 1, "Objective state should persist required progress.")
	assertCondition(quest001State.ObjectiveStates.obj_ep01_main_001_001.Completed == true, "Objective state should persist completed flag.")
	assertCondition(quest001State.ObjectiveStates.obj_ep01_main_001_001.Optional == false, "Objective state should persist optional flag.")
	assertCondition(quest001State.AssistedByCompanion == true, "Companion-assisted metadata should persist.")
	assertCondition(#quest001State.CoopParticipantUserIds >= 2, "Multiplayer metadata should persist without breaking solo state.")
	assertCondition(#quest001State.SourceContexts > 0, "Source contexts should persist.")

	local optionalPlayer = makeFakePlayer(931002, "Phase3BOptional")
	assertResultSuccess(PlayerDataService.InitPlayer(optionalPlayer), "Optional objective smoke player should initialize.")
	markPreviousQuestsCompleted(PlayerDataService, optionalPlayer, {
		"quest_ep01_main_001",
		"quest_ep01_main_002",
		"quest_ep01_main_003",
		"quest_ep01_main_004",
	})

	assertCondition(QuestService.CanStartQuest(optionalPlayer, "quest_ep01_main_005") == true, "Quest 005 should be startable after previous quest setup.")
	assertResultSuccess(QuestService.StartQuest(optionalPlayer, "quest_ep01_main_005", {
		SourceType = "SmokeTest",
		SourceId = "phase3b_start_005",
	}), "Quest 005 should start.")

	progressObjectives(QuestService, optionalPlayer, "quest_ep01_main_005", {
		"obj_ep01_main_005_001",
		"obj_ep01_main_005_002",
		"obj_ep01_main_005_003",
		"obj_ep01_main_005_004",
	}, "phase3b_progress_005_required")

	assertResultSuccess(QuestService.CompleteQuest(optionalPlayer, "quest_ep01_main_005", {
		SourceType = "QuestCompletion",
		SourceId = "quest_ep01_main_005",
	}), "Quest 005 should complete without optional objectives.")
	assertCondition(InventoryService.HasItem(optionalPlayer, "item_ep01_fragment_theos", 1), "Quest 005 main reward should grant THEOS fragment.")

	local optionalSnapshot = PlayerDataService.GetSnapshot(optionalPlayer)
	assertResultSuccess(optionalSnapshot, "Optional player snapshot should read.")
	assertCondition(optionalSnapshot.Data.Quests.QuestStates.quest_ep01_main_005.ObjectiveStates.obj_ep01_main_005_optional_001.Optional == true, "Optional objective should be marked optional.")
	assertCondition(optionalSnapshot.Data.Quests.QuestStates.quest_ep01_main_005.ObjectiveStates.obj_ep01_main_005_optional_001.Completed == false, "Incomplete optional objective should not block completion.")

	local finalPlayer = makeFakePlayer(931003, "Phase3BFinal")
	assertResultSuccess(PlayerDataService.InitPlayer(finalPlayer), "Final quest smoke player should initialize.")
	markPreviousQuestsCompleted(PlayerDataService, finalPlayer, {
		"quest_ep01_main_001",
		"quest_ep01_main_002",
		"quest_ep01_main_003",
		"quest_ep01_main_004",
		"quest_ep01_main_005",
		"quest_ep01_main_006",
		"quest_ep01_main_007",
	})

	assertCondition(QuestService.CanStartQuest(finalPlayer, "quest_ep01_main_008") == true, "Quest 008 should be startable after previous quest setup.")
	assertResultSuccess(QuestService.StartQuest(finalPlayer, "quest_ep01_main_008", {
		SourceType = "SmokeTest",
		SourceId = "phase3b_start_008",
	}), "Quest 008 should start.")

	progressObjectives(QuestService, finalPlayer, "quest_ep01_main_008", {
		"obj_ep01_main_008_001",
		"obj_ep01_main_008_002",
		"obj_ep01_main_008_003",
		"obj_ep01_main_008_004",
		"obj_ep01_main_008_005",
	}, "phase3b_progress_008")

	assertResultFailure(QuestService.CompleteQuest(finalPlayer, "quest_ep01_main_008", {
		SourceType = "QuestCompletion",
		SourceId = "quest_ep01_main_008",
	}), "MissingEpisodeOneAssemblyItem", "Quest 008 should not complete without required fragment ownership.")

	local finalSnapshot = PlayerDataService.GetSnapshot(finalPlayer)
	assertResultSuccess(finalSnapshot, "Final quest player snapshot should read.")
	assertCondition(finalSnapshot.Data.Quests.CompletedQuestIds.quest_ep01_main_008 ~= true, "Quest 008 should remain incomplete after reward validation failure.")

	assertResultSuccess(PlayerDataService.ReleasePlayer(quest001Player), "Quest 001 player should release.")
	assertResultSuccess(PlayerDataService.ReleasePlayer(optionalPlayer), "Optional player should release.")
	assertResultSuccess(PlayerDataService.ReleasePlayer(finalPlayer), "Final player should release.")

	print("[ANP Phase3BSmokeTest] Phase 3B smoke test passed.")
end

return Phase3BSmokeTest
