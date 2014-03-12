robocode-js
===========
LiveScript (Javascript) implementation of Robocode. Original from http://gumuz.nl/projects/robojs/

 * I created this project for students in [NCCUCS Software Engineering Course (2014)](http://nccucs-se.github.io/) to learn teamwork in git/github. For more information, please refer to http://nccucs-se.github.io/
 * The final idea is to donate this project to [g0v](http://g0v.tw/), for begineers of open source developers to learn git/github in a fun way.
 * The project is now lack of UI, to fight your own robots, you may need to edit the HTML pages to add your robot scripts to it.

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


## Build from LiveScript

 * To compile from LiveScript, first, install `nodejs` from http://nodejs.org/
 * Second, make sure you got `npm` and `run` command exetable on your console. (If you are on MS Windows, make sure the PATH environment variable is setting correct to run `npm` and `node`)
 * If you have `make` command, i.e. on Linux or Mac OSX, just go to the repository root directory and type `make`, everything will be done.
 * If you do not have `make` command, run the following command manually. (haven't test on MS Windows.)
   * `npm install`
   * `node_modules/.bin/lsc -c *.ls`
   * `node_modules/.bin/lsc -c -b log.ls`
   * `node_modules/.bin/lsc -c robot/*.ls`
 * Done. Use your browser to open `index.html` file.

## Run directly without compiling anything

 * switch to `gh-pages` branch, you will got everything to run this program.

   `git checkout gh-pages`

## Note

 * google-chrome is not allow to run a web worker of a local javascript file. Please use the `--allow-file-access-from-files` option to start chrome. If you run this project on a web server, this won't be a problem.

## Licensing

 * The first version of my LiveScript codes are converted from CoffeeScript, which is the work from Guyon at  [Gumuz](http://gumuz.nl/projects/robojs/). Guyon has agreed to release this project in a opensource license, but we havn't decide the license yet. It will be likely to be MIT. I'll update later.

 * All the arts in this project are under the Eclipse Public License (EPL).


## Credits

Special thanks to Martain Chen, Tim Chen, BinBin Tasi, Sid Wang, Louh Ren-Shan and 豬大寶 for mathematic support.
