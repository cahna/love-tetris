
{graphics: g, :timer, :mouse, :keyboard} = love

import gettime from require "socket"
import random, randomseed, floor from math

import dump from require "pl.pretty"

class Tile
  @width  = 25
  @height = 25

  new: (x,y) =>
    @color = 0 -- clear
    @isBlock = false
    @x = x
    @y = y

  isClear: =>
    @color == 0

  draw: =>
    g.draw(tiles[@color], @x, @y)

export class Tetris
  @blockTypes = {
    "step-up",
    "step-down",
    "J",
    "L",
    "T",
    "bar"
  }

  addNextBlock: (btype) =>
    tileIndices = switch btype
      when 1
        {5, 6, 14, 15} -- _|^ 'step-up'
      when 2
        {4, 5, 15, 16} -- ^|_ 'step-down'
      when 3
        {4, 5, 6, 16} -- ^^|
      when 4
        {4, 5, 6, 14} -- |^^
      when 5
        {5, 14, 15, 16} -- _|_ 'T shape'
      when 6
        {4, 5, 6, 7} -- ^^^^ 'bar'
      else
        error "Bad block type"

    -- Check if block can be added to game (if not, GAME OVER!)
    for ti in *tileIndices
      unless @grid[ti]\isClear! 
        error "Game Over!" 

    -- Add block to the game
    --with @currentBlock
      --.type = btype
      --.position = { x: 5, y: 5 }
      --.tiles = tileIndices
      --.orientation = 1

    for ti in *tileIndices
      with @grid[ti]
        .color = btype
        .isBlock = true

  new: (x, y) =>
    seed = "#{gettime!}"\gsub("%.", "")
    seed = tonumber(seed\sub(seed\len! / 2))
    randomseed seed

    @position = { x: x, y: y }
    @score    = 0
    @speed    = 1.0
    @width    = 10
    @height   = 15
    
    @startpos  = floor @width / 2
    @grid      = [Tile(@position.x + x*Tile.width, @position.y + y*Tile.height) for y=1,@height for x=1,@width]
    dump @grid
    @nextBlock = random #@@blockTypes
    @addNextBlock(@nextBlock)
    @currentBlock = {
      type: 0,
      position: { x: 0, y: 0 }
      tiles: {}
      orientation: 0
    }
  
  isLeftMoveAllowed: =>
    for i,t in ipairs @grid 
      if t.isBlock and @grid[i-1] ~= nil
        return false if i%10 <= 1
    return true

  isRightMoveAllowed: =>
    for i,t in ipairs @grid 
      if t.isBlock and @grid[i+1] ~= nil
        return false if i%10 >= 10
    true    

  doMove: (x) =>
    dump @
    assert(x == 1 or x == -1)
    for i,t in ipairs @grid 
      if t.isBlock and @grid[i+x] ~= nil
        with @grid[i+x]
          .color = t.color
          .isBlock = true
        with t
          .color = 0
          .isBlock = false

  moveLeft: =>
    if @isLeftMoveAllowed!
      @doMove(-1) 
  
  moveRight: =>
    if @isRightMoveAllowed!
      @doMove(1) 

  doit = true
  stepDown: =>
    @addNextBlock(@nextBlock) if doit
    doit = false
    @nextBlock = random #@@blockTypes

  draw: =>
    t\draw! for t in *@grid
