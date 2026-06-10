export type ObjectiveState = {
	ObjectiveId: string,
	Progress: number,
	RequiredProgress: number,
	Completed: boolean,
}

export type QuestState = {
	QuestId: string,
	EpisodeId: string,
	ZoneId: string?,
	Status: "Inactive" | "Active" | "Completed",
	ObjectiveStates: { [string]: ObjectiveState },
	StartedAt: number?,
	CompletedAt: number?,
	LastUpdatedAt: number?,
	AssistedByCompanion: boolean,
	ParticipantUserIds: { number },
	CoopParticipantUserIds: { number },
	RewardClaimIds: { [string]: boolean },
}

export type QuestDefinition = {
	QuestId: string,
	EpisodeId: string,
	ZoneId: string,
	ObjectiveIds: { string },
	ObjectiveDefinitions: {
		[string]: {
			RequiredAmount: number,
			ObjectiveText: string?,
			RequiresObjectiveIds: { string }?,
		},
	}?,
	RequiredObjectiveIds: { string },
	OptionalObjectiveIds: { string }?,
	RewardBundleIds: { string },
	RequiredCompanionAssists: { string },
	SoloSupportMetadata: {
		SoloCompletable: boolean,
		HasCoopStyleRequiredMechanic: boolean,
		RequiredSoloFallbackAssistIds: { string }?,
		Notes: string?,
	},
}

return {}
