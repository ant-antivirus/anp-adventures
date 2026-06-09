local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ZoneDefinitions = require(Shared.Definitions.ZoneDefinitions)
local InteractionDefinitions = require(Shared.Definitions.InteractionDefinitions)
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
		InteractionId = "interaction_ep01_main_005_003",
		QuestId = "quest_ep01_main_005",
		ObjectiveId = "obj_ep01_main_005_003",
		ZoneId = "zone_ep01_theos_satellite_center",
		Type = "QuestObjective",
	},
	{
		InteractionId = "interaction_ep01_main_008_005",
		QuestId = "quest_ep01_main_008",
		ObjectiveId = "obj_ep01_main_008_005",
		ZoneId = "zone_ep01_moon_walk",
		Type = "QuestObjective",
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

local function getOrCreateDeveloperLabel(part)
	local label = part:FindFirstChild(DEVELOPER_LABEL_NAME)
	if label and label:IsA("BillboardGui") then
		return label
	end

	label = Instance.new("BillboardGui")
	label.Name = DEVELOPER_LABEL_NAME
	label.AlwaysOnTop = true
	label.Size = UDim2.new(0, 260, 0, 76)
	label.Parent = part

	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "Text"
	textLabel.BackgroundColor3 = Color3.fromRGB(20, 24, 30)
	textLabel.BackgroundTransparency = 0.15
	textLabel.BorderSizePixel = 0
	textLabel.Font = Enum.Font.GothamMedium
	textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	textLabel.TextScaled = true
	textLabel.TextWrapped = true
	textLabel.Size = UDim2.fromScale(1, 1)
	textLabel.Parent = label

	return label
end

local function setDeveloperLabel(object, category, friendlyName, internalId)
	if not object:IsA("BasePart") then
		return
	end

	local label = getOrCreateDeveloperLabel(object)
	label.StudsOffset = Vector3.new(0, object.Size.Y / 2 + 3, 0)

	local textLabel = label:FindFirstChild("Text")
	if textLabel and textLabel:IsA("TextLabel") then
		textLabel.Text = "[" .. category .. "]\n" .. friendlyName .. "\n" .. internalId
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
			Vector3.new((index - 1) * 80, 2, 0),
			Vector3.new(48, 4, 48),
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
				Vector3.new((index - 1) * 80, 6, spawnIndex * 8),
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
				spawnPointId
			)
		end
	end

	for index, discovery in ipairs(MINIMUM_DISCOVERY_POINTS) do
		local discoveryObject = getOrCreatePartByAttribute(
			folders.DiscoveryPoints,
			"DiscoveryId",
			discovery.DiscoveryId,
			"Discovery_" .. discovery.DiscoveryId,
			Vector3.new((index - 1) * 20, 8, 70),
			Vector3.new(5, 5, 5),
			PLACEHOLDER_COLORS.Discovery,
			0.35,
			discovery
		)
		setDeveloperLabel(
			discoveryObject,
			"DISCOVERY",
			DISCOVERY_FRIENDLY_NAMES[discovery.DiscoveryId] or discovery.DiscoveryId,
			discovery.DiscoveryId
		)
	end

	for index, interaction in ipairs(MINIMUM_INTERACTION_POINTS) do
		local partName = interaction.Name or ("Interaction_" .. interaction.InteractionId)
		local interactionObject = getOrCreatePartByAttribute(
			folders.InteractionPoints,
			"InteractionId",
			interaction.InteractionId,
			partName,
			Vector3.new((index - 1) * 18, 7, -70),
			Vector3.new(8, 6, 8),
			PLACEHOLDER_COLORS[interaction.Type] or PLACEHOLDER_COLORS.QuestObjective,
			0.35,
			buildInteractionAttributes(interaction)
		)
		setDeveloperLabel(
			interactionObject,
			getInteractionLabelCategory(interaction.Type),
			getInteractionFriendlyName(interaction),
			interaction.InteractionId
		)
	end

	for index, marker in ipairs(NPC_MARKERS) do
		local markerObject = getOrCreatePartByAttribute(
			folders.NPCMarkers,
			"CharacterId",
			marker.CharacterId,
			"NPCMarker_" .. marker.CharacterId,
			Vector3.new((index - 1) * 8, 7, -18),
			Vector3.new(4, 6, 4),
			PLACEHOLDER_COLORS.NPCMarker,
			0.45,
			buildNPCMarkerAttributes(marker)
		)
		setDeveloperLabel(
			markerObject,
			"NPC GUIDE",
			CHARACTER_FRIENDLY_NAMES[marker.CharacterId] or marker.CharacterId,
			marker.InteractionId
		)
	end

	return result(true, "SkeletonWorldBuilt", nil, {
		WorldRoot = worldRoot,
	})
end

return SkeletonWorldBuilder
