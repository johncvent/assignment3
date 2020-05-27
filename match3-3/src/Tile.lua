--[[
    GD50
    Match-3 Remake

    -- Tile Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    The individual tiles that make up our game board. Each Tile can have a
    color and a variety, with the varietes adding extra points to the matches.
]]

Tile = Class{}

function Tile:init(x, y, color, variety, shiny)
    
    -- board positions
    self.gridX = x
    self.gridY = y

    -- coordinate positions
    self.x = (self.gridX - 1) * 32
    self.y = (self.gridY - 1) * 32

    -- tile appearance/points
    self.color = color
    self.variety = variety

    -- JCV - shiny tile flag (destroys entire row)
    self.shiny = shiny

    self.addshine = 1
    Timer.every(.5, function()
        self.addshine = self.addshine + 1
    end)
end

function Tile:render(x, y)
    
    -- draw shadow
    if self.shiny == false then
        love.graphics.setColor(34, 32, 52, 0)
        love.graphics.draw(gTextures['main'], gFrames['tiles'][self.color][self.variety],
            self.x + x + 2, self.y + y + 2)
    else
        love.graphics.setColor(34, 32, 52, 0)
        love.graphics.draw(gTextures['main'], gFrames['tiles'][self.color][self.variety],
            self.x + x + 2, self.y + y + 2)
    end

    -- draw tile itself
    love.graphics.setColor(255, 255, 255, 255)
    love.graphics.draw(gTextures['main'], gFrames['tiles'][self.color][self.variety],
        self.x + x, self.y + y)

    if self.shiny == true then
        if self.addshine % 4 == 0 then
            love.graphics.setColor(255, 255, 255, 60)
            love.graphics.rectangle('fill', self.x + x + 23, self.y + y + 23, 3, 3)
        else
            love.graphics.setColor(255, 255, 255, 80)
            love.graphics.rectangle('fill', self.x + x + 23, self.y + y + 23, 3, 3)
        end
    end
end