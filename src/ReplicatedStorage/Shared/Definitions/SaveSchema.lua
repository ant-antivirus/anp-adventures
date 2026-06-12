local SaveSchema = {
	SaveVersion = 1,
	StableSections = {
		"Profile",
		"Progression",
		"Episodes",
		"Quests",
		"Inventory",
		"Discoveries",
		"Journal",
		"Lore",
		"Badges",
		"Memories",
		"Zones",
		"Companion",
		"Settings",
	},
	ForbiddenRuntimeFields = {
		SessionStats = true,
		FeedbackPayloads = true,
		PromptState = true,
		QuestTrackerPayload = true,
		StudioObjects = true,
		Cooldowns = true,
	},
}

return table.freeze(SaveSchema)
