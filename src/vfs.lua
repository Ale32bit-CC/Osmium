local UserPath = ".UserData"

local native = {}
for k,v in pairs(_G.fs) do
    native[k] = v
end

local fs = {}

local function getPath(path)

    --Failsafe
    local fullPath = native.combine(path or "","")

    if (native.getDrive(fullPath) or native.getDrive(native.getDir(fullPath))) ~= "hdd" then
      return fullPath
    end


    if fullPath:sub(1,#UserPath) == UserPath then
        return fullPath
    end
    --End failsafe

    fullPath = native.combine(UserPath,fullPath)
    if fullPath:sub(1,#UserPath) == UserPath then
        return fullPath
    else
        error("Path doesn't exist")
    end
end




--shell.setDir("/.UserData/")
fs.open = function(file,mode)
    return native.open(getPath(file),mode)
end

fs.list = function(path)
    if native.combine(path,"") == "" then
      local l1 = native.list(getPath(path))
      local l2 = native.list(path)
      for i,v in pairs(l2) do
        if native.getDrive(v) ~= "hdd" then
          if v ~= "rom" then
            table.insert(l1,v)
          end
        end
      end
      return l1
    end
    return native.list(getPath(path))
end

fs.exists = function(path)
    return native.exists(getPath(path))
end

fs.isDir = function(path)
    return native.isDir(getPath(path))
end

fs.isReadOnly = function(path)
  return native.isReadOnly(getPath(path))
end

fs.getName = function(path)
    return native.getName(getPath(path))
end

fs.getDrive = function(path) return native.getDrive(getPath(path)) end

fs.getSize = function(path)
    return native.getSize(getPath(path))
end

fs.getFreeSpace = function(path)
    return native.getFreeSpace(getPath(path))
end

fs.makeDir = function(path)
    return native.makeDir(getPath(path))
end

fs.move = function(path,target)
    return native.move(getPath(path), getPath(target))
end

fs.copy = function(path,target)
    return native.copy(getPath(path),getPath(target))
end

fs.delete = function(path)
	    return native.delete(getPath(path))
end

fs.find = function(wildcard)

    local data = native.find(getPath(wildcard))
    local data2 = {}
    for i,v in pairs(data) do
        if v:sub(1,#UserPath) == UserPath then
          data2[i] = v:sub(string.len("./UserData"))
        else
          data2[i] = v
        end
    end
    return data2
end




fs.getDir = function(path)
	 return native.getDir(getPath(path))
end

fs.complete = function(sName, path, _third, _fourth)
		return native.complete(sName,getPath(path),_third,_fourth)
end

fs.combine = function(first,second)
		return native.combine(first,second)
end

_G.fs = fs
