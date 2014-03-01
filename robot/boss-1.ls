importScripts('../base-robot.js')

class Boss1 extends BaseRobot

  onIdle: !->
    @shoot!
    @move_forwards 50
    @move_backwards 50
    @turn_turret_right 180
    @shoot!

  onWallCollide: !->
    @move_opposide 10
    @turn_left 90
    @move_forwards 100

  onHit: !->
    @yell "Oops!"
    @move_backwards 100
    @shoot!


  onEnemySpot: !->
    @yell "Fire!"
    @shoot!

tr = new Boss1("Boss 1")
