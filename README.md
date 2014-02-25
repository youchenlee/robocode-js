robocode-js
===========

LiveScript (Javascript) implementation of http://gumuz.nl/projects/robojs/

Creating a robot is even simpler

```
importScripts('base-robot.js')

class TestRobot1 extends BaseRobot
    onIdle: ->
        @move_forwards 100
        if Math.random! > 0.5
            @turn_right 30
        else
            @turn_left 30

    onWallCollide: ->
        @move_backwards 10
        @turn_left 90

bot = new TestRobot1("My first test robot")

```

TODO: need more bot actions and callback events
