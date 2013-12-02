
{graphics: g, :timer, :mouse, :keyboard} = love
{floor: f, min: _min, :cos, :sin, :abs}  = math

require "ui"

import dump from require "pl.pretty"

local ui

love.load = () ->
  export background = g.newImage("resources/windowbg.png")
  export tiles = {i, g.newImage "resources/tile#{i}.png" for i = 0, 7}
  ui = Game!
  ui\attach love

