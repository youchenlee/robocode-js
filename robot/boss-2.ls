importScripts('../base-robot.js')

class Boss2 extends BaseRobot
  onIdle: !->
    @turn_right 10
    @turn_turret_right 180

    @move_forwards 100
    if Math.random! > 0.5
      @turn_right 30
    else
      @turn_left 30

  onWallCollide: !->
    @move_opposide 10
    @turn_left 90

  onHit: !->
    @turn_right 30
    @move_forwards 50

  onEnemySpot: !->
    @shoot!

tr = new Boss2("Boss 2")
