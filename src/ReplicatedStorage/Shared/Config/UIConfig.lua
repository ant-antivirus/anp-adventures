local UIConfig = {
	Feedback = {
		MaxVisibleNotifications = 3,
		DefaultDurationSeconds = 4,
		LongDurationSeconds = 7,
	},

	QuestTracker = {
		Enabled = true,
		Width = 360,
		Height = 170,
		CompactWidth = 310,
		MaxObjectiveTextLength = 90,
		MaxHintTextLength = 100,
	},

	Theme = {
		UseRoundedCorners = true,
		UseSoftStroke = true,
	},
}

return table.freeze(UIConfig)
