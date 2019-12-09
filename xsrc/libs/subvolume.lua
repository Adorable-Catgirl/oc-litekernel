local subvol = {}

local passthrough = {
	["read"] = true,
	["write"] = true,
	["close"] = true,
	["getLabel"] = true,
	["seek"] = true,
	["spaceTotal"] = true,
	["spaceUsed"] = true,
	["isReadOnly"] = true,
	["setLabel"] = true
}
function subvol.make(proxy, fpath)
	local t = {}
	setmetatable(t, {__index=function(_,v)
		if (passthrough[v]) then
			return proxy[v]
		else
			return function(path, ...)
				local rpath = fpath .. "/" .. path
				return proxy[v](rpath, ...)
			end
		end
	end})
end

return subvol