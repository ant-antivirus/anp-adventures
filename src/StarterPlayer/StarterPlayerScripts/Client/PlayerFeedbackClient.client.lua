local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local UIConfig = require(Shared.Config.UIConfig)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotesFolder = ReplicatedStorage:WaitForChild("ANP_Remotes")
local feedbackEvent = remotesFolder:WaitForChild("PlayerFeedbackEvent")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ANP_PlayerFeedback"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = false
screenGui.Parent = playerGui

local typeStyles = {
	Hint = {
		Title = "Guide",
		Accent = Color3.fromRGB(92, 180, 255),
		Background = Color3.fromRGB(22, 32, 44),
	},
	Blocked = {
		Title = "Not Yet",
		Accent = Color3.fromRGB(255, 190, 92),
		Background = Color3.fromRGB(44, 34, 22),
	},
	QuestStarted = {
		Title = "Quest Started",
		Accent = Color3.fromRGB(99, 218, 132),
		Background = Color3.fromRGB(20, 38, 28),
	},
	ObjectiveUpdated = {
		Title = "Objective Complete",
		Accent = Color3.fromRGB(106, 202, 255),
		Background = Color3.fromRGB(20, 34, 42),
	},
	QuestCompleted = {
		Title = "Quest Complete",
		Accent = Color3.fromRGB(77, 225, 218),
		Background = Color3.fromRGB(18, 42, 42),
		Long = true,
	},
	RewardReceived = {
		Title = "Reward Received",
		Accent = Color3.fromRGB(255, 216, 96),
		Background = Color3.fromRGB(46, 38, 18),
		Long = true,
	},
	EpisodeCompleted = {
		Title = "Episode Complete",
		Accent = Color3.fromRGB(255, 244, 140),
		Background = Color3.fromRGB(38, 32, 56),
		Long = true,
	},
	Onboarding = {
		Title = "Welcome",
		Accent = Color3.fromRGB(99, 218, 132),
		Background = Color3.fromRGB(22, 36, 36),
		Long = true,
	},
}

local function createCorner(parent, radius)
	if not UIConfig.Theme.UseRoundedCorners then
		return nil
	end

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
	return corner
end

local function createStroke(parent, color, transparency)
	if not UIConfig.Theme.UseSoftStroke then
		return nil
	end

	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Transparency = transparency
	stroke.Thickness = 1
	stroke.Parent = parent
	return stroke
end

local function createLabel(name, parent, font, textSize, color)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Font = font
	label.TextSize = textSize
	label.TextColor3 = color
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.Text = ""
	label.Parent = parent
	return label
end

local notificationContainer = Instance.new("Frame")
notificationContainer.Name = "NotificationStack"
notificationContainer.AnchorPoint = Vector2.new(1, 0)
notificationContainer.Position = UDim2.new(1, -20, 0, 198)
notificationContainer.Size = UDim2.fromOffset(360, 260)
notificationContainer.BackgroundTransparency = 1
notificationContainer.Parent = screenGui

local notificationLayout = Instance.new("UIListLayout")
notificationLayout.SortOrder = Enum.SortOrder.LayoutOrder
notificationLayout.Padding = UDim.new(0, 8)
notificationLayout.VerticalAlignment = Enum.VerticalAlignment.Top
notificationLayout.Parent = notificationContainer

local questFrame = Instance.new("Frame")
questFrame.Name = "QuestPanel"
questFrame.AnchorPoint = Vector2.new(1, 0)
questFrame.Position = UDim2.new(1, -20, 0, 18)
questFrame.Size = UDim2.fromOffset(UIConfig.QuestTracker.Width, UIConfig.QuestTracker.Height)
questFrame.BackgroundColor3 = Color3.fromRGB(18, 24, 34)
questFrame.BackgroundTransparency = 0.05
questFrame.BorderSizePixel = 0
questFrame.Parent = screenGui

createCorner(questFrame, 10)
createStroke(questFrame, Color3.fromRGB(96, 132, 170), 0.5)

local questAccent = Instance.new("Frame")
questAccent.Name = "Accent"
questAccent.Position = UDim2.fromOffset(0, 0)
questAccent.Size = UDim2.new(0, 5, 1, 0)
questAccent.BackgroundColor3 = Color3.fromRGB(92, 180, 255)
questAccent.BorderSizePixel = 0
questAccent.Parent = questFrame
createCorner(questAccent, 10)

local questTitleLabel = createLabel("QuestTitle", questFrame, Enum.Font.GothamBold, 17, Color3.fromRGB(255, 255, 255))
questTitleLabel.Position = UDim2.fromOffset(18, 12)
questTitleLabel.Size = UDim2.new(1, -34, 0, 28)
questTitleLabel.Text = "ANP Adventures"

local objectiveLabel = createLabel("CurrentObjective", questFrame, Enum.Font.GothamMedium, 14, Color3.fromRGB(230, 238, 246))
objectiveLabel.Position = UDim2.fromOffset(18, 44)
objectiveLabel.Size = UDim2.new(1, -34, 0, 42)
objectiveLabel.Text = "No active quest"

local progressLabel = createLabel("Progress", questFrame, Enum.Font.GothamBold, 13, Color3.fromRGB(151, 222, 255))
progressLabel.Position = UDim2.fromOffset(18, 90)
progressLabel.Size = UDim2.new(1, -34, 0, 20)
progressLabel.Text = "Progress: No active quest"

local hintLabel = createLabel("Hint", questFrame, Enum.Font.Gotham, 12, Color3.fromRGB(202, 216, 230))
hintLabel.Position = UDim2.fromOffset(18, 112)
hintLabel.Size = UDim2.new(1, -34, 0, 34)
hintLabel.Text = "Hint: Look for a green Quest Start marker."

local zoneLabel = createLabel("Zone", questFrame, Enum.Font.GothamMedium, 11, Color3.fromRGB(176, 192, 208))
zoneLabel.Position = UDim2.fromOffset(18, 148)
zoneLabel.Size = UDim2.new(1, -34, 0, 18)
zoneLabel.Text = ""

local episodeBanner = Instance.new("Frame")
episodeBanner.Name = "EpisodeCompleteBanner"
episodeBanner.AnchorPoint = Vector2.new(0.5, 0)
episodeBanner.Position = UDim2.fromScale(0.5, 0.12)
episodeBanner.Size = UDim2.fromOffset(460, 118)
episodeBanner.BackgroundColor3 = Color3.fromRGB(34, 30, 58)
episodeBanner.BackgroundTransparency = 1
episodeBanner.BorderSizePixel = 0
episodeBanner.Visible = false
episodeBanner.Parent = screenGui

createCorner(episodeBanner, 12)
createStroke(episodeBanner, Color3.fromRGB(255, 232, 130), 0.35)

local episodeTitle = createLabel("Title", episodeBanner, Enum.Font.GothamBold, 24, Color3.fromRGB(255, 246, 176))
episodeTitle.Position = UDim2.fromOffset(22, 18)
episodeTitle.Size = UDim2.new(1, -44, 0, 34)
episodeTitle.TextXAlignment = Enum.TextXAlignment.Center
episodeTitle.Text = "Episode 1 Complete!"

local episodeMessage = createLabel("Message", episodeBanner, Enum.Font.GothamMedium, 16, Color3.fromRGB(245, 248, 255))
episodeMessage.Position = UDim2.fromOffset(22, 58)
episodeMessage.Size = UDim2.new(1, -44, 0, 42)
episodeMessage.TextXAlignment = Enum.TextXAlignment.Center
episodeMessage.Text = "Star Core Segment 01 Restored"

local activeNotifications = {}
local lastNotificationKey = nil
local lastNotificationTime = 0
local bannerToken = 0

local function getNow()
	return os.clock()
end

local function truncateText(value, maxLength)
	local text = tostring(value or "")
	if #text <= maxLength then
		return text
	end

	return string.sub(text, 1, math.max(0, maxLength - 3)) .. "..."
end

local function tweenTransparency(root, targetTransparency, duration)
	for _, instance in ipairs(root:GetDescendants()) do
		if instance:IsA("TextLabel") then
			TweenService:Create(instance, TweenInfo.new(duration), { TextTransparency = targetTransparency }):Play()
		elseif instance:IsA("Frame") then
			TweenService:Create(instance, TweenInfo.new(duration), { BackgroundTransparency = math.clamp(targetTransparency, 0, 0.92) }):Play()
		elseif instance:IsA("UIStroke") then
			TweenService:Create(instance, TweenInfo.new(duration), { Transparency = math.clamp(targetTransparency, 0, 1) }):Play()
		end
	end
	if root:IsA("Frame") then
		TweenService:Create(root, TweenInfo.new(duration), { BackgroundTransparency = math.clamp(targetTransparency, 0, 0.92) }):Play()
	end
end

local function removeNotification(card)
	for index, activeCard in ipairs(activeNotifications) do
		if activeCard == card then
			table.remove(activeNotifications, index)
			break
		end
	end

	if card.Parent then
		tweenTransparency(card, 1, 0.2)
		task.delay(0.22, function()
			card:Destroy()
		end)
	end
end

local function createNotificationCard(payload)
	local style = typeStyles[payload.Type] or typeStyles.Hint
	local lines = if type(payload.Lines) == "table" then payload.Lines else nil
	local messageText = tostring(payload.Message or "")
	if lines and #lines > 0 then
		messageText ..= "\n" .. table.concat(lines, "\n")
	end

	local card = Instance.new("Frame")
	card.Name = tostring(payload.Type or "Notification")
	card.Size = UDim2.fromOffset(360, if lines and #lines > 0 then 146 else 86)
	card.BackgroundColor3 = style.Background
	card.BackgroundTransparency = 0.05
	card.BorderSizePixel = 0
	card.Parent = notificationContainer

	createCorner(card, 8)
	createStroke(card, style.Accent, 0.42)

	local accent = Instance.new("Frame")
	accent.Name = "Accent"
	accent.Position = UDim2.fromOffset(0, 0)
	accent.Size = UDim2.new(0, 5, 1, 0)
	accent.BackgroundColor3 = style.Accent
	accent.BorderSizePixel = 0
	accent.Parent = card
	createCorner(accent, 8)

	local title = createLabel("Title", card, Enum.Font.GothamBold, 15, Color3.fromRGB(255, 255, 255))
	title.Position = UDim2.fromOffset(16, 10)
	title.Size = UDim2.new(1, -28, 0, 22)
	title.Text = tostring(payload.Title or style.Title or payload.Type or "ANP")

	local message = createLabel("Message", card, Enum.Font.Gotham, 13, Color3.fromRGB(232, 238, 245))
	message.Position = UDim2.fromOffset(16, 36)
	message.Size = UDim2.new(1, -28, 0, 42)
	if lines and #lines > 0 then
		message.Size = UDim2.new(1, -28, 0, 100)
	end
	message.Text = messageText

	return card, style
end

local function showNotification(payload)
	local message = tostring(payload.Message or "")
	local notificationKey = tostring(payload.Type or "") .. "|" .. message
	local now = getNow()
	if notificationKey == lastNotificationKey and now - lastNotificationTime < 1.5 then
		lastNotificationTime = now
		return
	end
	lastNotificationKey = notificationKey
	lastNotificationTime = now

	local card, style = createNotificationCard(payload)
	table.insert(activeNotifications, 1, card)
	card.LayoutOrder = math.floor(-now * 1000)

	while #activeNotifications > UIConfig.Feedback.MaxVisibleNotifications do
		local oldestCard = table.remove(activeNotifications)
		if oldestCard then
			oldestCard:Destroy()
		end
	end

	local duration = tonumber(payload.Duration)
		or (style.Long and UIConfig.Feedback.LongDurationSeconds)
		or UIConfig.Feedback.DefaultDurationSeconds

	card.BackgroundTransparency = 1
	tweenTransparency(card, 0.05, 0.18)
	task.delay(duration, function()
		removeNotification(card)
	end)
end

local function updateQuestPanel(payload)
	local state = tostring(payload.State or "NoQuest")
	local title = payload.QuestTitle or payload.QuestId or "ANP Adventures"
	local objective = payload.CurrentObjectiveText or "No active quest"
	local progress = payload.ProgressText or state
	local hint = payload.HintText or "Look for a green Quest Start marker."
	local zoneName = payload.ZoneName

	if state == "NoQuest" then
		title = payload.QuestTitle or "ANP Adventures"
		objective = payload.CurrentObjectiveText or "No active quest"
		progress = payload.ProgressText or "No active quest"
		hint = payload.HintText or "Look for a green Quest Start marker."
		questAccent.BackgroundColor3 = Color3.fromRGB(99, 218, 132)
	elseif state == "QuestCompleted" then
		objective = payload.CurrentObjectiveText or "Quest complete. Find the next green marker."
		progress = payload.ProgressText or "Quest complete"
		hint = payload.HintText or "Start the next quest at the green marker."
		questAccent.BackgroundColor3 = Color3.fromRGB(77, 225, 218)
	elseif state == "EpisodeCompleted" then
		title = payload.QuestTitle or "Episode 1 Complete!"
		objective = payload.CurrentObjectiveText or "Star Core Segment 01 restored."
		progress = payload.ProgressText or "Episode 1 complete"
		hint = payload.HintText or "Star Core Segment 01 restored."
		questAccent.BackgroundColor3 = Color3.fromRGB(255, 232, 130)
	else
		questAccent.BackgroundColor3 = Color3.fromRGB(92, 180, 255)
	end

	questTitleLabel.Text = truncateText(title, 48)
	objectiveLabel.Text = truncateText(objective, UIConfig.QuestTracker.MaxObjectiveTextLength)
	progressLabel.Text = "Progress: " .. tostring(progress)
	hintLabel.Text = "Hint: " .. truncateText(hint, UIConfig.QuestTracker.MaxHintTextLength)
	zoneLabel.Text = zoneName and ("Zone: " .. tostring(zoneName)) or ""
end

local function updateLastHint(payload)
	local message = payload.Message
	if type(message) ~= "string" or message == "" then
		return
	end

	hintLabel.Text = "Hint: " .. truncateText(message, UIConfig.QuestTracker.MaxHintTextLength)
end

local function showEpisodeBanner(payload)
	bannerToken += 1
	local token = bannerToken
	episodeTitle.Text = tostring(payload.Title or "Episode 1 Complete!")
	episodeMessage.Text = tostring(payload.Message or "Star Core Segment 01 Restored")
	episodeBanner.Visible = true
	tweenTransparency(episodeBanner, 0.04, 0.2)

	task.delay(tonumber(payload.Duration) or UIConfig.Feedback.LongDurationSeconds, function()
		if token ~= bannerToken then
			return
		end
		tweenTransparency(episodeBanner, 1, 0.35)
		task.delay(0.38, function()
			if token == bannerToken then
				episodeBanner.Visible = false
			end
		end)
	end)
end

feedbackEvent.OnClientEvent:Connect(function(payload)
	if type(payload) ~= "table" then
		return
	end

	if payload.Type == "QuestTracker" then
		updateQuestPanel(payload)
		return
	end

	if payload.Type == "Hint" or payload.Type == "Blocked" then
		updateLastHint(payload)
	end

	if payload.Type == "EpisodeCompleted" then
		showEpisodeBanner(payload)
	end

	showNotification(payload)
end)
