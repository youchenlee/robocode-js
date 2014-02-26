importScripts('../base-robot.js')

class TestRobot1 extends BaseRobot
  onIdle: ->
    @shoot!
    @move_forwards Math.random! * 50

    turn-val = Math.random! * 10
    if Math.random! > 0.5
      @turn_left turn-val
    else
      @turn_right turn-val

  onWallCollide: ->
    @move_backwards 10
    @turn_left 90

tr = new TestRobot1("My first test robot")
