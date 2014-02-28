importScripts('../base-robot.js')

class TestRobot1 extends BaseRobot
  onIdle: ->
    @turn_turret_left 90
    @move_forwards Math.random! * 200

    turn-val = Math.random! * 30
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
