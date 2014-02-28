importScripts('../base-robot.js')

class TestRobot2 extends BaseRobot
  onIdle: ->
    @turn_left 5
    /*
    if @me.x < 200
      @move_forwards 200
    else
      @move_backwards 200
    */

    @move_forwards 30
    if Math.random! > 0.5
      @turn_right 30
    else
      @turn_left 30



  onWallCollide: ->
    @move_opposide 10
    @turn_left 90

  onHit: ->
    @turn_right 30
    @move_forwards 50

  onEnemySpot: ->
    @shoot!

tr = new TestRobot2("My first test robot")
