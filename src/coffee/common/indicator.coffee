_ = require 'lodash'


##
# Accumulates counts of unique elements.
# @class ElementCounter
class ElementCounter

  ##
  # @constructor

  constructor: ->
    @elements = []
    @counts   = []


  ##
  # Increments the count for the passed element.
  # @method increment
  # @param {HTMLElement} el The element for-which to increment the count of.

  increment: (el) ->
    if el not in @elements and el isnt null
      @elements.push el
      @counts.push 1
    else if el isnt null
      i = @elements.indexOf el
      @counts[i]++


  ##
  # Returns the HTMLElement with the highest count.
  # @return {HTMLElement} The element with the largest count.

  max: ->
    m = 0
    idx = null
    for el in @elements
      if el.hasAttribute('data-eyejs-snap')
        return el
    for c, i in @counts
      if c > m
        idx = i
        m = c
    if idx isnt null then @elements[idx] else null



##
# Gaze indicator class represents the gaze-indicator object dynamically
# rendered on the screen.
#
module.exports = class Indicator

  ##
  # Creates the gaze indicator object take a variety of options affecting how
  # it is rendered and it's behavior.
  # @constructor
  # @param {Object} [opts] Optional indicator options.
  # @param {string} [opts.transform] Initial transformation.
  # @param {string} [opts.transition] Transition setting.
  # @param {boolean} [opts.visible] Visibility setting. If set to false, then
  # the indicator is initially invisible.

  constructor: (opts = {}) ->

    transform  = opts.transform  or 'translate3d(0, 0, 0)'
    transition = opts.transition or '-webkit-transform 0.2s ease-out,
      -moz-transform 0.2s ease-out,
      -ms-transform 0.2s ease-out,
      transform 0.2s ease-out,
      height 1s ease-out,
      width 1s ease-out'

    if opts.visible?
      visibility = opts.visible ? 'visible' : 'hidden'
    else
      visibility = 'visible'

    @transforms = {}
    @size = +opts.size or 40
    @scaleTimer = null

    @el = document.createElement('div')
    styles =
      position:         'fixed'
      height:           @size + 'px'
      width:            @size + 'px'
      top:              0
      left:             0
      borderRadius:     '1000px'
      visibility:       visibility
      background:       opts.color or 'rgba(255, 255, 255, 0.4)'
      border:           '1px solid rgba(0,0,0,0.6)'
      boxShadow:        '0 0 6px rgba(255,255,255,0.2)'
      transform:        transform
      MozTransform:     transform
      WebkitTransform:  transform
      msTransform:      transform
      transition:       transition
      MozTransition:    transition
      WebkitTransition: transition
      msTransition:     transition
      opacity:          0.5
      zIndex:           100000
    for k, s of styles
      @el.style[k] = s
    document.body.appendChild(@el)

    ##
    # Gets and returns a list of element currently under the gaze indicator.
    # This method is throttled and is only effectively called once every 100
    # milliseconds.
    # @method getGazeElements
    # @returns {Array<HTMLElement>}

    @getGazeElements = _.throttle =>
      [x, y] = @center()
      v = @visible()
      if v then @hide()
      counter = new ElementCounter
      for r in [0..@size/2] by 9
        for a in [0..2] by 0.2
          px = x + r * Math.cos(a * Math.PI)
          py = y + r * Math.sin(a * Math.PI)
          el = document.elementFromPoint px, py
          counter.increment el
      if v then @show()
      [counter.max()]
    , 100


  ##
  # Returns an [x,y] tuple representing the center coordinates of the
  # gaze indicator.
  # @method center
  # @return {Array<number>} Tuple array `[x, y]` of center coordinates.

  center: ->
    b = @el.getBoundingClientRect()
    [parseInt(b.left + 0.5 * @size), parseInt(b.top + 0.5 * @size)]


  ##
  # Moves the indicator to the specified `x` and `y` coordinates.
  # @method move
  # @param {number} x The x-coordinate to move to.
  # @param {number} y The y-coordinate to move to.

  move: (x, y) ->
    h = 0.5 * @size
    @push 'translate', "#{+x - h}px, #{+y - h}px"


  ##
  # Scales the size of the gaze indicator for the specified period of time.
  # @method scale
  # @param {number} [scale=0.7] The scaling factor.
  # @param {number} [time=300] The amount of time to hold the scaling.

  scale: (scale = 0.7, time = 300) ->
    @push 'scale', +scale
    @scaleTimer = setTimeout =>
      @pop 'scale'
    , time


  ##
  # Re-sizes the indicator to the passed value.
  # @param {number} size New size in pixels.

  resize: (size) ->
    @size = size
    @el.style.height = size + 'px'
    @el.style.width = size + 'px'


  ##
  # Sets the indicator opacity.
  # @param {number} opacity New opacity, from 0 to 100.

  opacity: (op) ->
    if op? then @el.style.opacity = +op / 100 else @el.style.opacity * 100


  ##
  # Shows the view indicator.
  # @method show

  show: -> @el.style.visibility = 'visible'


  ##
  # Hides the view indicator.
  # @method hide

  hide: -> @el.style.visibility = 'hidden'


  ##
  # Toggles the gaze indicator's visibility.
  # @method toggle

  toggle: -> if @visible() then @hide() else @show()


  ##
  # Returns the indicator's current visibility state.
  # @return {boolean} `true` if currently visible, otherwise false.

  visible: -> @el.style.visibility is 'visible'


  ##
  # Draws the gaze indicator and it's various transforms.
  # @method draw
  # @private

  draw: ->
    ts = []
    for t of @transforms
      ts.push "#{t}(#{@transforms[t]})" unless @transforms[t] is null
    if ts.length is 0 then t = 'none' else t = ts.join ' '
    for k in ['transform', 'MozTransform', 'WebkitTransform', 'msTransform']
      @el.style[k] = t


  ##
  # Adds a transformation to the stack of transforms currently active.
  # @method push
  # @param {string} transform The transformation.
  # @param {string} value The transformation value.
  # @private

  push: (transform, value) ->
    @transforms[transform] = value
    @draw()


  ##
  # Removes the specified transformation from the gaze indicator.
  # @param {string} transform The transformation to remove.
  # @private

  pop: (transform) ->
    @transforms[transform] = null
    @draw
