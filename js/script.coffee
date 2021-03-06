
jQuery ->  

  ($ 'input#start_multiplaer').focus()
  ($ 'section#setup').hide()
  ($ 'section#board').hide()

  notice = (message) ->
    ($ 'div#statusBar > p').html("<p>#{message}</p>")

  class Game

    constructor: (options) ->
      players = options[0] ? '1'
      switch players
        when 0, "0" then p1 = p2 = false
        when 2, "2" then p1 = p2 = true
        else
          p1 = true
          p2 = false
      @player1 = new Player(options[1] ? 'X', p1 )
      @player2 = new Player(options[2] ? 'O', p2 )
      @cells   = ($ "section#board .cell")
      @cells.each ->
        $(@).text(" ")
        $(@).removeClass('score')
      @currentPlayer = @player1
      @availableMoves = 9
      ($ 'span.p1-title').text(" #{options[1]} Wins : ")
      ($ 'span.p2-title').text(" #{options[2]} Wins : ")
      notice("#{@currentPlayer.type}: It's your turn")
      ($ 'section#board div.cell').on
        click: @.makeMove
        mouseleave: @.resetCell

      setTimeout(@.computerMove(@currentPlayer), 1000) if parseInt(players) is 0
    makeMove:(e) =>
      if ($ e.target).text() isnt " "
        ($ e.target).addClass('invalid')
        ($ e.target).removeClass('valid')
      else
        ($ e.target).addClass('valid')

      if ($ e.target).hasClass('valid') is true
        if ($ e.target).hasClass('invalid') is false
          ($ e.target).text(@currentPlayer.type)
          @.checkForWinner()


    checkForWinner: ->
      type      = @currentPlayer.type
      gameOver  = false
      winner    = if type is @player1.type then "p1" else "p2"
      theRowsAndCols = [($ 'div.row1'),($ 'div.row2'),($ 'div.row3'),($ 'div.col1'),($ 'div.col2'),($ 'div.col3')]
      theAngles = [$('div.row1.col1, div.row2.col2, div.row3.col3'),$('div.row3.col1, div.row2.col2, div.row1.col3')]
      allTheDirections = [theRowsAndCols,theAngles]
      
      for selection in allTheDirections
        for group in selection
          count = []
          group.each ->
            if $(@).text() is type
              count.push($(@))
            if count.length is 3
              for c in count
                $(c).addClass('score')
              gameOver = true
      if gameOver is true
          score = ($ ".#{winner}-wins").text()    
          ($ ".#{winner}-wins").text( parseInt(score) + 1)    
          @.gameOver("GAMEOVER!")
          return undefined
      else
        moves = 9
        @cells.each ->
          if $(@).text() isnt " "
            moves -= 1
        @availableMoves = moves
        if @availableMoves <= 0       
          @.gameOver("STALEMATE")
        else
          @.switchPlayer()

      return undefined

    gameOver: (message) ->
      notice(message)
      ($ 'section#setup').slideToggle()


    computerMove: (player) ->
      type     = player.type
      opponent = if @currentPlayer.type is @player1.type then @player2.type else @player1.type
      rows     = [($ 'div.row1'),($ 'div.row2'),($ 'div.row3')]
      rank     = [[3,3,3],
                 [3,5,3],
                 [3,3,3]]
      # Reset rank for existing moves
      for row, index in rows
        row.each (col) ->
          if $(@).text() isnt " "
            rank[index][col] = 0

      @.checkForWinAndBlock    type,  9, rank #win
      if @.getMax(rank) isnt 9
        @.checkForWinAndBlock opponent,  8, rank #block
      if @.getMax(rank) isnt 9
        @.checkCorners        opponent, rank

      max = @.getMax(rank)
      move = []
      for row, i in rank
        for cell, j in row
          if cell is max
            move = "#{i},#{j}"

      switch move
        when "0,0" then move = 0
        when "0,1" then move = 1
        when "0,2" then move = 2
        when "1,0" then move = 3
        when "1,1" then move = 4
        when "1,2" then move = 5
        when "2,0" then move = 6
        when "2,1" then move = 7
        when "2,2" then move = 8

      console.log(rank)
      cells = ($ 'section#board div.cell')
      $(cells[move]).text(type)

      @.checkForWinner()

    getMax: (rank) ->
      max = [].concat(rank...)
      max = max.sort()
      max = max[max.length - 1]
      return max

    checkCorners: (opponent, rank) ->
      corners = [($ 'div.row1.col1'),($ 'div.row1.col3'),($ 'div.row3.col1'),($ 'div.row3.col3')]
      if corners[0].text() is opponent and corners[3].text() is " "
         rank[2][2] += 1
      if corners[3].text() is opponent and corners[0].text() is " "
         rank[0][0] += 1
      if corners[1].text() is opponent and corners[2].text() is " "
         rank[2][0] += 1
      if corners[2].text() is opponent and corners[1].text() is " "
         rank[0][2] += 1
      return rank

    checkForWinAndBlock: (type, amount, rank) ->
      rank = rank
      rows  = [($ 'div.row1'),($ 'div.row2'),($ 'div.row3')]
      cols  = [($ 'div.col1'),($ 'div.col2'),($ 'div.col3')]
      ltrs  = ($ 'div.row1.col1, div.row2.col2, div.row3.col3')
      rtls  = ($ 'div.row3.col1, div.row2.col2, div.row1.col3')
      # Check for winning moves horizontally
      for row, index in rows
        results = []
        row.each ->
          if $(@).hasClass("row#{index + 1}")
            if $(@).text() is type
              results.push($(@))
              if results.length is 2
                for cell, i in rank[index]
                  if cell isnt 0
                    rank[index][i] = amount
      # Check for winning moves vertically
      for col, index in cols
        results = []
        col.each ->
          if $(@).hasClass("col#{index + 1}")
            if $(@).text() is type
              results.push($(@))
              if results.length is 2
                rank_cols = [rank[0][index],rank[1][index],rank[2][index]]
                for cell, i in rank_cols
                  if cell isnt 0
                    rank_cols[i] = amount
                [rank[0][index],rank[1][index],rank[2][index]] = rank_cols
      # Check the angles for winning moves
      result = 0
      ltrs.each ->
        if $(@).text() is type
          result += 1
          if result is 2
            for n in [0..2]
              rank[n][n] = amount if rank[n][n] isnt 0
      result = 0
      rtls.each ->
        if $(@).text() is type
          result += 1
          if result is 2
            for n in [0..2]
              rank[2-n][n] = amount if rank[2-n][n] isnt 0
      return rank


    resetCell:(e)=> 
      ($ e.target).removeClass('invalid')
      ($ e.target).removeClass('valid') 

    switchPlayer: ->
      @currentPlayer = if @currentPlayer is @player1 then @player2 else @player1
      if @currentPlayer.human isnt true
        setTimeout(@.computerMove(@currentPlayer), 800)
      notice("#{@currentPlayer.type}: It's your turn")


  class Player
    constructor: (type, human) ->
      @type  = type
      @human = human ? true


  ($ '#offOrOnline').submit (event) ->

    ($ 'section#board div.cell').off()
    event.target.checkValidity()
    event.preventDefault()

    if ($ 'select#onOrOff option:selected').val() is "offline"
      ($ 'section#off-online').hide()
      ($ 'section#setup').show()
      ($ '#start_button').focus()

    if ($ 'select#onOrOff option:selected').val() is "online"
      socket = io.connect('http://localhost')
      socket.on('move', (data) ->
        console.log(data)
        socket.emit('move', { my: 'data'})
      )
      ($ 'section#off-online').hide()
      ($ 'section#board').show()

  ($ '#gameOptions').submit (event) ->
    ($ 'section#board div.cell').off()
    delete game if game isnt null
    event.target.checkValidity()
    event.preventDefault()
    game = new Game [($ '#player-count').val(), ($ '#player-1-type').val(), ($ '#player-2-type').val()]

    ($ 'section#setup').slideToggle()
    ($ 'section#board').show()
