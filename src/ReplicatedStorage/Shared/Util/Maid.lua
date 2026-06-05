local Maid = {}
Maid.__index = Maid

function Maid.new()
	return setmetatable({
		_tasks = {},
	}, Maid)
end

function Maid:GiveTask(task)
	table.insert(self._tasks, task)
	return task
end

function Maid:DoCleaning()
	for _, task in ipairs(self._tasks) do
		local taskType = typeof(task)

		if taskType == "RBXScriptConnection" then
			task:Disconnect()
		elseif taskType == "Instance" then
			task:Destroy()
		elseif type(task) == "function" then
			task()
		elseif type(task) == "table" and type(task.Destroy) == "function" then
			task:Destroy()
		end
	end

	table.clear(self._tasks)
end

Maid.Destroy = Maid.DoCleaning

return Maid
