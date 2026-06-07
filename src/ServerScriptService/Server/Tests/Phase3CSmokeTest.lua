local RunService = game:GetService("RunService")

local Phase3CSmokeTest = {}

local EPISODE_ONE_ZONE_IDS = {
	zone_ep01_command_center = true,
	zone_ep01_universe_explorer = true,
	zone_ep01_terrain_sandbox = true,
	zone_ep01_theos_satellite_center = true,
	zone_ep01_rocket_mission = true,
	zone_ep01_astronaut_training = true,
	zone_ep01_moon_walk = true,
}

local MINIMUM_DISCOVERY_IDS = {
	disc_ep01_command_expedition_terminal = true,
	disc_ep01_command_star_core_display = true,
	disc_ep01_universe_first_signal_marker = true,
	disc_ep01_theos_satellite_history = true,
	disc_ep01_moon_star_core_segment_restoration_point = true,
}

local MINIMUM_INTERACTION_IDS = {
	interaction_ep01_main_001_001 = true,
	interaction_ep01_main_001_002 = true,
	interaction_ep01_main_001_003 = true,
	interaction_ep01_main_002_002 = true,
	interaction_ep01_main_005_003 = true,
	interaction_ep01_main_008_005 = true,
}

local function assertCondition(condition, message)
	if not condition then
		error("[ANP Phase3CSmokeTest] " .. message, 2)
	end
end

local function assertResultSuccess(serviceResult, message)
	assertCondition(serviceResult and serviceResult.Success == true, message .. " Code: " .. tostring(serviceResult and serviceResult.Code))
end

local function countMapValues(map)
	local count = 0
	for _ in pairs(map) do
		count += 1
	end
	return count
end

function Phase3CSmokeTest.Run(services)
	local SkeletonWorldBuilder = services.SkeletonWorldBuilder
	local WorldRegistryService = services.WorldRegistryService
	local WorldObjectValidator = services.WorldObjectValidator

	print("[ANP Phase3CSmokeTest] Starting Phase 3C smoke test.")

	assertCondition(RunService:IsStudio(), "Phase 3C smoke test must run in Studio only.")

	assertResultSuccess(SkeletonWorldBuilder.BuildIfMissing(), "Skeleton world should build in Studio.")
	assertResultSuccess(WorldRegistryService.Init(), "WorldRegistryService should register skeleton world.")

	local validationResult = WorldObjectValidator.Validate()
	if not validationResult.Success then
		for _, errorMessage in ipairs(validationResult.Errors) do
			warn("[ANP Phase3CSmokeTest] " .. errorMessage)
		end
	end
	assertCondition(validationResult.Success == true, "WorldObjectValidator should pass.")
	assertCondition(validationResult.Summary.DuplicateIds == 0, "WorldObjectValidator should report no duplicate IDs.")
	local duplicatesResult = WorldRegistryService.GetDuplicates()
	assertResultSuccess(duplicatesResult, "WorldRegistryService should expose duplicate ID results.")
	assertCondition(#duplicatesResult.Data == 0, "WorldRegistryService should report no duplicate IDs.")

	local zonesResult = WorldRegistryService.GetZones()
	assertResultSuccess(zonesResult, "WorldRegistryService should return zones.")
	assertCondition(countMapValues(zonesResult.Data) >= 7, "WorldRegistryService should register at least 7 Episode 1 zones.")
	for zoneId in pairs(EPISODE_ONE_ZONE_IDS) do
		assertCondition(zonesResult.Data[zoneId] ~= nil, "Episode 1 zone should exist: " .. zoneId)
	end

	local npcMarkersResult = WorldRegistryService.GetNPCMarkers()
	assertResultSuccess(npcMarkersResult, "WorldRegistryService should return NPC markers.")
	assertCondition(countMapValues(npcMarkersResult.Data) >= 3, "WorldRegistryService should register at least 3 NPC markers.")

	local discoveryPointsResult = WorldRegistryService.GetDiscoveryPoints()
	assertResultSuccess(discoveryPointsResult, "WorldRegistryService should return discovery points.")
	for discoveryId in pairs(MINIMUM_DISCOVERY_IDS) do
		assertCondition(discoveryPointsResult.Data[discoveryId] ~= nil, "Minimum discovery point should exist: " .. discoveryId)
	end

	local interactionPointsResult = WorldRegistryService.GetInteractionPoints()
	assertResultSuccess(interactionPointsResult, "WorldRegistryService should return interaction points.")
	for interactionId in pairs(MINIMUM_INTERACTION_IDS) do
		assertCondition(interactionPointsResult.Data[interactionId] ~= nil, "Minimum interaction point should exist: " .. interactionId)
	end

	print("[ANP Phase3CSmokeTest] Phase 3C smoke test passed.")
end

return Phase3CSmokeTest
