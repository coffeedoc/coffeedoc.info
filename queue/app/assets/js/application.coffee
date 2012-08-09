$(->

  # Create the jobs stripes
  #
  $('.jobs li').each (i, el) ->
    if i % 2 is 0 then $(el).addClass('stripe') else $(el).removeClass('stripe')

  # Clear jobs log
  #
  $('.clearJobLog a').on 'click', (event) ->
    $.post($(@).attr('href')).success =>
      $(@).parent().parent().next().html '<li>No jobs logged.</li>'

    event.preventDefault()

)
