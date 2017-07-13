--[[
  Osmium
  Init
]]--
if osmium then
    return
end

-- recovery

local logo = { { 0, 0, 2048, 2048, 2048, 2048, 2048, 2048, }, { 0, 2048, 0, 0, 0, 0, 0, 0, 2048, }, { 2048, 0, 0, 0, 0, 0, 0, 0, 0, 2048, }, { 2048, 0, 0, 0, 0, 0, 0, 0, 0, 2048, 0, 0, 0, 0, 2048, 2048, 2048, 2048, }, { 2048, 0, 0, 0, 0, 0, 0, 0, 0, 2048, 0, 0, 0, 2048, }, { 2048, 0, 0, 0, 0, 0, 0, 0, 0, 2048, 0, 0, 0, 0, 2048, 2048, 2048, }, { 0, 2048, 0, 0, 0, 0, 0, 0, 2048, 0, 0, 0, 0, 0, 0, 0, 0, 2048, }, { 0, 0, 2048, 2048, 2048, 2048, 2048, 2048, 0, 0, 0, 0, 0, 2048, 2048, 2048, 2048, }, }

local function centerWrite(text)
    local w,h = term.getSize()
    local _,y = term.getCursorPos()
    term.setCursorPos(math.ceil(w/2)-math.ceil(#text/2),y)
    write(text)
end
local w,h = term.getSize()
local dev = false

local function recovery()
    local exit = false
    local options = {
        {"Wipe drive",function() 
            -- not yet
        end},
        {"Update Osmium", function() 
            local ok,err = pcall(setfenv(loadstring(http.get("https://raw.github.com/Ale32bit/Osmium/master/src/installer.lua").readAll()),getfenv()))
        end},
        {"Exit", function()
            exit = true
        end},
        {"DEV: Load CraftOS",function() dev = true exit = true end,},
    }
    term.setBackgroundColor(colors.white)
    term.setTextColor(colors.black)
    term.clear()
    term.setCursorPos(1,1)
    print("Osmium recovery")
    for k,v in ipairs(options) do
        print(v[1])
    end
    local selected = 1
    local old = 1
    while not exit do
        term.setCursorPos(1,old+1)
        term.clearLine()
        term.write(options[old][1])
        term.setCursorPos(1,selected+1)
        term.clearLine()
        term.write("[ "..options[selected][1].." ]")
        local _,k = os.pullEventRaw("key")
        old = selected
        if k == keys.up then
            selected = selected-1
        elseif k == keys.down then
            selected = selected+1
        elseif k == keys.enter then
            options[selected][2]()
        end
        if selected < 1 then
            selected = 1
        elseif selected > #options then
            selected = #options
        end
    end
end

term.setBackgroundColor(colors.lightBlue)
term.setTextColor(colors.white)
term.clear()
term.setCursorPos(1,2)
centerWrite("Osmium")
term.setCursorPos(1,1)
term.setTextColor(colors.gray)
print("Developed by")
term.setTextColor(colors.blue)
print("Ale32bit")
print("Rahph")
print("Tomtrein")
term.setTextColor(colors.white)
term.setCursorPos(1,h)
centerWrite("ALT to access recovery")
paintutils.drawImage(logo,math.ceil(w/2)-math.ceil(#logo[#logo]/2),math.ceil(h/2)-math.ceil(#logo/2))
local timer = os.startTimer(1) --access time
while true do
    local ev = {os.pullEventRaw()}
    if ev[1] == "timer" and ev[2] == timer then
        break
    elseif ev[1] == "key" and ev[2] == keys.leftAlt then
        recovery()
        break
    end
end
if dev then
    return
end
if _G.debug and _G.debug.getupvalue then
  _G.debug.getupvalue = nil
end
_G.osmium = {}



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

local panicMode = false
term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)
term.clear()
term.setCursorPos(1,1)

local function panic(err) -- crash 
    panicMode = true
    pcall(function()
        for k,v in ipairs(task.getInfo()) do -- kill all processes
            task.kill(k)
        end
    end)
    term.setBackgroundColor(colors.red)
    term.setTextColor(colors.white)
    term.clear()
    term.setCursorPos(1,1)
    print("Osmium")
    print("")
    print("Osmium errored and has been shut down")
    print("")
    print(err or "Unknown error")
    print("")
    print("Please report to the developers")
end

local function init() 
    local ok, err = pcall(setfenv(nativeLoadfile("/.Osmium/appEngine.lua"),setmetatable({
            nFS = nativeFS,
            shell = shell,
        },{__index = getfenv()})))
    if not ok then
        panic(err)
    end
end

-- change os version

function os.version()
    return "Osmium 0.1"
end

-- Require function

function osmium.require(lib)
    if not lib then
        return nil
    end
    libn = fs.getName(lib)
    if nativeFS.exists("/.Osmium/libs/"..libn) and not nativeFS.isDir("/.Osmium/libs/"..libn) then
        lib = "/.Osmium/libs/"..libn
    elseif nativeFS.exists("/rom/apis/"..libn) and not nativeFS.isDir("/rom/apis/"..libn) then
        lib = "/rom/apis/"..libn
    elseif nativeFS.exists(lib) then
        lib = lib -- really?!
    elseif _G[lib] and type(_G[lib]) == "table" then
        return _G[lib]
    end
    
    local tEnv = {}
    setmetatable(tEnv,{__index = _G})
    local fnAPI, err = nativeLoadfile( lib, tEnv)
    if fnAPI then
        local ok, err = pcall(fnAPI)
        if not ok then
            printError(err)
            return nil
        end
    else
        printError(err)
        return nil
    end
    
    local tAPI = {}
    for k,v in pairs( tEnv ) do
        if k ~= "_ENV" then
            tAPI[k] = v
        end
    end
    return tAPI
end

-- task
--[[
  task.signal(pid, signal)
  task.kill(pid)
  task.launch(function, process name)
  task.getInfo(): returns processes list

  Proc multitask by MultMine
]]--

local _proc = {}
local _killProc = {}
_G.task = {}
function task.signal(pid, sig)
  local p = _proc[pid]
  if p then
    if not p.filter or p.filter == "signal" then
      local ok, rtn = coroutine.resume(p.co, "signal", tostring(sig))
      if ok then
        p.filter = rtn
      end
    end
    return true
  end
  return false
end
function task.kill(pid)
  _killProc[pid] = true
end
function task.launch(fn, name)
  _proc[#_proc + 1] = {
    co = coroutine.create(setfenv(fn, getfenv())),
    name = name or "lua",
  }
  return true
end
function task.getInfo()
  local t = {}
  for pid, v in pairs(_proc) do
    t[pid] = v.name
  end
  return t
end

-- start
task.launch(init, "init")
os.queueEvent("multitask")
while _proc[1] ~= nil do
    local ev = {os.pullEventRaw()}
    for pid, v in pairs(_proc) do
      if not v.filter or ev[1] == "terminate" or v.filter == ev[1] then
        local ok, rtn = coroutine.resume(v.co, unpack(ev))
        if ok then
          v.filter = rtn
        else
            printError(rtn)
        end
      end
      if coroutine.status(v.co) == "dead" then
        _killProc[pid] = true
      end
    end
    for pid in pairs(_killProc) do
      _proc[pid] = nil
    end
    if next(_killProc) then
      _killProc = {}
    end
end

if panicMode then -- shows error
    os.pullEventRaw("key")
end
_G.term = nil -- force shutdown computer
