window.addEventListener "load", ->
  Q = window.Q = Quintus({audioSupported: [ 'wav','mp3','ogg' ]})
  .include("Sprites, Scenes, Input, 2D, Anim, Touch, UI, Audio")
  .setup(maximize: true)
  .controls()
  .touch()
  .enableSound()

  SPRITE_BOX = 1
  SPRITE_COLLECTABLE = 8
  Q.gravityY = 2000
  Q.Sprite.extend "Player",
    init: (p) ->
      @_super p,
        sheet: "player"
        sprite: "player"
        collisionMask: SPRITE_BOX | SPRITE_COLLECTABLE
        x: 40
        y: 555
        standingPoints: [ [ -16, 44], [ -23, 35 ], [-23,-48], [23,-48], [23, 35 ], [ 16, 44 ]]
        duckingPoints:  [ [ -16, 44], [ -23, 35 ], [-23,-10], [23,-10], [23, 35 ], [ 16, 44 ]]
        speed: 500
        jump: -700
        strength: 100
        score: 0

      @p.points = @p.standingPoints
      @p.jumped = false
      @add "2d, animation"
      @on "strength.change","onStrengthChange"
      @on "score.change","onScoreChange"

      return

    onStrengthChange: (e) ->
      @p.strength += e.value
      Q.stageScene 'hud', 3, @p

    onScoreChange: (e) ->
      @p.score += e.value
      Q.stageScene 'hud', 3, @p

    step: (dt) ->
      @p.vx += (@p.speed - @p.vx) / 4
      if @p.y > 555
        @p.y = 555
        @p.jumped = false
        @p.landed = 1
        @p.vy = 0
      else
        Q.audio.play('jump.mp3') unless @p.jumped
        @p.jumped = true
        @p.landed = 0
      @p.vy = @p.jump  if Q.inputs["up"] and @p.landed > 0
      @p.points = @p.standingPoints
      if @p.landed
        if Q.inputs["down"]
          @play "duck_right"
          @p.points = @p.duckingPoints
        else
          @play "walk_right"
      else
        @play "jump_right"
      @stage.viewport.centerOn @p.x + 300, 400
      return

  Q.Sprite.extend "CoinGold",
    init: ->
      levels = [565,540,500,450]
      player = Q("Player").first()
      @_super
        x: player.p.x + Q.width + 50
        y: levels[Math.floor(Math.random() * 3)]
        sheet: "coin_gold"
        type: SPRITE_COLLECTABLE
        vx: -600 + 200 * Math.random()
        vy: 0
        ay: 0
        theta: 0
        sensor: true
     
      @on "hit"
      return

    step: (dt) ->
      @p.x += @p.vx * dt
      @p.vy += @p.ay * dt
      @p.y += @p.vy * dt
      @p.angle += @p.theta * dt  unless @p.y is 565
      @destroy()  if @p.y > 800
      return

    hit: (col) ->
      @p.type = 0
      @p.collisionMask = Q.SPRITE_NONE
      if col.obj.isA("Player") and !@grabbed
        col.obj.trigger 'score.change', {value: 10}
        Q.audio.play "coin.mp3"  
      @grabbed = true
      @p.vx = -50
      @p.ay = 400
      @p.vy = -800
      @p.opacity = 0.5
      return

  Q.GameObject.extend "CoinGoldEmitter",
    init: ->
      @p =
        launchDelay: 0.75
        launchRandom: 1
        launch: 2

      return

    update: (dt) ->
      @p.launch -= dt
      if @p.launch < 0
        @stage.insert new Q.CoinGold()
        @p.launch = @p.launchDelay + @p.launchRandom * Math.random()
      return

  Q.Sprite.extend "Heart",
    init: ->
      levels = [565,540,500,450]
      player = Q("Player").first()
      @_super
        x: player.p.x + Q.width + 50
        y: levels[Math.floor(Math.random() * 3)]
        sheet: "heart"
        type: SPRITE_COLLECTABLE
        vx: -600 + 200 * Math.random()
        vy: 0
        ay: 0
        theta: 0
        sensor: true
     
      @on "hit"
      return

    step: (dt) ->
      @p.x += @p.vx * dt
      @p.vy += @p.ay * dt
      @p.y += @p.vy * dt
      @p.angle += @p.theta * dt  unless @p.y is 565
      @destroy()  if @p.y > 800
      return

    hit: (col) ->
      @p.type = 0
      @p.collisionMask = Q.SPRITE_NONE
      if col.obj.isA("Player") and !@grabbed
        col.obj.trigger 'strength.change', {value: 10}
        Q.audio.play "heart.mp3" 
      @grabbed = true
      @p.vx = -50
      @p.ay = 400
      @p.vy = -800
      @p.opacity = 0.5
      return

  Q.GameObject.extend "HeartEmitter",
    init: ->
      @p =
        launchDelay: 10
        launchRandom: 50
        launch: 2

      return

    update: (dt) ->
      @p.launch -= dt
      if @p.launch < 0
        @stage.insert new Q.Heart()
        @p.launch = @p.launchDelay + @p.launchRandom * Math.random()
      return

  Q.Sprite.extend "Box",
    init: ->
      levels = [565,540,500,450]
      player = Q("Player").first()
      @_super
        x: player.p.x + Q.width + 50
        y: levels[Math.floor(Math.random() * 3)]
        frame: (if Math.random() < 0.5 then 1 else 0)
        scale: 2
        type: SPRITE_BOX
        sheet: "crates"
        vx: -600 + 200 * Math.random()
        vy: 0
        ay: 0
        theta: (300 * Math.random() + 200) * ((if Math.random() < 0.5 then 1 else -1))
     
      @on "hit"
      return

    step: (dt) ->
      @p.x += @p.vx * dt
      @p.vy += @p.ay * dt
      @p.y += @p.vy * dt
      @p.angle += @p.theta * dt  unless @p.y is 565
      @destroy()  if @p.y > 800
      return

    hit: (col) ->
      if col.obj.isA("Player") and !@box_hit
        col.obj.trigger 'strength.change', {value: -5}
        Q.audio.play "hit.mp3"  
      @box_hit = true    
      @p.type = 0
      @p.collisionMask = Q.SPRITE_NONE
      @p.vx = 200
      @p.ay = 400
      @p.vy = -300
      @p.opacity = 0.5
      return

  Q.GameObject.extend "BoxThrower",
    init: ->
      @p =
        launchDelay: 0.75
        launchRandom: 1
        launch: 2

      return

    update: (dt) ->
      @p.launch -= dt
      if @p.launch < 0
        @stage.insert new Q.Box()
        @p.launch = @p.launchDelay + @p.launchRandom * Math.random()
      return

  Q.scene "level1", (stage) ->
    stage.insert new Q.Repeater(
      asset: "background-wall.png"
      speedX: 0.5
    )
    stage.insert new Q.Repeater(
      asset: "background-floor.png"
      repeatY: false
      speedX: 1.0
      y: 300
    )
    stage.insert new Q.BoxThrower()
    stage.insert new Q.CoinGoldEmitter()
    stage.insert new Q.HeartEmitter()
    stage.insert new Q.Player()
    stage.add "viewport"
    return

  Q.scene 'hud', (stage) ->
    container = stage.insert new Q.UI.Container
      x: 50
      y: 0

    label = container.insert new Q.UI.Text
      x:200
      y: 20
      label: "Score: " + stage.options.score
      color: "white"

    strength = container.insert new Q.UI.Text
      x:50
      y: 20
      label: "Health: " + stage.options.strength + '%'
      color: "white"

    container.fit(20)

  Q.load "player.json, player.png, background-wall.png, background-floor.png, crates.png, crates.json, collectables.png, collectables.json, coin.mp3, jump.mp3, hit.mp3, heart.mp3", ->
    Q.compileSheets "player.png", "player.json"
    Q.compileSheets "crates.png", "crates.json"
    Q.compileSheets "collectables.png", "collectables.json"
    Q.animations "player",
      walk_right:
        frames: [0,1,2,3,4,5,6,7,8,9,10]
        rate: 1 / 15
        flip: false
        loop: true

      jump_right:
        frames: [13]
        rate: 1 / 10
        flip: false

      stand_right:
        frames: [14]
        rate: 1 / 10
        flip: false

      duck_right:
        frames: [15]
        rate: 1 / 10
        flip: false

    Q.stageScene "level1"
    Q.stageScene 'hud', 3, Q('Player').first().p
    return

  return
