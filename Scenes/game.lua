
local composer = require( "composer" )

local scene = composer.newScene()

-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------

local physics = require( "physics" )
physics.start()
physics.setGravity( 0, 0 )

-- Initialize variables
local lives = 3
local score = 0
local died = false

local enemiesTable = {}
local explosionTable = {}
local bossAttackTable = {}

local dragon
local livesText
local scoreText

local background
local backGroup
local mainGroup
local uiGroup

local phase1Sound = audio.loadSound( "Audios/Stars_-_phase_1.mp3" )
local phase1SoundChannel = 1

local fireballSound = audio.loadSound( "Audios/105016__julien-matthey__jm-fx-fireball-01.wav" )

local explosionSound = audio.loadSound( "Audios/Explosion.wav" )
local fireballSoundChannel

local countDeadEnemies = 0
local boss
local bossLife = 50

local gameLoopTimer

-- Configure image sheet - Garuda
local sheetOptions =
{
    width = 60.3,
    height = 66,
    numFrames = 8
}
local sheet_flyingGaruna = graphics.newImageSheet( "Images/Garuda/fly2.png", sheetOptions )

-- sequences table
local sequences_flyingGaruna = {
    -- first sequence
    {
        name = "normalFlight",
        start = 1,
        count = 8,
        time = 2000,
        loopCount = 0,
        loopDirection = "forward"
    },
    -- second sequence
    {
        name = "fastFlight",
        start = 1,
        count = 8,
        time = 600,
        loopCount = 0,
        loopDirection = "forward"
    }
}

-- Configure image sheet - Fireball
local sheetOptions_fireball =
{
    width = 187,
    height = 108,
    numFrames = 4
}
local sheet_fireball = graphics.newImageSheet( "Images/fireball_sheet.png", sheetOptions_fireball )

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


-- Configure image sheet - bossFireball
local sheetOptions_bossFireball =
{
    width = 187,
    height = 108,
    numFrames = 4
}
local sheet_bossFireball = graphics.newImageSheet( "Images/fireball_sheet_-_boss.png", sheetOptions_bossFireball )

-- sequences table
local sequences_bossFireball = {
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



-- Configure image sheet - Explosion
local sheetOptions_explosion =
{
    width = 42,
    height = 42,
    numFrames = 8
}
local sheet_explosion = graphics.newImageSheet( "Images/explosion_sheet.png", sheetOptions_explosion )

-- sequences table
local sequences_explosion = {
    -- first sequence
    {
        name = "normalExplosion",
        start = 1,
        count = 8,
        time = 500,
        loopCount = 1,
        loopDirection = "forward"
    }
}

-- Configure image sheet - Enemy
local sheetOptions_enemy =
{
    width = 65,
    height = 65,
    numFrames = 16
}
local sheet_flyingEnemy = graphics.newImageSheet( "Images/enemy.png", sheetOptions_enemy )

-- sequences table
local sequences_flyingEnemy = {
    {
        name = "normalFlight",
        start = 13,
        count = 4,
        time = 600,
        loopCount = 0,
        loopDirection = "forward"
    }
}


-- Configure image sheet - Boss
local sheetOptions_boss =
{
    width = 87,
    height = 110,
    numFrames = 8
}
local sheet_boss = graphics.newImageSheet( "Images/boss.png", sheetOptions_boss )

-- sequences table
local sequences_boss = {
    -- first sequence
    {
        name = "normalFlight",
        start = 1,
        count = 8,
        time = 2000,
        loopCount = 0,
        loopDirection = "forward"
    },
    -- second sequence
    {
        name = "fastFlight",
        start = 1,
        count = 8,
        time = 600,
        loopCount = 0,
        loopDirection = "forward"
    }
}


local function updateText()
	livesText.text = "Vidas: " .. lives
	scoreText.text = "Pontos: " .. score
end


local function createEnemy()
    local newEnemy = display.newSprite( mainGroup, sheet_flyingEnemy, sequences_flyingEnemy )

    -- local newEnemy = display.newSprite( mainGroup, sheet_enemy, sequences_enemy )
	table.insert( enemiesTable, newEnemy )
    newEnemy:setSequence("normalFlight")
    newEnemy:play()

    -- physics.addBody( newEnemy, { radius=30, isSensor=true } )
	physics.addBody( newEnemy, "dynamic", { radius=40, bounce=0.8 } )

	-- local newEnemy = display.newImageRect( mainGroup, objectSheet, 1, 102, 85 )
    newEnemy.myName = "enemy"
    newEnemy.yScale = 2.5
    newEnemy.xScale = 2.5

	local whereFrom = math.random( 3 )

	if ( whereFrom == 1 ) then
		-- From the top
		newEnemy.x = display.contentWidth + 60
		newEnemy.y = -60
		newEnemy:setLinearVelocity( math.random( -200, -150 ), math.random( 20, 60 ) )
	elseif ( whereFrom == 2 ) then
		-- From the right
		newEnemy.x = display.contentWidth + 60
		newEnemy.y = math.random( display.contentHeight - 180 )
		newEnemy:setLinearVelocity( math.random( -200, -150 ), 0 )
	elseif ( whereFrom == 3 ) then
		-- From the bottom
		newEnemy.x = display.contentWidth + 60
		newEnemy.y = display.contentHeight + 60
		newEnemy:setLinearVelocity( math.random( -200,-150 ), math.random( -60, -20 ) )
	end

	-- newEnemy:applyTorque( math.random( -12,-2 ) )
end

-- Game loop
local function gameLoop()
 
    -- Create new enemy
    createEnemy()
 
    -- Remove enemies which have drifted off screen
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


-- Boss attack loop
local function bossAttackLoop()
    -- BossAtack
    if ( boss.isBodyActive and bossLife > 0)
    then
        bossAttack()
    end
end


local function endGame()
    composer.setVariable( "finalScore", score )
    composer.gotoScene( "Scenes.highscores", { time=800, effect="crossFade" } )
end


-- clean explosions
local function cleanExplosions()  
    for i = #explosionTable, 1, -1 do
        local thisExplosion = explosionTable[i]
        
        if ( not thisExplosion.isPlaying )
        then
            display.remove( thisExplosion )
            table.remove( explosionTable, i )
        end
    end
end


-- show boss
local function createBoss()
    -- timer.cancel( gameLoopTimer )
    -- gameLoopTimer = timer.performWithDelay( 1000, gameLoop, 0 )

    boss = display.newSprite( mainGroup, sheet_boss, sequences_boss )
    boss:setSequence("fastFlight")
    boss:play()
    physics.addBody( boss, "static", { radius=40, bounce=0.8 } )
    boss.isBodyActive = false

    boss.myName = "boss"
    boss.x = display.contentWidth + 100
    boss.y = display.contentCenterY
    boss.yScale = 1.8
    boss.xScale = 1.8
end


-- explosion
local function explosion( x, y )
    local newExplosion = display.newSprite( mainGroup, sheet_explosion, sequences_explosion )
    table.insert( explosionTable, newExplosion )

    newExplosion:setSequence("normalExplosion")
    newExplosion:play()
    newExplosion.myName = "explosion"

    newExplosion.x = x
    newExplosion.y = y
    newExplosion.yScale = 2
    newExplosion.xScale = 2
end


-- explosion - all enemies
local function explosionOfAllEnemies( x, y )
    for i = #enemiesTable, 1, -1 do
        local thisEnemy = enemiesTable[i]
        
        explosion( thisEnemy.x, thisEnemy.y )
        display.remove( thisEnemy )
        table.remove( enemiesTable, i )
    end
end


-- boss dead
local function bossDead( x, y )
    timer.cancel( gameLoopTimer )
    
    explosionOfAllEnemies()

    for i = 1, 14 do
        timer.performWithDelay( 500 + i*500,
            function() explosion( x + math.random( -30, 30 ), y  + math.random( -60, 60 )) end
        )
    end
    
    timer.performWithDelay( 8000,
    function()
        display.remove( boss )
        timer.performWithDelay( 2000, endGame )
    end
)
end


function bossAttack()
    local newBossAttack = display.newSprite( mainGroup, sheet_bossFireball, sequences_bossFireball )
    newBossAttack:setSequence("fastFireball")
    newBossAttack:play()
    physics.addBody( newBossAttack, "dynamic", { isSensor=true } )
    newBossAttack.isBullet = true
    newBossAttack.myName = "bossAttack"

    newBossAttack.x = boss.x - 50
    newBossAttack.y = boss.y

    newBossAttack.yScale = 0.8
    newBossAttack.xScale = 0.8

    newBossAttack:toBack()

    transition.to( newBossAttack, { x = dragon.x, y = dragon.y, time=1400,
        onComplete = function() display.remove( newBossAttack ) end
    } )

    -- fireballSoundChannel = audio.play( fireballSound )
    -- audio.setVolume( 0.3, { channel=fireballSoundChannel } )
end


-- check if it's time to show the boss
local function checkShowBoss()
    --------------------------------------------------------------------------------------- MUDAR
    if ( countDeadEnemies == 1 ) then
        transition.to( boss, { x = display.contentCenterX + 380, time=5000,
        onComplete = function()
            boss.isBodyActive = true
            bossAttack()
        end
    } )
    end
end


-- Create a fireball
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
    
    fireballSoundChannel = audio.play( fireballSound )
    audio.setVolume( 0.3, { channel=fireballSoundChannel } )
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

 
local function onCollision( event )
 
    if ( event.phase == "began" ) then
 
        local obj1 = event.object1
        local obj2 = event.object2
 
        if ( ( obj1.myName == "laser" and obj2.myName == "enemy" ) or
             ( obj1.myName == "enemy" and obj2.myName == "laser" ) )
        then
            -- count
            countDeadEnemies = countDeadEnemies + 1

            -- Remove both the laser and asteroid
            display.remove( obj1 )
            display.remove( obj2 )

            -- check if it's time to show the boss
            checkShowBoss()

            -- Sound of colision
            explosionSoundChannel = audio.play( explosionSound )
            audio.setVolume( 1.2, { channel=explosionSoundChannel } )

            if ( obj1.myName == "enemy" ) then
                explosion( obj1.x, obj1.y )
    
            elseif ( obj2.myName == "enemy" ) then
                explosion( obj2.x, obj2.y )
            end
 
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
                 ( obj1.myName == "enemy" and obj2.myName == "dragon" ) or
                 ( obj1.myName == "bossAttack" and obj2.myName == "dragon" ) or
                 ( obj1.myName == "dragon" and obj2.myName == "bossAttack" )
               )
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
        elseif ( ( obj1.myName == "laser" and obj2.myName == "boss" ) or
                 ( obj1.myName == "boss" and obj2.myName == "laser" ) )
        then
           -- Sound of colision
           explosionSoundChannel = audio.play( explosionSound )
           audio.setVolume( 1.2, { channel=explosionSoundChannel } )

           -- explosion and remove fireball
           if ( obj1.myName == "boss" ) then
               explosion( obj1.x - 20, obj1.y )
               display.remove( obj2 )
   
           elseif ( obj2.myName == "boss" ) then
               explosion( obj2.x - 20, obj2.y )
               display.remove( obj1 )
           end

           -- decrement boss life
           bossLife = bossLife - 1

           -- remove boss
           if (bossLife == 0) then
                if ( obj1.myName == "boss" ) then
                    bossDead( obj1.x, obj1.y )
                elseif ( obj2.myName == "boss" ) then
                    bossDead( obj2.x, obj2.y )
                end
           end

           -- Increase score
           score = score + 100
           scoreText.text = "Pontos: " .. score
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

    background = display.newRect( backGroup, display.contentCenterX , display.contentCenterY, 1200 , 600 )
    background.fill={ type = "image", filename = "Images/background2.png" }
    local function animateBackground()
        transition.to( background.fill, { time = 3000, x=1 , delta = true, onComplete = animateBackground })
    end

    animateBackground()

	dragon = display.newSprite( mainGroup, sheet_flyingGaruna, sequences_flyingGaruna )
    dragon:setSequence("fastFlight")
    dragon:play()
    dragon.x = 100
    dragon.y = display.contentCenterY
    dragon.yScale = 1.9
    dragon.xScale = 1.9
    physics.addBody( dragon, { radius=30, isSensor=true } )
    dragon.myName = "dragon"

    createBoss()
 
    -- Display lives and score
    livesText = display.newText( uiGroup, "Vidas: " .. lives, 100, 160, "fonts/Purnima-Brush 05.ttf", 36 )
    scoreText = display.newText( uiGroup, "Pontos: " .. score, 300, 160, "fonts/Purnima-Brush 05.ttf", 36 )

	-- dragon:addEventListener( "tap", fireball )
	background:addEventListener( "tap", fireball )
    dragon:addEventListener( "touch", dragDragon )
end


-- show()
function scene:show( event )
    
	local sceneGroup = self.view
	local phase = event.phase
    
	if ( phase == "will" ) then
        -- Code here runs when the scene is still off screen (but is about to come on screen)
        audio.play( phase1Sound, { loops=-1, channel=phase1SoundChannel })

	elseif ( phase == "did" ) then
		-- Code here runs when the scene is entirely on screen
		physics.start()
        Runtime:addEventListener( "collision", onCollision )
        gameLoopTimer = timer.performWithDelay( 500, gameLoop, 0 )
        timer.performWithDelay( 2000, bossAttackLoop, 0 )
        cleanExplosionsTimer = timer.performWithDelay( 100, cleanExplosions, 0 )
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
        
        audio.stop(phase1SoundChannel)
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
