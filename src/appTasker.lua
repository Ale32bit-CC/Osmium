local appTasker = {}

local appWindow = osmium.require("appWindow.lua")



local os_pullEventRaw = os.pullEventRaw
--local os_shutdown = os.shutdown
--local os_reboot = os.reboot

local function n_pullEventRaw(trg)
    local m_event = {}
    while true do
        m_event = {coroutine.yield()}
        if m_event[1] == "terminate" then
            break
        elseif trg == nil or trg == m_event[1] then
            break
        end
    end
    return unpack(m_event)
end


        




local main_term = term.current()

local w, h = term.getSize()

local m_running = false

--term.setPaletteColor(colors.magenta,0xaaaaaa)

local apps = {}
local positions = {}
local appIDs = {}

function reOrder()
    local pos2 = {}
    pos2[1] = true
    for i=1,#positions do
        local v = positions[i]
        if v ~= true then
            pos2[#pos2+1] = v
        end
    end
    --print(textutils.serialize(pos2))
    --read()
    positions = pos2
end

local function setMainApp(pid)
    for i=1,#positions do
        if positions[i] == pid then positions[i] = true end
    end
    positions[1] = pid
    reOrder()
end
appTasker.setMain = setMainApp

local function switch(appid)
	if appIDs[appid] then
		for i=1,#positions do
			if positions[i] == pid then positions[i] = true end
		end
		positions[1] = appIDs[appid]
		reOrder()
	end
end
appTasker.switch = switch



local function launchApp(...)
    local m_args = {...}
    local env = setmetatable({},{__index = getfenv()})
    env._ENV = env
    
    
    local run = coroutine.create(function() local err,txt = pcall(os.run,env,unpack(m_args)) if not err then term.native().write(txt) end end)
    local app = {co=run}
    app.name = fs.getName(m_args[1])
    app.terminal = appWindow.create(app,main_term,1,1,w,h,m_running)
    local pid = (#apps+1)
    print(pid)
    apps[pid] = app
    reOrder()
    positions[1] = pid
    reOrder()
    
    return pid
end

local function launchFunction(func,name,appid)
	if appid then
		if appIDs[appid] then
			switch(appIDs[appid])
			return
		end
	end
    local pid = #apps+1
    local app = {}
    app.name = name or "[nameless]"
    app.co = coroutine.create(func)
    app.terminal = appWindow.create(app,main_term,1,1,w,h,m_running)
	if appid then
		app.aID = appid
		appIDs[appid] = app.co
	end
    apps[pid] = app
    reOrder()
    positions[1] = pid
    reOrder()
    return pid
end


appTasker.launchFunction = launchFunction
appTasker.launch = launchApp

 --removed feature
function repositionApp(pid,x,y)
    local app = apps[pid]
    app.terminal.reposition(x,y,app.terminal.getFullSize())
end

appTasker.reposition = repositionApp


function resumeApp(pid,evt)
    os.pullEventRaw = n_pullEventRaw
    --os.runningApp = pid
    local app = apps[pid]
    if not app then return end
    local curTerm = term.current()
    term.redirect(app.terminal)
    local ret = {coroutine.resume(app.co,unpack(evt or {}))}
    term.redirect(curTerm)
    os.pullEventRaw = os_pullEventRaw
    return unpack(ret)
end

function redraw()
    reOrder()
    term.setBackgroundColor(colors.black)
    term.clear()
    for i=#positions,2,-1  do
        local app = apps[positions[i]]
        
        app.terminal.redraw()
    end
end

appTasker.redraw = redraw

local isDragging = false
local dragx = 0



function updateTop(evt)
    local x = evt[3]
    local y = evt[4]
    local oldPid = positions[2]
    for i=2,#positions do
        local pid = positions[i]
        local app = apps[pid]
        local wx,wy = app.terminal.getPosition()
        local n_x,n_y = (x-wx+1),(y-wy+1)
        local ww,wh = app.terminal.getShownSize()
        if n_x >= 1 and n_x <= ww and n_y >= 0 and n_y <= wh then
            if i~=2 then
                setMainApp(pid)
                resumeApp(oldPid,{"lost_focus"})
                resumeApp(pid,{"gained_focus"})
            end
            if n_y == 0 then
              if n_x == (ww-1) then
                  app.terminal.setMinimized(not app.terminal.getMinimized())
              else
                  isDragging = true; dragx = n_x
              end
            end
            return (i==2 and n_y ~= 0)
        end
    end
    return true
end

local isUserEvent = {
char = true,
key = true,
key_up = true,
paste = true,
terminate = true,
mouse_scroll = true,
mouse_up = true,
mouse_click = true,
mouse_drag = true,

}



function doEvents()
    m_running = true
	local oldColor
	if term.setPaletteColor then
		oldColor = term.getPaletteColor(colors.magenta)
		term.native().setPaletteColor(colors.magenta,0xaaaaaa)
	end
    for i,v in pairs(apps) do
        v.terminal.setVisible(true)
    end
    os.queueEvent("start_apptasker")
    
    while #positions > 1 do
        redraw()
        local evt = {os.pullEventRaw()}
        reOrder()
        if evt[1] == "mouse_click" then
            if updateTop(evt) then
                local app = apps[positions[2]]
                local wx,wy = app.terminal.getPosition()
                evt[3] = evt[3] - wx + 1
                evt[4] = evt[4] - wy + 1
                resumeApp(positions[2],evt)
            end
        elseif isDragging == true then
            if evt[1] == "mouse_drag" then
                local x = evt[3]
                local y = evt[4]
                repositionApp(positions[2],(x-dragx+1),y)
            elseif evt[1] == "mouse_up" then
                isDragging = false
            else
                resumeApp(positions[2],evt)
            end
        elseif isUserEvent[evt[1]] then
            if evt[1]:find("mouse") then
                local app = apps[positions[2]]
                local wx,wy = app.terminal.getPosition()
                evt[3] = evt[3] - wx + 1
                evt[4] = evt[4] - wy + 1
            end
            
            resumeApp(positions[2],evt)
        else
            for i=2,#positions do
                resumeApp(positions[i],evt)
            end
        end
        for i=2,#positions do
            local pid = positions[i]
            local app = apps[pid]
            if coroutine.status(app.co) == "dead" then
                apps[pid] = nil
                positions[i] = true
            end
        end
    end
	if term.setPaletteColor then
		term.setPaletteColor(colors.magenta,oldColor)
	end
    term.setBackgroundColor(colors.black)
    term.clear()
    term.setCursorPos(1,1)
    m_running = false
end

appTasker.run = doEvents    







--[[
local pid1 = launchApp("/rom/programs/shell.lua")
local pid2 = launchApp("print.lua")
repositionApp(pid2,21,1)
resumeApp(pid1)
resumeApp(pid2)

doEvents()

term.setBackgroundColor(colors.black)
term.clear()
term.setCursorPos(1,1)
term.write("All apps have ended, exiting")
os.sleep(1)
term.clearLine()
term.setCursorPos(1,1)
]]


_G.appTasker = appTasker
return appTasker