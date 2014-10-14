require 'yaml'

class Board
  
  def initialize
    @board = Array.new(9) { Array.new(9) }
    @bomb_num = 8
    board_set
  end
  
  def random
    (0...9).to_a.sample
  end
  
  def board_set
    len = @board.size
    bomb_pos_arr = []
   
    # maybe bombing the same city twice?
    @bomb_num.times { bomb_pos_arr << [random, random] }
    
    (0...len).each do |i|
      (0...len).each do |j|
        neighbombs = set_neighbombs(i, j, bomb_pos_arr)
        if bomb_pos_arr.include?([i, j])
          @board[i][j] = Tile.new([i, j], neighbombs, true) # pass in board
        else
          @board[i][j] = Tile.new([i, j], neighbombs)
        end
      end
    end
  end
  
  def set_neighbombs(x, y, bomb_pos_arr)
    bomb_num = 0
    moves = [[0, 1], [0, -1], [1, 0], [1, -1], [-1, 0], [-1, 1], [1, 1], [-1, -1]]
    
    moves.each do |move|
      pos = [x + move[0], y + move[1] ]
      bomb_num += 1 if bomb_pos_arr.include?(pos)
    end
    
    bomb_num
  end
  
  def display_cheat
    len = @board.size
    (0...len).each do |i|
      puts
      (0...len).each do |j|
        tile = @board[i][j]
        if tile.bombed
          print "b "
        else
          print "_ "
        end
      end
    end
    puts
  end
  
  def display # move some of this into Tile#to_s
    len = @board.size
    (0...len).each do |i|
      puts
      (0...len).each do |j|
        tile = @board[i][j]
        if tile.revealed
          if tile.neighbombs > 0
            print "#{tile.neighbombs} "
          else
            print "_ " 
          end
        elsif tile.flagged
          print "F "
        else
          print "* "
        end
      end
    end
    puts
  end
  
  def won?
    select_tiles(:bombed) == select_tiles(:flagged)
  end
  
  # def tiles
  #   @board.flatten
  # end
  #
  # def bombed_tiles
  #   tiles.select(&:bombed?)
  # end
  
  def select_tiles(flag)
    # @board.flatten.select(&flag)
    [].tap { |arr| @board.select { |row| arr.concat(row.select(&flag)) } }
  end
  
  def [](pos)
    x, y = pos
    @board[x][y]
  end

end

class Minesweeper
  
  attr_accessor :board
  
  def initialize
    @board = Board.new
  end
  
  def open_saved_game
    puts "Would you like to open your last saved game? y/n"
    ans = gets.chomp
    saved_game = nil
    saved_game = YAML.load(File.read('minesweeper_save.txt')) if ans == 'y'
  end
  
  def play
    saved_game = open_saved_game
    self.board = saved_game.board unless saved_game.nil?
    
    until board.won?
      board.display_cheat
      board.display
      pos, command = user_input
      return p "You lost..." if command == 'r' && board[pos].bombed
      
      board[pos].range_check(board) if command == 'r'
      board[pos].set_flag if command == 'f' 
    end
    
    p "You won!!!"
  end
  
  def user_input
    puts "Would you like to save your game? y/n"
    ans = gets.chomp
    File.open('minesweeper_save.txt', 'w') { |f| f.puts(self.to_yaml) } if ans == 'y'
    puts "Please input the x, y coordinates and reveal (r), or flag (f) command, ex: x, y, r"
    input = gets.chomp
    *pos, command = input.split(', ')
    pos.map!(&:to_i)
    [pos, command]
  end

end


class Tile
  DIFFS = [[0, 1], [0, -1], [1, 0], [1, -1], [-1, 0], [-1, 1], [1, 1], [-1, -1]]
  
  attr_accessor :bombed, :revealed, :flagged, :neighbombs
  
  def initialize(pos, neighbombs, bombed = false, revealed = false, flagged = false)
    @bombed = bombed
    @revealed = revealed
    @flagged = flagged
    @pos = pos
    @neighbombs = neighbombs
  end
  
  def set_flag
    self.flagged = !flagged
  end
  
  def neighbors
    
  end
  
  def range_check(board)
    x, y = @pos
    self.revealed = true
    moves = [[0, 1], [0, -1], [1, 0], [1, -1], [-1, 0], [-1, 1], [1, 1], [-1, -1]]
    
    moves.each do |move|
      pos = [x + move[0], y + move[1] ]
      next if pos[0] > 8 || pos[1] > 8 || pos[0] < 0 || pos[1] < 0 ||
                                    board[pos].revealed || board[pos].bombed
      if board[pos].neighbombs > 0
        board[pos].revealed = true
        return nil 
      end
      
      board[pos].revealed = true
      
      board[pos].range_check(board)
    end
    
  end
  
end

game = Minesweeper.new
game.play
#File.open('minesweeper_save.txt', 'w') { |f| f.puts(game.to_yaml) }
