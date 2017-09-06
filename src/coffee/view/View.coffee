require('./jQuery')

###
TODO:
- fix UIControls

###

module.exports = (model)->
  Editors = require('./Editors')
  Notifications = require('./Notifications')
  UIControls = require('./UIControls')
  Persistence = require('./Persistence')
  Grid = require('./Grid')

  view =
    model: model
    notifications: Notifications()
    editors: Editors()
    persistence: new Persistence
    grid: new Grid '#hex-grid'

    running: true
    won: false
    autorestart: false
    delay: 20

  #Initialize Editors
  view.controls = UIControls(view)
  view.persistence.init()
  view.editors.checkPersistence view.persistence

  #Callbacks
  view.applyBots = (which)->
    for team in which
      code = @editors.getCode team
      bot = @model.Bot.fromString code, @model.Bot, @model.Hex
      $(".editortitle.#{team}").html(
        bot.name
      )
      @model.setBot(team, bot)
      @persistence.save team, code

  view.resetBots = (which)->
    for team in which
      @persistence.clear(team)
      editor = @editors.editors[if team is 'red' then 0 else 1]
      editor.setValue(@editors.defaultbot, -1)
    view.applyBots(which)

  view.play = ->
    $('#TogglePlay').html 'pause'
    view.running = true
    view.notifications.clear()

  view.pause = ->
    $('#TogglePlay').html 'play_arrow'
    view.running = false

  view.loop = ->
    if @running and not @won
      @model.step()
    setTimeout(@loop.bind(@), @delay)

  #Load bots now!
  view.applyBots(['red', 'blue'])

  #Callbacks
  view.restart = ()->
    @model.restart()
    @grid.onRestart()
    setTimeout(
      (()->@won=false).bind(@),
      190
    )
  view.onTake = (x, y, v) ->
    view.grid.onHexChange x, y, v
  view.onWin = (who, path, state) ->
    @won = true

    #Title Colour and Flash
    $('.title').removeClass "red"
    $('.title').removeClass "blue"
    $('.title').addClass "#{who}"
    $('.title').css("opacity", "0.4")
      .transition({ opacity: "1"}, 1000)

    @grid.onWin(path, state)

    #Automatically Restart the game
    if @autorestart
      setTimeout @restart.bind(@), 500

  view.model.onWin = view.onWin.bind(view)
  view.model.onTake = view.onTake.bind(view)

  view.model.error = (title, message) ->
    view.notifications.post(title, message)
    view.pause()

  view.model.warn = (title, message) ->
    view.notifications.post("Warning", title)
  #Start The Loop
  view.loop()

  return view
