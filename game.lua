
local composer = require( "composer" )

local scene = composer.newScene()

-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------

local physics = require( "physics" )
physics.start()
physics.setGravity( 0, 0 )

-- Configure image sheet
local sheetOptions =
{
    width = 144,
    height = 128,
    numFrames = 12
}
local sheet_flyingGaruna = graphics.newImageSheet( "garuna.png", sheetOptions )

-- sequences table
local sequences_flyingGaruna = {
    -- first sequence
    {
        name = "normalFlight",
        start = 4,
        count = 3,
        time = 600,
        loopCount = 0,
        loopDirection = "forward"
    },
    -- second sequence
    {
        name = "fastFlight",
        start = 4,
        count = 3,
        time = 300,
        loopCount = 0,
        loopDirection = "forward"
    }
}

-- Configure image sheet
local sheetOptions_fireball =
{
    width = 187,
    height = 108,
    numFrames = 4
}
local sheet_fireball = graphics.newImageSheet( "fireball_sheet.png", sheetOptions_fireball )

-- sequences table
local sequences_fireball = {
    -- first sequence
    {
        name = "normalFireball",
        start = 1,
        count = 4,
        time = 500,
        loopCount = 0,
        loopDirection = "forward"
    },
    -- second sequence
    {
        name = "fastFireball",
        start = 1,
        count = 4,
        time = 100,
        loopCount = 0,
        loopDirection = "forward"
    }
}

-- Initialize variables
local lives = 3
local score = 0
local died = false

local asteroidsTable = {}

local dragon
local livesText
local scoreText

local backGroup
local mainGroup
local uiGroup


local function updateText()
	livesText.text = "Lives: " .. lives
	scoreText.text = "Score: " .. score
end


local function createAsteroid()

	local newAsteroid = display.newImageRect( mainGroup, objectSheet, 1, 102, 85 )
	table.insert( asteroidsTable, newAsteroid )
	physics.addBody( newAsteroid, "dynamic", { radius=40, bounce=0.8 } )
	newAsteroid.myName = "asteroid"

	local whereFrom = math.random( 3 )

	if ( whereFrom == 1 ) then
		-- From the left
		newAsteroid.x = -60
		newAsteroid.y = math.random( 500 )
		newAsteroid:setLinearVelocity( math.random( 40,120 ), math.random( 20,60 ) )
	elseif ( whereFrom == 2 ) then
		-- From the top
		newAsteroid.x = math.random( display.contentWidth )
		newAsteroid.y = -60
		newAsteroid:setLinearVelocity( math.random( -40,40 ), math.random( 40,120 ) )
	elseif ( whereFrom == 3 ) then
		-- From the right
		newAsteroid.x = display.contentWidth + 60
		newAsteroid.y = math.random( 500 )
		newAsteroid:setLinearVelocity( math.random( -120,-40 ), math.random( 20,60 ) )
	end

	newAsteroid:applyTorque( math.random( -6,6 ) )
end


local function fireball()

	local newLaser = display.newSprite( mainGroup, sheet_fireball, sequences_fireball )
    newLaser:setSequence("fastFireball")
    newLaser:play()
    physics.addBody( newLaser, "dynamic", { isSensor=true } )
	newLaser.isBullet = true
	newLaser.myName = "laser"

	newLaser.x = dragon.x + 50
	newLaser.y = dragon.y + 20
	newLaser:toBack()

	transition.to( newLaser, { x = display.contentWidth + 40, time=1000,
		onComplete = function() display.remove( newLaser ) end
	} )
end


local function dragDragon( event )
 
    local dragon = event.target
    local phase = event.phase
 
    if ( "began" == phase ) then
        -- Set touch focus on the dragon
        display.currentStage:setFocus( dragon )
        -- Store initial offset position
        dragon.touchOffsetY = event.y - dragon.y
        dragon.touchOffsetX = event.x - dragon.x
 
    elseif ( "moved" == phase ) then
        local newPositionY = event.y - dragon.touchOffsetY

        -- Move the dragon to the new touch position
        if ( newPositionY > 160 and newPositionY < 630 ) then
            dragon.y = newPositionY
        end

    elseif ( "ended" == phase or "cancelled" == phase ) then
        -- Release touch focus on the dragon
        display.currentStage:setFocus( nil )
    end
 
    return true  -- Prevents touch propagation to underlying objects
end
 
local function restoredragon()
 
    dragon.isBodyActive = false
    dragon.x = 100
    dragon.y = display.contentCenterY
 
    -- Fade in the dragon
    transition.to( dragon, { alpha=1, time=4000,
        onComplete = function()
            dragon.isBodyActive = true
            died = false
        end
    } )
end


local function endGame()
    composer.gotoScene( "menu", { time=800, effect="crossFade" } )
end

 
local function onCollision( event )
 
    if ( event.phase == "began" ) then
 
        local obj1 = event.object1
        local obj2 = event.object2
 
        if ( ( obj1.myName == "laser" and obj2.myName == "asteroid" ) or
             ( obj1.myName == "asteroid" and obj2.myName == "laser" ) )
        then
            -- Remove both the laser and asteroid
            display.remove( obj1 )
            display.remove( obj2 )
 
            for i = #asteroidsTable, 1, -1 do
                if ( asteroidsTable[i] == obj1 or asteroidsTable[i] == obj2 ) then
                    table.remove( asteroidsTable, i )
                    break
                end
            end
 
            -- Increase score
            score = score + 100
            scoreText.text = "Score: " .. score
 
        elseif ( ( obj1.myName == "dragon" and obj2.myName == "asteroid" ) or
                 ( obj1.myName == "asteroid" and obj2.myName == "dragon" ) )
        then
            if ( died == false ) then
                died = true
 
                -- Update lives
                lives = lives - 1
                livesText.text = "Lives: " .. lives
 
                if ( lives == 0 ) then
					display.remove( dragon )
					timer.performWithDelay( 2000, endGame )
                else
                    dragon.alpha = 0
                    timer.performWithDelay( 1000, restoredragon )
                end
            end
        end
    end
end


-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------

-- create()
function scene:create( event )

	local sceneGroup = self.view
	-- Code here runs when the scene is first created but has not yet appeared on screen

	physics.pause()  -- Temporarily pause the physics engine

	-- Set up display groups
	backGroup = display.newGroup()  -- Display group for the background image
	sceneGroup:insert( backGroup )  -- Insert into the scene's view group
	
	mainGroup = display.newGroup()  -- Display group for the dragon, asteroids, lasers, etc.
	sceneGroup:insert( mainGroup )  -- Insert into the scene's view group
	
	uiGroup = display.newGroup()    -- Display group for UI objects like the score
	sceneGroup:insert( uiGroup )    -- Insert into the scene's view group

	-- Load the background
	local background = display.newImageRect( backGroup, "background2.png", 1200, 600 )
	background.x = display.contentCenterX
	background.y = display.contentCenterY

	dragon = display.newSprite( mainGroup, sheet_flyingGaruna, sequences_flyingGaruna )
    dragon:setSequence("fastFlight")
    dragon:play()
    dragon.x = 100
    dragon.y = display.contentCenterY
    physics.addBody( dragon, { radius=30, isSensor=true } )
    dragon.myName = "dragon"
 
    -- Display lives and score
    livesText = display.newText( uiGroup, "Lives: " .. lives, 200, 80, native.systemFont, 36 )
    scoreText = display.newText( uiGroup, "Score: " .. score, 400, 80, native.systemFont, 36 )

	dragon:addEventListener( "tap", fireball )
    dragon:addEventListener( "touch", dragDragon )
end


-- show()
function scene:show( event )

	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		-- Code here runs when the scene is still off screen (but is about to come on screen)

	elseif ( phase == "did" ) then
		-- Code here runs when the scene is entirely on screen
		physics.start()
        Runtime:addEventListener( "collision", onCollision )
	end
end


-- hide()
function scene:hide( event )

	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		-- Code here runs when the scene is on screen (but is about to go off screen)

	elseif ( phase == "did" ) then
		-- Code here runs immediately after the scene goes entirely off screen
		Runtime:removeEventListener( "collision", onCollision )
		physics.pause()
		composer.removeScene( "game" )
	end
end


-- destroy()
function scene:destroy( event )

	local sceneGroup = self.view
	-- Code here runs prior to the removal of scene's view

end


-- -----------------------------------------------------------------------------------
-- Scene event function listeners
-- -----------------------------------------------------------------------------------
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )
-- -----------------------------------------------------------------------------------

return scene
