importScripts('../base-robot.js')

class Boss0 extends BaseRobot

  onIdle: !->
    @turn_turret_right 45

  onWallCollide: !->

  onHit: !->
    @yell "Oops!"

  onEnemySpot: !->
    @yell "Fire!"
    @shoot!

tr = new Boss0("Boss 0")
