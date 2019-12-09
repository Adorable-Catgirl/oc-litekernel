local vfs = {}

local fs = {}

function fs.mount(path, proxy)
	vfs[#vfs+1] = {path, proxy}
end

function fs.resolve(path)
	for i=#vfs, 1, -1 do
		if (path:sub(1, #vfs[i][1]) == vfs[i][1]) or (path:sub(1, #vfs[i][1]).."/" == vfs[i][1]) then
			return path:sub(#vfs[i][1]), vfs[i][2]
		end
	end
	return nil, "not found"
end

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
	fs.mount("/"..c:sub(1, 8).."/", component.proxy(c))
end

return fs