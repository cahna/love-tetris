
{graphics: g, :timer, :mouse, :keyboard} = love
{floor: f, min: _min, :cos, :sin, :abs}  = math

require "ui"

export MIN_WAIT  = 120
export FULL_STEP = 1000

local ui

love.load = () ->
  export background = g.newImage("resources/windowbg.png")
  export tiles = {i, g.newImage "resources/tile#{i}.png" for i = 0, 8}
  export mainFont = g.newFont("resources/UbuntuMono-BI.ttf", 18)

  ui = Game!
  ui\attach love

