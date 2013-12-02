
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
  new: =>
    @value = 0

    @width = 100
    @height = 10
    @padding = 4

  draw: =>
    import padding, w, h from screen
    g.setColor 255,255,255

    ox = w - @width - padding
    oy = padding

    g.rectangle "line",
      ox - @padding, oy - @padding,
      @width + @padding*2, @height + @padding*2

    g.setColor 227, 52, 52, 200
    g.rectangle "fill",
      ox, oy, @width * @value, @height

--- Define interface for difference screens within the game UI
class UiState
  attach: (love) =>
    love.update = self\update
    love.draw = self\draw
    love.keypressed = self\keypressed
    love.mousepressed = self\mousepressed
    -- love.keyreleased = g\keyreleased

  draw: =>
    g.setColorMode "replace"
    g.draw(background, 0, 0)

  update: =>
  keypressed: =>
  mousepressed: =>

class Game extends UiState
  tetris = {}
  scorebar = {}
  action = nil

  new: =>
    tetris = Tetris(50, 20)
    scorebar = ScoreBar!
    action   = nil

  draw: =>
    super!
    tetris\draw!
    scorebar\draw!

  update: (dt) =>
    --if tetris
    --  print "load time:", dt
      
  keypressed: (key, code) =>
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
        tetris\moveDown!
      when "escape"
        os.exit!
      else
        print "Unknown action"
