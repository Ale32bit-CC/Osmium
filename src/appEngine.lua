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
	nativeFS.makeDir("/.OsmiumApps")
end

_G.appEngine = {}

local opkSystem = { -- Put OPK ids that can't be altered

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
    if not oopk then --i'm an idiot..
        return false, "not opk"
    end
    local opk = textutils.unserialise(oopk.readAll())
    oopk.close()
    
    local config = opk.config
    local files = opk.files
    local dat = opk.opkData
    
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
    
    nativeFS.makeDir("/.OsmiumApps/"..config.id)
    for k, v in pairs(files) do
        local f = nativeFS.open("/.OsmiumApps/"..config.id.."/"..k,"w")
        if f then
            f.write(v)
            f.close()
        end
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
        
        if fullPath:find("^%.OsmiumApps/" .. id) then
            return path
        end
        
        
        fullPath = nativeFS.combine("/.OsmiumApps/" .. id .. "/",path or "")
        
        if fullPath:find("^%.OsmiumApps/" .. id) then
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
    
    local ok, err = pcall(setfenv(nativeLoadfile("/.OsmiumApps/"..id.."/main.lua"), setmetatable(
        { --opk api
            opk = opkApi,
	    shell = shell,
        },{__index = getfenv()}
    )))
    if not ok then
        printError(err)
    end
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
    nativeFS.delete("/.OsmiumApps/"..id)
    return true
end

function appEngine.list()
    local f = nativeFS.open(configFile,"r")
    if f then
        local opks = textutils.unserialise(f.readAll())
        f.close()
        local opk = {}
        for k,v in pairs(opks) do
            table.insert(opk,k)
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

dofile("/.Osmium/vfs.lua")

dofile("/rom/programs/advanced/multishell.lua") --temp
