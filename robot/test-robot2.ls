importScripts('../base-robot.js')

class TestRobot1 extends BaseRobot
  onIdle: ->
    @move_forwards 30
    if Math.random! > 0.5
      @turn_right 30
    else
      @turn_left 30
    @shoot!

  onWallCollide: ->
    @move_backwards 10
    @turn_left 90

tr = new TestRobot1("My first test robot")
