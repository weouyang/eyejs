_ = require 'lodash'
Buffer = require './buffer'
Indicator = require './indicator'

# List of previous eye-opens.
opens     = new Buffer()

# List of previous eye-closes.
closes    = new Buffer()

# The last frame received.
lastFrame = null

# Element currently gazing-at.
gazeEl    = null

# Number of frames the left-eye has been closed for.
leftCount = 0

# Number of frames the right-eye has been closed for.
rightCount = 0


getElement = (frame) ->
  document.elementFromPoint frame.avg.x, frame.avg.y


triggerEvent = (event) ->
  evt = new CustomEvent event
  gazeEl?.dispatchEvent(evt)


handleWink = (side, el) ->
  switch side
    when 'left'
      if ++leftCount <= 3 then return
      leftCount = 0
      triggerEvent 'leftwink'
      triggerEvent 'wink'
    when 'right'
      if ++rightCount <= 3 then return
      rightCount = 0
      triggerEvent 'rightwink'
      triggerEvent 'wink'


handleBlink = (open, close) ->
  blinkTime = 600
  blinkCushion = 200

  # if the last open isn't recent, then skip.
  if _.now() - open > 100 then return

  diff = open - close

  if ((diff >= blinkTime - blinkCushion) && (diff <= blinkTime + blinkCushion))
    Eye.indicator.scale(0.5, 1000)
    Eye.freeze()
    triggerEvent 'blink'



handleDoubleBlink = (open, close) ->
  diff = close - open
  if _.now() - close > 500 then return
  if (diff < 200)
    Eye.indicator.scale 2, 1000
    Eye.freeze()
    triggerEvent 'doubleblink'



handleBlinks = (frame) ->
  open  = opens.get 0
  close = closes.get 0
  dOpen = opens.get 1
  left  = frame.lefteye.avg
  right = frame.righteye.avg

  if (open  && close) then handleBlink open, close
  if (dOpen && close) then handleDoubleBlink dOpen, close

  if ((left.x == 0 && left.y == 0) && (right.x != 0 && right.y != 0))
    handleWink 'left'

  if ((left.x != 0 && left.y != 0) && (right.x == 0 && right.y == 0))
    handleWink 'right'


# Handles gaze event. If the current gaze element is unchanged, then
# do nothing... but if it has changed, trigger a gazeleave on previous and
# a gaze on the new one.
handleGaze = (frame) ->
  el = getElement frame
  if el and el isnt Eye.indicator.el and el isnt gazeEl
    if gazeEl isnt null then triggerEvent 'gazeleave', gazeEl
    gazeEl = el
    triggerEvent 'gaze', gazeEl






# Create the global Eye object.
window.Eye =

  indicator: new Indicator

  freeze: ->
    @frozen = true
    setTimeout =>
      @frozen = false
    , 1500

  frozen: false

  handleFrame: (frame) ->
    if window.Eye.frozen then return
    if lastFrame

      closedThisFrame = frame.avg.x == 0 and frame.avg.y == 0
      openLastFrame   = lastFrame.avg.x != 0 and lastFrame.avg.y != 0

      closedLastFrame = lastFrame.avg.x == 0 and lastFrame.avg.y == 0
      openThisFrame   = frame.avg.x != 0 and frame.avg.y != 0

      if closedThisFrame and openLastFrame
        closes.push(new Date());

      if closedLastFrame and openThisFrame
        opens.push(new Date());

    lastFrame = frame

    if frame.avg.x != 0 and frame.avg.y != 0
      window.Eye.indicator.move frame.avg.x, frame.avg.y

      handleGaze(frame)
      handleBlinks(frame)

  connection: require './connection'


window.Eye.connection.connect()