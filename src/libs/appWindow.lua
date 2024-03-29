
local tHex = {
    [ colors.white ] = "0",
    [ colors.orange ] = "1",
    [ colors.magenta ] = "2",
    [ colors.lightBlue ] = "3",
    [ colors.yellow ] = "4",
    [ colors.lime ] = "5",
    [ colors.pink ] = "6",
    [ colors.gray ] = "7",
    [ colors.lightGray ] = "8",
    [ colors.cyan ] = "9",
    [ colors.purple ] = "a",
    [ colors.blue ] = "b",
    [ colors.brown ] = "c",
    [ colors.green ] = "d",
    [ colors.red ] = "e",
    [ colors.black ] = "f",
}

local type = type
local string_rep = string.rep
local string_sub = string.sub
local table_unpack = table.unpack

function create( m_app, parent, nX, nY, nWidth, nHeight, bStartVisible )
    if type( parent ) ~= "table" then error( "bad argument #1 (expected table, got " .. type( parent ) .. ")", 2 ) end
    if type( nX ) ~= "number" then error( "bad argument #2 (expected number, got " .. type( nX ) .. ")", 2 ) end
    if type( nY ) ~= "number" then error( "bad argument #3 (expected number, got " .. type( nY ) .. ")", 2 ) end
    if type( nWidth ) ~= "number" then error( "bad argument #4 (expected number, got " .. type( nWidth ) .. ")", 2 ) end
    if type( nHeight ) ~= "number" then error( "bad argument #5 (expected number, got " .. type( nHeight ) .. ")", 2 ) end
    if bStartVisible ~= nil and type( bStartVisible ) ~= "boolean" then error( "bad argument #6 (expected boolean, got " .. type( bStartVisible ) .. ")", 2 ) end

    if parent == term then
        error( "term is not a recommended window parent, try term.current() instead", 2 )
    end
    
    --nHeight = nHeight - 1
    --nY = nY + 1
    
    local minimized = false
    local sEmptySpaceLine
    local tEmptyColorLines = {}
    local function createEmptyLines( nWidth )
        sEmptySpaceLine = string_rep( " ", nWidth )
        for n=0,15 do
            local nColor = 2^n
            local sHex = tHex[nColor]
            tEmptyColorLines[nColor] = string_rep( sHex, nWidth )
        end
    end

    createEmptyLines( nWidth )

    -- Setup
    local bVisible = (bStartVisible ~= false)
    local nCursorX = 1
    local nCursorY = 1
    local bCursorBlink = false
    local nTextColor = colors.white
    local nBackgroundColor = colors.black
    local tLines = {}
    local tPalette = {}
    do
        local sEmptyText = sEmptySpaceLine
        local sEmptyTextColor = tEmptyColorLines[ nTextColor ]
        local sEmptyBackgroundColor = tEmptyColorLines[ nBackgroundColor ]
        for y=1,nHeight do
            tLines[y] = {
                text = sEmptyText,
                textColor = sEmptyTextColor,
                backgroundColor = sEmptyBackgroundColor,
            }
        end
		
		if term.setPaletteColor then
			for i=0,15 do
				local c = 2 ^ i
				tPalette[c] = { parent.getPaletteColour( c ) }
			end
		end
    end

    -- Helper functions
    local function updateCursorPos()
        if nCursorX >= 1 and nCursorY >= 1 and
           nCursorX <= nWidth and nCursorY <= nHeight then
            parent.setCursorPos( nX + nCursorX - 1, nY + nCursorY - 1 )
        else
            parent.setCursorPos( 0, 0 )
        end
    end
    
    local function updateCursorBlink()
        if not minimized then
            parent.setCursorBlink( bCursorBlink )
        else
            parent.setCursorBlink(false)
        end
    end
    
    local function updateCursorColor()
        parent.setTextColor( nTextColor )
    end

    local function redrawLine( n )
        local tLine = nil
        if n == 0 then
            tLine = {}
            tLine.text = string.rep(" ",nWidth)
            --tLine.text = m_app.name..tLine.text:sub(#m_app.name+1)
            local textstrt = math.floor((nWidth-#m_app.name)/2)
            tLine.text = tLine.text:sub(1,textstrt-1)..m_app.name..tLine.text:sub(textstrt+#m_app.name)
            tLine.text = tLine.text:sub(1,-4)..string.rep(string.char(7),3)
            tLine.textColor = string.rep("0",nWidth)
            tLine.backgroundColor = string.rep("b",nWidth)
            tLine.textColor = tLine.textColor:sub(1,-4).."d1e"
        else
            tLine = tLines[ n ]
        end
        if n == 0 or minimized ~= true then
            parent.setCursorPos( nX, nY + n - 1)
            parent.blit( tLine.text, tLine.textColor, tLine.backgroundColor )
        end
    end

    local function redraw()
        for n=0,nHeight do
            redrawLine( n )
        end
    end

    local function updatePalette()
		if term.setPaletteColor then
			for k,v in pairs( tPalette ) do
				parent.setPaletteColour( k, v[1], v[2], v[3] )
			end
		end
    end

    local function internalBlit( sText, sTextColor, sBackgroundColor )
        local nStart = nCursorX
        local nEnd = nStart + #sText - 1
        if nCursorY >= 1 and nCursorY <= nHeight then
            if nStart <= nWidth and nEnd >= 1 then
                -- Modify line
                local tLine = tLines[ nCursorY ]
                if nStart == 1 and nEnd == nWidth then
                    tLine.text = sText
                    tLine.textColor = sTextColor
                    tLine.backgroundColor = sBackgroundColor
                else
                    local sClippedText, sClippedTextColor, sClippedBackgroundColor
                    if nStart < 1 then
                        local nClipStart = 1 - nStart + 1
                        local nClipEnd = nWidth - nStart + 1
                        sClippedText = string_sub( sText, nClipStart, nClipEnd )
                        sClippedTextColor = string_sub( sTextColor, nClipStart, nClipEnd )
                        sClippedBackgroundColor = string_sub( sBackgroundColor, nClipStart, nClipEnd )
                    elseif nEnd > nWidth then
                        local nClipEnd = nWidth - nStart + 1
                        sClippedText = string_sub( sText, 1, nClipEnd )
                        sClippedTextColor = string_sub( sTextColor, 1, nClipEnd )
                        sClippedBackgroundColor = string_sub( sBackgroundColor, 1, nClipEnd )
                    else
                        sClippedText = sText
                        sClippedTextColor = sTextColor
                        sClippedBackgroundColor = sBackgroundColor
                    end

                    local sOldText = tLine.text
                    local sOldTextColor = tLine.textColor
                    local sOldBackgroundColor = tLine.backgroundColor
                    local sNewText, sNewTextColor, sNewBackgroundColor
                    if nStart > 1 then
                        local nOldEnd = nStart - 1
                        sNewText = string_sub( sOldText, 1, nOldEnd ) .. sClippedText
                        sNewTextColor = string_sub( sOldTextColor, 1, nOldEnd ) .. sClippedTextColor
                        sNewBackgroundColor = string_sub( sOldBackgroundColor, 1, nOldEnd ) .. sClippedBackgroundColor
                    else
                        sNewText = sClippedText
                        sNewTextColor = sClippedTextColor
                        sNewBackgroundColor = sClippedBackgroundColor
                    end
                    if nEnd < nWidth then
                        local nOldStart = nEnd + 1
                        sNewText = sNewText .. string_sub( sOldText, nOldStart, nWidth )
                        sNewTextColor = sNewTextColor .. string_sub( sOldTextColor, nOldStart, nWidth )
                        sNewBackgroundColor = sNewBackgroundColor .. string_sub( sOldBackgroundColor, nOldStart, nWidth )
                    end

                    tLine.text = sNewText
                    tLine.textColor = sNewTextColor
                    tLine.backgroundColor = sNewBackgroundColor
                end

                -- Redraw line
                if bVisible then
                    redrawLine( nCursorY )
                end
            end
        end

        -- Move and redraw cursor
        nCursorX = nEnd + 1
        if bVisible then
            updateCursorColor()
            updateCursorPos()
        end
    end

    -- Terminal implementation
    local window = {}

    function window.write( sText )
        sText = tostring( sText )
        internalBlit( sText, string_rep( tHex[ nTextColor ], #sText ), string_rep( tHex[ nBackgroundColor ], #sText ) )
    end
    
    function window.setMinimized(isMin)
        if type(isMin) ~= "boolean" then error("Type must be a boolean",2) end
        minimized = isMin
        if not minimized then
            local cx,cy = window.getPosition()
            local ww,wh = window.getSize()
            local tw,th = parent.getSize()
            if (cy-1) == th then
                window.reposition(cx,th-wh,window.getFullSize())
            end
        else
            local cx,cy = window.getPosition()
            local cw,ch = window.getSize()
            local tw,th = parent.getSize()
            if (cy+ch-1) == th then
                window.reposition(cx,th,window.getFullSize())
            end
        end
    end
    
    function window.getMinimized()
        return minimized
    end

    function window.blit( sText, sTextColor, sBackgroundColor )
        if type( sText ) ~= "string" then error( "bad argument #1 (expected string, got " .. type( sText ) .. ")", 2 ) end
        if type( sTextColor ) ~= "string" then error( "bad argument #2 (expected string, got " .. type( sTextColor ) .. ")", 2 ) end
        if type( sBackgroundColor ) ~= "string" then error( "bad argument #3 (expected string, got " .. type( sBackgroundColor ) .. ")", 2 ) end
        if #sTextColor ~= #sText or #sBackgroundColor ~= #sText then
            error( "Arguments must be the same length", 2 )
        end
        internalBlit( sText, sTextColor, sBackgroundColor )
    end

    function window.clear()
        local sEmptyText = sEmptySpaceLine
        local sEmptyTextColor = tEmptyColorLines[ nTextColor ]
        local sEmptyBackgroundColor = tEmptyColorLines[ nBackgroundColor ]
        for y=1,nHeight do
            tLines[y] = {
                text = sEmptyText,
                textColor = sEmptyTextColor,
                backgroundColor = sEmptyBackgroundColor,
            }
        end
        if bVisible then
            redraw()
            updateCursorColor()
            updateCursorPos()
        end
    end

    function window.clearLine()
        if nCursorY >= 1 and nCursorY <= nHeight then
            local sEmptyText = sEmptySpaceLine
            local sEmptyTextColor = tEmptyColorLines[ nTextColor ]
            local sEmptyBackgroundColor = tEmptyColorLines[ nBackgroundColor ]
            tLines[ nCursorY ] = {
                text = sEmptyText,
                textColor = sEmptyTextColor,
                backgroundColor = sEmptyBackgroundColor,
            }
            if bVisible then
                redrawLine( nCursorY )
                updateCursorColor()
                updateCursorPos()
            end
        end
    end

    function window.getCursorPos()
        return nCursorX, nCursorY
    end

    function window.setCursorPos( x, y )
        if type( x ) ~= "number" then error( "bad argument #1 (expected number, got " .. type( x ) .. ")", 2 ) end
        if type( y ) ~= "number" then error( "bad argument #2 (expected number, got " .. type( y ) .. ")", 2 ) end
        nCursorX = math.floor( x )
        nCursorY = math.floor( y )
        if bVisible then
            updateCursorPos()
        end
    end

    function window.setCursorBlink( blink )
        if type( blink ) ~= "boolean" then error( "bad argument #1 (expected boolean, got " .. type( blink ) .. ")", 2 ) end
        bCursorBlink = blink
        if bVisible then
            updateCursorBlink()
        end
    end

    local function isColor()
        return parent.isColor()
    end

    function window.isColor()
        return isColor()
    end

    function window.isColour()
        return isColor()
    end

    local function setTextColor( color )
        if type( color ) ~= "number" then 
            error( "bad argument #1 (expected number, got " .. type( color ) .. ")", 2 )
        elseif tHex[color] == nil then
            error( "Invalid color", 2 )
        end
        nTextColor = color
        if bVisible then
            updateCursorColor()
        end
    end

    window.setTextColor = setTextColor
    window.setTextColour = setTextColor
	
	if term.setPaletteColor then

		function window.setPaletteColour( colour, r, g, b )
			if type( colour ) ~= "number" then error( "bad argument #1 (expected number, got " .. type( colour ) .. ")", 2 ) end
			
			local tCol
			if type(r) == "number" and g == nil and b == nil then
				tCol = { colours.rgb8( r ) }
				tPalette[ colour ] = tCol
			else
				if type( r ) ~= "number" then error( "bad argument #2 (expected number, got " .. type( r ) .. ")", 2 ) end
				if type( g ) ~= "number" then error( "bad argument #3 (expected number, got " .. type( g ) .. ")", 2 ) end
				if type( b ) ~= "number" then error( "bad argument #4 (expected number, got " .. type( b ) .. ")", 2 ) end
				
				tCol = tPalette[ colour ]
				tCol[1] = r
				tCol[2] = g
				tCol[3] = b
			end

			if bVisible then
				return parent.setPaletteColour( colour, tCol[1], tCol[2], tCol[3] )
			end
		end

		window.setPaletteColor = window.setPaletteColour
	end
	
	if term.getPaletteColor then
		function window.getPaletteColour( colour )
			local tCol = tPalette[ colour ]
			return tCol[1], tCol[2], tCol[3]
		end

		window.getPaletteColor = window.getPaletteColour
	end

    local function setBackgroundColor( color )
        if type( color ) ~= "number" then
            error( "bad argument #1 (expected number, got " .. type( color ) .. ")", 2 )
        elseif tHex[color] == nil then
            error( "Invalid color", 3 )
        end
        nBackgroundColor = color
    end

    window.setBackgroundColor = setBackgroundColor
    window.setBackgroundColour = setBackgroundColor

    function window.getSize()
        return nWidth, nHeight
    end
    
    function window.getShownSize()
        if minimized then
            return nWidth,0
        else
            return nWidth,nHeight
        end
    end
    
    function window.getFullSize()
        return nWidth,nHeight+1
    end
    

    function window.scroll( n )
        if type( n ) ~= "number" then error( "bad argument #1 (expected number, got " .. type( n ) .. ")", 2 ) end
        if n ~= 0 then
            local tNewLines = {}
            local sEmptyText = sEmptySpaceLine
            local sEmptyTextColor = tEmptyColorLines[ nTextColor ]
            local sEmptyBackgroundColor = tEmptyColorLines[ nBackgroundColor ]
            for newY=1,nHeight do
                local y = newY + n
                if y >= 1 and y <= nHeight then
                    tNewLines[newY] = tLines[y]
                else
                    tNewLines[newY] = {
                        text = sEmptyText,
                        textColor = sEmptyTextColor,
                        backgroundColor = sEmptyBackgroundColor,
                    }
                end
            end
            tLines = tNewLines
            if bVisible then
                redraw()
                updateCursorColor()
                updateCursorPos()
            end
        end
    end

    function window.getTextColor()
        return nTextColor
    end

    function window.getTextColour()
        return nTextColor
    end

    function window.getBackgroundColor()
        return nBackgroundColor
    end

    function window.getBackgroundColour()
        return nBackgroundColor
    end

    -- Other functions
    function window.setVisible( bVis )
        if type( bVis ) ~= "boolean" then error( "bad argument #1 (expected boolean, got " .. type( bVis ) .. ")", 2 ) end
        if bVisible ~= bVis then
            bVisible = bVis
            if bVisible then
                window.redraw()
            end
        end
    end

    function window.redraw()
        if bVisible then
            redraw()
            updatePalette()
            updateCursorBlink()
            updateCursorColor()
            updateCursorPos()
        end
    end

    function window.restoreCursor()
        if bVisible then
            updateCursorBlink()
            updateCursorColor()
            updateCursorPos()
        end
    end

    function window.getPosition()
        return nX, nY
    end

    function window.reposition( nNewX, nNewY, nNewWidth, nNewHeight )
        if type( nNewX ) ~= "number" then error( "bad argument #1 (expected number, got " .. type( nNewX ) .. ")", 2 ) end
        if type( nNewY ) ~= "number" then error( "bad argument #2 (expected number, got " .. type( nNewY ) .. ")", 2 ) end
        if type( nNewWidth ) ~= "number" then error( "bad argument #3 (expected number, got " .. type( nNewWidth ) .. ")", 2 ) end
        if type( nNewHeight ) ~= "number" then error( "bad argument #4 (expected number, got " .. type( nNewHeight ) .. ")", 2 ) end

        nX = nNewX
        nY = nNewY+1
        if nNewWidth and nNewHeight then
            nNewHeight = nNewHeight - 1
            local tNewLines = {}
            createEmptyLines( nNewWidth )
            local sEmptyText = sEmptySpaceLine
            local sEmptyTextColor = tEmptyColorLines[ nTextColor ]
            local sEmptyBackgroundColor = tEmptyColorLines[ nBackgroundColor ]
            for y=1,nNewHeight do
                if y > nHeight then
                    tNewLines[y] = {
                        text = sEmptyText,
                        textColor = sEmptyTextColor,
                        backgroundColor = sEmptyBackgroundColor
                    }
                else
                    local tOldLine = tLines[y]
                    if nNewWidth == nWidth then
                        tNewLines[y] = tOldLine
                    elseif nNewWidth < nWidth then
                        tNewLines[y] = {
                            text = string_sub( tOldLine.text, 1, nNewWidth ),
                            textColor = string_sub( tOldLine.textColor, 1, nNewWidth ),
                            backgroundColor = string_sub( tOldLine.backgroundColor, 1, nNewWidth ),
                        }
                    else
                        tNewLines[y] = {
                            text = tOldLine.text .. string_sub( sEmptyText, nWidth + 1, nNewWidth ),
                            textColor = tOldLine.textColor .. string_sub( sEmptyTextColor, nWidth + 1, nNewWidth ),
                            backgroundColor = tOldLine.backgroundColor .. string_sub( sEmptyBackgroundColor, nWidth + 1, nNewWidth ),
                        }
                    end
                end
            end
            nWidth = nNewWidth
            nHeight = nNewHeight
            tLines = tNewLines
        end
        if bVisible then
            window.redraw()
        end
    end

    if bVisible then
        window.redraw()
    end
    return window
end