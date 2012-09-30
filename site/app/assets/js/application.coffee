$(->

  # Wait until docs have been completed
  #
  waitForDocs = (repo, commit, id, url) ->
    $.ajax
      url: "/state/#{ id }",
      timeout: 2000
      success: (data) ->
        if data is 'succeed'
          docsComplete(url)
        else if data is 'failed'
          docsFailed()
        else
          setTimeout (-> waitForDocs(repo, commit, id, url)), 1000
      error: -> setTimeout (-> waitForDocs(repo, commit, id, url)), 1000

  # Generation complete complete
  #
  docsComplete = (url) ->
    $('#checkout').removeClass 'loading'
    $('#submit').attr 'disabled', false
    $('#checkout').fadeOut 'fast'
    $('.loadicon').css 'display', 'none'
    $('#message').html "<p>Documentation has been generated.</p>"

    location.href = url

  # Document generation failed
  #
  docsFailed = (msg = '<p>Failed to generate the documentation.</p>') ->
    $('#checkout').addClass 'error'
    $('#checkout').removeClass 'loading'
    $('#submit').attr 'disabled', false
    $('.loadicon').css 'display', 'none'
    $('#message').html msg
    $('#message').fadeIn().fadeOut().fadeIn()

  # Checkout new project
  #
  $('#checkout_form').submit ->

    $('#submit').attr 'disabled', true
    $('#checkout').addClass 'loading'
    $('.loadicon').css 'display', 'block'

    url = $('#url').val().trim()
    commit = $('#commit').val() || 'master'

    if /^(?:https?|git):\/\/(?:www\.?)?github\.com\/([^\s/]+)\/([^\s/]+?)(?:\.git)?\/?$/.test url

      [repo, user, project] = url.match /^(?:https?|git):\/\/(?:www\.?)?github\.com\/([^\s/]+)\/([^\s/]+?)(?:\.git)?\/?$/

      xhr = $.post('/add', {
        url: repo
        commit: commit
      }).success((data) ->
        $('.loadicon').css('display', 'block')
        $('#message').html "<p>Generating Codo documentation...</p>"
        setTimeout (-> waitForDocs repo, commit, data, "/github/#{ user }/#{ project }/#{ commit }"), 1000
      ).error docsFailed

    else
      docsFailed '<p>The GitHub repository URL is not valid!</p>'

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

  # Create the library stripes
  #
  $('.libraries li').each (i, el) ->
    if i % 2 is 0 then $(el).addClass('stripe') else $(el).removeClass('stripe')

)
