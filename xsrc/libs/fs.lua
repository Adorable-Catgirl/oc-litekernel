local vfs = {}

local fs = {}

function fs.mount(path, proxy)
	vfs[#vfs+1] = {path, proxy}
end

function fs.remount(path, proxy)
	for i=1, #vfs do
		if (vfs[i][1] == path) then
			vfs[i][2] = proxy
			return true
		end
	end
	return false
end

function fs.umount(path)
	for i=1, #vfs do
		if (vfs[i][1] == path) then
			table.remove(vfs, i)
			return
		end
	end
end

function fs.get_mounts()
	local tbl = {}
	for i=1, #vfs do
		tbl[#tbl+1] = {vfs[i][1], vfs[i][2]}
	end
	return tbl
end

function fs.resolve(path)
	for i=#vfs, 1, -1 do
		if (path:sub(1, #vfs[i][1]) == vfs[i][1]) or (path:sub(1, #vfs[i][1]).."/" == vfs[i][1]) then
			return path:sub(#vfs[i][1]), vfs[i][2]
		end
	end
	return nil, "not found"
end

local handles = {}
setmetatable(handles, {__mode="k"})

local function passthrough(k)
	fs[k] = function(path)
		local ppart, dev = fs.resolve(path)
		return dev[k](ppart)
	end
end

local function protected(k, ...)
	local vargs = {...}
	fs[k] = function(path)
		local ppart, dev = fs.resolve(path)
		if dev[k] then
			return dev[k](ppart)
		else
			return table.unpack(vargs)
		end
	end
end

passthrough"list"
passthrough"exists"
passthrough"isDirectory"
protected("size", 0)
protected("lastModified", 0)
protected("remove", false, "unsupported opperation")
protected("makeDirectory", false, "unsupported opperation")

function fs.open(path, mode)
	local ppart, dev = fs.resolve(path)
	if dev.open then
		local hand = {dev.open(ppart, mode)}
		handles[hand] = dev
		return hand
	else
		return nil, "unsupported opperation"
	end
end

local function io(k)
	fs[k] = function(h, ...)
		return handles[h][k](h[1], ...)
	end
end

io"seek"
io"read"
io"write"
io"close"

-- filesystem mount
fs.mount("/", {
	list = function()
		local lst = {}
		for i=1, #vfs do
			if (vfs[i][1]:match("^/.+/$")) then
				lst[#lst+1] = vfs[i][1]:sub(2)
			end
		end
		return lst
	end,
	exists = function(path)
		local lst = {}
		for i=1, #vfs do
			if (vfs[i][1]:match("^/.+/$")) then
				lst[vfs[i][1]:sub(1, #vfs[i][1]-1)] = true
			end
		end
		return (lst[path]~=nil)
	end,
	isDirectory = function(path)
		local lst = {}
		for i=1, #vfs do
			if (vfs[i][1]:match("^/.+/$")) then
				lst[vfs[i][1]:sub(1, #vfs[i][1]-1)] = true
			end
		end
		return (lst[path]~=nil)
	end,
	isReadOnly = function()
		return true
	end
})

-- Mount all filesystems.
for c in component.list("filesystem") do
	fs.mount("/"..c:sub(1, 4).."/", component.proxy(c))
end

return fs