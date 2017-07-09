local native = {}
for k,v in pairs(_G.fs) do
    native[k] = v
end

local function getPath(path)
    path = path or ""
    
    --Failsafe
    local fullPath = native.combine(path,"")
    
    if fullPath:find("^%.UserData") then
        return path
    end   
    --Enf failsafe
    
    
    fullPath = native.combine("/.UserData/",path or "")
    if fullPath:find("^%.UserData") then
        return fullPath
    else
        error("Path doesn't exist")
    end
end




--shell.setDir("/.UserData/")
_G.fs.open = function(file,mode)
    local pos = {string.find(file,"rom")}
    if pos[2] ~= 3 and pos[2] ~= 4 then
        return native.open(getPath(file),mode)
    else
        return native.open(file,mode)
    end
end

_G.fs.list = function(path)
    local pos = {string.find(path,"rom")}
    if pos[2] ~= 3 and pos[2] ~= 4 then
        return native.list(getPath(path))
    else
        return native.list(path)
    end
end

_G.fs.exists = function(path)
    local pos = {string.find(path,"rom")}
    if pos[2] ~= 3 and pos[2] ~= 4 then
        return native.exists(getPath(path))
    else
        return native.exists(path)
    end
end

_G.fs.isDir = function(path)
    local pos = {string.find(path,"rom")}
    if pos[2] ~= 3 and pos[2] ~= 4 then
        return native.isDir(getPath(path))
    else
        return native.isDir(path)
    end
end

_G.fs.isReadOnly = function(path)
    local pos = {string.find(path,"rom")}
    if pos[2] ~= 3 and pos[2] ~= 4 then
        return false
    else
        return true
    end
end

_G.fs.getName = function(path)
    local pos = {string.find(path,"rom")}
    if pos[2] ~= 3 and pos[2] ~= 4 then
        return native.getName(getPath(path))
    else
        return native.getName(path)
    end
end

_G.fs.getDrive = function() return nil end

_G.fs.getSize = function(path)
    local pos = {string.find(path,"rom")}
    if pos[2] ~= 3 and pos[2] ~= 4 then
        return native.getSize(getPath(path))
    else
        return native.getSize(path)
    end
end

_G.fs.getFreeSpace = function(path)
    local pos = {string.find(path,"rom")}
    if pos[2] ~= 3 and pos[2] ~= 4 then
        return native.getFreeSpace(getPath(path))
    else
        return native.getFreeSpace(path)
    end
end

_G.fs.makeDir = function(path)
    local pos = {string.find(path,"rom")}
    if pos[2] ~= 3 and pos[2] ~= 4 then
        return native.makeDir(getPath(path))
    else
        return native.makeDir(path)
    end
end

_G.fs.move = function(path,target)
    local pos = {string.find(path,"rom")}
    if pos[2] ~= 3 and pos[2] ~= 4 then
        return native.move(getPath(path), getPath(target))
    else
        return native.move(path, getPath(target))
    end
end

_G.fs.copy = function(path,target)
    local pos = {string.find(path,"rom")}
    if pos[2] ~= 3 and pos[2] ~= 4 then
        return native.copy(getPath(path),getPath(target))
    else
        return native.copy(path, getPath(target))
    end
end

_G.fs.delete = function(path)
  local pos = {string.find(path,"rom")}
  if pos[2] ~= 3 and pos[2] ~= 4 then
		    return native.delete(getPath(path))
  else 
      return native.delete(path)
  end
end
--[[
_G.fs.find = function(wildcard)
	local pos = {string.find(wildcard,"rom")}
	if pos[2] ~= 3 and pos[2] ~= 4 then
		return native.find(getPath(wildcard))
	else
		return native.find(wildcard)
	end
end
]]

_G.fs.find = function(wildcard)
    local pos = {string.find(wildcard,"rom")}
    if pos[2] ~= 3 and pos[2] ~= 4 then
    
    local data = native.find(getPath(wildcard))
    local data2 = {}
    for i,v in pairs(data) do
        data2[i] = v:sub(string.len("./UserData"))
    end
    return data2
    
    else
    
    return native.find(wildcard)
    
    end
end
    



_G.fs.getDir = function(path)
	local pos = {string.find(path,"rom")}
	if pos[2] ~= 3 and pos[2] ~= 4 then
		return native.getDir(getPath(path))
	else
		return native.getDir(path)
	end
end

_G.fs.complete = function(sName, path, _third, _fourth)
	local pos = {string.find(path,"rom")}
	if pos[2] ~= 3 and pos[2] ~= 4 then
		return native.complete(sName,getPath(path),_third,_fourth)
	else
		return native.complete(sName,path,_third,_fourth)
	end
end

_G.fs.combine = function(first,second)
		return native.combine(first,second)
end
