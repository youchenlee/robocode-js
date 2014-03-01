importScripts('../base-robot.js')

class MyRobot extends BaseRobot

  onIdle: !->
    @move_forwards 50
    @turn_turret_left 10
    @turn_right 90

  onWallCollide: !->
    @move_opposide 10
    @turn_left 90

  onHit: !->
    @yell "Oops!"

  onEnemySpot: !->
    @yell "Fire!"
    @shoot!

tr = new MyRobot("MyRobot")
