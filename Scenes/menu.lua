
local composer = require( "composer" )

local scene = composer.newScene()

-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------

local menuSound = audio.loadSound( "Audios/Light_Years_Away_-_menu.mp3" )
local menuSoundChannel
local menuChoiceSound = audio.loadSound( "Audios/Menu_Choice.mp3" )
local menuChoiceSoundChannel = 2

local function gotoGame()
	audio.play( menuChoiceSound, { channel=menuChoiceSoundChannel } )
	composer.gotoScene("Scenes.game", { time=800, effect="crossFade" } )
end

local function gotoHighScores()
	audio.play( menuChoiceSound, { channel=menuChoiceSoundChannel } )
	composer.gotoScene("Scenes.highscores", { time=800, effect="crossFade" } )
end


-- local menuSound

-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------

-- create()
function scene:create( event )

	local sceneGroup = self.view
	-- Code here runs when the scene is first created but has not yet appeared on screen

	local background = display.newImageRect( sceneGroup, "Images/background.png", 1200, 600 )
    background.x = display.contentCenterX
	background.y = display.contentCenterY
	
	local playButton = display.newText( sceneGroup, "Play", display.contentCenterX, 530, "fonts/Purnima-Brush 05.ttf", 48 )
	playButton:setFillColor( 0.82, 0.86, 1 )
	
	local highScoresButton = display.newText( sceneGroup, "Rankings", display.contentCenterX, 600, "fonts/Purnima-Brush 05.ttf", 48 )
	highScoresButton:setFillColor( 0.75, 0.78, 1 )
	
	playButton:addEventListener( "tap", gotoGame )
    highScoresButton:addEventListener( "tap", gotoHighScores )
end


-- show()
function scene:show( event )

	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		-- Code here runs when the scene is still off screen (but is about to come on screen)
		menuSoundChannel = audio.play( menuSound, { loops=-1 })
	elseif ( phase == "did" ) then
		-- Code here runs when the scene is entirely on screen
	end
end


-- hide()
function scene:hide( event )

	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		-- Code here runs when the scene is on screen (but is about to go off screen)
		audio.stop( menuSoundChannel )

	elseif ( phase == "did" ) then
		-- Code here runs immediately after the scene goes entirely off screen

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
