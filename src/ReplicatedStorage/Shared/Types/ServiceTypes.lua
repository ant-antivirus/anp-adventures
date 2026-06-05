export type ServiceResult<T> = {
	Success: boolean,
	Code: string,
	Message: string?,
	Data: T?,
}

export type SourceContext = {
	SourceType: string,
	SourceId: string,
	RequestId: string?,
	ActorUserIds: { number }?,
}

export type PlayerRef = {
	Player: Player,
}

return {}
