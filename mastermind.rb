# frozen_string_literal: true

# Rules
module Rules
  COLORS = %w[Red Green Yellow Blue Orange Violet].freeze

  def self.to_colors(numbers)
    numbers.map do |number|
      Rules::COLORS[number]
    end
  end

  def self.get_pegs(guess, sequence)
    pegs = []
    number_of_black_pegs(guess, sequence).times do
      pegs << 'Black'
    end
    number_of_white_pegs(guess, sequence, pegs).times do
      pegs << 'White'
    end
    while pegs.length < 4
      pegs << 'Empty'
    end
    pegs
  end

  def self.number_of_black_pegs(guess, sequence)
    blacks = 0
    guess.guess.each_index do |index|
      blacks += 1 if guess.guess[index] == sequence[index]
    end
    blacks
  end

  def self.number_of_white_pegs(guess, sequence, pegs)
    whites = Rules::COLORS.reduce(0) do |sum, color|
      sum + [guess.guess.count(color), sequence.count(color)].min
    end
    whites - pegs.length
  end

  def self.valid_input?(input)
    return false unless input.length == 4

    input.each do |entry|
      return false unless !Integer(self).nil? rescue false
      return false unless entry.to_i >= 1 && entry.to_i <= COLORS.length
    end
    true
  end
end

# KIPlayer
class KIPlayer
  def initialize
    @set = []
    (0...Rules::COLORS.length).each do |a|
      (0...Rules::COLORS.length).each do |b|
        (0...Rules::COLORS.length).each do |c|
          (0...Rules::COLORS.length).each do |d|
            @set << [a, b, c, d]
          end
        end
      end
    end

    @complete_set = @set
  end

  def reset
    @set = @complete_set
  end


  def make_sequence
    numbers = []
    4.times do
      numbers << rand(Rules::COLORS.length)
    end
    Rules.to_colors(numbers)
  end

  def get_guess(guesses)
    if guesses.empty?
      Guess.new(@set[rand(@set.length)])
    else
      @set = reduce_set(guesses[-1].pegs, guesses[-1].guess_numbers)
      Guess.new(@set[rand(@set.length)])
    end
  end

  def reduce_set(pegs, guess_numbers)
    @set.reduce([]) do |new_set, entry|
      test_guess = Guess.new(guess_numbers)
      sequence = Rules.to_colors(entry)
      test_pegs = Rules.get_pegs(test_guess, sequence)
      if pegs == test_pegs
        new_set << entry
      else
        new_set
      end
    end
  end
end

# Guess
class Guess
  attr_reader :guess, :pegs, :guess_numbers

  def initialize(numbers)
    @guess = Rules.to_colors(numbers)
    @guess_numbers = numbers
  end

  def set_pegs(pegs)
    @pegs = pegs
  end
end

# GM
class GM
  def initialize
    @player = Player.new
    @ki_player = KIPlayer.new
  end

  def main_loop
    puts 'MASTERMIND'

    running = true
    while running
      puts ''
      puts 'What do you want do?'
      puts '(g)uess, (q)uit, (s)et a sequence'
      input = gets.chomp
      case input
      when 'g'
        puts ''
        game_loop
      when 'q'
        running = false
      when 's'
        puts ''
        reverse_game_loop
      else
        puts 'Invalid input'
      end
    end
  end

  private

  def set_pegs(guess, sequence)
    guess.set_pegs(Rules.get_pegs(guess, sequence))
  end

  def game_loop
    @board = Board.new(@ki_player.make_sequence)
    @gamestate = 'playing'

    print_start_message

    guess_loop while @gamestate == 'playing'

    print_end_message
  end

  def reverse_game_loop
    @board = Board.new(@player.get_sequence)
    puts "Your sequence is: #{@board.sequence}"
    @ki_player.reset
    @gamestate = 'reverse_playing'

    reverse_guess_loop while @gamestate == 'reverse_playing'

    print_end_message
  end

  def guess_loop
    guess = @player.get_guess
    set_pegs(guess, @board.sequence)
    @board.add_guess(guess)
    puts ''
    @board.draw_board
    @gamestate = 'lost' if @board.guesses.length == 10
    @gamestate = 'won' if guess.guess == @board.sequence
  end

  def reverse_guess_loop
    guess = @ki_player.get_guess(@board.guesses)
    set_pegs(guess, @board.sequence)
    @board.add_guess(guess)
    puts ''
    @board.draw_board
    @gamestate = 'reverse_lost' if guess.guess == @board.sequence
    @gamestate = 'reverse_won' if @board.guesses.length == 10
  end

  def print_start_message
    case @gamestate
    when 'playing'
      puts 'Can you guess the secret Code in 10 tries?'
      puts 'You are looking for a sequence of four colors.'
      puts 'Your feedback is also color coded.'
      puts 'Black means: There is one correct color at the corect position.'
      puts 'White means: There is one correct color at a wrong position'
      puts ''
    when 'reverse_playing'
      puts 'Reverse Playing'
    else
      puts 'ERROR. This should not be reached'
    end
  end

  def print_end_message
    case @gamestate
    when 'lost'
      puts "You have lost! The correct sequence is #{@board.sequence}"
    when 'won'
      puts "You have won in #{@board.guesses.length} tries!"
    when 'reverse_lost'
      puts 'You have lost!'
      puts "The computer guessed your sequence in #{@board.guesses.length} tries"
    when 'reverse_won'
      puts "You have won! The computer couldn't guess your sequence."
    else
      puts 'ERROR! This should not be reached.'
    end
  end
end

# Board
class Board
  attr_reader :guesses, :sequence

  def initialize(sequence)
    @sequence = sequence
    @guesses = []
  end

  def add_guess(guess)
    @guesses << guess
  end

  def draw_board
    @guesses.each_with_index do |guess, index|
      puts "Guess Nr. #{index + 1}:"
      puts "Guess: #{guess.guess}"
      puts "Result: #{guess.pegs}"
      puts ''
    end
  end
end

# Player
class Player
  def get_guess
    input_is_valid = false
    until input_is_valid
      input = prompt_guess.split(' ')
      input_is_valid = Rules.valid_input?(input)
    end
    input = input.map { |entry| entry.to_i - 1 }
    Guess.new(input)
  end

  def get_sequence
    input_is_valid = false
    until input_is_valid
      input = prompt_sequence.split(' ')
      input_is_valid = Rules.valid_input?(input)
    end
    input = input.map { |entry| entry.to_i - 1 }
    Rules.to_colors(input)
  end

  private

  def prompt_guess
    puts 'The sequence can consist of the colors: '
    Rules::COLORS.each_with_index do |color, index|
      puts "#{index + 1}: #{color} "
    end
    puts 'Enter your guess (numbers seperated by spaces): '
    gets
  end

  def prompt_sequence
    puts 'Choose a sequence for the computer to guess.'
    puts 'The sequence can consist of the colors: '
    Rules::COLORS.each_with_index do |color, index|
      puts "#{index + 1}: #{color} "
    end
    puts 'Enter your sequence (numbers seperated by spaces): '
    gets
  end
end

gm = GM.new
gm.main_loop
