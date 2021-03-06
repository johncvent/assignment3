--[[
    GD50
    Match-3 Remake

    -- PlayState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    State in which we can actually play, moving around a grid cursor that
    can swap two tiles; when two tiles make a legal swap (a swap that results
    in a valid match), perform the swap and destroy all matched tiles, adding
    their values to the player's point score. The player can continue playing
    until they exceed the number of points needed to get to the next level
    or until the time runs out, at which point they are brought back to the
    main menu or the score entry menu if they made the top 10.
]]

PlayState = Class{__includes = BaseState}

function PlayState:init()
    
    -- start our transition alpha at full, so we fade in
    self.transitionAlpha = 255

    -- position in the grid which we're highlighting
    self.boardHighlightX = 0
    self.boardHighlightY = 0

    -- timer used to switch the highlight rect's color
    self.rectHighlighted = false

    -- flag to show whether we're able to process input (not swapping or clearing)
    self.canInput = true

    -- tile we're currently highlighting (preparing to swap)
    self.highlightedTile = nil

    self.score = 0
    self.timer = 60

    -- set our Timer class to turn cursor highlight on and off
    Timer.every(0.5, function()
        self.rectHighlighted = not self.rectHighlighted
    end)

    -- subtract 1 from timer every second
    Timer.every(1, function()
        self.timer = self.timer - 1

        -- play warning sound on timer if we get low
        if self.timer <= 5 then
            gSounds['clock']:play()
        end
    end)

    self.gridcoords = {}
end

function PlayState:enter(params)
    
    -- grab level # from the params we're passed
    self.level = params.level

    -- spawn a board and place it toward the right
    --self.board = params.board or Board(VIRTUAL_WIDTH - 272, 16,self.level)
    
    --JCV - only spawn boards in the BeginGameState
    self.board = params.board

    -- grab score from params if it was passed
    self.score = params.score or 0

    -- score we have to reach to get to the next level
    self.scoreGoal = self.level * 1.25 * 1000

    for tileY = 1, 8 do
        -- empty table that will serve as a new row
        table.insert(self.gridcoords, {})
        for tileX = 1, 8 do    
            table.insert(self.gridcoords[tileY], {x = 240.3+(tileX-1)*32, y = 16.8+(tileY-1)*32})
        end
    end
end

function PlayState:update(dt)
    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end

    -- go back to start if time runs out
    if self.timer <= 0 then
        
        -- clear timers from prior PlayStates
        Timer.clear()
        
        gSounds['game-over']:play()

        gStateMachine:change('game-over', {
            score = self.score
        })
    end

    -- go to next level if we surpass score goal
    if self.score >= self.scoreGoal then
        
        -- clear timers from prior PlayStates
        -- always clear before you change state, else next state's timers
        -- will also clear!
        Timer.clear()

        gSounds['next-level']:play()

        -- change to begin game state with new level (incremented)
        gStateMachine:change('begin-game', {
            level = self.level + 1,
            score = self.score
        })
    end

    if self.canInput then
        -- move cursor around based on bounds of grid, playing sounds
        if love.keyboard.wasPressed('up') then
            self.boardHighlightY = math.max(0, self.boardHighlightY - 1)
            gSounds['select']:play()
        elseif love.keyboard.wasPressed('down') then
            self.boardHighlightY = math.min(7, self.boardHighlightY + 1)
            gSounds['select']:play()
        elseif love.keyboard.wasPressed('left') then
            self.boardHighlightX = math.max(0, self.boardHighlightX - 1)
            gSounds['select']:play()
        elseif love.keyboard.wasPressed('right') then
            self.boardHighlightX = math.min(7, self.boardHighlightX + 1)
            gSounds['select']:play()
        end

        -- if we've pressed enter, to select or deselect a tile...
        if love.keyboard.wasPressed('enter') or love.keyboard.wasPressed('return') then
            
            -- if same tile as currently highlighted, deselect
            local x = self.boardHighlightX + 1
            local y = self.boardHighlightY + 1
            
            -- if nothing is highlighted, highlight current tile
            if not self.highlightedTile then
                self.highlightedTile = self.board.tiles[y][x]

            -- if we select the position already highlighted, remove highlight
            elseif self.highlightedTile == self.board.tiles[y][x] then
                self.highlightedTile = nil

            -- if the difference between X and Y combined of this highlighted tile
            -- vs the previous is not equal to 1, also remove highlight
            elseif math.abs(self.highlightedTile.gridX - x) + math.abs(self.highlightedTile.gridY - y) > 1 then
                gSounds['error']:play()
                self.highlightedTile = nil
            else
                
                -- swap grid positions of tiles
                local tempX = self.highlightedTile.gridX
                local tempY = self.highlightedTile.gridY

                local newTile = self.board.tiles[y][x]

                self.highlightedTile.gridX = newTile.gridX
                self.highlightedTile.gridY = newTile.gridY
                newTile.gridX = tempX
                newTile.gridY = tempY

                -- swap tiles in the tiles table
                self.board.tiles[self.highlightedTile.gridY][self.highlightedTile.gridX] =
                    self.highlightedTile

                self.board.tiles[newTile.gridY][newTile.gridX] = newTile

                if self.board:calculateMatches() then

                    -- tween coordinates between the two so they swap
                    --JCV - change canInput to false to stop movement while tiles swap and drop
                    self.canInput = false
                    Timer.tween(.1, {
                        [self.highlightedTile] = {x = newTile.x, y = newTile.y},
                        [newTile] = {x = self.highlightedTile.x, y = self.highlightedTile.y}
                    })
                    
                    -- once the swap is finished, we can tween falling blocks as needed
                    :finish(function()
                        self:calculateMatches()
                    end)
                else                   
                    
                    --JCV - revert grid positions of tiles
                    tempX = self.highlightedTile.gridX
                    tempY = self.highlightedTile.gridY

                    self.highlightedTile.gridX = newTile.gridX
                    self.highlightedTile.gridY = newTile.gridY

                    newTile.gridX = tempX
                    newTile.gridY = tempY

                    --JCV - revert tiles in the tiles table
                    self.board.tiles[self.highlightedTile.gridY][self.highlightedTile.gridX] =
                        self.highlightedTile

                    self.board.tiles[newTile.gridY][newTile.gridX] = newTile  

                    --JCV - play error sound and unhighlight the tile                    
                    gSounds['error']:play()
                    self.highlightedTile = nil                 
                end
            end
        end

        -- if we've clicked the mouse, to select or deselect a tile...
        if love.mouse.wasPressed(1) then
            --local i = #love.mouse.buttonsPressed
            local i = 1
            local foundX = 0
            local foundY = 0 
            for x = 1, 7 do
                if (love.mouse.buttonsPressed[i].x > self.gridcoords[1][x].x) and 
                    (love.mouse.buttonsPressed[i].x < self.gridcoords[1][x+1].x) then
                    self.boardHighlightX = x-1
                    foundX = 1   
                end
            end
            if foundX == 0 then
                self.boardHighlightX = 7
            end
            for y = 1, 7 do
                if (love.mouse.buttonsPressed[i].y > self.gridcoords[y][1].y) and 
                    (love.mouse.buttonsPressed[i].y < self.gridcoords[y+1][1].y) then
                    self.boardHighlightY = y-1
                    foundY = 1  
                end
            end 
            if foundY == 0 then
                self.boardHighlightY = 7
            end                               
            -- if same tile as currently highlighted, deselect
            local x = self.boardHighlightX + 1
            local y = self.boardHighlightY + 1

            -- if nothing is highlighted, highlight current tile
            if not self.highlightedTile then
                self.highlightedTile = self.board.tiles[y][x]

            -- if we select the position already highlighted, remove highlight
            elseif self.highlightedTile == self.board.tiles[y][x] then
                self.highlightedTile = nil

            -- if the difference between X and Y combined of this highlighted tile
            -- vs the previous is not equal to 1, also remove highlight
            elseif math.abs(self.highlightedTile.gridX - x) + math.abs(self.highlightedTile.gridY - y) > 1 then
                gSounds['error']:play()
                self.highlightedTile = nil
            else
                    
                -- swap grid positions of tiles
                local tempX = self.highlightedTile.gridX
                local tempY = self.highlightedTile.gridY

                local newTile = self.board.tiles[y][x]

                self.highlightedTile.gridX = newTile.gridX
                self.highlightedTile.gridY = newTile.gridY
                newTile.gridX = tempX
                newTile.gridY = tempY

                -- swap tiles in the tiles table
                self.board.tiles[self.highlightedTile.gridY][self.highlightedTile.gridX] =
                    self.highlightedTile

                self.board.tiles[newTile.gridY][newTile.gridX] = newTile

                if self.board:calculateMatches() then

                    -- tween coordinates between the two so they swap
                    --JCV - change canInput to false to stop movement while tiles swap and drop
                    self.canInput = false
                    Timer.tween(.1, {
                        [self.highlightedTile] = {x = newTile.x, y = newTile.y},
                        [newTile] = {x = self.highlightedTile.x, y = self.highlightedTile.y}
                    })
                        
                    -- once the swap is finished, we can tween falling blocks as needed
                    :finish(function()
                        self:calculateMatches()
                    end)
                else                   
                        
                    --JCV - revert grid positions of tiles
                    tempX = self.highlightedTile.gridX
                    tempY = self.highlightedTile.gridY

                    self.highlightedTile.gridX = newTile.gridX
                    self.highlightedTile.gridY = newTile.gridY

                    newTile.gridX = tempX
                    newTile.gridY = tempY

                    --JCV - revert tiles in the tiles table
                    self.board.tiles[self.highlightedTile.gridY][self.highlightedTile.gridX] =
                        self.highlightedTile

                    self.board.tiles[newTile.gridY][newTile.gridX] = newTile  

                    --JCV - play error sound and unhighlight the tile                    
                    gSounds['error']:play()
                    self.highlightedTile = nil                 
                end
            end
        end
    end
    
    Timer.update(dt)
end

--[[
    Calculates whether any matches were found on the board and tweens the needed
    tiles to their new destinations if so. Also removes tiles from the board that
    have matched and replaces them with new randomized tiles, deferring most of this
    to the Board class.
]]
function PlayState:calculateMatches()
    --JCV - change canInput to false to stop movement while tiles swap
    --self.canInput = false
    self.highlightedTile = nil

    -- if we have any matches, remove them and tween the falling blocks that result
    local matches = self.board:calculateMatches()
    
    if matches then
        gSounds['match']:stop()
        gSounds['match']:play()

        -- add score for each match
        --JCV - modify score to add 100 points for variety other than 1
        for k, match in pairs(matches) do
            for i, tile in pairs(match) do
                if tile.variety==1 then
                    self.score = self.score + 50
                elseif tile.variety==2 then
                    self.score = self.score + 100                
                elseif tile.variety==3 then
                    self.score = self.score + 150  
                elseif tile.variety==4 then
                    self.score = self.score + 200
                elseif tile.variety==5 then
                    self.score = self.score + 250 
                else
                    self.score = self.score + 300                   
                end
            end
            --JCV - increase the time by 1 second for each matching tile
            self.timer = self.timer + (1 * #match)
        end

        -- remove any tiles that matched from the board, making empty spaces
        self.board:removeMatches()

        -- gets a table with tween values for tiles that should now fall
        local tilesToFall = self.board:getFallingTiles()

        -- tween new tiles that spawn from the ceiling over 0.25s to fill in
        -- the new upper gaps that exist
        Timer.tween(.25, tilesToFall):finish(function()
            
            -- recursively call function in case new matches have been created
            -- as a result of falling blocks once new blocks have finished falling
            self:calculateMatches()
            while not self.board:potentialMatches() do
                -- recursively initialize if future matches do not exist so we always have
                -- a match potential board on start
                self.board:initializeTiles()
                gSounds['re-initialize']:play()
            end
        end)
    
    -- if no matches, we can continue playing
    else
        self.canInput = true
    end
end
--[[
function PlayState:potentialMatches()
    local potMatches = 0

    local tile1 = self.board.tiles[2][2]
    local tile2 = self.board.tiles[2][2]
    for y = 2, 7 do
        for x = 2, 7 do
            tile1 = self.board.tiles[y][x]
            tile2 = self.board.tiles[y][x+1]
            if self:pretendSwap(tile1, tile2) then 
                potMatches = potMatches + 1
            end
            tile2 = self.board.tiles[y][x-1]
            if self:pretendSwap(tile1, tile2) then 
                potMatches = potMatches + 1
            end
            tile2 = self.board.tiles[y+1][x]
            if self:pretendSwap(tile1, tile2) then 
                potMatches = potMatches + 1
            end 
            tile2 = self.board.tiles[y-1][x]
            if self:pretendSwap(tile1, tile2) then 
                potMatches = potMatches + 1
            end                           
        end
    end

    if potMatches == 0 then
        self.board:initializeTiles()
        gSounds['re-initialize']:play()
        self:potentialMatches()
    end
end

function PlayState:pretendSwap(tile1, tile2)
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
    self.board.tiles[newTile1.gridY][newTile1.gridX] =
        newTile1

    self.board.tiles[newTile2.gridY][newTile2.gridX] = newTile2

    if self.board:calculateMatches() then
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
    self.board.tiles[newTile1.gridY][newTile1.gridX] =
        newTile1

    self.board.tiles[newTile2.gridY][newTile2.gridX] = newTile2   

    -- return true if potential matches count > 0, else return false
    return potentialMatches > 0 and true or false
end
---]]
function PlayState:render()
    -- render board of tiles
    self.board:render()

    -- render highlighted tile if it exists
    if self.highlightedTile then
        
        -- multiply so drawing white rect makes it brighter
        love.graphics.setBlendMode('add')

        love.graphics.setColor(255, 255, 255, 96)
        love.graphics.rectangle('fill', (self.highlightedTile.gridX - 1) * 32 + (VIRTUAL_WIDTH - 272),
            (self.highlightedTile.gridY - 1) * 32 + 16, 32, 32, 4)

        -- back to alpha
        love.graphics.setBlendMode('alpha')
    end

    -- render highlight rect color based on timer
    if self.rectHighlighted then
        love.graphics.setColor(217, 87, 99, 255)
    else
        love.graphics.setColor(172, 50, 50, 255)
    end

    -- draw actual cursor rect
    love.graphics.setLineWidth(4)
    love.graphics.rectangle('line', self.boardHighlightX * 32 + (VIRTUAL_WIDTH - 272),
        self.boardHighlightY * 32 + 16, 32, 32, 4)

    -- GUI text
    love.graphics.setColor(56, 56, 56, 234)
    love.graphics.rectangle('fill', 16, 16, 186, 116, 4)

    love.graphics.setColor(99, 155, 255, 255)
    love.graphics.setFont(gFonts['medium'])
    love.graphics.printf('Level: ' .. tostring(self.level), 20, 24, 182, 'center')
    love.graphics.printf('Score: ' .. tostring(self.score), 20, 52, 182, 'center')
    love.graphics.printf('Goal : ' .. tostring(self.scoreGoal), 20, 80, 182, 'center')
    love.graphics.printf('Timer: ' .. tostring(self.timer), 20, 108, 182, 'center')
end