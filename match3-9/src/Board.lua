--[[
    GD50
    Match-3 Remake

    -- Board Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    The Board is our arrangement of Tiles with which we must try to find matching
    sets of three horizontally or vertically.
]]

Board = Class{}

function Board:init(x, y, level)
    self.x = x
    self.y = y
    self.matches = {}
    self.level = level

    self:initializeTiles()
end

function Board:initializeTiles()
    self.tiles = {}

    for tileY = 1, 8 do
        
        -- empty table that will serve as a new row
        table.insert(self.tiles, {})
        local randshine = nil
        for tileX = 1, 8 do    
            -- create a new tile at X,Y with a random color and variety
            --table.insert(self.tiles[tileY], Tile(tileX, tileY, math.random(18), math.random(6)))
            randshine = math.random(15)
            --JCV - uses level passed in to determine which tiles to include in the board
            if self.level == 1 then
                if randshine == 1 then
                    table.insert(self.tiles[tileY], Tile(tileX, tileY, math.random(8), 1, true))
                else
                    table.insert(self.tiles[tileY], Tile(tileX, tileY, math.random(8), 1, false))     
                end
            elseif self.level == 2 then
                if randshine == 1 then                
                    table.insert(self.tiles[tileY], Tile(tileX, tileY, math.random(8), math.random(2),true))
                else           
                    table.insert(self.tiles[tileY], Tile(tileX, tileY, math.random(8), math.random(2),false))
                end
            elseif self.level == 3 then
                if randshine == 1 then
                    table.insert(self.tiles[tileY], Tile(tileX, tileY, math.random(8), math.random(3), true))
                else
                    table.insert(self.tiles[tileY], Tile(tileX, tileY, math.random(8), math.random(3), false))
                end
            elseif self.level == 4 then
                if randshine == 1 then
                    table.insert(self.tiles[tileY], Tile(tileX, tileY, math.random(8), math.random(4), true))
                else
                    table.insert(self.tiles[tileY], Tile(tileX, tileY, math.random(8), math.random(4), false))
                end
            elseif self.level == 5 then
                if randshine == 1 then
                    table.insert(self.tiles[tileY], Tile(tileX, tileY, math.random(8), math.random(5), true))
                else
                    table.insert(self.tiles[tileY], Tile(tileX, tileY, math.random(8), math.random(5), false))
                end
            else
                if randshine == 1 then
                    table.insert(self.tiles[tileY], Tile(tileX, tileY, math.random(8), math.random(6), true))
                else
                    table.insert(self.tiles[tileY], Tile(tileX, tileY, math.random(8), math.random(6), false))
                end
            end 
        end
    end

    while self:calculateMatches() do
        
        -- recursively initialize if matches were returned so we always have
        -- a matchless board on start
        self:initializeTiles()
    end

    while not self:potentialMatches() do
        
        -- recursively initialize if future matches do not exist so we always have
        -- a match potential board on start
        self:initializeTiles()
        gSounds['re-initialize']:play()
    end
end

--[[
    Goes left to right, top to bottom in the board, calculating matches by counting consecutive
    tiles of the same color. Doesn't need to check the last tile in every row or column if the 
    last two haven't been a match.
]]
function Board:calculateMatches()
    local matches = {}

    -- how many of the same color blocks in a row we've found
    local matchNum = 1

    -- horizontal matches first
    for y = 1, 8 do
        local colorToMatch = self.tiles[y][1].color

        matchNum = 1
        
        -- every horizontal tile
        for x = 2, 8 do
            
            -- if this is the same color as the one we're trying to match...
            if self.tiles[y][x].color == colorToMatch then
                matchNum = matchNum + 1
            else
                
                -- set this as the new color we want to watch for
                colorToMatch = self.tiles[y][x].color

                -- if we have a match of 3 or more up to now, add it to our matches table
                if matchNum >= 3 then
                    local match = {}

                    -- go backwards from here by matchNum
                    for x2 = x - 1, x - matchNum, -1 do
                        if self.tiles[y][x2].shiny == true then
                            -- JCV - insert entire row of tiles as match if shiny
                            for x = 1, 8, 1 do
                                table.insert(match, self.tiles[y][x])
                            end
                        else
                            -- add each tile to the match that's in that match
                            table.insert(match, self.tiles[y][x2])                            
                        end
                    end

                    -- add this match to our total matches table
                    table.insert(matches, match)
                end

                matchNum = 1

                -- don't need to check last two if they won't be in a match
                if x >= 7 then
                    break
                end
            end
        end

        -- account for the last row ending with a match
        if matchNum >= 3 then
            local match = {}

            -- go backwards from here by matchNum
            for x = 8, 8 - matchNum + 1, -1 do
                if self.tiles[y][x].shiny == true then
                    -- JCV - insert entire row of tiles as match if shiny
                    for x2 = 1, 8, 1 do
                        table.insert(match, self.tiles[y][x2])
                    end
                else
                    -- add each tile to the match that's in that match
                    table.insert(match, self.tiles[y][x])                            
                end
            end            

            table.insert(matches, match)
        end
    end

    -- vertical matches
    for x = 1, 8 do
        local colorToMatch = self.tiles[1][x].color

        matchNum = 1

        -- every vertical tile
        for y = 2, 8 do
            if self.tiles[y][x].color == colorToMatch then
                matchNum = matchNum + 1
            else
                colorToMatch = self.tiles[y][x].color

                if matchNum >= 3 then
                    local match = {}

                    for y2 = y - 1, y - matchNum, -1 do
                        table.insert(match, self.tiles[y2][x])
                    end

                    -- go backwards from here by matchNum
                    for y2 = y - 1, y - matchNum, -1 do
                        if self.tiles[y2][x].shiny == true then
                            -- JCV - insert entire row of tiles as match if shiny
                            for y3 = 1, 8, 1 do
                                table.insert(match, self.tiles[y3][x])
                            end
                        else
                            -- add each tile to the match that's in that match
                            table.insert(match, self.tiles[y2][x])                            
                        end
                    end


                    table.insert(matches, match)
                end

                matchNum = 1

                -- don't need to check last two if they won't be in a match
                if y >= 7 then
                    break
                end
            end
        end

        -- account for the last column ending with a match
        if matchNum >= 3 then
            local match = {}

            -- go backwards from here by matchNum
            for y = 8, 8 - matchNum + 1, -1 do
                if self.tiles[y][x].shiny == true then
                    -- JCV - insert entire row of tiles as match if shiny
                    for y3 = 1, 8, 1 do
                        table.insert(match, self.tiles[y3][x])
                    end
                else
                    -- add each tile to the match that's in that match
                    table.insert(match, self.tiles[y][x])                            
                end
            end

            table.insert(matches, match)
        end
    end

    -- store matches for later reference
    self.matches = matches

    -- return matches table if > 0, else just return false
    return #self.matches > 0 and self.matches or false
end

--[[
    Remove the matches from the Board by just setting the Tile slots within
    them to nil, then setting self.matches to nil.
]]
function Board:removeMatches()
    for k, match in pairs(self.matches) do
        for k, tile in pairs(match) do
            self.tiles[tile.gridY][tile.gridX] = nil
        end
    end

    self.matches = nil
end

--[[
    Shifts down all of the tiles that now have spaces below them, then returns a table that
    contains tweening information for these new tiles.
]]
function Board:getFallingTiles()
    -- tween table, with tiles as keys and their x and y as the to values
    local tweens = {}

    -- for each column, go up tile by tile till we hit a space
    for x = 1, 8 do
        local space = false
        local spaceY = 0

        local y = 8
        while y >= 1 do
            
            -- if our last tile was a space...
            local tile = self.tiles[y][x]
            
            if space then
                
                -- if the current tile is *not* a space, bring this down to the lowest space
                if tile then
                    
                    -- put the tile in the correct spot in the board and fix its grid positions
                    self.tiles[spaceY][x] = tile
                    tile.gridY = spaceY

                    -- set its prior position to nil
                    self.tiles[y][x] = nil

                    -- tween the Y position to 32 x its grid position
                    tweens[tile] = {
                        y = (tile.gridY - 1) * 32
                    }

                    -- set Y to spaceY so we start back from here again
                    space = false
                    y = spaceY

                    -- set this back to 0 so we know we don't have an active space
                    spaceY = 0
                end
            elseif tile == nil then
                space = true
                
                -- if we haven't assigned a space yet, set this to it
                if spaceY == 0 then
                    spaceY = y
                end
            end

            y = y - 1
        end
    end

    -- create replacement tiles at the top of the screen
    for x = 1, 8 do
        for y = 8, 1, -1 do
            local tile = self.tiles[y][x]

            -- if the tile is nil, we need to add a new one
            if not tile then

                -- new tile with random color and variety
                --local tile = Tile(x, y, math.random(18), math.random(6))

                --JCV - uses level passed in to determine which tiles to include in the board
                local tile = nil

                if self.level == 1 then
                    tile = Tile(x, y, math.random(18), 1) 
                elseif self.level == 2 then
                    tile = Tile(x, y, math.random(18), math.random(2))
                elseif self.level == 3 then
                    tile = Tile(x, y, math.random(18), math.random(3))
                elseif self.level == 4 then
                    tile = Tile(x, y, math.random(18), math.random(4))
                elseif self.level == 5 then
                    tile = Tile(x, y, math.random(18), math.random(5))
                else
                    tile = Tile(x, y, math.random(18), math.random(6))
                end


                tile.y = -32
                self.tiles[y][x] = tile

                -- create a new tween to return for this tile to fall down
                tweens[tile] = {
                    y = (tile.gridY - 1) * 32
                }
            end
        end
    end

    return tweens
end

function Board:potentialMatches()
    local potMatches = 0

    local tile1 = self.tiles[2][2]
    local tile2 = self.tiles[2][2]
    for y = 2, 7 do
        for x = 2, 7 do
            tile1 = self.tiles[y][x]
            tile2 = self.tiles[y][x+1]
            if self:pretendSwap(tile1, tile2) then 
                potMatches = potMatches + 1
            end
            tile2 = self.tiles[y][x-1]
            if self:pretendSwap(tile1, tile2) then 
                potMatches = potMatches + 1
            end
            tile2 = self.tiles[y+1][x]
            if self:pretendSwap(tile1, tile2) then 
                potMatches = potMatches + 1
            end 
            tile2 = self.tiles[y-1][x]
            if self:pretendSwap(tile1, tile2) then 
                potMatches = potMatches + 1
            end                           
        end
    end

    return potMatches > 0 and true or false
    --if potMatches == 0 then
    --    self:initializeTiles()
    --    gSounds['re-initialize']:play()
    --    self:potentialMatches()
    --end
end

function Board:pretendSwap(tile1, tile2)
    local potentialMatches = 0

    -- swap grid positions of tiles
    local newTile1 = tile1
    local newTile2 = tile2

    local tempX = newTile1.gridX
    local tempY = newTile1.gridY

    newTile1.gridX = newTile2.gridX
    newTile1.gridY = newTile2.gridY
    
    newTile2.gridX = tempX
    newTile2.gridY = tempY

    -- swap tiles in the tiles table
    self.tiles[newTile1.gridY][newTile1.gridX] =
        newTile1

    self.tiles[newTile2.gridY][newTile2.gridX] = newTile2

    if self:calculateMatches() then
        potentialMatches = potentialMatches + 1
    end                   
                    
    --JCV - revert grid positions of tiles

    tempX = newTile1.gridX
    tempY = newTile1.gridY

    newTile1.gridX = newTile2.gridX
    newTile1.gridY = newTile2.gridY
    
    newTile2.gridX = tempX
    newTile2.gridY = tempY

    --JCV - revert tiles in the tiles table
    self.tiles[newTile1.gridY][newTile1.gridX] =
        newTile1

    self.tiles[newTile2.gridY][newTile2.gridX] = newTile2   

    -- return true if potential matches count > 0, else return false
    return potentialMatches > 0 and true or false
end

function Board:render()
    for y = 1, #self.tiles do
        for x = 1, #self.tiles[1] do
            self.tiles[y][x]:render(self.x, self.y)
        end
    end
end