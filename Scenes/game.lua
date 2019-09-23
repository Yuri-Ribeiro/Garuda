
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
local sheet_flyingGaruna = graphics.newImageSheet( "images/garuda.png", sheetOptions )

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
local sheet_fireball = graphics.newImageSheet( "images/fireball_sheet.png", sheetOptions_fireball )

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

local enemiesTable = {}

local dragon
local livesText
local scoreText

local backGroup
local mainGroup
local uiGroup


local function updateText()
	livesText.text = "Vidas: " .. lives
	scoreText.text = "Pontos: " .. score
end


local function createEnemy()

	-- local newEnemy = display.newImageRect( mainGroup, objectSheet, 1, 102, 85 )
    local newEnemy = display.newImage( mainGroup, "images/fireball.png" )
	table.insert( enemiesTable, newEnemy )
	physics.addBody( newEnemy, "dynamic", { radius=40, bounce=0.8 } )
    newEnemy.myName = "enemy"
    newEnemy.yScale = 0.3
    newEnemy.xScale = 0.3

	local whereFrom = math.random( 3 )

	if ( whereFrom == 1 ) then
		-- From the top
		newEnemy.x = display.contentWidth + 60
		newEnemy.y = -60
		newEnemy:setLinearVelocity( math.random( -150, -100 ), math.random( 20, 60 ) )
	elseif ( whereFrom == 2 ) then
		-- From the right
		newEnemy.x = display.contentWidth + 60
		newEnemy.y = math.random( display.contentHeight - 180 )
		newEnemy:setLinearVelocity( math.random( -150, -100 ), 0 )
	elseif ( whereFrom == 3 ) then
		-- From the bottom
		newEnemy.x = display.contentWidth + 60
		newEnemy.y = display.contentHeight + 60
		newEnemy:setLinearVelocity( math.random( -150,-100 ), math.random( -60, -20 ) )
	end

	newEnemy:applyTorque( math.random( -12,-2 ) )
end


local function gameLoop()
 
    -- Create new asteroid
    createEnemy()
 
    -- Remove asteroids which have drifted off screen
    for i = #enemiesTable, 1, -1 do
        local thisEnemy = enemiesTable[i]
 
        if ( thisEnemy.x < -100 or
             thisEnemy.x > display.contentWidth + 100 or
             thisEnemy.y < -100 or
             thisEnemy.y > display.contentHeight + 100 )
        then
            display.remove( thisEnemy )
            table.remove( enemiesTable, i )
        end
    end
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
        local newPositionX = event.x - dragon.touchOffsetX

        -- Move the dragon to the new touch position
        if ( newPositionY > 160 and newPositionY < 630 ) then
            dragon.y = newPositionY
        end

        if ( newPositionX > 85 and newPositionX < display.contentWidth - 50 ) then
            dragon.x = newPositionX
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
    composer.setVariable( "finalScore", score )
    composer.gotoScene( "Scenes.highscores", { time=800, effect="crossFade" } )
end

 
local function onCollision( event )
 
    if ( event.phase == "began" ) then
 
        local obj1 = event.object1
        local obj2 = event.object2
 
        if ( ( obj1.myName == "laser" and obj2.myName == "enemy" ) or
             ( obj1.myName == "enemy" and obj2.myName == "laser" ) )
        then
            -- Remove both the laser and asteroid
            display.remove( obj1 )
            display.remove( obj2 )
 
            for i = #enemiesTable, 1, -1 do
                if ( enemiesTable[i] == obj1 or enemiesTable[i] == obj2 ) then
                    table.remove( enemiesTable, i )
                    break
                end
            end
 
            -- Increase score
            score = score + 100
            scoreText.text = "Pontos: " .. score
 
        elseif ( ( obj1.myName == "dragon" and obj2.myName == "enemy" ) or
                 ( obj1.myName == "enemy" and obj2.myName == "dragon" ) )
        then
            if ( died == false ) then
                died = true
 
                -- Update lives
                lives = lives - 1
                livesText.text = "Vidas: " .. lives
 
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
    
    display.setDefault("textureWrapX","mirroredRepeat")

    local background = display.newRect( backGroup, display.contentCenterX , display.contentCenterY, 1200 , 600 )
    background.fill={ type = "image", filename = "images/background2.png" }
    local function animateBackground()
        transition.to( background.fill, { time = 3000, x=1 , delta = true, onComplete = animateBackground })
    end

    animateBackground()

	dragon = display.newSprite( mainGroup, sheet_flyingGaruna, sequences_flyingGaruna )
    dragon:setSequence("fastFlight")
    dragon:play()
    dragon.x = 100
    dragon.y = display.contentCenterY
    physics.addBody( dragon, { radius=30, isSensor=true } )
    dragon.myName = "dragon"
 
    -- Display lives and score
    livesText = display.newText( uiGroup, "Vidas: " .. lives, 100, 160, native.systemFont, 36 )
    scoreText = display.newText( uiGroup, "Pontos: " .. score, 300, 160, native.systemFont, 36 )

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
        gameLoopTimer = timer.performWithDelay( 400, gameLoop, 0 )
	end
end


-- hide()
function scene:hide( event )

	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
        -- Code here runs when the scene is on screen (but is about to go off screen)
        timer.cancel( gameLoopTimer )

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
