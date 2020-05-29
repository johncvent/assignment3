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

    -- JCV - Create an object to hold opacity
    self.overlay = { opacity = 0}

    -- JCV - Create a set of tweens.
    -- JCV - This tween completes every 3 seconds.
    Timer.every(3, function()
        Timer.tween(.5, {
            -- Meanwhile, overlay fades in as color changes from black to red
            [self.overlay] = { opacity = 60},
        })
        :finish(function()
            Timer.tween(.5, {
                -- Meanwhile, overlay fades in as color changes from black to red
                [self.overlay] = { opacity = 0},
            })
        end)
    end)
end

function Tile:render(x, y)
    
    -- draw shadow
        love.graphics.setColor(34, 32, 52, 0)
        love.graphics.draw(gTextures['main'], gFrames['tiles'][self.color][self.variety],
            self.x + x + 2, self.y + y + 2)

    -- draw tile itself
    love.graphics.setColor(255, 255, 255, 255)
    love.graphics.draw(gTextures['main'], gFrames['tiles'][self.color][self.variety],
        self.x + x, self.y + y)

    if self.shiny == true then
            love.graphics.setColor(255, 255, 255, self.overlay.opacity)
            love.graphics.rectangle('fill', self.x + x, self.y + y, 32, 32, 6)
    end
end