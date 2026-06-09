local RunService = game:GetService("RunService")

local Phase3FSmokeTest = {}

local function assertCondition(condition, message)
	if not condition then
		error("[ANP Phase3FSmokeTest] " .. message, 2)
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

function Phase3FSmokeTest.Run(services)
	local PlayerDataService = services.PlayerDataService
	local QuestService = services.QuestService
	local PromptBindingService = services.PromptBindingService
	local SkeletonWorldBuilder = services.SkeletonWorldBuilder
	local WorldRegistryService = services.WorldRegistryService

	print("[ANP Phase3FSmokeTest] Starting Phase 3F smoke test.")

	assertCondition(RunService:IsStudio(), "Phase 3F smoke test must run in Studio only.")

	PlayerDataService.ResetForTests()
	PromptBindingService.ResetForTests()

	assertResultSuccess(SkeletonWorldBuilder.BuildIfMissing(), "Skeleton world should build in Studio.")
	assertResultSuccess(WorldRegistryService.Init(), "World registry should initialize for Phase 3F.")
	assertResultSuccess(PromptBindingService.BindAllPrompts(), "PromptBindingService should bind Phase 3F prompts.")

	local player = makeFakePlayer(934001, "Phase3FQuestStart")
	assertResultSuccess(PlayerDataService.InitPlayer(player), "Phase 3F player data should initialize.")

	local startQuest001Result = PromptBindingService.SimulatePromptTrigger(player, "interaction_start_ep01_main_001", {})
	assertResultSuccess(startQuest001Result, "Quest 001 should start through QuestStart interaction.")
	assertCondition(startQuest001Result.GrantedQuestStart == true, "QuestStart interaction should report quest start.")

	local quest001State = QuestService.GetQuestState(player, "quest_ep01_main_001")
	assertResultSuccess(quest001State, "Quest 001 state should read after QuestStart interaction.")
	assertCondition(quest001State.Data.Status == QuestService.QuestStatus.Active, "Quest 001 should be active after QuestStart interaction.")

	assertResultSuccess(
		PromptBindingService.SimulatePromptTrigger(player, "interaction_ep01_main_001_001", {}),
		"Quest 001 objective 001 should progress through existing objective interaction."
	)
	assertResultSuccess(
		PromptBindingService.SimulatePromptTrigger(player, "interaction_ep01_main_001_002", {}),
		"Quest 001 objective 002 should progress through existing objective interaction."
	)
	assertResultSuccess(
		PromptBindingService.SimulatePromptTrigger(player, "interaction_ep01_main_001_003", {}),
		"Quest 001 objective 003 should progress through existing objective interaction."
	)

	assertResultSuccess(QuestService.ApplyObjectiveProgress(player, "quest_ep01_main_001", "obj_ep01_main_001_004", 1, {
		SourceType = "SmokeTest",
		SourceId = "phase3f_complete_remaining_q001_objective",
	}, {}), "Quest 001 final required objective should progress through QuestService test hook.")

	local completeQuest001Result = QuestService.CompleteQuest(player, "quest_ep01_main_001", {
		SourceType = "SmokeTest",
		SourceId = "phase3f_complete_q001",
	})
	assertResultSuccess(completeQuest001Result, "Quest 001 should complete after required objectives.")

	local progressionSnapshot = PlayerDataService.GetSnapshot(player, "Progression")
	assertResultSuccess(progressionSnapshot, "Progression should read after Quest 001 completion.")
	assertCondition(progressionSnapshot.Data.ExplorerScore == 125, "Quest 001 completion should grant reward_ep01_main_001 ExplorerScore.")

	local zoneSnapshot = PlayerDataService.GetSnapshot(player, "Zones")
	assertResultSuccess(zoneSnapshot, "Zone state should read after Quest 001 reward.")
	assertCondition(zoneSnapshot.Data.UnlockedZoneIds.zone_ep01_universe_explorer == true, "Quest 001 reward should unlock Universe Explorer.")

	local quest002ObjectiveBeforeStart = PromptBindingService.SimulatePromptTrigger(player, "interaction_ep01_main_002_002", {})
	assertResultFailure(quest002ObjectiveBeforeStart, "QuestNotActive", "Quest 002 objective interaction should fail before quest start.")

	local startQuest002Result = PromptBindingService.SimulatePromptTrigger(player, "interaction_start_ep01_main_002", {})
	assertResultSuccess(startQuest002Result, "Quest 002 should start through QuestStart interaction after prerequisite and zone unlock.")

	local quest002State = QuestService.GetQuestState(player, "quest_ep01_main_002")
	assertResultSuccess(quest002State, "Quest 002 state should read after QuestStart interaction.")
	assertCondition(quest002State.Data.Status == QuestService.QuestStatus.Active, "Quest 002 should be active after QuestStart interaction.")

	local duplicateQuest002Start = PromptBindingService.SimulatePromptTrigger(player, "interaction_start_ep01_main_002", {})
	assertResultFailure(duplicateQuest002Start, "QuestAlreadyActive", "Duplicate QuestStart should be blocked for active quest.")

	local completedQuest001Restart = PromptBindingService.SimulatePromptTrigger(player, "interaction_start_ep01_main_001", {})
	assertResultFailure(completedQuest001Restart, "QuestAlreadyCompleted", "Completed quest cannot be started again.")

	assertResultSuccess(PlayerDataService.ReleasePlayer(player), "Phase 3F player data should release.")

	print("[ANP Phase3FSmokeTest] Phase 3F smoke test passed.")
end

return Phase3FSmokeTest
