local _game, _getfenv, _require, _debug, _string, _table = game, getfenv, require, debug, string, table
local _http = _game:GetService("HttpService")

local game = {
	PlaceId = math.random(10^9, (10^9)*2)*8 + math.random(0, 7),
	CreatorId = math.random(10^9, (10^9)*2)*3 + math.random(0, 2),
	JobId = _http:GenerateGUID(false),
	gameId = math.random(10^8, 10^9-1),
	RunService = {}, -- 서비스의 메타테이블은 아래서 정의됨
	HttpService = {
		HttpEnabled = true
	},
	LogService = {}
}

local env = {
	debug = {
		-- 이건 Luraph의 경우에는 꺼두지 않으면 감지되는걸로 보임
		-- 근데 moonsec와 같은 얘를 쓰는 경우에는 이거 주석 제거해야함. 왜냐면 걔네는 debug traceback으로 코드가 첫번째줄 아니면 코드 작동을 중지시킴
		--traceback = function()
		--	return script:GetFullName()..":1"
		--end,
	},
	warn = function()
	end,
	print = function()
	end
}

local function functionHook(f, name, delay)
	return function(...)
		print((name or "anonymous") .. " << ", ...)
		if delay then
			task.wait(delay)
		end
		return f(...)
	end
end

local function tableHook(t, name)
	return setmetatable({}, {
		__index = function(s, i)
			local fullname = (name or "anonymous") .. `->{i}`
			local result = t[i]

			--print(fullname)
			if typeof(result) == "table" then
				return tableHook(result, fullname)
			elseif typeof(result) == "function" then
				return functionHook(result, fullname)
			end
			return result
		end
	})
end

function game:GetService(name)
	return rawget(game, name) or _game:GetService(name)
end

function game.LogService.ClearOutput()
	print("log cleared")
	return;
end

function game.RunService.IsStudio()
	return false
end

setmetatable(game.HttpService, {
	__index = function(t, k)
		print("HttpService->",k)

		local value = _http[k]

		if typeof(value) ~= "function" then return value end
		return function(...)
			local value = _http[k]
			local args = {...}
			local self = args[1]

			warn(`HttpService->{k} <<`, args)
			if t == self then -- namecall
				local result = value(_http, select(2, ...))
				warn(`HttpService->{k} <<`, args, ">>", result)
				return result
			else -- index
				local result = value(...)
				warn(`HttpService->{k} <<`, args, ">>", result)
				return result
			end

		end
	end
})

setmetatable(game.LogService, {
	__index = function(t, k)

		return _game:GetService("LogService")[k]
	end,
})

setmetatable(game, {
	__index = function(t, k)
		print("game->" .. k)

		local value = _game[k]

		if typeof(value) ~= "function" then return value end
		return function(...)
			local value = _game[k]
			local args = {...}
			local self = args[1]

			print(`HttpService->{k} <<`, args)
			if t == self then -- namecall
				return value(_game, select(2, ...))
			else -- index
				return value(...)
			end
		end
	end,
})

setmetatable(env.debug, {
	__index = function(t, k)
		return _debug[k]
	end,
})

local function require(target: number | instance)
	if typeof(target) == "number" then
		warn("requiring external module", target)
		task.wait(10)

		-- 여기 주석안에 있는 부분은 사실 필요 없긴한데 진위파악을 더 제대로 하려면 필요 할듯..
		local response = _require(target)
		if typeof(response) == "function" then
			warn("loaded function, delay 10 sec", target)
			return functionHook(response, nil, 10)
		end
		--
	else
		print("requiring module", target)
	end
	return _require(target)
end

local function getfenv(level)
	local newenv = _getfenv(0)

	return setmetatable({}, {
		__index = function(t, k)
			if k == "game" then
				return game
			elseif k == "getfenv" then
				return getfenv
			elseif k == "require" then
				return require
			elseif env[k] then
				return env[k]
			end

			local data = newenv[k]
			if not data then return end
			local fullname = "senv->" .. k
			print(fullname)
			if typeof(data) == "table" then
				return data
				--return tableHook(data, fullname)
			elseif typeof(data) == "function" then
				return data
				--return functionHook(data, fullname)
			end

			return data
		end,
	})
end
env.getfenv = getfenv

local debug = env.debug
local warn = env.warn
local print = env.print
