-- LockedBrick.lua
LockedBrick = Class{}

function LockedBrick:init(x, y, image, quads)
    self.image = image
    self.quads = quads
    self.x = x
    self.y = y
    self.width = 32
    self.height = 16
end

function LockedBrick:hit()
    if paddle:hasKeyPowerUp() then
            self:destroy()
    else
        ball.dy = -ball.dy
        ball.dx = -ball.dx
    end
    
end

function LockedBrick:destroy()
    -- Perform actions to make the locked brick disappear or handle its destruction
    -- For example, set a flag to mark it for removal from the bricks list
    self.inPlay = false
end

function LockedBrick:update(dt)
end

function LockedBrick:render()
    love.graphics.draw(self.image, gFrames['lockedbrick'][1], self.x, self.y)
end

function LockedBrick:renderParticles()
    love.graphics.draw(self.psystem, self.x + 16, self.y + 8)
end

function LockedBrick:isLockedBrick()
    return true
end

