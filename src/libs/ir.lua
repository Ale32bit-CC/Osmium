--[[
	Iridium
	A GUI API developed for Osmium
	Copyright (C) 2017 Rahph
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>
--]]
_G.aread = function( _sReplaceChar, _sDefault )
	if _sReplaceChar ~= nil and type( _sReplaceChar ) ~= "string" then
		error( "bad argument #1 (expected string, got " .. type( _sReplaceChar ) .. ")", 2 )
	end
	if _sDefault ~= nil and type( _sDefault ) ~= "string" then
		error( "bad argument #2 (expected string, got " .. type( _sDefault ) .. ")", 2 )
	end
	term.setCursorBlink( true )
--.
	local sLine
	if type( _sDefault ) == "string" then
		sLine = _sDefault
	else
		sLine = ""
	end
	local nPos = #sLine
	if _sReplaceChar then
		_sReplaceChar = string.sub( _sReplaceChar, 1, 1 )
	end

	local w = term.getSize()
	local sx = term.getCursorPos()

	local function redraw( _bClear )
		local nScroll = 0
		if sx + nPos >= w then
			nScroll = (sx + nPos) - w
		end

		local cx,cy = term.getCursorPos()
		term.setCursorPos( sx, cy )
		local sReplace = (_bClear and " ") or _sReplaceChar
		if sReplace then
			term.write( string.rep( sReplace, math.max( string.len(sLine) - nScroll, 0 ) ) )
		else
			term.write( string.sub( sLine, nScroll + 1 ) )
		end

		term.setCursorPos( sx + nPos - nScroll, cy )
	end

	local function clear()
		redraw( true )
	end

	redraw()

	while true do
		local sEvent, param, x,y = os.pullEvent()
		if sEvent == "char" then
			-- Typed key
			clear()
			sLine = string.sub( sLine, 1, nPos ) .. param .. string.sub( sLine, nPos + 1 )
			nPos = nPos + 1
			redraw()

		elseif sEvent == "paste" then
			-- Pasted text
			clear()
			sLine = string.sub( sLine, 1, nPos ) .. param .. string.sub( sLine, nPos + 1 )
			nPos = nPos + string.len( param )
			redraw()

		elseif sEvent == "key" then
			if param == keys.enter then
				-- Enter
				break

			elseif param == keys.backspace then
				-- Backspace
				if nPos > 0 then
					clear()
					sLine = string.sub( sLine, 1, nPos - 1 ) .. string.sub( sLine, nPos + 1 )
					nPos = nPos - 1
					redraw()
				end

			elseif param == keys.home then
				-- Home
				if nPos > 0 then
					clear()
					nPos = 0
					redraw()
				end

			elseif param == keys.delete then
				-- Delete
				if nPos < string.len(sLine) then
					clear()
					sLine = string.sub( sLine, 1, nPos ) .. string.sub( sLine, nPos + 2 )
					redraw()
				end

			elseif param == keys["end"] then
				-- End
				if nPos < string.len(sLine ) then
					clear()
					nPos = string.len(sLine)
					redraw()
				end
			end

		elseif sEvent == "term_resize" then
			-- Terminal resized
			w = term.getSize()
			redraw()

		elseif sEvent == "mouse_click" then
				os.queueEvent("mouse_click",param,x,y)
				break
			end
	end

	local cx, cy = term.getCursorPos()
	term.setCursorBlink( false )
	term.setCursorPos( w + 1, cy )
	print()

	return sLine
end

function create(viewport, _BG, _allowTerminate, _xMouseOffset, _yMouseOffset)
	local obj = {}
	local bg = _BG or colors.black
	local vp = viewport
	local elements = {}
	local timers = {}
	local at
	local lastid = 1
	local lasttimerid = 1
	local stop = false
	local xOffset = _xMouseOffset or 0
	local cleanStop = false
	local yOffset = _yMouseOffset or 0
	if _allowTerminate == true then
		at = true
	elseif _allowTerminate == false then
		at = false
	else
		at = true
	end

  local selectedInput = nil

  function getObjectWithId(targetid)
    for i=1,#elements do
			if elements[i].id == targetid then
        return elements[i]
      end
    end
  end

	function obj.changeViewport(newVP)
		vp = newVP
		obj.redraw()
	end

	function obj.setXOffset(newXOffset)
		xOffset = newXOffset
	end

	function obj.setYOffset(newYOffset)
		yOffset = newYOffset
	end

	function obj.setBg(newBG)
		bg = newBG
	end

	function obj.deleteTimer(id)
		os.cancelTimer(id)
		for i=1,#timers do
			if timers[i].id == id then
				table.remove(timers,i)
			end
		end
	end

	function obj.addTimer(time,callback)
		local id = os.startTimer(time)
		timers[#timers+1] = {id=lasttimerid + 1,callback=callback,evid=id, time=time}
		lasttimerid = lasttimerid + 1
		return lasttimerid
	end



	function obj.deleteItem(targetid)
		for i=1,#elements do
			if elements[i].id == targetid then
				table.remove(elements,i)
				break
			end
		end
		obj.redraw()
	end
	function obj.addButton(x,y,text,callback, _BG, _FG)
		elements[#elements + 1] = {id=lastid+1,element="BTN",callback = callback, x = x, y = y, text = text, bg = _BG or colors.lightGray, fg = _FG or colors.white}
		local id = lastid + 1
		lastid = lastid + 1
		return id
	end
	function obj.alterButton(targetid,_newX,_newY,_newText,_newCallback,_newBG,_newFG)
		for i=1,#elements do
			if elements[i].id == targetid then
				local oldCallback = elements[i].callback
				local oldX = elements[i].x
				local oldY = elements[i].y
				local oldText = elements[i].text
				local oldBg = elements[i].bg
				local oldFg = elements[i].fg
				elements[i] = {id=targetid,element="BTN",callback = _newCallback or oldCallback, x = _newX or oldX, y = _newY or oldY, text = _newText or oldText, bg = _newBG or oldBg, fg = _newFG or oldFg}
			end
		end
	end
	function drawButton(id)
    local m_obj = getObjectWithId(id)
		vp.setCursorPos(m_obj.x,m_obj.y)
		vp.setBackgroundColor(m_obj.bg)
		vp.setTextColor(m_obj.fg)
		vp.write(m_obj.text)
	end

	function obj.addLabel(x,y,text, _BG, _FG)
		elements[#elements + 1] = {id=lastid+1,element="LBL", x = x, y = y, text = text, bg = _BG or bg, fg = _FG or colors.white}
		local id = lastid + 1
		lastid = lastid + 1
		return id
	end

	function drawLabel(id)
    local m_obj = getObjectWithId(id)
		vp.setCursorPos(m_obj.x,m_obj.y)
		vp.setBackgroundColor(m_obj.bg)
		vp.setTextColor(m_obj.fg)
		vp.write(m_obj.text)
	end

	function obj.alterLabel(targetid,_newX,_newY,_newText,_newBG,_newFG)
		for i=1,#elements do
			if elements[i].id == targetid then
				local oldX = elements[i].x
				local oldY = elements[i].y
				local oldText = elements[i].text
				local oldBg = elements[i].bg
				local oldFg = elements[i].fg
				elements[i] = {id=targetid,element="LBL", x = _newX or oldX, y = _newY or oldY, text = _newText or oldText, bg = _newBG or oldBg, fg = _newFG or oldFg}
			end
		end
	end

	function obj.addInput(x,y,width,_replace,_placeholder,_callback,_BG,_FG,_PHFG)
    local id = lastid + 1
		elements[#elements + 1] = {id=id,width = width, text = "", rep = _replace or false,element="INP", x = x, y = y, placeholder = _placeholder or "", callback = _callback or function() end, bg = _BG or colors.lightGray, fg = _FG or colors.black, placecol = _PHFG or colors.gray}
		lastid = lastid + 1
		return id
	end

  function drawInput(id)
    local m_input = getObjectWithId(id)
    local selected = selectedInput  == id
    local startX = m_input.x
    local startY = m_input.y
    local use_placeholder = false
    local text = m_input.text
    local width = m_input.width

    --Get right colors
    vp.setCursorPos(startX,startY)
    vp.setBackgroundColor(m_input.bg)
    if text == "" and not selected then
      vp.setTextColor(m_input.placecol)
      text = m_input.placeholder
      use_placeholder = true
    else
      vp.setTextColor(m_input.fg)
    end

    --Fill area
    vp.write(string.rep(" ",width))
    vp.setCursorPos(startX,startY)
    local onscreen = text:sub(-width)
    if use_placeholder or not m_input.rep then
        vp.write(onscreen)
    else
        vp.write(string.rep(m_input.rep,#onscreen))
    end
    m_input.cursx,m_input.cursy = vp.getCursorPos()
  end

  function getInputCursor(id)
    local m_input = getObjectWithId(id)
    vp.setTextColor(m_input.fg)
    vp.setCursorBlink(true)
    vp.setCursorPos(m_input.cursx,m_input.cursy)
  end



	function drawInputOld(id)
		local toDraw = {}
		vp.setCursorPos(elements[id].x,elements[id].y)
		vp.setBackgroundColor(elements[id].bg)
		for i=1,elements[id].width do
			vp.write(" ")
		end
		if #elements[id].text == 0 then
			vp.setTextColor(elements[id].placecol)
			for i=1,#elements[id].placeholder do
				toDraw[i] = elements[id].placeholder:sub(i,i)
			end
		else
			vp.setTextColor(elements[id].fg)
			for i=1,#elements[id].text do
				toDraw[i] = elements[id].text:sub(i,i)
			end
		end
		vp.setCursorPos(elements[id].x,elements[id].y)
		if #toDraw > elements[id].width then
			for i=1,elements[id].width - 3 do
				if elements[id].rep and #elements[id].text > 0 then vp.write(elements[id].rep) else vp.write(toDraw[i]) end
			end
			vp.write("...")
		else
			for i=1,#toDraw do
				if elements[id].rep and #elements[id].text > 0 then vp.write(elements[id].rep) else vp.write(toDraw[i]) end
			end
		end
	end

	function obj.alterInput(id,_x,_y,_width,_text,_replace,_placeholder,_callback,_bg,_fg,_phfg)
		for i=1,#elements do
			if id == elements[i].id then
				local id = elements[i].id
				local element = "INP"
				local x = _x or elements[i].x
				local y = _y or elements[i].y
				local width = _width or elements[i].width
				local text = _text or elements[i].text
				local replace = _replace or elements[i].rep
				local placeholder = _placeholder or elements[i].placeholder
				local callback = _callback or elements[i].callback
				local bg = _bg or elements[i].bg
				local fg = _fg or elements[i].fg
				local phfg = _phfg or elements[i].placecol
				elements[i] = {id=id,element=element,x=x,y=y,width=width,text=text,rep=replace,placeholder=placeholder,callback=callback,bg=bg,fg=fg,placecol=phfg}
			end
		end
	end
	function obj.getInput(id)
		local m_obj = getObjectWithId(id)
    printError(m_obj.text)
    os.sleep(2)
				return m_obj.text
	end

	function handleInput(id)
		local svp = window.create(vp,elements[id].x,elements[id].y,elements[id].width,1,true)
		svp.setBackgroundColor(elements[id].bg)
		svp.setTextColor(elements[id].fg)
		svp.clear()
		svp.setCursorPos(1,1)
		local old = term.current()
		term.redirect(svp)
		if elements[id].rep == false then elements[id].rep = nil end
		local input = aread(elements[id].rep, elements[id].text)
		term.redirect(old)
		elements[id].text = input
		elements[id].callback(input)
	end
	function obj.addImage(image,x,y)
		elements[#elements+1] = {element="IMG",x=x,y=y,image=image, id=lastid+1}
		local id = lastid + 1
		lastid = lastid + 1
		return id
	end
	function obj.alterImage(id,_image,_x,_y)
		for i=1,#elements do
			if id == elements[i].id then
				local image = _image or elements[i].image
				local x = _x or elements[i].x
				local y = _y or elements[i].y
				elements[i] = {element="IMG",id=id,image=image,x=x,y=y}
			end
		end
	end

	function drawImage(id)
    local m_obj = getObjectWithId(id)
		local oldterm = term.current()
		term.redirect(vp)
		paintutils.drawImage(m_obj.image,m_obj.x,m_obj.y)
		term.redirect(oldterm)
	end

	function obj.addFilledBox(x,y,x2,y2,color)
		elements[#elements+1] = {element="FBX",x=x,y=y,x2=x2,y2=y2,color=color}
		local id = lastid + 1
		lastid = lastid + 1
		return id
	end
	function obj.alterFilledBox(id,_x,_y,_x2,_y2,_color)
		for i=1,#elements do
			if id == elements[i].id then
				local x = _x or elements[i].x
				local y = _y or elements[i].y
				local x2 = _x2 or elements[i].x2
				local y2 = _y2 or elements[i].y2
				local color = _color or elements[i].color
				elements[i] = {element="FBX",id=id,x=x,y=y,x2=x2,y2=y2,color=color}
			end
		end
	end

	function drawFilledBox(id)
    local m_obj = getObjectWithId(id)
		local oldterm = term.current()
		term.redirect(vp)
		paintutils.drawFilledBox(m_obj.x,m_obj.y,m_obj.x2,m_obj.y2,m_obj.color)
		term.redirect(oldterm)
	end

	function obj.addBox(x,y,x2,y2,color)
		elements[#elements+1] = {element="BOX",x=x,y=y,x2=x2,y2=y2,color=color}
		local id = lastid + 1
		lastid = lastid + 1
		return id
	end
	function obj.alterBox(id,_x,_y,_x2,_y2,_color)
		for i=1,#elements do
			if id == elements[i].id then
				local x = _x or elements[i].x
				local y = _y or elements[i].y
				local x2 = _x2 or elements[i].x2
				local y2 = _y2 or elements[i].y2
				local color = _color or elements[i].color
				elements[i] = {element="BOX",id=id,x=x,y=y,x2=x2,y2=y2,color=color}
			end
		end
	end

	function drawBox(id)
    local m_obj = getObjectWithId(id)
		local oldterm = term.current()
		term.redirect(vp)
		paintutils.drawBox(m_obj.x,m_obj.y,m_obj.x2,elements[index].y2,m_obj.color)
		term.redirect(oldterm)
	end


	function obj.addLine(x,y,x2,y2,color)
		elements[#elements+1] = {element="LNE",x=x,y=y,x2=x2,y2=y2,color=color}
		local id = lastid + 1
		lastid = lastid + 1
		return id
	end
	function obj.alterLine(id,_x,_y,_x2,_y2,_color)
		for i=1,#elements do
			if id == elements[i].id then
				local x = _x or elements[i].x
				local y = _y or elements[i].y
				local x2 = _x2 or elements[i].x2
				local y2 = _y2 or elements[i].y2
				local color = _color or elements[i].color
				elements[i] = {element="LNE",id=id,x=x,y=y,x2=x2,y2=y2,color=color}
			end
		end
	end

	function drawLine(id)
    local m_obj = getObjectWithId(id)
		local oldterm = term.current()
		term.redirect(vp)
		paintutils.drawLine(m_obj.x,m_obj.y,m_obj.x2,m_obj.y2,m_obj.color)
		term.redirect(oldterm)
	end

  function obj.setHidden(id,hid)
    local obj = getObjectWithId(id)
    obj.hidden = hid
  end

  function obj.addGroup()
		local id = lastid + 1
		lastid = lastid + 1
    elements[#elements+1] = {element="GROUP",hidden = false,objects = {}, id = id}
		return id
	end

  function obj.moveGroup(id,dx,dy)
    local grp = getObjectWithId(id)
    if grp.element ~= "GROUP" then
      error("Cannot move non-group objects")
    end
    for i,v in pairs(grp.objects) do
      local obj = getObjectWithId(v)
      if obj.x then obj.x = obj.x + dx end
      if obj.y  then obj.y = obj.y + dy end
      if obj.x2 then obj.x = obj.x2 + dx end
      if obj.y2  then obj.y = obj.y2 + dy end
    end
  end

  function obj.setGroupHidden(id,hid)
    local grp = getObjectWithId(id)
    for i,v in pairs(grp.objects) do
      local obj = getObjectWithId(v)
      obj.hidden = hid
    end
  end

  function obj.addToGroup(grpid,id)
    local grp = getObjectWithId(grpid)
    grp.objects[#grp.objects+1] = id
  end




	function obj.redraw()
  vp.setCursorBlink(false)
		vp.setBackgroundColor(bg)
		vp.clear()
		for i=1,#elements do
      local id = elements[i].id
      if elements[i].hidden ~= true then
  			if elements[i].element == "BTN" then
  				drawButton(id)
  			end
  			if elements[i].element == "LBL" then
  				drawLabel(id)
  			end
  			if elements[i].element == "INP" then
  				drawInput(id)
  			end
  			if elements[i].element == "IMG" then
  				drawImage(id)
  			end
  			if elements[i].element == "FBX" then
  				drawFilledBox(id)
  			end
  			if elements[i].element == "BOX" then
  				drawBox(id)
  			end
  			if elements[i].element == "LNE" then
  				drawLine(id)
  			end
      end
		end
    if selectedInput then getInputCursor(selectedInput) end
	end
	function obj.alert(text, _title, _titlefg, _border, _middlebg, _middlefg, _buttonbg, _buttonfg)
		local xx, yy = vp.getSize()
		xx = xx / 2
		yy = yy / 2
		local bcol = _border or colors.blue
		local titlecol = _titlefg or colors.white
		local title = _title or "Alert"
		local mcolbg = _middlebg or colors.lightBlue
		local mcolfg = _middlefg or colors.white
		local buttonbg = _buttonbg or colors.lightBlue
		local buttonfg = _buttonfg or colors.white
		vp.setCursorPos(xx-10,yy-2)
		vp.setBackgroundColor(bcol)
		vp.setTextColor(titlecol)
		for i=1,20 do
			vp.write(" ")
		end
		vp.setCursorPos(xx-9,yy-2)
		vp.write(title)
		vp.setCursorPos(xx-10,yy-1)
		for i=1,20 do
			vp.write(" ")
		end
		vp.setCursorPos(xx-9,yy-1)
		vp.setBackgroundColor(mcolbg)
		for i=1,18 do
			vp.write(" ")
		end
		vp.setCursorPos(xx-9,yy-1)
		vp.setTextColor(mcolfg)
		vp.write(text)
		vp.setCursorPos(xx-10,yy)
		vp.setBackgroundColor(bcol)
		for i=1,20 do
			vp.write(" ")
		end
		vp.setCursorPos(xx+8,yy)
		vp.setBackgroundColor(buttonbg)
		vp.setTextColor(buttonfg)
		vp.setBackgroundColor(buttonbg)
		vp.write("OK")
		local ev
		repeat
			ev = os.pullEvent()
		until ev == "mouse_click" or ev == "key"
		obj.redraw()
	end
	function obj.exit(_clean)
		stop = true
		cleanStop = _clean
		os.queueEvent("_")
	end



	function handleMouse()
		os.sleep(0.05)
		obj.redraw()
		while stop == false do
		local ev = {os.pullEventRaw("mouse_click")}
		if ev[1] == "mouse_click" then
      local oldSelected = selectedInput
      selectedInput = nil
			ev[3] = ev[3] - xOffset
			ev[4] = ev[4] - yOffset
			for i=1,#elements do
				if elements[i].element == "BTN" and elements[i].hidden ~= true then
					if ev[1] == "mouse_click" then
						--print("Mouse click")
						if ev[4] == elements[i].y then
							--print("Y correct")
							--print("X: " .. ev[3] .. " Y: " .. ev[4] .. elements[i].x .. " to " .. elements[i].x + #elements[i].text)
							if ev[3] >= elements[i].x and ev[3] <= elements[i].x + #elements[i].text then
								--print("DOING STUFF")
								--sleep(2)
								elements[i].callback(elements[i].id)
								break
							end
						end
					end
				end
				if elements[i].element == "INP" and elements[i].hidden ~= true then
					if ev[1] == "mouse_click" then
						--print("Mouse click")
						if ev[4] == elements[i].y then
							--print("Y correct")
							--print("X: " .. ev[3] .. " Y: " .. ev[4] .. elements[i].x .. " to " .. elements[i].x + #elements[i].text)
							if ev[3] >= elements[i].x and ev[3] <= elements[i].width then
								--print("DOING STUFF")
								--sleep(2)
                selectedInput = elements[i].id
								--OLD, uses gread
                --handleInput(i)
								break
							end
						end
					end
				end
			end
   if oldSelected and oldSelected ~= selectedInput then
       local inp = getObjectWithId(oldSelected)
       if inp.callback then inp.callback(inp.text) end
   end
		end
		--sleep(1)
		obj.redraw()
		end
	end

	function stopSignalHandler()
		while true do
			local ev = {os.pullEventRaw()}
			if ev[1] == "terminate" and at == true then break end
			if ev[1] == "_" and stop then break end
		end
		vp.setBackgroundColor(colors.black)
		vp.setTextColor(colors.white)
		vp.setCursorPos(1,1)
		vp.clear()
	end

	function timerHandler()
		while true do
			local ev = {os.pullEventRaw("timer")}
			for i=1,#timers do
				if timers[i] then
				if ev[2] == timers[i].evid  then
					local call = timers[i].callback
					local time = timers[i].time
					local id = timers[i].id
					timers[i].callback()
					if timers[i] then
						local evid = os.startTimer(time)
						timers[i] = {callback = call, evid = evid, time = time, id = id}
					end
					obj.redraw()
				end
				else break end
			end
		end
	end

  function keyHandler()
    while true do
      local evt = {os.pullEventRaw()}
      if selectedInput then
        if evt[1] == "char" then
          local m_inp = getObjectWithId(selectedInput)
          m_inp.text = m_inp.text..evt[2]
          obj.redraw()
        elseif evt[1] == "key" then
          if evt[2] == keys.backspace then
            local m_inp = getObjectWithId(selectedInput)
            m_inp.text = m_inp.text:sub(1,-2)
            obj.redraw()
          elseif evt[2] == keys.enter then
              local inp = getObjectWithId(selectedInput)
              if inp.callback then inp.callback(inp.text) end
              selectedInput = nil
              obj.redraw()
          end
        end
      end
    end
  end

	function obj.go()
		parallel.waitForAny(stopSignalHandler,handleMouse,timerHandler,keyHandler)
		if cleanStop == true then
		term.setBackgroundColor(colors.black)
		term.setTextColor(colors.white)
		term.clear()
		term.setCursorPos(1,1)
		end
	end



	return obj
end
