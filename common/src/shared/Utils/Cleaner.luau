local Cleaner = {}
Cleaner.__index = Cleaner

local function cleanupTask(task)
	local taskType = typeof(task)

	if taskType == "RBXScriptConnection" then
		task:Disconnect()
		return
	end

	if taskType == "Instance" then
		task:Destroy()
		return
	end

	if type(task) == "function" then
		task()
		return
	end

	if type(task) == "table" then
		if type(task.Destroy) == "function" then
			task:Destroy()
			return
		end

		if type(task.Disconnect) == "function" then
			task:Disconnect()
			return
		end

		if type(task.Stop) == "function" then
			task:Stop()
			return
		end

		if type(task.stop) == "function" then
			task:stop()
			return
		end
	end

	error(`Unsupported cleanup task of type "{taskType}"`, 3)
end

function Cleaner.new()
	return setmetatable({
		_tasks = {},
	}, Cleaner)
end

function Cleaner:add(task)
	assert(task ~= nil, "Cleaner task cannot be nil")

	table.insert(self._tasks, task)

	return task
end

function Cleaner:clean()
	for index = #self._tasks, 1, -1 do
		local task = self._tasks[index]
		self._tasks[index] = nil
		cleanupTask(task)
	end
end

return Cleaner
