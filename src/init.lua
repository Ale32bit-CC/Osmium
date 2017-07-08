--[[
  Osmium
  Init
]]--

local panicMode = false

local function panic(err) -- crash 
    panicMode = true
    pcall(function()
        for k,v in ipairs(task.getInfo()) do -- kill all processes
            task.kill(k)
        end
    end)
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clear()
    term.setCursorPos(1,1)
    printError(err)
end

local function init() 
    local ok, err = pcall(function() -- 
        dofile("/rom/programs/shell.lua") --temp
    end)
    if not ok then
        panic(err)
    end
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
    name = name or tostring(co):gsub("thread: ",""),
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
