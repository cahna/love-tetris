
require "tetris"

{graphics: g, :timer, :mouse, :keyboard} = love

export ^

screen = {
  padding: 8
  scale: 1
  w: g.getWidth!
  h: g.getHeight!
}

class ScoreBar
  new: (t) =>
    @tetris = t

    @width = 100
    @height = 10
    @padding = 4

  draw: =>
    g.setColor 255,255,255

    text = "
      Level:\t #{@tetris.level}
      Score:\t #{@tetris.score}
      Lines:\t #{@tetris.linesCleared}
    "

    g.printf(text, 400, 200, 300, "left")

--- Define interface for difference screens within the game UI
class UiState
  attach: (love) =>
    love.update = self\update
    love.draw = self\draw
    love.keypressed = self\keypressed
    love.mousepressed = self\mousepressed
    -- love.keyreleased = g\keyreleased

  draw: =>
    g.setFont(mainFont)
    g.setColorMode "replace"
    g.draw(background, 0, 0)

  update: =>
  mousepressed: =>
  keypressed: (key, code) =>
    if key == "escape"
      os.exit!

class GameOver extends UiState
  new: (t) =>
    @t = t

  draw: =>
    super!
    g.setColor 255,255,255
    g.printf("GAME OVER!", 400, 200, 400)
    g.printf("Score: #{@t.score} / Lines: #{@t.linesCleared} / Level #{@t.level}", 400, 240, 400)

class Game extends UiState
  tetris     = {}
  scorebar   = {}
  lastEvent  = 0
  lastDrop   = 0
  milliClock = 0

  new: =>
    tetris = Tetris(50, 20)
    scorebar = ScoreBar(tetris)

  draw: =>
    super!
    tetris\draw!
    scorebar\draw!

  safeDown: =>
    tetris\moveDown!
    if tetris.gameOver
      endscreen = GameOver(tetris)
      endscreen\attach(love)

  update: (dt) =>
    if lastEvent == 0 or timer.getTime!*1000 - lastEvent > MIN_WAIT
      if love.keyboard.isDown "left"
        tetris\moveLeft!
      if love.keyboard.isDown "right"
        tetris\moveRight!
      if love.keyboard.isDown "down"
        @safeDown!

      lastEvent = timer.getTime!*1000

    if timer.getTime!*1000 - lastDrop > tetris.speed * FULL_STEP
      @safeDown!
      lastDrop = timer.getTime!*1000

  keypressed: (key, code) =>
    super(key, code)
    switch key
      when "left"
        print "User wants to move left..."
        tetris\moveLeft!
      when "right"
        print "User wants to move right..."
        tetris\moveRight!
      when "up"
        print "User wants to rotate piece..."
        tetris\rotate!
      when " "
        print "User wants to force drop..."
        tetris\forceDrop!
      when "down"
        print "User wants to move down..."
        @safeDown!
      else
        print "Unknown action"
