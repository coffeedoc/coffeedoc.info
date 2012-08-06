$(->

  socket = io.connect()

  # Update progress status
  #
  socket.on 'progress', (data) ->
    $('#message').html "<p>Generating Codo documentation: #{ data.progress }%</p>"

  # Checkout complete
  #
  socket.on 'complete', (data) ->
    $('#checkout').removeClass 'loading'
    $('#submit').attr 'disabled', false
    $('#checkout').fadeOut 'fast'
    $('.loadicon').css 'display', 'none'
    $('#message').html "<p>Documentation has been generated.</p>"

  # Checkout failed
  #
  socket.on 'failed', (data) ->
    $('#checkout').addClass 'error'
    $('#checkout').removeClass 'loading'
    $('#submit').attr 'disabled', false
    $('.loadicon').css 'display', 'none'
    $('#message').html "<p>Failed to generate the documentation!</p>"

  # Checkout new project
  #
  $('#checkout_form').submit ->

    $('#submit').attr 'disabled', true
    $('#checkout').addClass 'loading'
    $('.loadicon').css 'display', 'block'

    $('#message').html "<p>Generating Codo documentation: 0%</p>"

    socket.emit 'checkout', {
      url: $('#url').val()
      commit: $('#commit').val()
    }

    false

  # Show the about box
  #
  $('a.about').click (event) ->
    if $('#info').is(':hidden')
      $('#checkout').hide()
      $('#info').fadeIn 'fast'
    else
      $('#info').fadeOut 'fast'

    event.preventDefault()

  # Show the checkout box
  #
  $('a.new_checkout').click (event) ->
    if $('#checkout').is(':hidden')
      $('#info').hide()
      $('#checkout').removeClass 'error'
      $('#message').html ''
      $('#url').val ''
      $('#commit').val ''
      $('#checkout').fadeIn 'fast'
    else
      $('#checkout').fadeOut 'fast'

    event.preventDefault()

  $('.libraries li').each (i, el) ->
    if i % 2 is 0 then $(el).addClass('stripe') else $(el).removeClass('stripe')

)
