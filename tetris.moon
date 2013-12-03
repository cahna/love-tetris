
--{graphics: g, :timer} = love

import graphics, timer from love
import random, randomseed, floor from math

import dump from require "pl.pretty"

class Tile
  @width  = 25
  @height = 25

  new: (x,y,c = 0) =>
    @color = c
    @x = x
    @y = y

  isClear: =>
    @color == 0

  isFilled: =>
    @color ~= 0

  draw: =>
    graphics.draw(tiles[@color], @x, @y)

class Block
  types = {
    { -- step-up
      {1, 2, 10, 11}, {0, 10, 11, 21}
    },
    { -- step-down
      {0, 1, 11, 12}, {1, 10, 11, 20}
    },
    { -- J
      {0, 1, 2, 12}, {0, 10, 11, 12}, {0, 1, 10, 20}, {1, 11, 20, 21}
    },
    { -- L
      {0, 1, 2, 10}, {0, 1, 11, 21}, {2, 10, 11, 12}, {0, 10, 20, 21}
    },
    { -- T
      {1, 10, 11, 12}, {0, 10, 11, 20}, {0, 1, 2, 11}, {1, 10, 11, 21}
    },
    { -- bar
      {0, 1, 2, 3}, {0, 10, 20, 30}
    },
    {
      {0, 1, 10, 11}
    }
  }

  new: =>
    @gameGrid    = nil
    @type        = random #types
    --@width       = if @type == 6 then 4 else 3 -- All blocks are width 3 except bar (#6)
    @pivot       = 0  -- Top-left corner tile of block within grid
    @tiles       = {}
    @orientation = 1 -- Use 4 orientations for each block (use mod2 for step-up/down and bar)

  getWidth: (t = @type, o = @orientation) =>
    max = 0
    for val in *types[t][o]
      v = (val%10)+1
      max = v if v > max
    max

  -- Will use @pivot and @orientation if respective params omitted
  getPlacement: (p = @pivot, ori = @orientation) =>
    if p == @pivot and ori == @orientation
      return @tiles -- Current position

    return [p+delta for delta in *types[@type][ori]]

  nextOrientation: =>
    return (@orientation >= #types[@type]) and 1 or @orientation + 1

  -- Will use currently attached @grid if no grid param given
  canBePlacedAt: (pivot, grid = @gameGrid, ori = @orientation) =>
    return false if not grid

    -- Get list of tile indices that need to be free for attachment
    neededTiles = @getPlacement pivot, ori

    -- Check for needed room to add block to grid 
    for ti in *neededTiles
      if ti > #grid
        print "Can't place block at #{pivot}! That would move the block off the bottom of the map!"
        return false
      if grid[ti]\isFilled! 
        print "Can't place block at #{pivot}! There is a block in the way." 
        return false

    return true, neededTiles, ori

  fillTiles: (color = @type) =>
    for ti in *@tiles
      @gameGrid[ti].color = color

  clearTiles: =>
    @fillTiles 0

  updateTiles: (newTiles) =>
    @clearTiles!
    @tiles = newTiles
    @fillTiles!

  rotate: =>
    newOri = @nextOrientation!

    isTooWide    = (@pivot % 10) + @getWidth(@type, newOri) > 11
    isBarTooWide = @getWidth! == 1 and (@pivot % 10 >=8) or (@pivot % 10 == 0) 

    if isTooWide or isBarTooWide
      print "Refusing to rotate at #{@pivot} which is #{@getWidth(@type, newOri)} wide. Block would be too wide..."
      @fillTiles!
      return 

    @clearTiles!
    isLegal, neededTiles, ori = @canBePlacedAt(@pivot, nil, newOri)

    if not isLegal
      print "That is not a legal rotation!"
      @fillTiles!
      return false

    @orientation = ori
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
    if (@getWidth! == 1 and (@pivot-1)%10 == 9) or (@pivot % 10) + @getWidth! > 10
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
  lineMultiplier = { 40, 100, 300, 1200 }

  addBlock: (b) =>
    if b\attach(@grid, 4)
      @currentBlock = b
      true
    else
      @gameOver = true
      false -- Game over

  new: (x, y, level = 1) =>
    randomseed timer.getTime!

    -- Rendering Stuff
    @position = { x: x, y: y } -- Rendering position
    @startp   = 4              -- Where to place new block's pivot
    @width    = 10             -- width & height in # of tiles
    @height   = 15
    @grid     = [Tile(@position.x + x*Tile.width, @position.y + y*Tile.height) for y=1,@height for x=1,@width]
    
    -- Scoring stuff
    @level        = level
    @score        = 0
    @linesCleared = 0
    @speed        = 1.0
    @gameOver     = false
    
    @currentBlock = nil
    @nextBlock    = Block!

    @addBlock(@nextBlock)
    @nextBlock = Block!

  clearLines: =>
    g = @grid
    lc = 0
    
    -- Clear lines by shifting tile contents down at each filled line
    for i=141, 1, -10
      while #[1 for off=0,9 when g[i+off]\isFilled!] == 10
        print "Line #{i} is complete."
        lc += 1
        for j=i, 11, -10
          g[j+x].color = g[j-10+x].color for x=0, 9

    if lc > 0
      @score += lineMultiplier[lc] * (@level + 1)
      @linesCleared += lc

  moveLeft: =>
    @currentBlock\moveLeft!
  
  moveRight: =>
    @currentBlock\moveRight!

  moveDown: =>
    success = @currentBlock\moveDown!
    unless success
      @clearLines!
      @addBlock(@nextBlock)
      @nextBlock = Block!
    success

  forceDrop: =>
    while @moveDown!
      print "Continuing to move down..."

  rotate: =>
    @currentBlock\rotate!

  draw: =>
    t\draw! for _,t in ipairs @grid
