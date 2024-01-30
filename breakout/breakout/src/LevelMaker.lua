--[[
    GD50
    Breakout Remake

    -- LevelMaker Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Creates randomized levels for our Breakout game. Returns a table of
    bricks that the game can render, based on the current level we're at
    in the game.
]]

-- global patterns (used to make the entire map a certain shape)
NONE = 1
SINGLE_PYRAMID = 2
MULTI_PYRAMID = 3

-- per-row patterns
SOLID = 1           -- all colors the same in this row
ALTERNATE = 2       -- alternate colors
SKIP = 3            -- skip every other block
NONE = 4            -- no blocks this row

--[[ NOTE: the logic for lines 62, 63, 82, 83 were suggested as a solution to an 
issue I was having with lockedbricks spawning by reddit user IMP1. 
That discussion also helped me realize that I had deleted the brick update
in the Playstate. This was the extent of the interaction]]

LevelMaker = Class{}

--[[
    Creates a table of Bricks to be returned to the main game, with different
    possible ways of randomizing rows and columns of bricks. Calculates the
    brick colors and tiers to choose based on the level passed in.
]]
function LevelMaker.createMap(level)

    -- randomly choose the number of rows
    local numRows = math.random(1, 5)

    -- randomly choose the number of columns, ensuring odd
    local numCols = math.random(7, 13)
    if numCols % 2 == 0 then
        numCols = numCols + 1
    end

    -- highest possible spawned brick color in this level; ensure we
    -- don't go above 3
    local highestTier = math.min(3, math.floor(level / 5))

    -- highest color of the highest tier, no higher than 5
    local highestColor = math.min(5, level % 5 + 3)

    -- lay out bricks such that they touch each other and fill the space
    
    local LOCKED_BRICK_PROBABILITY = 20

    local solidColor = math.random(1, highestColor)
    local solidTier = math.random(0, highestTier)
    
    local bricks = {}  -- Initialize the bricks table

    for j = 1, numRows do
        local y = j * 16
        -- whether we want to enable skipping for this row
        local skipPattern = (math.random(1, 2) == 1)

        -- whether we want to enable alternating colors for this row
        local alternatePattern = (math.random(1, 2) == 1)
                
        -- choose two colors to alternate between
        local alternateColor1 = math.random(1, highestColor)
        local alternateColor2 = math.random(1, highestColor)
        local alternateTier1 = math.random(0, highestTier)
        local alternateTier2 = math.random(0, highestTier)
                
        -- used only when we want to skip a block, for skip pattern
        local skipFlag = (math.random(2) == 1)

        -- used only when we want to alternate a block, for alternate pattern
        local alternateFlag = (math.random(2) == 1)
            
        for i = 1, numCols do
            local x = (i - 1) * 32 + 8 + (13 - numCols) * 16

            -- if skipping is turned on and we're on a skip iteration...
            if skipPattern and skipFlag then
                -- turn skipping off for the next iteration
                skipFlag = not skipFlag

                -- Lua doesn't have a continue statement, so this is the workaround
                goto continue
            else
                -- flip the flag to true on an iteration we don't use it
                skipFlag = not skipFlag
            end

            local brick
            if math.random(1, 100) <= LOCKED_BRICK_PROBABILITY then
                brick = LockedBrick(x, y, gTextures['main'], gFrames['lockedbrick'])
            else  
                brick = Brick(x, y)

                -- if we're alternating, figure out which color/tier we're on
                if alternatePattern and alternateFlag then
                    brick.color = alternateColor1
                    brick.tier = alternateTier1
                else
                    brick.color = alternateColor2
                    brick.tier = alternateTier2
                    alternateFlag = not alternateFlag
                end

                -- if not alternating and we made it here, use the solid color/tier
                if not alternatePattern then
                    brick.color = solidColor
                    brick.tier = solidTier
                end 
            end

            table.insert(bricks, brick)

            -- Lua's version of the 'continue' statement
            ::continue::
            
        end 
    end
    -- in the event we didn't generate any bricks, try again
    if #bricks == 0 then
        return self.createMap(level)
    else
        return bricks
    end
end