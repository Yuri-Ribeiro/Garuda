
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
    frames =
    {
        {   -- 1) garuna
            x = 0,
            y = 130,
            width = 135,
            height = 100
        },
    },
}
local objectSheet = graphics.newImageSheet( "garuna.png", sheetOptions )

-- Initialize variables
local lives = 3
local score = 0
local died = false

local asteroidsTable = {}

local ship
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

	local newLaser = display.newImageRect( mainGroup, "fireball.png", 50, 50 )
	physics.addBody( newLaser, "dynamic", { isSensor=true } )
	newLaser.isBullet = true
	newLaser.myName = "laser"

	newLaser.x = ship.x + 50
	newLaser.y = ship.y + 20
	newLaser:toBack()

	transition.to( newLaser, { x = display.contentWidth + 40, time=1000,
		onComplete = function() display.remove( newLaser ) end
	} )
end


local function dragShip( event )
 
    local ship = event.target
    local phase = event.phase
 
    if ( "began" == phase ) then
        -- Set touch focus on the ship
        display.currentStage:setFocus( ship )
        -- Store initial offset position
        ship.touchOffsetY = event.y - ship.y
 
    elseif ( "moved" == phase ) then
        -- Move the ship to the new touch position
        ship.y = event.y - ship.touchOffsetY
 
    elseif ( "ended" == phase or "cancelled" == phase ) then
        -- Release touch focus on the ship
        display.currentStage:setFocus( nil )
    end
 
    return true  -- Prevents touch propagation to underlying objects
end
 
local function restoreShip()
 
    ship.isBodyActive = false
    ship.x = 100
    ship.y = display.contentCenterY
 
    -- Fade in the ship
    transition.to( ship, { alpha=1, time=4000,
        onComplete = function()
            ship.isBodyActive = true
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
 
        elseif ( ( obj1.myName == "ship" and obj2.myName == "asteroid" ) or
                 ( obj1.myName == "asteroid" and obj2.myName == "ship" ) )
        then
            if ( died == false ) then
                died = true
 
                -- Update lives
                lives = lives - 1
                livesText.text = "Lives: " .. lives
 
                if ( lives == 0 ) then
					display.remove( ship )
					timer.performWithDelay( 2000, endGame )
                else
                    ship.alpha = 0
                    timer.performWithDelay( 1000, restoreShip )
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
	
	mainGroup = display.newGroup()  -- Display group for the ship, asteroids, lasers, etc.
	sceneGroup:insert( mainGroup )  -- Insert into the scene's view group
	
	uiGroup = display.newGroup()    -- Display group for UI objects like the score
	sceneGroup:insert( uiGroup )    -- Insert into the scene's view group

	-- Load the background
	local background = display.newImageRect( backGroup, "background2.png", 1200, 600 )
	background.x = display.contentCenterX
	background.y = display.contentCenterY

	ship = display.newImageRect( mainGroup, objectSheet, 1, 135, 90 )
    ship.x = 100
    ship.y = display.contentCenterY
    physics.addBody( ship, { radius=30, isSensor=true } )
    ship.myName = "ship"
 
    -- Display lives and score
    livesText = display.newText( uiGroup, "Lives: " .. lives, 200, 80, native.systemFont, 36 )
    scoreText = display.newText( uiGroup, "Score: " .. score, 400, 80, native.systemFont, 36 )

	ship:addEventListener( "tap", fireball )
    ship:addEventListener( "touch", dragShip )
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
