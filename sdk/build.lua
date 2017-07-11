local args = {...}
if #args < 2 then
    print("Usage: build <directory> <output>")
    return
end

local input = args[1]
local output = args[2]

-- functions readFile and explore took from Compress by Creator

local function readFile(path)
	local file = fs.open(path,"r")
	local variable = file.readAll()
	file.close()
	return variable
end

local function explore(dir)
	local buffer = {}
	local sBuffer = fs.list(dir)
	for i,v in pairs(sBuffer) do
		if fs.isDir(dir.."/"..v) then
			if v ~= ".git" then
				buffer[v] = explore(dir.."/"..v)
			end
		else
			buffer[v] = readFile(dir.."/"..v)
		end
	end
	return buffer
end

local files = explore(input.."/files")

local file = fs.open(input.."/config","r")
local config = textutils.unserialise(file.readAll())
file.close()

for k,v in pairs(config) do
	print(k..":"..v)
end

local out = {}
out["config"] = config
out["files"] = files
out["opkData"] = {
	version = 1,
	builder = "OPK BUILDER",
}

local f = fs.open(output,"w")
f.write(textutils.serialise(out))
f.close()
print("Built")
