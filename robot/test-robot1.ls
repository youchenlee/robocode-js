importScripts('../base-robot.js')

class TestRobot1 extends BaseRobot
  onIdle: ->
    if @my-var-enemy
      if (@me.angle + @me.angle_turret % 360 ) > @my-var-enemy.[0].angle
        @turn_turret_left 45
      else
        @turn_turret_right 45
      @shoot!
    else
      @turn_turret_left 35
      @turn_left 35
      @move_forwards Math.random! * 200

    @my-var-enemy = undefined

  onWallCollide: ->
    @move_opposide 10
    @turn_left 90

  onHit: ->
    #@turn_turret_right 180
    @move_forwards 40
    @turn_left 40
    @move_forwards 40
    @turn_right 40
    @yell "No! I'm hit!"

  onEnemySpot: ->
    @my-var-enemy = @enemy-spot
    @shoot!
    @yell "Enemy spotted!"

tr = new TestRobot1("My first test robot")
