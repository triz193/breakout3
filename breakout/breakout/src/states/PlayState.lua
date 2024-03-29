--[[GD50
Breakout Remake

-- PlayState Class --

Author: Colton Ogden
cogden@cs50.harvard.edu

Represents the state of the game in which we are actively playing;
player should control the paddle, with the ball actively bouncing between
the bricks, walls, and the paddle. If the ball goes below the paddle, then
the player should lose one point of health and be taken either to the Game
Over screen if at 0 health or the Serve screen otherwise.
]]


PlayState = Class{__includes = BaseState}

--[[
We initialize what's in our PlayState via a state table that we pass between
states as we go from playing to serving.
]]


function PlayState:enter(params)
self.paddle = params.paddle
self.bricks = params.bricks
self.health = params.health
self.score = params.score
self.highScores = params.highScores
self.ball = params.ball
self.level = params.level

self.recoverPoints = 5000

-- spawning the extra balls powerup
self.powerup = nil
self.powerupSpawnTimer = 0
-- powerup every 5 to 30 seconds
self.powerupSpawnInterval = math.random(2, 5)

-- spawining the key powerup
self.keypowerup = nil
self.keySpawnTimer = 0
self.keySpawnInterval = math.random(2, 5)


-- initialize the main ball
self.balls = {self.ball}

-- give ball random starting velocity
self.balls[1].dx = math.random(-200, 200)
self.balls[1].dy = math.random(-50, -60)    

end


function PlayState:update(dt)
    -- Checking if we should spawn a power-up
    self.powerupSpawnTimer = self.powerupSpawnTimer + dt
    if self.powerupSpawnTimer > self.powerupSpawnInterval then
        -- Spawn a power-up and reset the timer
        self.powerup = Powerup(gTextures['main'])
        self.powerupSpawnTimer = 0
    end

    -- Checking for powerup collision with the paddle
    
    if self.powerup then 
        if self.powerup:collides(self.paddle) then
            -- Spawn extra balls
            local randomSkin = math.random(1, 4)

            local newBalls = {}
            for i = 1, 2 do
                local newBall = Ball(randomSkin)
                newBall.x = self.paddle.x + self.paddle.width / 2 - newBall.width / 2
                newBall.y = self.paddle.y - newBall.height
                newBall.dx = math.random(-200, 200)
                newBall.dy = math.random(-50, -60)
                table.insert(newBalls, newBall)
            end

            -- Insert the new balls into the list of balls
            for _, newBall in pairs(newBalls) do
                table.insert(self.balls, newBall)
            end

            -- Removing the power-up
            self.powerup = nil

        else
            -- Update power-up position and check if it goes below the screen
            self.powerup:update(dt)

            if self.powerup.y > VIRTUAL_HEIGHT then
                -- Remove the power-up if it goes below the screen
                self.powerup = nil
            end
        
        end

    end

    if self.powerup then
        self.powerup:update(dt)
    end

    if self.keypowerup then 
        if self.keypowerup:collides(self.paddle) then
           
            -- TODO: Change to mode that lets the ball hit the locked bricks

            -- TODO: reset after some time

            -- Removing the power-up
            self.keypowerup = nil

        else
            -- Update power-up position and check if it goes below the screen
            self.keypowerup:update(dt)

            if self.keypowerup.y > VIRTUAL_HEIGHT then
                -- Remove the power-up if it goes below the screen
                self.keypowerup = nil
            end
        
        end

    end


    -- Checking if we should spawn a key
    self.keySpawnTimer = self.keySpawnTimer + dt
    if self.keySpawnTimer > self.keySpawnInterval then
        -- Spawn a power-up and reset the timer
        self.keypowerup = KeyPowerup(gTextures['main'])
        self.keySpawnTimer = 0
    end

    if self.keypowerup then
        self.keypowerup:update(dt)
    end

    -- Update positions based on velocity for all balls
    for _, ball in pairs(self.balls) do
        ball:update(dt)

        -- Checking for collision with the paddle for each ball
        if ball:collides(self.paddle) then
            -- raising ball above paddle in case it goes below it, then reverse dy
            ball.y = self.paddle.y - 8
            ball.dy = -ball.dy
        end
    end

    if self.paused then
        if love.keyboard.wasPressed('space') then
            self.paused = false
            gSounds['pause']:play()
        else
            return
        end
    elseif love.keyboard.wasPressed('space') then
        self.paused = true
        gSounds['pause']:play()
        return
    end

    -- update positions based on velocity
    self.paddle:update(dt)

    -- Detect collision across all bricks with each ball
    for _, ball in pairs(self.balls) do
        for k, brick in pairs(self.bricks) do
            -- Only check collision if the brick is in play
            if brick.inPlay and ball:collides(brick) then

                for _, ball in pairs(self.balls) do
                    for k, brick in pairs(self.bricks) do
                        if not brick:isLockedBrick() and brick.inPlay and ball:collides(brick) then
                            -- Handle collision with regular brick
                            brick:hit()

                            -- Additional logic for regular bricks
                        elseif brick:isLockedBrick() and brick.inPlay and ball:collides(brick) then
                            lockedbrick:hit()
                        end
                    end
                end
                
                -- Add to score
                self.score = self.score + (brick.tier * 200 + brick.color * 25)

            
                -- If we have enough points, recover a point of health
                if self.score > self.recoverPoints then
                    -- Can't go above 3 health
                    self.health = math.min(3, self.health + 1)

                    -- Multiply recover points by 2
                    self.recoverPoints = self.recoverPoints + math.min(100000, self.recoverPoints * 2)

                    -- Change paddle size to larger (not above 4)
                    self.paddle.size = math.min(4, self.paddle.size + 1)
                    
                    -- Update paddle width based on the new size
                    self.paddle:updateWidth()

                    -- Play recover sound effect
                    gSounds['recover']:play()
                end
                
                -- go to our victory screen if there are no more bricks left
                if self:checkVictory() then
                    gSounds['victory']:play()

                    gStateMachine:change('victory', {
                        level = self.level,
                        paddle = self.paddle,
                        health = self.health,
                        score = self.score,
                        highScores = self.highScores,
                        ball = self.balls,  -- Pass all balls to the victory state
                        recoverPoints = self.recoverPoints
                    })
                end

                -- collision code for bricks
                --
                -- we check to see if the opposite side of our velocity is outside of the brick;
                -- if it is, we trigger a collision on that side. else we're within the X + width of
                -- the brick and should check to see if the top or bottom edge is outside of the brick,
                -- colliding on the top or bottom accordingly 
                --

                -- left edge; only check if we're moving right, and offset the check by a couple of pixels
                -- so that flush corner hits register as Y flips, not X flips
                if ball.x + 2 < brick.x and ball.dx > 0 then
                    
                    -- flip x velocity and reset position outside of brick
                    ball.dx = -ball.dx
                    ball.x = brick.x - 8
                
                -- right edge; only check if we're moving left, , and offset the check by a couple of pixels
                -- so that flush corner hits register as Y flips, not X flips
                elseif ball.x + 6 > brick.x + brick.width and ball.dx < 0 then
                    
                    -- flip x velocity and reset position outside of brick
                    ball.dx = -ball.dx
                    ball.x = brick.x + 32
                
                -- top edge if no X collisions, always check
                elseif ball.y < brick.y then
                    
                    -- flip y velocity and reset position outside of brick
                    ball.dy = -ball.dy
                    ball.y = brick.y - 8
                
                -- bottom edge if no X collisions or top collision, last possibility
                else
                    
                    -- flip y velocity and reset position outside of brick
                    ball.dy = -ball.dy
                    ball.y = brick.y + 16
                end

                -- slightly scale the y velocity to speed up the game, capping at +- 150
                if math.abs(ball.dy) < 150 then
                    ball.dy = ball.dy * 1.02
                end

                -- only allow colliding with one brick, for corners
                break
                end

        end

       
    end


    -- if (all) ball(s) go(es) below bounds, revert to serve state and decrease health
    local allBallsBelowBounds = true
    for _, ball in pairs(self.balls) do
        if ball.y < VIRTUAL_HEIGHT then
            allBallsBelowBounds = false
            break
        end
    end

    if allBallsBelowBounds then
        self.health = self.health - 1

        gSounds['hurt']:play()
    
        -- change paddle size (not below 1)
        self.paddle.size = math.max(1, self.paddle.size - 1)
        
        -- Update paddle width based on the new size
        self.paddle:updateWidth()


        if self.health == 0 then
            gStateMachine:change('game-over', {
                score = self.score,
                highScores = self.highScores
            })
        else
            gStateMachine:change('serve', {
                paddle = self.paddle,
                bricks = self.bricks,
                health = self.health,
                score = self.score,
                highScores = self.highScores,
                level = self.level,
                recoverPoints = self.recoverPoints
            })
        end
    end

    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end

    for k, brick in pairs(self.bricks) do
        brick:update(dt)
    end

   
end

function PlayState:render()

    for k, brick in pairs(self.bricks) do
        if not brick:isLockedBrick() then
            brick:renderParticles()
            brick:render()
        else
            brick:render()
        end
    end

    -- Update and render the power-up if it exists
    if self.powerup then
        self.powerup:render()
    end

    if self.keypowerup then
        self.keypowerup:render()
    end

    -- Render the extra balls for the powerup
    for _, ball in pairs(self.balls) do
        ball:render()
    end

    self.paddle:render()

    renderScore(self.score)
    renderHealth(self.health)

    -- pause text, if paused
    if self.paused then
        love.graphics.setFont(gFonts['large'])
        love.graphics.printf("PAUSED", 0, VIRTUAL_HEIGHT / 2 - 16, VIRTUAL_WIDTH, 'center')
    end
end

function PlayState:checkVictory()
    for k, brick in pairs(self.bricks) do
        if brick.inPlay and (not brick:isLockedBrick() or brick:isLockedBrick()) then
            return false
        end 
    end
    
return true
end