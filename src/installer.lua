

if not term.isColor() then
  print("Osmium only supports advanced terminals.")
  return
end

local old = os.pullEvent
os.pullEvent = os.pullEventRaw

local files = {
    ["src/init.lua"] = "/.Osmium/init.lua",
    ["src/vfs.lua"] = "/.Osmium/vfs.lua",
    ["src/appEngine.lua"] = "/.Osmium/appEngine.lua",
    ["src/appTasker.lua"] = "/.Osmium/appTasker.lua",
    
	["src/libs/ir.lua"] = "/.Osmium/libs/ir.lua",
	["src/libs/sha256.lua"] = "/.Osmium/libs/sha256.lua",
	["src/libs/db.lua"] = "/.Osmium/libs/db.lua",
	["src/libs/appWindow.lua"] = "/.Osmium/libs/appWindow.lua",
    
    ["src/startup.lua"] = "/.Osmium/startup.lua",
    ["src/startup.lua"] = "/startup",
	["src/apps/osmium.login.opk"] = "/.UserData/.AppEngineScheduled/login",
	["src/apps/osmium.desktop.opk"] = "/.UserData/.AppEngineScheduled/desktop",
}

local githubUser    = "Ale32bit"
local githubRepo    = "Osmium"
local githubBranch  = "master"

local w, h = term.getSize()


local function clear()
  term.setBackgroundColor(colors.blue)
  term.clear()
  term.setCursorPos(1, 1)
  term.setTextColor(colors.white)
end

local function gui()
	clear()
	term.setTextColor(colors.white)
	term.setCursorPos(2,1)
	print("Osmium")
	term.setCursorPos(1,2)
	term.setTextColor(colors.white)
	term.setBackgroundColor(colors.blue)
end

local function center(text, y)
  local w, h = term.getSize()
  if not y then
  	local x, y = term.getCursorPos()
  end
  term.setCursorPos(math.ceil(w/2)-math.ceil(#text/2), y)
  write(text)
end

local function httpGet(url, save)
	if not url then
		error("not enough arguments, expected 1 or 2", 2)
	end
	local remote = http.get(url)
	if not remote then
		return false
	end
	local text = remote.readAll()
	remote.close()
	if save then
		local file = fs.open(save, "w")
		file.write(text)
		file.close()
		return true
	end
	return text
end

local function get(user, repo, bran, path, save)
	if not user or not repo or not bran or not path then
		error("not enough arguments, expected 4 or 5", 2)
	end
    local url = "https://raw.github.com/"..user.."/"..repo.."/"..bran.."/"..path
	local remote = http.get(url)
	if not remote then
		return false
	end
	local text = remote.readAll()
	remote.close()
	if save then
		local file = fs.open(save, "w")
		file.write(text)
		file.close()
		return true
	end
	return text
end

local function getFile(file, target)
	return get(githubUser, githubRepo, githubBranch, file, target)
end

gui()

local fileCount = 0
for _ in pairs(files) do
	fileCount = fileCount + 1
end
local filesDownloaded = 0

local w, h = term.getSize()
--[[
term.setBackgroundColor(colors.white)
term.setTextColor(colors.black)
term.clear()
term.setCursorPos(1,1)
gui()
term.setCursorPos(2,3)
print("License\n")
printError("You must accept the license to install sPhone\n")
print("The MIT License (MIT)\nCopyright (c) 2017 Sertex\n\nRead full license here:\nhttps://raw.github.com/SertexTeam/sPhone/master/LICENSE")
paintutils.drawFilledBox(2,17,9,19,colors.lime)
term.setCursorPos(3,18)
term.setTextColor(colors.white)
print("Accept")

paintutils.drawFilledBox(18,17,25,19,colors.red)
term.setCursorPos(20,18)
term.setTextColor(colors.white)
print("Deny")

while true do
	local e = {os.pullEvent()}
	if e[1] == "mouse_click" then
		local x,y = e[3],e[4]
		if (x >= 2 and y >= 17 ) and (x <= 9 and y <= 19 ) then
			break
		elseif (x >= 18 and y >= 17) and (x <= 25 and y <= 19) then
			os.pullEvent = old
			return
		end
	elseif e[1] == "terminate" then
		os.pullEvent = old
		print("Terminated")
		return
	end
end
]]
if fs.exists("/startup") then
	fs.delete("/startup")
end
parallel.waitForAny(function()
for k, v in pairs(files) do
	term.setTextColor(colors.black)
	term.setBackgroundColor(colors.white)
	gui()
	center("Downloading files",6)
	term.setCursorPos(1,12)
	term.clearLine()
	center("  "..filesDownloaded.."/"..fileCount, 12)
	local ok = k:sub(1, 4) == "ext:" and httpGet(k:sub(5), v) or getFile(k, v)
	if not ok then
		if term.isColor() then
			term.setTextColor(colors.red)
		end
		term.setCursorPos(2, 16)
		print("Error getting file:")
		term.setCursorPos(2, 17)
		print(k)
		sleep(1.5)
	end
	filesDownloaded = filesDownloaded + 1
end
term.setCursorPos(1,12)
term.clearLine()
center("  "..filesDownloaded.."/"..fileCount, 12)
end, function()
    local shades = {
        0x3366cc,
        0x3b6ed4,
        0x4275db,
        0x4a7de3,
        0x5285eb,
        0x598cf2,
        0x6194fa,
        0x699cff,
        0x70a3ff,
        0x78abff,
    }
    while true do
        if term.setPaletteColor then
            for i=1,#shades do
                term.setPaletteColor(colors.blue,shades[i])
                sleep(0.1)
            end
            for i=#shades,1,-1 do
                term.setPaletteColor(colors.blue,shades[i])
                sleep(0.1)
            end
        end
        sleep(0.1)
    end
end)

if not fs.exists("/startup") then
	fs.copy("/.Osmium/startup.lua","/startup")
end
center("  Osmium installed!",h-2)
center("  Rebooting...",h-1)
sleep(2)
os.reboot()
