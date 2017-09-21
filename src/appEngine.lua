local nativeFS = {}
for k,v in pairs(_G.fs) do
    nativeFS[k] = v
end

local nativeLoadfile = function(file,env)
    if not nativeFS.exists(file) then
        return nil
    end
    local handle = nativeFS.open(file,"r")
    local script = handle.readAll()
    handle.close()
    local func, err = load(script, nativeFS.getName( file ), "t", env)
    return func, err 
end

if not nativeFS.exists("/.UserData") then
	nativeFS.makeDir("/.UserData")
end

if not nativeFS.exists("/.UserData/rom") then
	nativeFS.makeDir("/.UserData/rom")
end

if not nativeFS.exists("/.UserData/rom/readme") then
	local f = nativeFS.open("/.UserData/rom/readme","w")
	f.write("print(\"What ever you are doing, please stop it now.\\nModifying system files can cause unexpected behaviour.\\nIf you managed to access this file without putting your computer in a disk drive, please report the expoit to Ale32bit or Rahph.\")")
	f.close()
end

if not nativeFS.exists("/.OsmiumApps") then
	nativeFS.makeDir("/.OsmiumApps/apps")
end

_G.appEngine = {}
local runningOpk = {}

local opkSystem = { -- Put OPK ids that can't be altered
	["osmium.restore"] = true,
	["osmium.login"] = true,
	["osmium.desktop"] = true,
}

local configFile = "/.OsmiumApps/config"

local function set(id,conf,value)
    local dat
    local f = nativeFS.open(configFile,"r")
    if f then
        dat = textutils.unserialise(f.readAll())
        f.close()
    else
        dat = {}
    end
    if not dat[id] then
        dat[id] = {}
    end
    dat[id][conf] = value
    local f = nativeFS.open(configFile,"w")
    f.write(textutils.serialise(dat))
    f.close()
end

local function get(id,conf)
    local dat
    local f = nativeFS.open(configFile,"r")
    if not f then
        dat = {}
    else
        dat = textutils.unserialise(f.readAll())
        f.close()
    end
    if not dat[id] then
        return false
    end
    return dat[id][conf]
end

function appEngine.exists(id)
    if get(id,"name") then
        return true
    end
    return false
end

function appEngine.install(path)
    if not fs.exists(path) or fs.isDir(path) then
        return false, "not a file"
    end
    local oopk = fs.open(path,"r")
    if not oopk then
        return false, "not opk"
    end
    local opk = textutils.unserialise(oopk.readAll())
    oopk.close()
    
    local config = opk.config
    local files = opk.files
    local dat = opk.opkData
	local icon = opk.icon
    
    if not config.id then
        return false, "not opk, missing id"
    end
    
    if opkSystem[config.id] then
        return false, "system opk"
    end
    
    -- set configs
    
    set(config.id,"name",config.name or "n/a")
    set(config.id,"version",config.version or 1)
    set(config.id,"author",config.author or "none")
    set(config.id,"dependencies",config.dependencies or {})
    
    -- install files
    
    nativeFS.makeDir("/.OsmiumApps/apps/"..config.id)
    for k, v in pairs(files) do
        local f = nativeFS.open("/.OsmiumApps/apps/"..config.id.."/"..k,"w")
        if f then
            f.write(v)
            f.close()
        end
    end
	local finalIcon = {}
	if icon and type(icon) == "table" then
		for y = 1,4 do
			finalIcon[y] = {}
			for x = 1,5 do
				if icon[y] and icon[y][x] then
					finalIcon[y][x] = icon[y][x]
				end
			end
		end
		local f = nativeFS.open("/.OsmiumApps/icons/"..config.id,"w")
		f.write(textutils.serialise(finalIcon))
		f.close()
	end
	
    return true, config.id
end

function appEngine.launch(id)
    if not appEngine.exists(id) then
        return false
    end
    local config = {
        name = get(id,"name") or "n/a",
        author = get(id,"author") or "none",
        version = get(id,"version") or 1,
        dependencies = get(id,"dependencies") or {},
    }
    
    local opkApi = {}
    local function getPath(path)
        path = path or ""
        
        local fullPath = nativeFS.combine(path,"")
        
        if fullPath:find("^%.OsmiumApps/apps/" .. id) then
            return path
        end
        
        
        fullPath = nativeFS.combine("/.OsmiumApps/apps/" .. id .. "/",path or "")
        
        if fullPath:find("^%.OsmiumApps/apps/" .. id) then
            return fullPath
        else
            error("Path does not exist")
        end
    end
    
    
    opkApi.open = function(file,mode)
        if mode ~= "r" and mode ~= "rb" then
            error("File is read only")
        else
            return nativeFS.open(getPath(file,mode))
        end
    end
    
    opkApi.copy = function(source,target)
        local handle = nativeFS.open(getPath(source),"r")
        local file = handle.readAll()
        handle.close()
        local handle = fs.open(target,"w")
        handle.write(file)
        handle.close()
    end
    runningOpk[id] = true
    local func = function() local ok, err = pcall(
        setfenv(nativeLoadfile("/.OsmiumApps/apps/"..id.."/main.lua"), setmetatable(
            { --opk api
            opk = opkApi,
	            shell = shell,
            },{__index = getfenv()}
        )))
		runningOpk[id] = nil
       if not ok then
           printError(err)
           read()
        end 
    end
    
	--task.launch(func,config.name)
	
    appTasker.launchFunction(func,config.name,config.id)
    
    --if not ok then
        --printError(err)
    --end
end

function appEngine.uninstall(id)
    if opkSystem[id] then
        return false, "system opk"
    end
    if not appEngine.exists(id) then
        return false, "not found"
    end
    local list
    local f = nativeFS.open(configFile,"r")
    if f then
        list = textutils.unserialise(f.readAll())
        f.close()
    else
        list = {}
    end
    list[id] = nil
    local f = nativeFS.open(configFile,"w")
    f.write(textutils.serialise(list))
    f.close()
    nativeFS.delete("/.OsmiumApps/apps/"..id)
	nativeFS.delete("/.OsmiumApps/icons/"..id)
    return true
end

function appEngine.list()
    local f = nativeFS.open(configFile,"r")
    if f then
        local opks = textutils.unserialise(f.readAll())
        f.close()
        local opk = {}
        for k,v in pairs(opks) do
            opk[k] = v.name
        end
        return opk
    else
        return {}
    end
end

function appEngine.canAlter(id)
    if opkSystem[id] then
        return false
    end
    return true
end

function appEngine.getInfo(id)
    local f = nativeFS.open(configFile,"r")
    if f then
        local opks = textutils.unserialise(f.readAll())
        f.close()
        if opks[id] then
            return opks[id]
        else
            return nil
        end
    end
    return nil
end

function appEngine.isRunning(id)
	return runningOpk[id] or false
end

function appEngine.getIcon(id)
	if not appEngine.exists(id) then
		return nil
	end
	local f = nativeFS.open("/.OsmiumApps/icons/"..id,"r")
	if f then
		local icon = textutils.unserialise(f.readAll())
		f.close()
		return icon
	end
	return nil
end

if nativeFS.exists("/.UserData/.AppEngineScheduled") then
	for k,v in ipairs(nativeFS.list("/.UserData/.AppEngineScheduled")) do
		appEngine.install("/.UserData/.AppEngineScheduled/" .. v)
		nativeFS.delete("/.UserData/.AppEngineScheduled/".. v)
	end
end

local appTasker = dofile("/.Osmium/appTasker.lua")

dofile("/.Osmium/vfs.lua")

appEngine.launch("osmium.desktop")
appEngine.launch("osmium.login")

appTasker.run()
