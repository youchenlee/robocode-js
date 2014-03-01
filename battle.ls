# TODO Hit another bot detection
# TODO hp
# TODO show bot name
# TODO turn turret


$SET_TIMEOUT = 10
$BULLET_SPEED = 3
$HP = 20
$ROBOT_RADIUS = 10 # r

$SEQUENTIAL_EVENTS = [\move_forwards \move_backwards \turn_left \turn_right \move_opposide]
$PARALLEL_EVENTS = [\shoot \turn_turret_left \turn_turret_right \turn_radar_left \turn_radar_right]

$CANVAS_DEBUG = false
$DIV_DEBUG = false


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
    @angle = 0
    @turret_angle = 0
    @radar_angle = Math.random()*360
    @bullet = null
    @events = {}
    @status = {}
    @hp = $HP
    @id = 0
    @is-hit = false
    @enemy-spot = []
    @me = {}

    @worker = new Worker(source)
    @worker.onmessage = (e) ~>
      @receive(e.data)

  @set-battlefield = (width, height) ->
    @@battlefield-width = width
    @@battlefield-height = height

  move: (distance) ->
    new-x = @x + distance * Math.cos(degrees-to-radians(@angle));
    new-y = @y + distance * Math.sin(degrees-to-radians(@angle));

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
    @angle += degrees
    @angle = @angle % 360

  turn-turret: (degrees) !->
    @turret_angle += degrees
    @turret_angle = @turret_angle % 360

  receive: (msg) ->
    event = JSON.parse(msg)
    #logger.log "receive #{msg}"
    if event.log != undefined
      logger.log event.log
      return
    if event.action == "shoot" && @bullet
      @send-callback event["event_id"]
      return
    if event.action == "shoot"
      @bullet = {
        x: @x,
        y: @y,
        direction: @angle + @turret_angle
      }
      @send-callback event["event_id"]
      return

    # FIXME improve performance
    if event.action == "turn_turret_left"
      for ev in @events
        if ev.event == "turn_turret_left"
          return

    # FIXME improve performance
    if event.action == "turn_turret_right"
      for ev in @events
        if ev.event == "turn_turret_right"
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
    for enemy-robot in @get-enemy-robots!
      my-angle = (@angle + @turret_angle) % 360
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
        @enemy-spot.push {id: enemy-robot.id, angle: enemy-position-degrees, distance: distance, hp: enemy-robot.hp}
    if @enemy-spot.length > 0
      return true
    return false



  update-bullet: ->
    @bullet.x += $BULLET_SPEED * Math.cos degrees-to-radians @bullet.direction
    @bullet.y += $BULLET_SPEED * Math.sin degrees-to-radians @bullet.direction
    bullet_wall_collide = !in_rect @bullet.x, @bullet.y, 2, 2, @@battlefield-width - 2, @@battlefield-height - 2
    if bullet_wall_collide
      @bullet = null
      return true

    for enemy_robot in @get-enemy-robots!
      # FIXME skip my own robot
      #if enemy_robot.id == @id
      #  continue

      robot_hit = (euclid_distance(@bullet.x, @bullet.y, enemy_robot.x, enemy_robot.y) < 20)

      if robot_hit
        enemy_robot.hp -= 3
        enemy_robot.is-hit = true
        Battle.explosions.push({
          x: enemy_robot.x,
          y: enemy_robot.y,
          progress: 1
        })
        @bullet = null
        return true
      # end if robot_hit
    # end for enemy_robot
    false

  update: !->
    @me = {angle: @angle, angle_turret: @angle_turret, id: @id, x: @x, y: @y, hp: @hp}
    has_sequential_event = false
    is-bullet-hit = false
    @status = {}

    if @bullet
      is-bullet-hit = @update-bullet!

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
            event["progress"]++
            @turn-turret -1

          when "turn_turret_right"
            event["progress"]++
            @turn-turret 1

        # end switch
      # end if / else
    # end for
  # end update()

class Battle
  @robots = []
  @explosions = []
  (@ctx, @width, @height, sources) ->
    @@explosions = []
    Robot.set-battlefield @width, @height
    @@robots = [new Robot(Math.random()*@width, Math.random()*@height, source) for source in sources]
    id = 0
    for r in @@robots
      r.id = id
      id++

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
    if $DIV_DEBUG
      @_update-debug!

    setTimeout(~>
      @_loop!
    , $SET_TIMEOUT)

  send_all: (msg_obj) ->
    for robot in @@robots
      robot.send(msg_obj)

  _update: !->
    for robot in @@robots
      robot.update()

  _update-debug: !->
    text = ""
    for robot in @@robots
      text += "#{robot.id}:<br />" + "hp: #{robot.me.hp}<br />" + "angle: #{robot.me.angle}<br />" + "<br />"

    $ \#debug .html text

  _draw: !->
    @ctx.clearRect(0, 0, @width, @height)

    for robot in @@robots
      # draw robot
      body = \body
      if robot.id == 0
        body = \body-red

      # TODO stop the game
      if robot.hp <= 0
        body = \explosion1-10
        robot = {}

      @ctx.save!

      @ctx.translate(robot.x, robot.y)

      # draw text
      @ctx.textAlign = "right";
      @ctx.textBaseline = "bottom";
      text-x = 40
      text-y = 30
      if (@width - robot.x) < 30
        text-x = - text-x
      if (@height - robot.y) < 30
        text-y = - text-y
      text = "#{robot.hp}/#{$HP}"

      if $CANVAS_DEBUG
        text += " turret_angle#{robot.turret_angle}"
      @ctx.fillText(text, text-x, text-y);



      @ctx.rotate(degrees-to-radians(robot.angle))
      @ctx.drawImage(@assets.get(body), -(38/2), -(36/2), 38, 36)
      @ctx.rotate(degrees-to-radians(robot.turret_angle))
      @ctx.drawImage(@assets.get("turret"), -(54/2), -(20/2), 54, 20)
      @ctx.rotate(degrees-to-radians(robot.radar_angle))
      @ctx.drawImage(@assets.get("radar"), -(16/2), -(22/2), 16, 22)


      #@ctx.textAlign = "right";
      #@ctx.textBaseline = "bottom";
      #@ctx.fillText("( 500 , 375 )", 100, 100);

      @ctx.restore!

      if robot.bullet
        @ctx.save!
        @ctx.translate robot.bullet.x, robot.bullet.y
        @ctx.rotate(degrees-to-radians(robot.bullet.direction))
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
