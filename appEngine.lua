local nativeFS = {}
for k,v in pairs(_G.fs) do
    nativeFS[k] = v
end

dofile("/.Osmium/vfs.lua")


