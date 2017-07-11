--[[

	Database API Created by Ale32bit
	
	db v2.2
	
	MIT License

	Copyright (c) 2017 Ale32bit

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.

]]--

local database = "/.config" -- Config file

local db = {}

if fs.isDir(database) then
	error("database must be a file")
end

if not fs.exists(database) then
	local data = {
		database = {
			version = 2.2,
		}
	}
	local f = fs.open(database,"w")
	f.write(textutils.serialise(data))
	f.close()
end

-- init

local f = fs.open(database,"r")
db = textutils.unserialise(f.readAll())
f.close()
if not db then
	db = {
		database = {
			version = 2.2,
		}
	}
end

function checkDatabase()
  local f = fs.open(database,"r")
  local data = textutils.unserialise(f.readAll())
  f.close()
  if data then
    return true
  end
  return false
end

function get(group,config)
	if not db[group] then
		return nil
	end
	if not config then
		return db[group]
	end
	return db[group][config]
end

function set(group,config,value)
	local old = db
	if not db[group] then
		db[group] = {}
	end
	db[group][config] = value
	if not db then
		db = old
		return false
	end
	local f = fs.open(database,"w")
	f.write(textutils.serialise(db))
	f.close()
	return true
end

function list(group)
	return db[group]
end

function index()
	return db
end

function update() --update from file
	if not checkDatabase() then
		return false, "database corrupted"
	end
	local f = fs.open(database,"r")
	db = textutils.unserialise(f.readAll())
	f.close()
	return true
end

function fixFile() --update file from memory
	local f = fs.open(database, "w")
	f.write(textutils.serialize(db))
	f.close()
end

function delete(group)
	db[group] = nil
	local f = fs.open(database,"w")
	f.write(textutils.serialise(db))
	f.close()
end
