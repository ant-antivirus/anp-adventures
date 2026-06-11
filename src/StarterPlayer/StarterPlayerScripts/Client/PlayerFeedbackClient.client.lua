local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotesFolder = ReplicatedStorage:WaitForChild("ANP_Remotes")
local feedbackEvent = remotesFolder:WaitForChild("PlayerFeedbackEvent")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ANP_PlayerFeedback"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = false
screenGui.Parent = playerGui

local notificationFrame = Instance.new("Frame")
notificationFrame.Name = "Notification"
notificationFrame.AnchorPoint = Vector2.new(0.5, 0)
notificationFrame.Position = UDim2.fromScale(0.5, 0.06)
notificationFrame.Size = UDim2.fromOffset(420, 96)
notificationFrame.BackgroundColor3 = Color3.fromRGB(24, 28, 36)
notificationFrame.BackgroundTransparency = 0.08
notificationFrame.BorderSizePixel = 0
notificationFrame.Visible = false
notificationFrame.Parent = screenGui

local notificationCorner = Instance.new("UICorner")
notificationCorner.CornerRadius = UDim.new(0, 8)
notificationCorner.Parent = notificationFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.BackgroundTransparency = 1
titleLabel.Position = UDim2.fromOffset(16, 10)
titleLabel.Size = UDim2.new(1, -32, 0, 24)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 18
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.TextYAlignment = Enum.TextYAlignment.Center
titleLabel.Text = ""
titleLabel.Parent = notificationFrame

local messageLabel = Instance.new("TextLabel")
messageLabel.Name = "Message"
messageLabel.BackgroundTransparency = 1
messageLabel.Position = UDim2.fromOffset(16, 38)
messageLabel.Size = UDim2.new(1, -32, 1, -48)
messageLabel.Font = Enum.Font.Gotham
messageLabel.TextColor3 = Color3.fromRGB(235, 240, 245)
messageLabel.TextSize = 15
messageLabel.TextWrapped = true
messageLabel.TextXAlignment = Enum.TextXAlignment.Left
messageLabel.TextYAlignment = Enum.TextYAlignment.Top
messageLabel.Text = ""
messageLabel.Parent = notificationFrame

local questFrame = Instance.new("Frame")
questFrame.Name = "QuestPanel"
questFrame.AnchorPoint = Vector2.new(1, 0)
questFrame.Position = UDim2.new(1, -18, 0, 18)
questFrame.Size = UDim2.fromOffset(320, 150)
questFrame.BackgroundColor3 = Color3.fromRGB(18, 22, 30)
questFrame.BackgroundTransparency = 0.12
questFrame.BorderSizePixel = 0
questFrame.Parent = screenGui

local questCorner = Instance.new("UICorner")
questCorner.CornerRadius = UDim.new(0, 8)
questCorner.Parent = questFrame

local questTitleLabel = Instance.new("TextLabel")
questTitleLabel.Name = "CurrentQuest"
questTitleLabel.BackgroundTransparency = 1
questTitleLabel.Position = UDim2.fromOffset(14, 10)
questTitleLabel.Size = UDim2.new(1, -28, 0, 24)
questTitleLabel.Font = Enum.Font.GothamBold
questTitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
questTitleLabel.TextSize = 15
questTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
questTitleLabel.Text = "Current Quest"
questTitleLabel.Parent = questFrame

local objectiveLabel = Instance.new("TextLabel")
objectiveLabel.Name = "CurrentObjective"
objectiveLabel.BackgroundTransparency = 1
objectiveLabel.Position = UDim2.fromOffset(14, 36)
objectiveLabel.Size = UDim2.new(1, -28, 0, 34)
objectiveLabel.Font = Enum.Font.Gotham
objectiveLabel.TextColor3 = Color3.fromRGB(225, 232, 240)
objectiveLabel.TextSize = 13
objectiveLabel.TextWrapped = true
objectiveLabel.TextXAlignment = Enum.TextXAlignment.Left
objectiveLabel.TextYAlignment = Enum.TextYAlignment.Top
objectiveLabel.Text = "Start an expedition to see your next step."
objectiveLabel.Parent = questFrame

local progressLabel = Instance.new("TextLabel")
progressLabel.Name = "Progress"
progressLabel.BackgroundTransparency = 1
progressLabel.Position = UDim2.fromOffset(14, 74)
progressLabel.Size = UDim2.new(1, -28, 0, 20)
progressLabel.Font = Enum.Font.GothamMedium
progressLabel.TextColor3 = Color3.fromRGB(210, 220, 230)
progressLabel.TextSize = 12
progressLabel.TextXAlignment = Enum.TextXAlignment.Left
progressLabel.TextYAlignment = Enum.TextYAlignment.Center
progressLabel.Text = "Progress: No active quest"
progressLabel.Parent = questFrame

local hintLabel = Instance.new("TextLabel")
hintLabel.Name = "LastHint"
hintLabel.BackgroundTransparency = 1
hintLabel.Position = UDim2.fromOffset(14, 98)
hintLabel.Size = UDim2.new(1, -28, 0, 42)
hintLabel.Font = Enum.Font.Gotham
hintLabel.TextColor3 = Color3.fromRGB(190, 205, 220)
hintLabel.TextSize = 12
hintLabel.TextWrapped = true
hintLabel.TextXAlignment = Enum.TextXAlignment.Left
hintLabel.TextYAlignment = Enum.TextYAlignment.Top
hintLabel.Text = "Last hint will appear here."
hintLabel.Parent = questFrame

local activeNotificationToken = 0

local function showNotification(payload)
	activeNotificationToken += 1
	local token = activeNotificationToken

	titleLabel.Text = tostring(payload.Title or payload.Type or "ANP")
	messageLabel.Text = tostring(payload.Message or "")
	notificationFrame.Visible = true

	task.delay(tonumber(payload.Duration) or 4, function()
		if token == activeNotificationToken then
			notificationFrame.Visible = false
		end
	end)
end

local function updateQuestPanel(payload)
	if payload.Type == "QuestTracker" then
		questTitleLabel.Text = tostring(payload.QuestTitle or payload.QuestId or "ANP Adventures")
		objectiveLabel.Text = tostring(payload.CurrentObjectiveText or "Look for your next step.")
		progressLabel.Text = "Progress: " .. tostring(payload.ProgressText or payload.State or "No active quest")
		hintLabel.Text = "Hint: " .. tostring(payload.HintText or "Talk to Proton for guidance.")
	elseif payload.Type == "QuestStarted" then
		questTitleLabel.Text = payload.QuestId or "Quest Started"
		objectiveLabel.Text = payload.Message or "Follow the next objective."
	elseif payload.Type == "ObjectiveUpdated" then
		questTitleLabel.Text = payload.QuestId or questTitleLabel.Text
		objectiveLabel.Text = payload.ObjectiveId or "Objective updated."
	elseif payload.Type == "QuestCompleted" then
		questTitleLabel.Text = payload.QuestId or "Quest Complete"
		objectiveLabel.Text = payload.Message or "Quest complete."
	elseif payload.Type == "Hint" or payload.Type == "Blocked" then
		hintLabel.Text = payload.Message or ""
	elseif payload.Type == "EpisodeCompleted" then
		questTitleLabel.Text = payload.EpisodeId or "Episode Complete"
		objectiveLabel.Text = payload.Message or "Episode complete."
		progressLabel.Text = "Progress: Episode complete"
	end
end

feedbackEvent.OnClientEvent:Connect(function(payload)
	if type(payload) ~= "table" then
		return
	end

	updateQuestPanel(payload)
	if payload.Type ~= "QuestTracker" then
		showNotification(payload)
	end
end)
