require 'tty-table'
require 'tty-prompt'
require 'rainbow'

class TicTacToe
  EMPTY_CELL = ' '

  attr_reader :board

  WIN_COMBINATIONS = [
    [0, 1, 2], [3, 4, 5], [6, 7, 8],
    [0, 3, 6], [1, 4, 7], [2, 5, 8],
    [0, 4, 8], [2, 4, 6]
  ]

  def initialize
    @board = Array.new(9, EMPTY_CELL)
    @prompt = TTY::Prompt.new
    @current_player = 'X'
  end

  def display_board
    table = TTY::Table.new([
      display_row(0..2),
      :separator,
      display_row(3..5),
      :separator,
      display_row(6..8)
    ])

    puts table.render(:unicode)
  end

  def display_row(range)
    range.map { |index| display_cell(index) }
  end

  def display_cell(index)
    cell = @board[index]
    return (index + 1).to_s if cell == EMPTY_CELL

    colored_token(cell) || cell
  end

  def colored_token(token)
    return Rainbow(token).red if token == 'X'
    return Rainbow(token).blue if token == 'O'
  end

  def move(index, player)
    @board[index] = player
  end

  def switch_player
    @current_player = @current_player == 'X' ? 'O' : 'X'
  end

  def position_taken?(index)
    @board[index] != EMPTY_CELL
  end

  def valid_move?(index)
    index.between?(0, 8) && !position_taken?(index)
  end

  def make_move
    available = @board.map.with_index { |cell, index| cell == EMPTY_CELL ? index + 1 : nil }.compact
    selected_position = @prompt.select("Player #{@current_player}, choose position:", available)

    move(selected_position - 1, @current_player)
  end

  def winner?
    WIN_COMBINATIONS.any? do |combo|
      values = combo.map { |i| @board[i] }

      values.uniq.length == 1 && values.first != EMPTY_CELL
    end
  end

  def draw?
    @board.none? { |cell| cell == EMPTY_CELL }
  end

  def render_screen
    system('clear')
    display_board
  end

  def play
    loop do
      render_screen
      make_move

      if winner?
        render_screen
        puts Rainbow("Player #{@current_player} wins! 🎉").green
        break
      end

      if draw?
        render_screen
        puts Rainbow("It's a draw! 🤝").yellow
        break
      end

      switch_player
    end
  end

end

game = TicTacToe.new
game.play
