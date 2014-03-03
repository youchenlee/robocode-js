robocode-js
===========
LiveScript (Javascript) implementation of Robocode. Original from http://gumuz.nl/projects/robojs/

 * I created this project for students in [NCCUCS Software Engineering Course (2014)](http://nccucs-se.github.io/) to learn teamwork in git/github. For more information, please refer to http://nccucs-se.github.io/
 * The final idea is to donate this project to [g0v](http://g0v.tw/), for begineers of open source developers to learn git/github in a fun way.
 * The project is now lack of UI, to fight your own robots, you may need to edit the HTML pages to add your robot scripts to it.
 * Currently the copyright of this project is on [Gumuz](http://gumuz.nl/projects/robojs/). Thought I rewrite most of the codes, but the first version of my LiveScript codes are converted from CoffeeScript, which is the work from [Gumuz](http://gumuz.nl/projects/robojs/). I'm still waiting for the Author to provide a source code License.

 * Demo: http://youchenlee.github.io/robocode-js/
 * Report issues to https://github.com/youchenlee/robocode-js/issues


Creating a robot is even simpler

```
importScripts('base-robot.js')

class TestRobot1 extends BaseRobot
  onIdle: ->
    @turn_turret_left 30
    @move_forwards 100
      if Math.random! > 0.5
        @turn_right 30
      else
        @turn_left 30

  onWallCollide: ->
    @move_opposide 10
    @turn_left 90

  onEnemySpot: ->
    @shoot!

  onHit: ->
    for d from 20 to 30
      @move_backwards d
      @turn_right d

bot = new TestRobot1("My test robot")

```

Advanced:
```
  onEnemySpot: ->
    @my-var = @enemy-spot # remember it
    @shoot!
```

TODO: need more bot actions and callback events


## Robot HOWTO

### Available info:

 * Self info
   * @me.id
   * @me.x
   * @me.y
   * @me.hp
   * @me.angle - Your current angle (tank angle + turret angle)
   * @me.tank_angle
   * @me.turret_angle

 * Enemy info
   * @enemy-spot[N].id
   * @enemy-spot[N].hp
   * @enemy-spot[N].angle - The angle (direction) to the enemy

### Sequential Actions:

 * @turn_left (angle)
 * @turn_right (angle)
 * @move_forwards (distance)
 * @move_backwards (distance)
 * @move_opposide (distance) - This action can only be used in OnWallCollide()

### Parallel Actions:

 * @turn_turret_left (angle)
 * @turn_turret_right (angle)
 * @shoot()
 * @yell(message)

### Events:

 * OnIdle() - Triggered when idle (MUST implement)
 * OnWallCollide() - When the tank collide the wall
 * OnHit() - When hit by a bullet
 * OnEnemySpot() - When your turret is directly face to an enemy (there seems no reason not to fire!)

## Credits
Special thanks to Martain Chen, Tim Chen, BinBin Tasi, Sid Wang, Louh Ren-Shan and 豬大寶 for mathematic support.
