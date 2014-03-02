# TODO Hit another bot detection
# TODO hp
# TODO show bot name
# TODO turn turret


$SET_TIMEOUT = 5
$BULLET_SPEED = 3
$HP = 20
$ROBOT_RADIUS = 10 # r
$MAX_BULLET = 5
$BULLET_INTERVAL = 15
$YELL_TIMEOUT = 50

$SEQUENTIAL_EVENTS = [\move_forwards \move_backwards \turn_left \turn_right \move_opposide]
$PARALLEL_EVENTS = [\shoot \turn_turret_left \turn_turret_right \turn_radar_left \turn_radar_right]

$CANVAS_DEBUG = false


# assets
class AssetsLoader
  (@assets, @callback) ->
    @_resources = 0
    @_resources_loaded = 0

    for name, uri of assets
      @_resources++
      @assets[name] = new Image()
      @assets[name].src = uri
    for name, uri of assets
      @assets[name].onload = ~>
        @_resources_loaded++
        if @_resources_loaded is @_resources and typeof @callback is 'function'
          @callback()

  is_done_loading: ->
    @_resources_loaded is @_resources
  get: (asset_name) ->
    @assets[asset_name]


# utility functionsv
degrees-to-radians = (degrees) ->
  # convert degrees to radians
  degrees * (Math.PI/180)

radians-to-degrees = (radians) ->
  radians * (180/Math.PI)


euclid_distance = (x1, y1, x2, y2) ->
  # calculate euclidean distance between 2 points
  Math.sqrt(Math.pow(x1 - x2, 2) + Math.pow(y1 - y2, 2))

in_rect = (x1,y1, x2, y2, width, height) ->
  # calculate if point(x1,y1) is in rect(x2, y2, width, height)
  (x2+width) > x1 > x2 and (y2+height) > y1 > y2


class Robot
  @battlefield-width = 0
  @battlefield-height = 0

  (@x, @y, @source) ->
    @tank_angle = Math.random! * 360
    @turret_angle = Math.random! * 360
    @radar_angle = Math.random! * 360
    @bullet = []
    @events = {}
    @status = {}
    @hp = $HP
    @id = 0
    @is-hit = false
    @enemy-spot = []
    @me = {}
    @yell-ts = 0
    @is-yell = false
    @yell-msg = undefined
    @bullet-ts = 0

    @worker = new Worker(source)
    @worker.onmessage = (e) ~>
      @receive(e.data)

  @set-battlefield = (width, height) ->
    @@battlefield-width = width
    @@battlefield-height = height

  move: (distance) ->
    new-x = @x + distance * Math.cos(degrees-to-radians(@tank_angle));
    new-y = @y + distance * Math.sin(degrees-to-radians(@tank_angle));

    if in_rect new-x, new-y, 15, 15, @@battlefield-width - 15, @@battlefield-height - 15
      # hit the wall
      logger.log \not-wall-collide
      @status.wall-collide = false
      @x = new-x
      @y = new-y
    else
      logger.log \wall-collide
      @status.wall-collide = true

  turn: (degrees) !->
    @tank_angle += degrees
    @tank_angle = @tank_angle % 360
    if @tank_angle < 0
      @tank_angle = @tank_angle + 360

  turn-turret: (degrees) !->
    @turret_angle += degrees
    @turret_angle = @turret_angle % 360
    if @turret_angle < 0
      @turret_angle = @turret_angle + 360

  yell: (msg) !->
    @is-yell = true
    @yell-ts = 0
    @yell-msg = msg

  receive: (msg) ->
    event = JSON.parse(msg)
    #loggernnnn.log "receive #{msg}"
    if event.log != undefined
      logger.log event.log
      return

    if event.action == "shoot"
      if (@bullet.length >= $MAX_BULLET) || (@bullet-ts < $BULLET_INTERVAL)
        @send-callback event["event_id"]
        return
      @bullet-ts = 0
      @bullet.push {x: @x, y: @y, direction: @tank_angle + @turret_angle }
      @send-callback event["event_id"]
      return

    # remove duplicate events
    # FIXME improve performance
    if event.action == "turn_turret_left"
      for ev in @events
        if ev.action == "turn_turret_left"
          @send-callback event["event_id"]
          return

    # FIXME improve performance
    if event.action == "turn_turret_right"
      for ev in @events
        if ev.action == "turn_turret_right"
          @send-callback event["event_id"]
          return

    if event.action == "yell"
      if @yell-ts == 0
        @yell event.msg
      @send-callback event["event_id"]
      return

    event["progress"] = 0
    event_id = event["event_id"]
    logger.log "got event " + event_id + "," +event.action
    @events[event_id] = event

  send: (msg_obj) ->
    @worker.postMessage(JSON.stringify(msg_obj))

  get-enemy-robots: ->
    enemy = []
    for r in Battle.robots
      if r.id != @id
        enemy.push r
    enemy

  send-enemy-spot: ->
    logger.log \send-enemy-spot
    @send({
      "action": "enemy-spot",
      "me": @me,
      "enemy-spot": @enemy-spot,
      "status": @status
    })

  send-interruption: ->
    logger.log \send-interruption
    @send({
      "action": "interruption",
      "me": @me,
      #"enemy-robots": @get-enempy-robots!,
      "status": @status
    })

  send-callback: (event_id) ->
    @send({
      "action": "callback",
      "me": @me,
      "event_id": event_id,
      #"enemy-robots": @get-enemy-robots!,
      "status": @status
    })

  check-enemy-spot: ->
    @enemy-spot = []
    is-spot = false
    for enemy-robot in @get-enemy-robots!
      my-angle = (@tank_angle + @turret_angle) % 360
      if my-angle < 0
        my-angle = 360 + my-angle
      my-radians = degrees-to-radians(my-angle)
      enemy-position-radians = Math.atan2 enemy-robot.y - @.y, enemy-robot.x - @.x
      distance = euclid_distance @.x, @.y, enemy-robot.x, enemy-robot.y
      radians-diff = Math.atan2 $ROBOT_RADIUS, distance

      # XXX a dirty shift
      #my-radians = Math.abs my-radians
      if my-radians > Math.PI
        my-radians -= ( 2*Math.PI )
      if my-radians < -Math.PI
        my-radians += (2*Math.PI)

      max = enemy-position-radians + radians-diff
      min = enemy-position-radians - radians-diff

      # console.log "max = #{max}"
      # console.log "min = #{min}"
      # console.log "my-radians = #{my-radians}"
      # console.log "diff =" + radians-diff

      if my-radians >= min and my-radians <= max
        enemy-position-degrees = radians-to-degrees enemy-position-radians
        if enemy-position-degrees < 0
          enemy-position-degrees = 360 + enemy-position-degrees
        @enemy-spot.push {id: enemy-robot.id, angle: enemy-position-degrees, distance: distance, hp: enemy-robot.hp, x: enemy-robot.x, y: enemy-robot.y}
        is-spot = true
    if is-spot
      return true
    return false



  update-bullet: ->
    for id, b of @bullet
      b.x += $BULLET_SPEED * Math.cos degrees-to-radians b.direction
      b.y += $BULLET_SPEED * Math.sin degrees-to-radians b.direction
      bullet_wall_collide = !in_rect b.x, b.y, 2, 2, @@battlefield-width - 2, @@battlefield-height - 2
      if bullet_wall_collide
        b = null
        @bullet.splice id, 1
        continue

      for enemy_robot in @get-enemy-robots!
        robot_hit = (euclid_distance(b.x, b.y, enemy_robot.x, enemy_robot.y) < 20)

        if robot_hit
          enemy_robot.hp -= 3
          enemy_robot.is-hit = true
          Battle.explosions.push({
            x: enemy_robot.x,
            y: enemy_robot.y,
            progress: 1
          })
          b = null
          @bullet.splice id, 1
          break
        # end if robot_hit
      # end for enemy_robot
    true

  update: !->
    @me = {angle: (@tank_angle + @turret_angle) % 360, tank_angle: @tank_angle, turret_angle: @turret_angle, id: @id, x: @x, y: @y, hp: @hp}
    has_sequential_event = false
    @status = {}
    is-turning-turret = false

    if @bullet-ts == Number.MAX_VALUE
      @bullet-ts = 0
    else
      @bullet-ts++

    if @bullet.length > 0
      @update-bullet!


    if @is-hit
      @events = {}
      @status.is-hit = true
      @is-hit = false
      @send-interruption!
      return

    if @check-enemy-spot!
      #@events = {}
      @send-enemy-spot!

    for event_id, event of @events
      if $SEQUENTIAL_EVENTS.indexOf(event.action) != -1
        if has_sequential_event
          # we already have a sequential event in the queue
          continue
        has_sequential_event = true

      logger.log "events[#{event_id}] = {action=#{event.action},progress=#{event.progress}}"

      if event["amount"] <= event["progress"]
        # the action is done
        @send-callback event["event_id"]
        delete @events[event_id]
      else
        switch event["action"]
          when "move_forwards"
            event["progress"]++
            @move(1)
            if @status.wall-collide
              @action-to-collide = 1 #forward
              @events = {}
              @send-interruption!
              break

          when "move_backwards"
            event["progress"]++
            @move(-1)
            if @status.wall-collide
              @action-to-collide = -1 #backward
              @events = {}
              @send-interruption!
              break

          when "move_opposide"
            event["progress"]++
            @move(-@action-to-collide)
            if @status.wall-collide
              @action-to-collide = -@action-to-collide
              @events = {}
              @send-interruption!
              break

          when "turn_left"
            event["progress"]++
            @turn(-1)

          when "turn_right"
            event["progress"]++
            @turn(1)

          when "turn_turret_left"
            if is-turning-turret
              continue
            event["progress"]++
            @turn-turret -1
            is-turning-turret = true

          when "turn_turret_right"
            if is-turning-turret
              continue
            event["progress"]++
            @turn-turret 1
            is-turning-turret = true

        # end switch
      # end if / else
    # end for
  # end update()

class Battle
  @robots = []
  @explosions = []
  @enable-div-debug = false
  (@ctx, @width, @height, sources) ->
    @@explosions = []
    Robot.set-battlefield @width, @height
    robot-appear-pos-y = @height / 2
    robot-appear-pos-x-inc = @width / 3
    robot-appear-pos-x = robot-appear-pos-x-inc
    id = 0
    # FIXME support more than 2 robots
    for source in sources
      r = new Robot(robot-appear-pos-x, robot-appear-pos-y, source)
      r.id = id
      @@robots.push r
      id++
      robot-appear-pos-x += robot-appear-pos-x-inc
      if id >= 2
        robot-appear-pos-x = Math.random! * (@width - 100 + 20 )

    @assets = new AssetsLoader({
      "body": 'img/body.png',
      "body-red": 'img/body-red.png',
      "turret": 'img/turret.png'
      "radar": 'img/radar.png',
      'explosion1-1': 'img/explosion/explosion1-1.png',
      'explosion1-2': 'img/explosion/explosion1-2.png',
      'explosion1-3': 'img/explosion/explosion1-3.png',
      'explosion1-4': 'img/explosion/explosion1-4.png',
      'explosion1-5': 'img/explosion/explosion1-5.png',
      'explosion1-6': 'img/explosion/explosion1-6.png',
      'explosion1-7': 'img/explosion/explosion1-7.png',
      'explosion1-8': 'img/explosion/explosion1-8.png',
      'explosion1-9': 'img/explosion/explosion1-9.png',
      'explosion1-10': 'img/explosion/explosion1-10.png',
      'explosion1-11': 'img/explosion/explosion1-11.png',
      'explosion1-12': 'img/explosion/explosion1-12.png',
      'explosion1-13': 'img/explosion/explosion1-13.png',
      'explosion1-14': 'img/explosion/explosion1-14.png',
      'explosion1-15': 'img/explosion/explosion1-15.png',
      'explosion1-16': 'img/explosion/explosion1-16.png',
      'explosion1-17': 'img/explosion/explosion1-17.png'
    })

  run: ->
    @send_all({
      "action": "run"
    })
    @_loop!

  _loop: ->
    @_update!
    @_draw!
    if @@enable-div-debug
      @_update-debug!

    setTimeout(~>
      @_loop!
    , $SET_TIMEOUT)

  send_all: (msg_obj) ->
    for robot in @@robots
      robot.send(msg_obj)

  _update: !->
    for robot in @@robots
      if robot
        robot.update!

  _update-debug: !->
    text = ""
    for robot in @@robots
      ev = JSON.stringify robot.events, null, "\t"
      me = JSON.stringify robot.me, null, "\t"
      bullet = JSON.stringify robot.bullet, null, "\t"
      enemy-spot = JSON.stringify robot.enemy-spot, null, "\t"
      text += "#{robot.id}:\n" + "me:\n#{me}\n" + "events:\n#{ev}\nbullet:\n#{bullet}\nenemy-spot:#{enemy-spot}\n"

    $ \#debug .html text

  _draw: !->
    @ctx.clearRect(0, 0, @width, @height)

    for id, robot of @@robots
      # draw robot
      body = \body
      if robot.id == 0
        body = \body-red

      # TODO stop the game
      if robot.hp <= 0
        Battle.explosions.push({
          x: robot.x,
          y: robot.y,
          progress: 1
        })
        robot = {}
        delete @@robots[id]
        @@robots.splice id, 1
        continue

      @ctx.save!

      @ctx.translate(robot.x, robot.y)

      # draw text
      @ctx.textAlign = "left";
      @ctx.textBaseline = "top";
      text-x = 20
      text-y = 20
      if (@width - robot.x) < 100
        text-x = - text-x
        @ctx.textAlign = "right"
      if (@height - robot.y) < 100
        text-y = - text-y
      text = "#{robot.hp}/#{$HP}"

      if robot.is-yell and (robot.yell-ts < $YELL_TIMEOUT)
        @ctx.font = "17px Verdana"
        text = robot.yell-msg
        robot.yell-ts++
      else
        robot.yell-ts = 0
        robot.is-yell = false

      if $CANVAS_DEBUG
        text += " turret_angle#{robot.turret_angle}"
      @ctx.fillText(text, text-x, text-y);



      @ctx.rotate(degrees-to-radians(robot.tank_angle))
      @ctx.drawImage(@assets.get(body), -(38/2), -(36/2), 38, 36)
      @ctx.rotate(degrees-to-radians(robot.turret_angle))
      @ctx.drawImage(@assets.get("turret"), -(54/2), -(20/2), 54, 20)
      @ctx.rotate(degrees-to-radians(robot.radar_angle))
      @ctx.drawImage(@assets.get("radar"), -(16/2), -(22/2), 16, 22)
      @ctx.restore!

      if robot.bullet.length > 0
        for b in robot.bullet
          @ctx.save!
          @ctx.translate b.x, b.y
          @ctx.rotate(degrees-to-radians(b.direction))
          @ctx.fillRect -3, -3, 6, 6
          @ctx.restore!

    for i in @@explosions
      explosion = @@explosions.pop!
      if explosion.progress <= 17
        @ctx.drawImage @assets.get("explosion1-" + parseInt(explosion.progress)), explosion.x - 64, explosion.y - 64, 128, 128
        explosion.progress += 1
        @@explosions.unshift explosion


# export objects
window.Battle = Battle

window.triggerDebug = ->
  if window.Battle.enable-div-debug
    window.Battle.enable-div-debug = false
    $ \#debug .html ""
  else
    window.Battle.enable-div-debug = true
  true
