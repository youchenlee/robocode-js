importScripts('../base-robot.js')

class TestRobot1 extends BaseRobot
  onIdle: ->
    /*
    if @enemy-robots.length > 0
      if @enemy-robots[0].x < @me.x
        @move_forwards 10
      else
        @move_backwards 10
    else
      @shoot!
    */
    @move_forwards Math.random! * 50

    turn-val = Math.random! * 10
    if Math.random! > 0.5
      @turn_left turn-val
    else
      @turn_right turn-val


  onWallCollide: ->
    @move_opposide 10
    @turn_left 90

  onHit: ->
    for x from 20 to 25
      @move_backwards x
      @turn_left x
      @shoot!

  onEnemySpot: ->
    @shoot!

tr = new TestRobot1("My first test robot")
