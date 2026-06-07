local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ZoneDefinitions = require(Shared.Definitions.ZoneDefinitions)
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
		InteractionId = "interaction_ep01_main_001_001",
		QuestId = "quest_ep01_main_001",
		ObjectiveId = "obj_ep01_main_001_001",
		ZoneId = "zone_ep01_command_center",
	},
	{
		InteractionId = "interaction_ep01_main_001_002",
		QuestId = "quest_ep01_main_001",
		ObjectiveId = "obj_ep01_main_001_002",
		ZoneId = "zone_ep01_command_center",
	},
	{
		InteractionId = "interaction_ep01_main_001_003",
		QuestId = "quest_ep01_main_001",
		ObjectiveId = "obj_ep01_main_001_003",
		ZoneId = "zone_ep01_command_center",
	},
	{
		InteractionId = "interaction_ep01_main_002_002",
		QuestId = "quest_ep01_main_002",
		ObjectiveId = "obj_ep01_main_002_002",
		ZoneId = "zone_ep01_universe_explorer",
	},
	{
		InteractionId = "interaction_ep01_main_005_003",
		QuestId = "quest_ep01_main_005",
		ObjectiveId = "obj_ep01_main_005_003",
		ZoneId = "zone_ep01_theos_satellite_center",
	},
	{
		InteractionId = "interaction_ep01_main_008_005",
		QuestId = "quest_ep01_main_008",
		ObjectiveId = "obj_ep01_main_008_005",
		ZoneId = "zone_ep01_moon_walk",
	},
}

local NPC_MARKERS = {
	{
		CharacterId = CharacterConfig.Ids.Atom,
		ZoneId = "zone_ep01_command_center",
	},
	{
		CharacterId = CharacterConfig.Ids.Neutron,
		ZoneId = "zone_ep01_command_center",
	},
	{
		CharacterId = CharacterConfig.Ids.Proton,
		ZoneId = "zone_ep01_command_center",
	},
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

local function getOrCreatePartByAttribute(folder, attributeName, value, name, position, size, color, transparency, attributes)
	local object = findChildByAttribute(folder, attributeName, value)
	if not object then
		object = folder:FindFirstChild(name)
	end

	if not object then
		object = createPart(folder, name, position, size, color, transparency)
	end

	setAttributes(object, attributes)
	return object
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
			Vector3.new((index - 1) * 80, 2, 0),
			Vector3.new(48, 4, 48),
			Color3.fromRGB(70, 110, 160),
			0.65,
			{
				ZoneId = zoneId,
			}
		)

		for spawnIndex, spawnPointId in ipairs((ZoneDefinitions[zoneId] and ZoneDefinitions[zoneId].SpawnPoints) or {}) do
			getOrCreatePartByAttribute(
				folders.SpawnPoints,
				"SpawnPointId",
				spawnPointId,
				"Spawn_" .. spawnPointId,
				Vector3.new((index - 1) * 80, 6, spawnIndex * 8),
				Vector3.new(6, 1, 6),
				Color3.fromRGB(90, 210, 140),
				0.55,
				{
					SpawnPointId = spawnPointId,
					ZoneId = zoneId,
				}
			)
		end
	end

	for index, discovery in ipairs(MINIMUM_DISCOVERY_POINTS) do
		getOrCreatePartByAttribute(
			folders.DiscoveryPoints,
			"DiscoveryId",
			discovery.DiscoveryId,
			"Discovery_" .. discovery.DiscoveryId,
			Vector3.new((index - 1) * 20, 8, 70),
			Vector3.new(5, 5, 5),
			Color3.fromRGB(235, 190, 80),
			0.35,
			discovery
		)
	end

	for index, interaction in ipairs(MINIMUM_INTERACTION_POINTS) do
		getOrCreatePartByAttribute(
			folders.InteractionPoints,
			"InteractionId",
			interaction.InteractionId,
			"Interaction_" .. interaction.InteractionId,
			Vector3.new((index - 1) * 18, 7, -70),
			Vector3.new(5, 5, 5),
			Color3.fromRGB(110, 170, 240),
			0.35,
			interaction
		)
	end

	for index, marker in ipairs(NPC_MARKERS) do
		getOrCreatePartByAttribute(
			folders.NPCMarkers,
			"CharacterId",
			marker.CharacterId,
			"NPCMarker_" .. marker.CharacterId,
			Vector3.new((index - 1) * 8, 7, -18),
			Vector3.new(4, 6, 4),
			Color3.fromRGB(210, 120, 210),
			0.45,
			marker
		)
	end

	return result(true, "SkeletonWorldBuilt", nil, {
		WorldRoot = worldRoot,
	})
end

return SkeletonWorldBuilder
