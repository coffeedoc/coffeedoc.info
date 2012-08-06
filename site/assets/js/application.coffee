$(->
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
      $('#checkout').fadeIn 'fast'
    else
      $('#checkout').fadeOut 'fast'

    event.preventDefault()

  # Send checkout form
  #
  $('#checkout_form').submit ->
    $('#submit').attr 'disabled', true
    $('#checkout').addClass 'loading'

    $.post '/checkout', {
      url: $('#url').val()
      commit: $('#commit').val()
    }, (data, status) ->
      if status is 'success'
        $('.loadicon').css('display', 'block')
      else
        $('#checkout').removeClass 'loading'
        $('#checkout').addClass 'error'
        $('#submit').attr 'disabled', false

    false
)
