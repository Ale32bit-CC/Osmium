print("Osmium is still in development.")
print("Would you like to start it?")
print("Y/n")
local r = read() --very advanced dev script
if r == "" or r:lower() = "y" or r:lower() == "yes" then
  os.run({},"/.Osmium/init.lua")
else
  print("Boot aborted")
end
