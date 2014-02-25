# TODO Hit another bot detection
# TODO Hit by a bullet detection
# TODO fire and hp
# TODO show bot name


$SET_TIMEOUT = 20

$SEQUENTIAL_EVENTS = [\move_forwards \move_backwards \turn_left \turn_right]
$PARALLEL_EVENTS = [\fire \turn_turret_left \turn_turret_right \turn_radar_left \turn_radar_right]

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


# utility functions
degrees_to_radians = (degrees) ->
  # convert degrees to radians
  degrees * (Math.PI/180)

euclid_distance = (x1, y1, x2, y2) ->
  # calculate euclidean distance between 2 points
  Math.sqrt(Math.pow(x1-x2, 2) + Math.pow(y1-y2, 2))

in_rect = (x1,y1, x2, y2, width, height) ->
  # calculate if point(x1,y1) is in rect(x2, y2, width, height)
  (x2+width) > x1 > x2 and (y2+height) > y1 > y2


class Robot
  @battlefield-width = 0
  @battlefield-height = 0

  (@x, @y, @source) ->
    @health = 100
    @angle = Math.random()*360
    @turret_angle = 0
    @radar_angle = Math.random()*360
    @bullet = null
    @events = {}
    @status = {}

    @worker = new Worker(source)
    @worker.onmessage = (e) ~>
      @receive(e.data)

  @set-battlefield = (width, height) ->
    @@battlefield-width = width
    @@battlefield-height = height

  move: (distance) ->
    @x += distance * Math.cos(degrees_to_radians(@angle));
    @y += distance * Math.sin(degrees_to_radians(@angle));

    if in_rect @x, @y, 0, 0, @@battlefield-width, @@battlefield-height
      # hit the wall
      logger.log \not-wall-collide
      @status.wall-collide = false
    else
      logger.log \wall-collide
      @status.wall-collide = true


  turn: (degrees) ->
    @angle += degrees

  receive: (msg) ->
    event = JSON.parse(msg)
    #logger.log "receive #{msg}"
    if event.log != undefined
      logger.log event.log
      return

    event["progress"] = 0
    event_id = event["event_id"]
    logger.log "got event " + event_id + "," +event.action
    @events[event_id] = event

  send: (msg_obj) ->
    @worker.postMessage(JSON.stringify(msg_obj))

  send-interruption: ->
    logger.log \send-interruption
    @send({
      "action": "interruption",
      "x": @x,
      "y": @y,
      "status": @status
    })

  update: !->
    has_sequential_event = false
    for event_id, event of @events
      if $SEQUENTIAL_EVENTS.indexOf event.action != -1
        if has_sequential_event
          # we already have a sequential event in the queue
          continue
        has_sequential_event = true

      logger.log "events[#{event_id}] = {action=#{event.action},progress=#{event.progress}}"
      if event["amount"] is event["progress"]
        # the action is done
        @send({
          "action": "callback",
          "event_id": event["event_id"]
        })
        delete @events[event_id]
      else
        switch event["action"]
          when "move_forwards"
            event["progress"]++
            @move(1)
            if @status.wall-collide
              @events = {}
              @send-interruption!
              break

          when "move_backwards"
            event["progress"]++
            @move(-1)
            if @status.wall-collide
              @events = {}
              @send-interruption!
              break

          when "turn_left"
            event["progress"]++
            @turn(-1)

          when "turn_right"
            event["progress"]++
            @turn(1)
        # end switch
      # end if / else
    # end for
  # end update()

class Battle
  (@ctx, @width, @height, sources) ->
    @explosions = []
    Robot.set-battlefield @width, @height
    @robots = [new Robot(Math.random()*@width, Math.random()*@height, source) for source in sources]

    @assets = new AssetsLoader({
      "body": 'img/body.png',
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

    setTimeout(~>
      @_loop!
    , $SET_TIMEOUT)

  send_all: (msg_obj) ->
    for robot in @robots
      robot.send(msg_obj)

  _update: ->
    for robot in @robots
      robot.update()
  _draw: ->
    @ctx.clearRect(0, 0, @width, @height)

    for robot in @robots
      # draw robot
      @ctx.save()
      @ctx.translate(robot.x, robot.y)
      @ctx.rotate(degrees_to_radians(robot.angle))
      @ctx.drawImage(@assets.get("body"), -(38/2), -(36/2), 38, 36)
      @ctx.rotate(degrees_to_radians(robot.turret_angle))
      @ctx.drawImage(@assets.get("turret"), -(54/2), -(20/2), 54, 20)
      @ctx.rotate(degrees_to_radians(robot.radar_angle))
      @ctx.drawImage(@assets.get("radar"), -(16/2), -(22/2), 16, 22)
      @ctx.restore()


# export objects
window.Battle = Battle
