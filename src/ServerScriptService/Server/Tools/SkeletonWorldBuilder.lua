local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ZoneDefinitions = require(Shared.Definitions.ZoneDefinitions)
local InteractionDefinitions = require(Shared.Definitions.InteractionDefinitions)
local QuestDefinitions = require(Shared.Definitions.QuestDefinitions)
local CharacterConfig = require(Shared.Config.CharacterConfig)

local SkeletonWorldBuilder = {}

local WORLD_ROOT_NAME = "ANP_World"
local REQUIRED_FOLDERS = {
	"Zones",
	"SpawnPoints",
	"InteractionPoints",
	"DiscoveryPoints",
	"NPCMarkers",
}

local DEVELOPER_LABEL_NAME = "ANP_DeveloperLabel"

local DEV_LABEL_CONFIG = {
	Enabled = true,
	ShowLongIds = false,
	MaxDistance = 55,
	TextSize = 12,
	StudsOffsetY = 3.5,
	UseCompactText = true,
}

local PLACEHOLDER_COLORS = {
	QuestStart = Color3.fromRGB(80, 220, 120),
	QuestComplete = Color3.fromRGB(80, 230, 235),
	QuestObjective = Color3.fromRGB(90, 155, 255),
	Discovery = Color3.fromRGB(245, 210, 80),
	ZoneTravel = Color3.fromRGB(170, 110, 245),
	NPCMarker = Color3.fromRGB(245, 145, 65),
	SpawnPoint = Color3.fromRGB(245, 245, 245),
}

local CHARACTER_FRIENDLY_NAMES = {
	[CharacterConfig.Ids.Atom] = "Atom",
	[CharacterConfig.Ids.Neutron] = "Neutron",
	[CharacterConfig.Ids.Proton] = "Proton",
}

local DISCOVERY_FRIENDLY_NAMES = {
	disc_ep01_command_expedition_terminal = "Expedition Terminal",
	disc_ep01_command_star_core_display = "Star Core Display",
	disc_ep01_universe_first_signal_marker = "First Signal Marker",
	disc_ep01_universe_analysis_station = "Neutron Analysis Station",
	disc_ep01_theos_satellite_history = "THEOS Satellite History",
	disc_ep01_moon_star_core_segment_restoration_point = "Star Core Restoration Point",
}

local EPISODE_ONE_ZONE_IDS = {
	"zone_ep01_command_center",
	"zone_ep01_universe_explorer",
	"zone_ep01_terrain_sandbox",
	"zone_ep01_theos_satellite_center",
	"zone_ep01_rocket_mission",
	"zone_ep01_astronaut_training",
	"zone_ep01_moon_walk",
}

local MINIMUM_DISCOVERY_POINTS = {
	{
		DiscoveryId = "disc_ep01_command_expedition_terminal",
		ZoneId = "zone_ep01_command_center",
	},
	{
		DiscoveryId = "disc_ep01_command_star_core_display",
		ZoneId = "zone_ep01_command_center",
	},
	{
		DiscoveryId = "disc_ep01_universe_first_signal_marker",
		ZoneId = "zone_ep01_universe_explorer",
	},
	{
		DiscoveryId = "disc_ep01_universe_analysis_station",
		ZoneId = "zone_ep01_universe_explorer",
	},
	{
		DiscoveryId = "disc_ep01_theos_satellite_history",
		ZoneId = "zone_ep01_theos_satellite_center",
	},
	{
		DiscoveryId = "disc_ep01_moon_star_core_segment_restoration_point",
		ZoneId = "zone_ep01_moon_walk",
	},
}

local MINIMUM_INTERACTION_POINTS = {
	{
		InteractionId = "interaction_start_ep01_main_001",
		QuestId = "quest_ep01_main_001",
		ZoneId = "zone_ep01_command_center",
		Type = "QuestStart",
		Name = "StartQuest_001",
	},
	{
		InteractionId = "interaction_start_ep01_main_002",
		QuestId = "quest_ep01_main_002",
		ZoneId = "zone_ep01_universe_explorer",
		Type = "QuestStart",
		Name = "StartQuest_002",
	},
	{
		InteractionId = "interaction_start_ep01_main_003",
		QuestId = "quest_ep01_main_003",
		ZoneId = "zone_ep01_universe_explorer",
		Type = "QuestStart",
		Name = "StartQuest_003",
	},
	{
		InteractionId = "interaction_start_ep01_main_004",
		QuestId = "quest_ep01_main_004",
		ZoneId = "zone_ep01_terrain_sandbox",
		Type = "QuestStart",
		Name = "StartQuest_004",
	},
	{
		InteractionId = "interaction_start_ep01_main_005",
		QuestId = "quest_ep01_main_005",
		ZoneId = "zone_ep01_theos_satellite_center",
		Type = "QuestStart",
		Name = "StartQuest_005",
	},
	{
		InteractionId = "interaction_start_ep01_main_006",
		QuestId = "quest_ep01_main_006",
		ZoneId = "zone_ep01_rocket_mission",
		Type = "QuestStart",
		Name = "StartQuest_006",
	},
	{
		InteractionId = "interaction_start_ep01_main_007",
		QuestId = "quest_ep01_main_007",
		ZoneId = "zone_ep01_astronaut_training",
		Type = "QuestStart",
		Name = "StartQuest_007",
	},
	{
		InteractionId = "interaction_start_ep01_main_008",
		QuestId = "quest_ep01_main_008",
		ZoneId = "zone_ep01_moon_walk",
		Type = "QuestStart",
		Name = "StartQuest_008",
	},
	{
		InteractionId = "interaction_complete_ep01_main_001",
		QuestId = "quest_ep01_main_001",
		ZoneId = "zone_ep01_command_center",
		Type = "QuestComplete",
		Name = "CompleteQuest_001",
	},
	{
		InteractionId = "interaction_ep01_main_001_001",
		QuestId = "quest_ep01_main_001",
		ObjectiveId = "obj_ep01_main_001_001",
		ZoneId = "zone_ep01_command_center",
		Type = "QuestObjective",
	},
	{
		InteractionId = "interaction_ep01_main_001_002",
		QuestId = "quest_ep01_main_001",
		ObjectiveId = "obj_ep01_main_001_002",
		ZoneId = "zone_ep01_command_center",
		Type = "QuestObjective",
	},
	{
		InteractionId = "interaction_ep01_main_001_003",
		QuestId = "quest_ep01_main_001",
		ObjectiveId = "obj_ep01_main_001_003",
		ZoneId = "zone_ep01_command_center",
		Type = "QuestObjective",
	},
	{
		InteractionId = "interaction_ep01_main_002_002",
		QuestId = "quest_ep01_main_002",
		ObjectiveId = "obj_ep01_main_002_002",
		ZoneId = "zone_ep01_universe_explorer",
		Type = "QuestObjective",
		Name = "Quest002_LocateSignalMarker",
		FriendlyName = "Quest 002 - Locate Signal Marker",
	},
	{
		InteractionId = "interaction_ep01_main_002_001",
		QuestId = "quest_ep01_main_002",
		ObjectiveId = "obj_ep01_main_002_001",
		ZoneId = "zone_ep01_universe_explorer",
		Type = "QuestObjective",
		Name = "Quest002_EnterUniverseExplorer",
		FriendlyName = "Quest 002 - Enter Universe Explorer",
	},
	{
		InteractionId = "interaction_ep01_main_002_003",
		QuestId = "quest_ep01_main_002",
		ObjectiveId = "obj_ep01_main_002_003",
		ZoneId = "zone_ep01_universe_explorer",
		Type = "QuestObjective",
		Name = "Quest002_ScanSignalMarker",
		FriendlyName = "Quest 002 - Scan Signal Marker",
	},
	{
		InteractionId = "interaction_ep01_main_002_004",
		QuestId = "quest_ep01_main_002",
		ObjectiveId = "obj_ep01_main_002_004",
		ZoneId = "zone_ep01_universe_explorer",
		Type = "QuestObjective",
		Name = "Quest002_AnalysisStation",
		FriendlyName = "Quest 002 - Analysis Station",
	},
	{
		InteractionId = "interaction_ep01_main_003_001",
		QuestId = "quest_ep01_main_003",
		ObjectiveId = "obj_ep01_main_003_001",
		ZoneId = "zone_ep01_universe_explorer",
		Type = "QuestObjective",
		Name = "Quest003_StarSignalTrail",
		FriendlyName = "Quest 003 - Star Signal Trail",
	},
	{
		InteractionId = "interaction_ep01_main_003_002",
		QuestId = "quest_ep01_main_003",
		ObjectiveId = "obj_ep01_main_003_002",
		ZoneId = "zone_ep01_universe_explorer",
		Type = "QuestObjective",
		Name = "Quest003_SignalEcho",
		FriendlyName = "Quest 003 - Signal Echo",
	},
	{
		InteractionId = "interaction_ep01_main_003_003",
		QuestId = "quest_ep01_main_003",
		ObjectiveId = "obj_ep01_main_003_003",
		ZoneId = "zone_ep01_universe_explorer",
		Type = "QuestObjective",
		Name = "Quest003_StabilizeFragment",
		FriendlyName = "Quest 003 - Stabilize Fragment",
	},
	{
		InteractionId = "interaction_ep01_main_003_004",
		QuestId = "quest_ep01_main_003",
		ObjectiveId = "obj_ep01_main_003_004",
		ZoneId = "zone_ep01_universe_explorer",
		Type = "QuestObjective",
		Name = "Quest003_RecoverUniverseFragment",
		FriendlyName = "Quest 003 - Recover Universe Fragment",
	},
	{
		InteractionId = "interaction_ep01_main_004_001",
		QuestId = "quest_ep01_main_004",
		ObjectiveId = "obj_ep01_main_004_001",
		ZoneId = "zone_ep01_terrain_sandbox",
		Type = "QuestObjective",
		Name = "Quest004_EnterTerrainSandbox",
		FriendlyName = "Quest 004 - Enter Terrain Sandbox",
	},
	{
		InteractionId = "interaction_ep01_main_004_002",
		QuestId = "quest_ep01_main_004",
		ObjectiveId = "obj_ep01_main_004_002",
		ZoneId = "zone_ep01_terrain_sandbox",
		Type = "QuestObjective",
		Name = "Quest004_EarthMemoryMarker",
		FriendlyName = "Quest 004 - Earth Memory Marker",
	},
	{
		InteractionId = "interaction_ep01_main_004_003",
		QuestId = "quest_ep01_main_004",
		ObjectiveId = "obj_ep01_main_004_003",
		ZoneId = "zone_ep01_terrain_sandbox",
		Type = "QuestObjective",
		Name = "Quest004_RebuildTerrainPath",
		FriendlyName = "Quest 004 - Rebuild Terrain Path",
	},
	{
		InteractionId = "interaction_ep01_main_004_004",
		QuestId = "quest_ep01_main_004",
		ObjectiveId = "obj_ep01_main_004_004",
		ZoneId = "zone_ep01_terrain_sandbox",
		Type = "QuestObjective",
		Name = "Quest004_RecoverEarthFragment",
		FriendlyName = "Quest 004 - Recover Earth Fragment",
	},
	{
		InteractionId = "interaction_ep01_main_005_001",
		QuestId = "quest_ep01_main_005",
		ObjectiveId = "obj_ep01_main_005_001",
		ZoneId = "zone_ep01_theos_satellite_center",
		Type = "QuestObjective",
		Name = "Quest005_EnterTHEOS",
		FriendlyName = "Quest 005 - Enter THEOS Satellite Center",
	},
	{
		InteractionId = "interaction_ep01_main_005_002",
		QuestId = "quest_ep01_main_005",
		ObjectiveId = "obj_ep01_main_005_002",
		ZoneId = "zone_ep01_theos_satellite_center",
		Type = "QuestObjective",
		Name = "Quest005_SatelliteArchive",
		FriendlyName = "Quest 005 - Satellite Archive",
	},
	{
		InteractionId = "interaction_ep01_main_005_003",
		QuestId = "quest_ep01_main_005",
		ObjectiveId = "obj_ep01_main_005_003",
		ZoneId = "zone_ep01_theos_satellite_center",
		Type = "QuestObjective",
		Name = "Quest005_RestoreSignalRelay",
		FriendlyName = "Quest 005 - Restore Signal Relay",
	},
	{
		InteractionId = "interaction_ep01_main_005_004",
		QuestId = "quest_ep01_main_005",
		ObjectiveId = "obj_ep01_main_005_004",
		ZoneId = "zone_ep01_theos_satellite_center",
		Type = "QuestObjective",
		Name = "Quest005_RecoverTHEOSFragment",
		FriendlyName = "Quest 005 - Recover THEOS Fragment",
	},
	{
		InteractionId = "interaction_ep01_main_006_001",
		QuestId = "quest_ep01_main_006",
		ObjectiveId = "obj_ep01_main_006_001",
		ZoneId = "zone_ep01_rocket_mission",
		Type = "QuestObjective",
		Name = "Quest006_EnterRocketMission",
		FriendlyName = "Quest 006 - Enter Rocket Mission",
	},
	{
		InteractionId = "interaction_ep01_main_006_002",
		QuestId = "quest_ep01_main_006",
		ObjectiveId = "obj_ep01_main_006_002",
		ZoneId = "zone_ep01_rocket_mission",
		Type = "QuestObjective",
		Name = "Quest006_RocketControlPanel",
		FriendlyName = "Quest 006 - Rocket Control Panel",
	},
	{
		InteractionId = "interaction_ep01_main_006_003",
		QuestId = "quest_ep01_main_006",
		ObjectiveId = "obj_ep01_main_006_003",
		ZoneId = "zone_ep01_rocket_mission",
		Type = "QuestObjective",
		Name = "Quest006_LaunchDiagnostics",
		FriendlyName = "Quest 006 - Launch Diagnostics",
	},
	{
		InteractionId = "interaction_ep01_main_006_004",
		QuestId = "quest_ep01_main_006",
		ObjectiveId = "obj_ep01_main_006_004",
		ZoneId = "zone_ep01_rocket_mission",
		Type = "QuestObjective",
		Name = "Quest006_RecoverRocketFragment",
		FriendlyName = "Quest 006 - Recover Rocket Fragment",
	},
	{
		InteractionId = "interaction_ep01_main_007_001",
		QuestId = "quest_ep01_main_007",
		ObjectiveId = "obj_ep01_main_007_001",
		ZoneId = "zone_ep01_astronaut_training",
		Type = "QuestObjective",
		Name = "Quest007_EnterAstronautTraining",
		FriendlyName = "Quest 007 - Enter Astronaut Training",
	},
	{
		InteractionId = "interaction_ep01_main_007_002",
		QuestId = "quest_ep01_main_007",
		ObjectiveId = "obj_ep01_main_007_002",
		ZoneId = "zone_ep01_astronaut_training",
		Type = "QuestObjective",
		Name = "Quest007_MovementTrainingStation",
		FriendlyName = "Quest 007 - Movement Training Station",
	},
	{
		InteractionId = "interaction_ep01_main_007_003",
		QuestId = "quest_ep01_main_007",
		ObjectiveId = "obj_ep01_main_007_003",
		ZoneId = "zone_ep01_astronaut_training",
		Type = "QuestObjective",
		Name = "Quest007_OxygenSafetyStation",
		FriendlyName = "Quest 007 - Oxygen Safety Station",
	},
	{
		InteractionId = "interaction_ep01_main_007_004",
		QuestId = "quest_ep01_main_007",
		ObjectiveId = "obj_ep01_main_007_004",
		ZoneId = "zone_ep01_astronaut_training",
		Type = "QuestObjective",
		Name = "Quest007_MoonMissionClearance",
		FriendlyName = "Quest 007 - Moon Mission Clearance",
	},
	{
		InteractionId = "interaction_ep01_main_008_001",
		QuestId = "quest_ep01_main_008",
		ObjectiveId = "obj_ep01_main_008_001",
		ZoneId = "zone_ep01_moon_walk",
		Type = "QuestObjective",
		Name = "Quest008_EnterMoonWalk",
		FriendlyName = "Quest 008 - Enter Moon Walk",
	},
	{
		InteractionId = "interaction_ep01_main_008_002",
		QuestId = "quest_ep01_main_008",
		ObjectiveId = "obj_ep01_main_008_002",
		ZoneId = "zone_ep01_moon_walk",
		Type = "QuestObjective",
		Name = "Quest008_MoonSignalTrail",
		FriendlyName = "Quest 008 - Moon Signal Trail",
	},
	{
		InteractionId = "interaction_ep01_main_008_003",
		QuestId = "quest_ep01_main_008",
		ObjectiveId = "obj_ep01_main_008_003",
		ZoneId = "zone_ep01_moon_walk",
		Type = "QuestObjective",
		Name = "Quest008_RecoverMoonFragment",
		FriendlyName = "Quest 008 - Recover Moon Fragment",
	},
	{
		InteractionId = "interaction_ep01_main_008_004",
		QuestId = "quest_ep01_main_008",
		ObjectiveId = "obj_ep01_main_008_004",
		ZoneId = "zone_ep01_moon_walk",
		Type = "QuestObjective",
		Name = "Quest008_VerifyFragmentSet",
		FriendlyName = "Quest 008 - Verify Fragment Set",
	},
	{
		InteractionId = "interaction_ep01_main_008_005",
		QuestId = "quest_ep01_main_008",
		ObjectiveId = "obj_ep01_main_008_005",
		ZoneId = "zone_ep01_moon_walk",
		Type = "QuestObjective",
		Name = "Quest008_RestoreStarCoreSegment01",
		FriendlyName = "Quest 008 - Restore Star Core Segment 01",
	},
	{
		InteractionId = "interaction_travel_ep01_universe_explorer",
		QuestId = "quest_ep01_main_002",
		ObjectiveId = "obj_ep01_main_002_002",
		ZoneId = "zone_ep01_universe_explorer",
		Type = "ZoneTravel",
	},
	{
		InteractionId = "interaction_complete_ep01_main_002",
		QuestId = "quest_ep01_main_002",
		ZoneId = "zone_ep01_universe_explorer",
		Type = "QuestComplete",
		Name = "CompleteQuest_002",
	},
	{
		InteractionId = "interaction_complete_ep01_main_003",
		QuestId = "quest_ep01_main_003",
		ZoneId = "zone_ep01_universe_explorer",
		Type = "QuestComplete",
		Name = "CompleteQuest_003",
	},
	{
		InteractionId = "interaction_complete_ep01_main_004",
		QuestId = "quest_ep01_main_004",
		ZoneId = "zone_ep01_terrain_sandbox",
		Type = "QuestComplete",
		Name = "CompleteQuest_004",
	},
	{
		InteractionId = "interaction_complete_ep01_main_005",
		QuestId = "quest_ep01_main_005",
		ZoneId = "zone_ep01_theos_satellite_center",
		Type = "QuestComplete",
		Name = "CompleteQuest_005",
	},
	{
		InteractionId = "interaction_complete_ep01_main_006",
		QuestId = "quest_ep01_main_006",
		ZoneId = "zone_ep01_rocket_mission",
		Type = "QuestComplete",
		Name = "CompleteQuest_006",
	},
	{
		InteractionId = "interaction_complete_ep01_main_007",
		QuestId = "quest_ep01_main_007",
		ZoneId = "zone_ep01_astronaut_training",
		Type = "QuestComplete",
		Name = "CompleteQuest_007",
	},
	{
		InteractionId = "interaction_complete_ep01_main_008",
		QuestId = "quest_ep01_main_008",
		ZoneId = "zone_ep01_moon_walk",
		Type = "QuestComplete",
		Name = "CompleteEpisode_001",
		FriendlyName = "Episode 1 Finale",
	},
}

local NPC_MARKERS = {
	{
		CharacterId = CharacterConfig.Ids.Atom,
		InteractionId = "interaction_npc_atom_guide",
		ZoneId = "zone_ep01_command_center",
	},
	{
		CharacterId = CharacterConfig.Ids.Neutron,
		InteractionId = "interaction_npc_neutron_guide",
		ZoneId = "zone_ep01_command_center",
	},
	{
		CharacterId = CharacterConfig.Ids.Proton,
		InteractionId = "interaction_npc_proton_guide",
		ZoneId = "zone_ep01_command_center",
	},
}

local TRACK_ORIGIN = Vector3.new(0, 0, 0)
local TRACK_STEP_SPACING = 16
local TRACK_ROW_SPACING = 28
local TRACK_SIDE_OFFSET = 12
local TRACK_INTERACTION_Y = 7
local TRACK_DISCOVERY_Y = 8
local TRACK_ZONE_Y = 2
local TRACK_SPAWN_Y = 6
local TRACK_NPC_Y = 7

local ZONE_ROW_HINTS = {
	zone_ep01_command_center = 1,
	zone_ep01_universe_explorer = 2.5,
	zone_ep01_terrain_sandbox = 4,
	zone_ep01_theos_satellite_center = 5,
	zone_ep01_rocket_mission = 6,
	zone_ep01_astronaut_training = 7,
	zone_ep01_moon_walk = 8,
}

local DISCOVERY_TRACK_POSITIONS = {
	disc_ep01_command_expedition_terminal = { QuestId = "quest_ep01_main_001", StepIndex = 1, Side = 1 },
	disc_ep01_command_star_core_display = { QuestId = "quest_ep01_main_001", StepIndex = 4 },
	disc_ep01_universe_first_signal_marker = { QuestId = "quest_ep01_main_002", StepIndex = 2, Side = 1 },
	disc_ep01_universe_analysis_station = { QuestId = "quest_ep01_main_002", StepIndex = 4, Side = 1 },
	disc_ep01_theos_satellite_history = { QuestId = "quest_ep01_main_005", StepIndex = 2, Side = 1 },
	disc_ep01_moon_star_core_segment_restoration_point = { QuestId = "quest_ep01_main_008", StepIndex = 5, Side = 1 },
}

local function result(success, code, message, data)
	return {
		Success = success,
		Code = code,
		Message = message,
		Data = data,
	}
end

local function getOrCreateFolder(parent, folderName)
	local folder = parent:FindFirstChild(folderName)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = folderName
		folder.Parent = parent
	end

	return folder
end

local function findChildByAttribute(folder, attributeName, value)
	for _, child in ipairs(folder:GetChildren()) do
		if child:GetAttribute(attributeName) == value then
			return child
		end
	end

	return nil
end

local function getQuestIndex(questId)
	local questNumber = tonumber(string.match(questId or "", "main_(%d+)"))
	if questNumber then
		return questNumber
	end

	return 1
end

local function getQuestRowZ(questId)
	return TRACK_ORIGIN.Z + (getQuestIndex(questId) - 1) * TRACK_ROW_SPACING
end

local function getTrackPosition(questId, stepIndex, y, sideOffset)
	return Vector3.new(
		TRACK_ORIGIN.X + stepIndex * TRACK_STEP_SPACING,
		y,
		getQuestRowZ(questId) + (sideOffset or 0)
	)
end

local function getObjectiveStepIndex(questId, objectiveId)
	local questDefinition = QuestDefinitions[questId]
	for index, requiredObjectiveId in ipairs((questDefinition and questDefinition.RequiredObjectiveIds) or {}) do
		if requiredObjectiveId == objectiveId then
			return index
		end
	end

	for index, objectiveDefinitionId in ipairs((questDefinition and questDefinition.ObjectiveIds) or {}) do
		if objectiveDefinitionId == objectiveId then
			return index
		end
	end

	return 1
end

local function getQuestCompleteStepIndex(questId)
	local questDefinition = QuestDefinitions[questId]
	return #((questDefinition and questDefinition.RequiredObjectiveIds) or {}) + 1
end

local function getInteractionTrackPosition(interaction, fallbackIndex)
	if interaction.Type == "QuestStart" then
		return getTrackPosition(interaction.QuestId, 0, TRACK_INTERACTION_Y)
	elseif interaction.Type == "QuestComplete" then
		return getTrackPosition(interaction.QuestId, getQuestCompleteStepIndex(interaction.QuestId), TRACK_INTERACTION_Y)
	elseif interaction.Type == "QuestObjective" then
		return getTrackPosition(interaction.QuestId, getObjectiveStepIndex(interaction.QuestId, interaction.ObjectiveId), TRACK_INTERACTION_Y)
	elseif interaction.Type == "ZoneTravel" then
		return getTrackPosition(interaction.QuestId or "quest_ep01_main_002", 1, TRACK_INTERACTION_Y, -TRACK_SIDE_OFFSET)
	end

	return Vector3.new(TRACK_ORIGIN.X + (fallbackIndex - 1) * TRACK_STEP_SPACING, TRACK_INTERACTION_Y, TRACK_ORIGIN.Z - TRACK_ROW_SPACING)
end

local function getDiscoveryTrackPosition(discovery, fallbackIndex)
	local trackPosition = DISCOVERY_TRACK_POSITIONS[discovery.DiscoveryId]
	if trackPosition then
		return getTrackPosition(
			trackPosition.QuestId,
			trackPosition.StepIndex,
			TRACK_DISCOVERY_Y,
			(trackPosition.Side or 0) * TRACK_SIDE_OFFSET
		)
	end

	return Vector3.new(TRACK_ORIGIN.X + (fallbackIndex - 1) * TRACK_STEP_SPACING, TRACK_DISCOVERY_Y, TRACK_ORIGIN.Z + 9 * TRACK_ROW_SPACING)
end

local function getZoneTrackPosition(zoneId)
	local rowHint = ZONE_ROW_HINTS[zoneId] or 1
	return Vector3.new(TRACK_ORIGIN.X - 18, TRACK_ZONE_Y, TRACK_ORIGIN.Z + (rowHint - 1) * TRACK_ROW_SPACING)
end

local function getSpawnTrackPosition(zoneId, spawnIndex)
	local zonePosition = getZoneTrackPosition(zoneId)
	return Vector3.new(zonePosition.X, TRACK_SPAWN_Y, zonePosition.Z + 8 + ((spawnIndex - 1) * 5))
end

local function getNPCTrackPosition(index)
	return Vector3.new(TRACK_ORIGIN.X - 22, TRACK_NPC_Y, TRACK_ORIGIN.Z - 14 + ((index - 1) * 8))
end

local function createPart(folder, name, position, size, color, transparency)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.Size = size
	part.Position = position
	part.Color = color
	part.Transparency = transparency
	part.Parent = folder
	return part
end

local function setAttributes(instance, attributes)
	for attributeName, value in pairs(attributes) do
		instance:SetAttribute(attributeName, value)
	end
end

local function getOrCreateDeveloperLabel(part)
	local label = part:FindFirstChild(DEVELOPER_LABEL_NAME)
	if label and label:IsA("BillboardGui") then
		return label
	end

	label = Instance.new("BillboardGui")
	label.Name = DEVELOPER_LABEL_NAME
	label.AlwaysOnTop = true
	label.Size = UDim2.new(0, 150, 0, 42)
	label.MaxDistance = DEV_LABEL_CONFIG.MaxDistance
	label.Parent = part

	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "Text"
	textLabel.BackgroundColor3 = Color3.fromRGB(20, 24, 30)
	textLabel.BackgroundTransparency = 0.25
	textLabel.BorderSizePixel = 0
	textLabel.Font = Enum.Font.GothamMedium
	textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	textLabel.TextScaled = false
	textLabel.TextSize = DEV_LABEL_CONFIG.TextSize
	textLabel.TextWrapped = true
	textLabel.Size = UDim2.fromScale(1, 1)
	textLabel.Parent = label

	return label
end

local function getQuestShortName(questId)
	local questNumber = tonumber(string.match(questId or "", "main_(%d+)"))
	if questNumber then
		return "Q" .. tostring(questNumber)
	end

	return "Quest"
end

local function getObjectiveShortName(objectiveId)
	local objectiveNumber = tonumber(string.match(objectiveId or "", "_(%d+)$"))
	if objectiveNumber then
		return "Obj" .. tostring(objectiveNumber)
	end

	return "Obj"
end

local function getZoneShortName(zoneId)
	if zoneId == "zone_ep01_universe_explorer" then
		return "Universe"
	elseif zoneId == "zone_ep01_terrain_sandbox" then
		return "Terrain"
	elseif zoneId == "zone_ep01_theos_satellite_center" then
		return "THEOS"
	elseif zoneId == "zone_ep01_rocket_mission" then
		return "Rocket"
	elseif zoneId == "zone_ep01_astronaut_training" then
		return "Astronaut"
	elseif zoneId == "zone_ep01_moon_walk" then
		return "Moon Walk"
	end

	return "Command"
end

local function getCompactInteractionLabel(interaction, friendlyName)
	if interaction.Type == "QuestStart" then
		return getQuestShortName(interaction.QuestId) .. " Start"
	elseif interaction.Type == "QuestComplete" then
		return getQuestShortName(interaction.QuestId) .. " Complete"
	elseif interaction.Type == "QuestObjective" then
		return getQuestShortName(interaction.QuestId) .. " " .. getObjectiveShortName(interaction.ObjectiveId)
	elseif interaction.Type == "ZoneTravel" then
		return "Travel " .. getZoneShortName(interaction.ZoneId)
	end

	return friendlyName
end

local function setDeveloperLabel(object, category, friendlyName, internalId, compactText)
	if not object:IsA("BasePart") then
		return
	end

	if DEV_LABEL_CONFIG.Enabled ~= true then
		local existingLabel = object:FindFirstChild(DEVELOPER_LABEL_NAME)
		if existingLabel then
			existingLabel:Destroy()
		end
		return
	end

	local label = getOrCreateDeveloperLabel(object)
	label.Size = UDim2.new(0, 150, 0, 42)
	label.MaxDistance = DEV_LABEL_CONFIG.MaxDistance
	label.StudsOffset = Vector3.new(0, object.Size.Y / 2 + DEV_LABEL_CONFIG.StudsOffsetY, 0)

	local textLabel = label:FindFirstChild("Text")
	if textLabel and textLabel:IsA("TextLabel") then
		textLabel.TextScaled = false
		textLabel.TextSize = DEV_LABEL_CONFIG.TextSize
		if DEV_LABEL_CONFIG.UseCompactText and compactText then
			textLabel.Text = if DEV_LABEL_CONFIG.ShowLongIds then compactText .. "\n" .. internalId else compactText
		else
			local longIdText = if DEV_LABEL_CONFIG.ShowLongIds then "\n" .. internalId else ""
			textLabel.Text = "[" .. category .. "]\n" .. friendlyName .. longIdText
		end
	end
end

local function ensurePartShape(object, size, color, transparency)
	if not object:IsA("BasePart") then
		return
	end

	object.Anchored = true
	object.CanCollide = false
	object.Size = size
	object.Color = color
	object.Transparency = transparency
end

local function getOrCreatePartByAttribute(folder, attributeName, value, name, position, size, color, transparency, attributes)
	local object = findChildByAttribute(folder, attributeName, value)
	if not object then
		object = folder:FindFirstChild(name)
	end

	if not object then
		object = createPart(folder, name, position, size, color, transparency)
	end

	ensurePartShape(object, size, color, transparency)
	setAttributes(object, attributes)
	return object
end

local function questFriendlyName(questId)
	local questNumber = string.match(questId or "", "main_(%d+)")
	if questNumber then
		return "Quest " .. questNumber
	end

	return questId or "Quest"
end

local function getInteractionFriendlyName(interaction)
	if interaction.FriendlyName then
		return interaction.FriendlyName
	end

	if interaction.Type == "QuestStart" then
		return questFriendlyName(interaction.QuestId)
	elseif interaction.Type == "QuestComplete" then
		return questFriendlyName(interaction.QuestId)
	end

	local definition = InteractionDefinitions[interaction.InteractionId]
	if definition and definition.PromptObjectText then
		if interaction.QuestId == "quest_ep01_main_002" and interaction.Type == "QuestObjective" then
			return "Quest 002 - " .. definition.PromptObjectText
		end

		return definition.PromptObjectText
	end

	if interaction.Type == "ZoneTravel" then
		return "Zone Travel"
	end

	return interaction.ObjectiveId or interaction.InteractionId
end

local function getInteractionLabelCategory(interactionType)
	if interactionType == "QuestStart" then
		return "QUEST START"
	elseif interactionType == "QuestComplete" then
		return "QUEST COMPLETE"
	elseif interactionType == "QuestObjective" then
		return "QUEST OBJECTIVE"
	elseif interactionType == "ZoneTravel" then
		return "ZONE TRAVEL"
	elseif interactionType == "Discovery" then
		return "DISCOVERY"
	end

	return "INTERACTION"
end

local function buildInteractionAttributes(interaction)
	local attributes = {
		InteractionId = interaction.InteractionId,
		QuestId = interaction.QuestId,
		ZoneId = interaction.ZoneId,
		InteractionType = interaction.Type,
	}

	if interaction.ObjectiveId then
		attributes.ObjectiveId = interaction.ObjectiveId
	end

	return attributes
end

local function buildNPCMarkerAttributes(marker)
	return {
		CharacterId = marker.CharacterId,
		InteractionId = marker.InteractionId,
		ZoneId = marker.ZoneId,
		InteractionType = "NPCGuide",
	}
end

function SkeletonWorldBuilder.BuildIfMissing()
	if not RunService:IsStudio() then
		return result(false, "StudioOnly", "SkeletonWorldBuilder can only run in Studio.")
	end

	local worldRoot = Workspace:FindFirstChild(WORLD_ROOT_NAME)
	if not worldRoot then
		worldRoot = Instance.new("Folder")
		worldRoot.Name = WORLD_ROOT_NAME
		worldRoot.Parent = Workspace
	end

	local folders = {}
	for _, folderName in ipairs(REQUIRED_FOLDERS) do
		folders[folderName] = getOrCreateFolder(worldRoot, folderName)
	end

	for index, zoneId in ipairs(EPISODE_ONE_ZONE_IDS) do
		getOrCreatePartByAttribute(
			folders.Zones,
			"ZoneId",
			zoneId,
			"Zone_" .. zoneId,
			getZoneTrackPosition(zoneId),
			Vector3.new(20, 4, 20),
			Color3.fromRGB(70, 110, 160),
			0.65,
			{
				ZoneId = zoneId,
			}
		)

		for spawnIndex, spawnPointId in ipairs((ZoneDefinitions[zoneId] and ZoneDefinitions[zoneId].SpawnPoints) or {}) do
			local spawnObject = getOrCreatePartByAttribute(
				folders.SpawnPoints,
				"SpawnPointId",
				spawnPointId,
				"Spawn_" .. spawnPointId,
				getSpawnTrackPosition(zoneId, spawnIndex),
				Vector3.new(6, 1, 6),
				PLACEHOLDER_COLORS.SpawnPoint,
				0.55,
				{
					SpawnPointId = spawnPointId,
					ZoneId = zoneId,
				}
			)
			setDeveloperLabel(
				spawnObject,
				"SPAWN",
				spawnPointId,
				spawnPointId,
				"Spawn " .. getZoneShortName(zoneId)
			)
		end
	end

	for index, discovery in ipairs(MINIMUM_DISCOVERY_POINTS) do
		local discoveryObject = getOrCreatePartByAttribute(
			folders.DiscoveryPoints,
			"DiscoveryId",
			discovery.DiscoveryId,
			"Discovery_" .. discovery.DiscoveryId,
			getDiscoveryTrackPosition(discovery, index),
			Vector3.new(5, 5, 5),
			PLACEHOLDER_COLORS.Discovery,
			0.35,
			discovery
		)
		setDeveloperLabel(
			discoveryObject,
			"DISCOVERY",
			DISCOVERY_FRIENDLY_NAMES[discovery.DiscoveryId] or discovery.DiscoveryId,
			discovery.DiscoveryId,
			DISCOVERY_FRIENDLY_NAMES[discovery.DiscoveryId] or "Discovery"
		)
	end

	for index, interaction in ipairs(MINIMUM_INTERACTION_POINTS) do
		local partName = interaction.Name or ("Interaction_" .. interaction.InteractionId)
		local interactionObject = getOrCreatePartByAttribute(
			folders.InteractionPoints,
			"InteractionId",
			interaction.InteractionId,
			partName,
			getInteractionTrackPosition(interaction, index),
			Vector3.new(8, 6, 8),
			PLACEHOLDER_COLORS[interaction.Type] or PLACEHOLDER_COLORS.QuestObjective,
			0.35,
			buildInteractionAttributes(interaction)
		)
		setDeveloperLabel(
			interactionObject,
			getInteractionLabelCategory(interaction.Type),
			getInteractionFriendlyName(interaction),
			interaction.InteractionId,
			getCompactInteractionLabel(interaction, getInteractionFriendlyName(interaction))
		)
	end

	for index, marker in ipairs(NPC_MARKERS) do
		local markerObject = getOrCreatePartByAttribute(
			folders.NPCMarkers,
			"CharacterId",
			marker.CharacterId,
			"NPCMarker_" .. marker.CharacterId,
			getNPCTrackPosition(index),
			Vector3.new(4, 6, 4),
			PLACEHOLDER_COLORS.NPCMarker,
			0.45,
			buildNPCMarkerAttributes(marker)
		)
		setDeveloperLabel(
			markerObject,
			"NPC GUIDE",
			CHARACTER_FRIENDLY_NAMES[marker.CharacterId] or marker.CharacterId,
			marker.InteractionId,
			"NPC " .. (CHARACTER_FRIENDLY_NAMES[marker.CharacterId] or marker.CharacterId)
		)
	end

	return result(true, "SkeletonWorldBuilt", nil, {
		WorldRoot = worldRoot,
	})
end

SkeletonWorldBuilder.DevLabels = DEV_LABEL_CONFIG

return SkeletonWorldBuilder
