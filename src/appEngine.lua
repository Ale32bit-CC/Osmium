local nativeFS = {}
for k,v in pairs(_G.fs) do
    nativeFS[k] = v
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
    if not nativeFS.exists(path) or nativeFS.isDir(path) then
        return false, "not a file"
    end
    local oopk = nativeFS.open(path,"r")
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
    
    
end

function appEngine.uninstall(id)
    
end

function appEngine.list()
    
end

function appEngine.canAlter(id)
    
end

function appEngine.getInfo(id)
    
end

dofile("/.Osmium/vfs.lua")

pcall(loadfile("/rom/programs/shell.lua")) --temp
