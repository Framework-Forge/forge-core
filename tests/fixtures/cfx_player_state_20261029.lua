-- Verbatim installed citizen:/scripting/lua/scheduler.lua state/player section. Test-only.
local function NewStateBag(es)
	return setmetatable({}, {
		__index = function(_, s)
			if s == 'set' then
				return function(_, s2, v2, r2)
					local payload = msgpack_pack(v2)
					SetStateBagValue(es, s2, payload, payload:len(), r2)
				end
			end

			return GetStateBagValue(es, s)
		end,

		__newindex = function(_, s, v)
			local payload = msgpack_pack(v)
			SetStateBagValue(es, s, payload, payload:len(), isDuplicityVersion)
		end
	})
end

GlobalState = NewStateBag('global')

local function GetEntityStateBagId(entityGuid)
	if isDuplicityVersion or NetworkGetEntityIsNetworked(entityGuid) then
		return ('entity:%d'):format(NetworkGetNetworkIdFromEntity(entityGuid))
	else
		EnsureEntityStateBag(entityGuid)
		return ('localEntity:%d'):format(entityGuid)
	end
end

local entityMT
entityMT = {
	__index = function(t, s)
		if s == 'state' then
			local es = GetEntityStateBagId(t.__data)

			if isDuplicityVersion then
				EnsureEntityStateBag(t.__data)
			end

			return NewStateBag(es)
		end

		return nil
	end,

	__newindex = function()
		error('Setting values on Entity is not supported at this time.', 2)
	end,

	__ext = EXT_ENTITY,

	__pack = function(self, t)
		return tostring(NetworkGetNetworkIdFromEntity(self.__data))
	end,

	__unpack = function(data, t)
		local ref = NetworkGetEntityFromNetworkId(tonumber(data))

		return setmetatable({
			__data = ref
		}, entityMT)
	end
}

msgpack.extend(entityMT)

local playerMT
playerMT = {
	__index = function(t, s)
		if s == 'state' then
			local pid = t.__data

			if pid == -1 then
				pid = GetPlayerServerId(PlayerId())
			end

			local es = ('player:%d'):format(pid)

			return NewStateBag(es)
		end

		return nil
	end,

	__newindex = function()
		error('Setting values on Player is not supported at this time.', 2)
	end,

	__ext = EXT_PLAYER,

	__pack = function(self, t)
		return tostring(self.__data)
	end,

	__unpack = function(data, t)
		local ref = tonumber(data)

		return setmetatable({
			__data = ref
		}, playerMT)
	end
}

msgpack.extend(playerMT)

function Entity(ent)
	if type(ent) == 'number' then
		return setmetatable({
			__data = ent
		}, entityMT)
	end

	return ent
end

function Player(ent)
	if type(ent) == 'number' or type(ent) == 'string' then
		return setmetatable({
			__data = tonumber(ent)
		}, playerMT)
	end

	return ent
end

if not isDuplicityVersion then
	LocalPlayer = Player(-1)
end
