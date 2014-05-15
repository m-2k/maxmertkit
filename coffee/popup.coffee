"use strict"

_name = "popup"
_instances = []
_id = 0

MaxmertkitHelpers = window['MaxmertkitHelpers']

class Popup extends MaxmertkitHelpers

	_name: _name
	_instances: _instances

	opened: no
	enabled: yes

	constructor: ( @el, @options ) ->

		_options =
			# String; spy type, needed to autoinitialize modals by attribute data-toggle
			toggle: @el.getAttribute( 'data-toggle' ) or _name

			# String; selector of modal window element, searching globally in the DOM
			target: @el.getAttribute( 'data-target' ) or null

			# String; selector inside target for modal dialog
			dialog: @el.getAttribute( 'data-dialog' ) or "-content"

			# String; event to interact with button to open window
			event: @el.getAttribute( 'data-event' ) or "click"

			# String; event to interact with closer element to close window
			# Closer element should be anywhere in the DOM with attribute data-dismiss="target-selector", it will automatically initialize
			eventClose: @el.getAttribute( 'data-event-close' ) or "click"

			# Boolean; open modal after initialize
			autoOpen: @el.getAttribute('data-autoopen') or no

			position:
				# String; vertical position of target in regard to element
				vertical:'top'

				# String; horizontal position of target in regard to element
				horizontal: 'center'

			# Numbers; offset of target in regard to element
			offset:
				horizontal: 5
				vertical: 5

			# Boolean; close popup when unfocus the button or popup
			closeOnUnfocus: no

			# Boolean; close popup when window resizing
			closeOnResize: yes

			# Boolean; close other instances of Modal when current is opening
			selfish: no


			# Events
			beforeactive: ->
			onactive: ->
			failactive: ->
			beforedeactive: ->
			ondeactive: ->
			faildeactive: ->

		@options = @_merge _options, @options

		# Find modal element in DOM
		@target = document.querySelector @options.target

		# Find and init closer element inside modal element in DOM
		@closers = document.querySelectorAll "[data-dismiss='#{@options.target}']"

		# Find dialog element inside target
		@dialog = @target.querySelector @options.dialog

		@_setOptions @options

		super @el, @options

		# Set global event
		@reactor.registerEvent "initialize.#{_name}"
		@reactor.registerEvent "open.#{_name}"
		@reactor.registerEvent "close.#{_name}"

		@reactor.dispatchEvent "initialize.#{_name}"

		# Open modal if autoOpen setted
		if @options.autoOpen then @open()

	destroy: ->
		@_removeEventListener @el, @options.event, @clicker.bind( @ )
		@_removeEventListener document, @options.event, _closeUnfocus.bind( @ )
		@_removeEventListener window, "resize", @close.bind( @ )
		for closer in @closers
			@_removeEventListener closer, @options.eventClose, @close.bind( @ )
		@el.dataset["data-kit-#{@_name}"] = null
		super

	_setOptions: ( options ) ->
		for key, value of options
			if not @options[key]?
				return console.error "Maxmertkit Modal. You're trying to set unpropriate option – #{key}"

			switch key
				when 'event'
					@_removeEventListener @el, @options.event, @clicker.bind( @ )
					@_addEventListener @el, value, @clicker.bind( @ )

				when 'eventClose'
					for closer in @closers
						@_removeEventListener closer, @options.eventClose, @close.bind( @ )
						@_addEventListener closer, value, @close.bind( @ )

				when 'position'
					@_removeClass "_top_ _bottom_ _left_ _right_ _center_ _middle_", @target
					@_addClass "_#{@options.position.vertical}_ _#{@options.position.horizontal}_", @target

				when 'closeOnUnfocus'
					@_removeEventListener document, @options.event, _closeUnfocus.bind( @ )
					if value
						@_addEventListener document, @options.event, _closeUnfocus.bind( @ )

				when 'closeOnResize'
					@_removeEventListener window, "resize", @close.bind( @ )
					if value
						@_addEventListener window, "resize", @close.bind( @ )

			@options[key] = value
			if typeof value is 'function' then @[key] = value

	clicker: ->
		if not @opened
			@open()
		else
			@close()

	open: -> @activate()
	close: -> @deactivate()

	activate: ->
		if @enabled and not @opened
			_beforeactivate.call @

	deactivate: ->
		if @enabled and @opened
			_beforedeactivate.call @

	disable: ->
		@enabled = no

	enable: ->
		@enabled = yes

	setPosition: ->
		# btnPosition = @$btn.offset()
		scrollParent = @_getContainer @target
		scrollParentBtn = @_getContainer()
		# if @_equalNodes scrollParent, scrollParentBtn
		positionBtn = @el.getBoundingClientRect()
		position = @target.getBoundingClientRect()

		if scrollParent? and ((scrollParent.activeElement? and scrollParent.activeElement.nodeName isnt 'BODY') or (scrollParent.nodeName? and (scrollParent.nodeName isnt 'BODY' and scrollParent.nodeName isnt '#document')))
			offset = scrollParent?.getBoundingClientRect()
			if offset?
				positionBtn.top = positionBtn.top - offset.top
				positionBtn.left = positionBtn.left - offset.left

		sizeBtn =
			width: @_outerWidth()
			height: @_outerHeight()

		size =
			width: @_outerWidth @target
			height: @_outerHeight @target

		newTop = newLeft = 0

		switch @options.position.vertical

			when 'top'
				newTop = positionBtn.top - size.height - @options.offset.vertical

			when 'bottom'
				newTop = positionBtn.top + sizeBtn.height + @options.offset.vertical

			when 'middle' or 'center'
				newTop = positionBtn.top + sizeBtn.height / 2 - size.height / 2

		switch @options.position.horizontal

			when 'center' or 'middle'
				newLeft = positionBtn.left + sizeBtn.width / 2 - size.width / 2

			when 'left'
				newLeft = positionBtn.left - size.width -  @options.offset.horizontal

			when 'right'
				newLeft = positionBtn.left + sizeBtn.width + @options.offset.horizontal

		@target.style.left = newLeft
		@target.style.top = newTop

		true




# ===============
# PRIVATE METHODS

_closeUnfocus = ( event ) ->
	classes = '.' + @el.className.split(' ').join('.')
	if not @_closest(classes, event.target)? and event.target isnt @el
		@close()

# ===============
# PRIVATE METHODS

# If you have beforeactive function
# 	it will be called here
# if you don't
# 	just activate button
_beforeactivate = ->
	# If we need to close all other instances on Button
	if @options.selfish
		@_selfish()

	if @beforeactive?
		try
			deferred = @beforeactive.call @el
			deferred
				.done =>
					_activate.call @

				.fail =>
					@faildeactive?.call @el

		catch
			_activate.call @

	else
		_activate.call @


_activate = ->
	@setPosition()
	@_addClass '_active_', @target
	@onactive?.call @el
	@reactor.dispatchEvent "open.#{_name}"
	@opened = yes


# If you have beforeunactive function
# 	it will be called here
# if you don't
# 	just deactivate
_beforedeactivate = ->
	if @beforedeactive?
		try
			deferred = @beforedeactive.call @el
			deferred
				.done =>
					_deactivate.call @

				.fail =>
					@faildeactive?.call @el

		catch
			_deactivate.call @

	else
		_deactivate.call @

_deactivate = ->
	@_removeClass '_active_'
	@reactor.dispatchEvent "close.#{_name}"
	@ondeactive?.call @el
	@opened = no





window['Popup'] = Popup
window['mkitPopup'] = ( options ) ->
	result = null
	if not @dataset? then @dataset = {}

	unless @dataset['data-kit-popup']
		result = new Popup @, options
		@dataset['data-kit-popup'] = result

	else
		if typeof options is 'object'
			@dataset['data-kit-popup']._setOptions options
		else
			if typeof options is "string" and options.charAt(0) isnt "_"
				@dataset['data-kit-popup'][options]

		result = @dataset['data-kit-popup']

	return result


# 	# =============== Public methods
#
# 	constructor: ( @btn, @options ) ->
# 		@$btn = $(@btn)
#
# 		@_id = _id++
#
# 		_options =
# 			target: @$btn.data('target')				# Targeted popup windows
# 			toggle: @$btn.data('toggle') or 'popup'		# To automatically find elements which toggle popup windows
# 			event: "click"								# Event on button to open popup
# 			eventClose: "click"							# Event on close elements to close popup
# 			positionVertical: 'top'
# 			positionHorizontal: 'center'
# 			offset:										# Offset in pixels
# 				horizontal: 5
# 				vertical: 5
# 			closeUnfocus: no							# Close popup on click anywhere on document
# 			closeResize: yes							# Close popup on resize window
# 			selfish: yes								# Just 1 opened class instance, close others when open current
# 			# container: 'body'
#
# 		@options = @_merge _options, @options
#
#
# 		# Reset default event functions
# 		@beforeopen = @options.beforeopen
# 		@onopen = @options.onopen
# 		@beforeclose = @options.beforeclose
# 		@onclose = @options.onclose
#
# 		# Set popup window element
# 		@$el = $(document).find @options.target
#
# 		# Set event on button to show popup window
# 		@$btn.on @options.event, =>
# 			if not @$el.is ':visible'
# 				@open()
# 			else
# 				@close()
#
# 		# Set event on button to close popup window
# 		# but only if show and close events are not the same
# 		@$btn.on @options.eventClose, =>
# 			if @options.event isnt @options.eventClose
# 				@close()
#
# 		# Find dismiss buttons inside popup window
# 		@$el.find("*[data-dismiss='popup']").on @options.event, =>
# 			@close()
#
#
# 		# Close popup when we loose focus (click somewhere else)
# 		if @options.closeUnfocus
# 			$(document).on "click.#{_name}", ( event ) =>
# 				classes = '.' + @$el[0].className.split(' ').join('.')
# 				if not $(event.target).closest(classes ).length and @$el.is(':visible') and not @$el.is(':animated') and $(event.target)[0] isnt @$btn[0]
# 					@close()
#
# 		if @options.closeResize
# 			$(window).on "resize.#{_name}", ( event ) =>
# 				@close()
#
#
# 		# set position classes
# 		@$el.removeClass '_top_ _bottom_ _left_ _right_'
# 		@$el.addClass "_#{@options.positionVertical}_ _#{@options.positionHorizontal}_"
#
# 		super @$btn, @options
#
# 		setTimeout =>
# 			@reactor.addEventListener "close.modal", =>
# 				@close()
# 		,1
#
#
# 	_setOptions: ( options ) ->
#
# 		for key, value of options
# 			if not @options[key]?
# 				if key isnt "kit-#{_name}"
# 					return console.error "Maxmertkit Popup. You're trying to set unpropriate option – #{key}"
# 				else
# 					return null
#
# 			switch key
# 				when 'target'
# 					# Set popup window element
# 					@$el = $(document).find @options.target
#
# 					# Find dismiss buttons inside popup window
# 					@$el.find("*[data-dismiss='popup']").on @options.event, =>
# 						@close()
#
# 				when 'event'
# 					@$btn.off "#{@options.event}.#{@_name}"
#
# 					@options.event = value
#
# 					# Set event on button to show popup window
# 					@$btn.on "#{@options.event}.#{@_name}", =>
# 						if not @$el.is ':visible'
# 							@open()
# 						else
# 							@close()
#
# 				when 'eventClose'
# 					@$btn.off "#{@options.eventClose}.#{@_name}"
#
# 					@options.eventClose = value
#
# 					# Set event on button to close popup window
# 					# but only if show and close events are not the same
# 					@$btn.on "#{@options.eventClose}.#{@_name}", =>
# 						if @options.event isnt @options.eventClose
# 							@close()
#
# 				when 'closeUnfocus'
# 					@options.closeUnfocus = value
#
# 					$(document).off "click.#{@_name}"
#
# 					# Close popup when we loose focus (click somewhere else)
# 					if @options.closeUnfocus
# 						$(document).on "click.#{@_name}", ( event ) =>
# 							classes = '.' + @$el[0].className.split(' ').join('.')
# 							if not $(event.target).closest(classes ).length and @$el.is(':visible') and not @$el.is(':animated') and $(event.target)[0] isnt @$btn[0]
# 								@close()
#
# 				when 'positionVertical'
# 					# set position classes
# 					@$el.removeClass "_top_ _middle_ _bottom_"
#
# 					@options.positionVertical = value
#
# 					@$el.addClass "_#{@options.positionVertical}_"
#
# 				when'positionHorizontal'
# 					# set position classes
# 					@$el.removeClass "_left_ _center_ _right_"
#
# 					@options.positionHorizontal = value
#
# 					@$el.addClass "_#{@options.positionHorizontal}_"
#
#
# 				else
# 					@options[key] = value
#
#
#
# 	destroy: ->
# 		@$btn.off ".#{@_name}"
# 		super
#
# 	open: ->
# 		_beforeopen.call @
#
# 	close: ->
# 		_beforeclose.call @
#
#
#
#
#
#
# # =============== Private methods
#
#
#
# _position = ->
# 	# btnPosition = @$btn.offset()
# 	scrollParent = @_getContainer @$el
# 	scrollParentBtn = @_getContainer @$btn
#
# 	# if @_equalNodes scrollParent, scrollParentBtn
# 	positionBtn = @$btn.offset()
# 	position = @$el.offset()
#
# 	if scrollParent? and (not scrollParent[0]? or (scrollParent[0].activeElement? and scrollParent[0].activeElement.nodeName isnt 'BODY') or (scrollParent[0].nodeName? and scrollParent[0].nodeName isnt 'BODY'))
# 		offset = $(scrollParent).offset()
# 		if offset?
# 			positionBtn.top = positionBtn.top - offset.top
# 			positionBtn.left = positionBtn.left - offset.left
#
# 	sizeBtn =
# 		width: @$btn.outerWidth()
# 		height: @$btn.outerHeight()
#
# 	size =
# 		width: @$el.outerWidth()
# 		height: @$el.outerHeight()
#
# 	newTop = newLeft = 0
#
# 	switch @options.positionVertical
#
# 		when 'top'
# 			newTop = positionBtn.top - size.height - @options.offset.vertical
#
# 		when 'bottom'
# 			newTop = positionBtn.top + sizeBtn.height + @options.offset.vertical
#
# 		when 'middle' or 'center'
# 			newTop = positionBtn.top + sizeBtn.height / 2 - size.height / 2
#
# 	switch @options.positionHorizontal
#
# 		when 'center' or 'middle'
# 			newLeft = positionBtn.left + sizeBtn.width / 2 - size.width / 2
#
# 		when 'left'
# 			newLeft = positionBtn.left - size.width -  @options.offset.horizontal
#
# 		when 'right'
# 			newLeft = positionBtn.left + sizeBtn.width + @options.offset.horizontal
#
#
# 	@$el.css
# 		left: newLeft
# 		top: newTop
#
#
#
# # If you have beforeopen function
# # 	it will be called here
# # if you don't
# # 	just open modal window
# _beforeopen = ->
# 	# If we need to close all other instances on Popup
# 	if @options.selfish
# 		@_selfish()
#
# 	if @beforeopen?
# 		try
# 			deferred = @beforeopen.call @$btn
# 			deferred
# 				.done =>
# 					_open.call @
#
# 				.fail =>
# 					@$el.trigger "fail.#{@_name}"
#
# 		catch
# 			_open.call @
#
# 	else
# 		_open.call @
#
# # Opens modal
# # and triggers onopen
# _open = ->
# 	_position.call @
# 	@$el.addClass '_active_'
# 	@$el.trigger "opened.#{@_name}"
# 	if @onopen?
# 		try
# 			@onopen.call @$btn
#
#
# # If you have beforeclose function
# # 	it will be called here
# # if you don't
# # 	just close modal window
# _beforeclose = ->
# 	if @beforeclose?
# 		try
# 			deferred = @beforeclose.call @$btn
# 			deferred
# 				.done =>
# 					_close.call @
#
# 				.fail =>
# 					@$el.trigger "fail.#{@_name}"
#
# 		catch
# 			_close.call @
#
# 	else
# 		_close.call @
#
# # Closes modal
# # and triggers onclose
# _close = ->
# 	@$el.removeClass '_active_'
# 	@$el.trigger "closed.#{@_name}"
# 	if @onclose?
# 		try
# 			@onclose.call @$btn
#
#
#
#
#
#
# $.fn[_name] = (options) ->
# 	@each ->
# 		unless $.data(@, "kit-" + _name)
# 			$.data @, "kit-" + _name, new Popup(@, options)
# 		else
# 			if typeof options is "object"
# 				$.data(@, "kit-" + _name)._setOptions options
# 			else
# 				(if typeof options is "string" and options.charAt(0) isnt "_" then $.data(@, "kit-" + _name)[options] else console.error("Maxmertkit Popup. You passed into the #{_name} something wrong."))
# 		return
