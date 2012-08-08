$(->
  # Create the jobs stripes
  #
  $('.jobs li').each (i, el) ->
    if i % 2 is 0 then $(el).addClass('stripe') else $(el).removeClass('stripe')

)
