
--{graphics: g, :timer} = love

import graphics, timer from love
import random, randomseed, floor from math

import dump from require "pl.pretty"

class Tile
  @width  = 25
  @height = 25

  new: (x,y,c) =>
    @color = c or 0
    @x = x
    @y = y

  isClear: =>
    @color == 0

  isBlock: =>
    @color ~= 0

  draw: =>
    graphics.draw(tiles[@color], @x, @y)

class Block
  types = {
    {
      {1, 2, 10, 11}, {0, 10, 11, 21}
    },
    {
      {0, 1, 11, 12}, {1, 10, 11, 20}
    },
    {
      {0, 1, 2, 12}, {0, 10, 11, 12}, {0, 1, 10, 20}, {1, 11, 20, 21}
    },
    {
      {0, 1, 2, 10}, {0, 1, 11, 21}, {2, 10, 11, 12}, {0, 10, 20, 21}
    },
    {
      {1, 10, 11, 12}, {0, 10, 11, 20}, {0, 1, 2, 11}, {1, 10, 11, 21}
    },
    {
      {0, 1, 2, 3}, {0, 10, 20, 30}
    }
  }

  new: =>
    @gameGrid    = nil
    @type        = random #types
    @width       = if @type == 6 then 4 else 3 -- All blocks are width 3 except bar (#6)
    @pivot       = 0  -- Top-left corner tile of block within grid
    @tiles       = {}
    @orientation = 1 -- Use 4 orientations for each block (use mod2 for step-up/down and bar)

  getWidth: (btype, orientation) =>
    t = btype or @type
    o = orientation or @orientation
    max = 1
    for val in *types[t][o]
      v = (val%10)+1
      max = v if v > max
    max

  -- Will use @pivot and @orientation if respective params omitted
  getPlacement: (pivot, orientation) =>
    p = pivot or @pivot
    o = orientation or @orientation

    if p == @pivot and o == @orientation
      return @tiles -- Current position

    return [p+delta for delta in *types[@type][o]]

  nextOrientation: =>
    return (@orientation >= #types[@type] and 1 or @orientation + 1)

  -- Will use currently attached @grid if no grid param given
  canBePlacedAt: (pivot, grid, rotate) =>
    g = grid == nil and @gameGrid or grid
    r = if rotate then @nextOrientation! else @orientation

    return false, nil if not g

    -- Get list of tile indices that need to be free for attachment
    neededTiles = @getPlacement pivot, r

    -- Check for needed room to add block to grid 
    for ti in *neededTiles
      if ti > #g
        print "Can't place block at #{pivot}! That would move the block off the bottom of the map!"
        return false
      if g[ti]\isBlock! 
        print "Can't place block at #{pivot}! There is a block in the way." 
        return false

    return true, neededTiles, r

  fillTiles: (color) =>
    c = color or @type
    for ti in *@tiles
      @gameGrid[ti].color = c

  clearTiles: =>
    @fillTiles 0

  updateTiles: (newTiles) =>
    @clearTiles!
    @tiles = newTiles
    @fillTiles!

  rotate: =>
    @clearTiles!
    isLegal, neededTiles, orientation = @canBePlacedAt(@pivot, nil, true)

    if not isLegal
      print "That is not a legal rotation!"
      @fillTiles!
      return false

    @orientation = orientation
    @tiles = neededTiles
    @updateTiles(neededTiles)
    true

  moveTo: (p) =>
    @clearTiles!
    isLegal, neededTiles = @canBePlacedAt(p)
    
    if not isLegal
      print "That is not a legal move!"
      @fillTiles!
      return false
    
    @pivot = p
    @updateTiles(neededTiles)
    true

  moveLeft: =>
    if @pivot % 10 == 1
      print "Refusing to move left..."
      return false

    print "Attempting to move left..."
    return @moveTo(@pivot - 1)

  moveRight: =>
    if (@pivot % 10) + @width > 10
      print "Refusing to move right..."
      return false 
    
    print "Attempting to move right..."
    return @moveTo(@pivot + 1)

  moveDown: =>
    if @pivot > 140
      print "Refusing to move down..."
      return false
    
    print "Attempting to move down..."
    return @moveTo(@pivot + 10)

  attach: (grid, pivot) =>
    -- Enforce that block can only be attached once
    return false if @gameGrid

    -- Verify that the block can be placed in the game
    isLegal, neededTiles = @canBePlacedAt(pivot, grid)
    return false if not isLegal

    -- Set current position and insert tiles comprising block
    @gameGrid = grid
    @pivot    = pivot
    @tiles    = neededTiles

    @fillTiles!

    true   

  drawPreview: (ox, oy) =>
    shape = {} 
    for x, row in ipairs types[@type]
      for y, isFilled in ipairs row
        with Tile(ox + x*Tile.width, oy + y*Tile.height)
          .color = (if isFilled == 1 @type else 0)
          \draw!

-- 10x15 tetris game board
export class Tetris
  addBlock: (b) =>
    if b\attach(@grid, 4)
      @currentBlock = b
      true
    else
      error "GAME OVER!"
      -- false

  new: (x, y) =>
    randomseed timer.getTime!

    @position = { x: x, y: y } -- Rendering position
    @width    = 10 -- width & height in # of tiles
    @height   = 15
    @startp   = 4  -- Where to place new block's pivot
    @grid     = [Tile(@position.x + x*Tile.width, @position.y + y*Tile.height) for y=1,@height for x=1,@width]
    
    @score = 0
    @speed = 1.0
    
    @currentBlock = nil

    @nextBlock = Block!
    @addBlock(@nextBlock)    

  moveLeft: =>
    @currentBlock\moveLeft!
  
  moveRight: =>
    @currentBlock\moveRight!

  moveDown: =>
    @currentBlock\moveDown!

  forceDrop: =>
    while @currentBlock\moveDown!
      print "Continuing to move down..."

  rotate: =>
    @currentBlock\rotate!

  draw: =>
    t\draw! for _,t in ipairs @grid
