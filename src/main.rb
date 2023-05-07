require 'js'

STAGE_ROWS = 12.freeze
STAGE_COLS = 6.freeze
FALLING_SPEED = 0.2.freeze
ERASE_PIC_COUNT = 4.freeze

class Game
  attr_accessor :is_over, :stage, :player, :mode, :pos_x, :pos_y

  def initialize
    @is_over = false
    @stage = Stage.new
    @player = Player.new
    @player.add_event_listener
    @mode = 'create_pictograph'
    @pos_x = 2
    @pos_y = 0
  end

  def loop_action
    return if @is_over
    case @mode
    when 'create_pictograph'
      create
    when 'move_pictograph'
      move
    when 'erase_pictograph'
      if check_erase
        erase
      else
        @mode = 'create_pictograph'
      end
    when 'fall_pictograph'
      fall
    end
    sleep(FALLING_SPEED)
    window.requestAnimationFrame(lambda { |_| loop_action })
  end

  def create
    @pos_x = 2
    @pos_y = 0
    if stage.board[@pos_y][@pos_x] == 0
      stage.set_pic(@pos_x, @pos_y, Pictograph.new.type)
      @mode = 'move_pictograph'
    else
      @is_over = true
    end
  end

  def move
    if @player.key_status[:left] && @pos_x - 1 >= 0 && stage.board[@pos_y][@pos_x - 1] == 0
      # 左をクリックしていて、左のマスが空いている場合は、左に移動する
      swap_pic(@pos_x, @pos_y, @pos_x - 1, @pos_y)
      @pos_x -= 1
    elsif @player.key_status[:right] && @pos_x + 1 < STAGE_COLS && stage.board[@pos_y][@pos_x + 1] == 0
      # 右をクリックしていて、右のマスが空いている場合は、右に移動する
      swap_pic(@pos_x, @pos_y, @pos_x + 1, @pos_y)
      @pos_x += 1
    elsif @pos_y + 1 < STAGE_ROWS && stage.board[@pos_y + 1][@pos_x] == 0
      # 下のマスが空いている場合は、下に移動する
      swap_pic(@pos_x, @pos_y, @pos_x, @pos_y + 1)
      @pos_y += 1
      if @player.key_status[:down] && @pos_y + 1 < STAGE_ROWS && stage.board[@pos_y + 1][@pos_x] == 0
        # 下をクリックしていて、下のマスが空いている場合は、下に移動する
        swap_pic(@pos_x, @pos_y, @pos_x, @pos_y + 1)
        @pos_y += 1
      end
    else
      # 下のマスが空いていない場合は、現在の位置に固定し、ピクトグラムが消せるかどうかをチェックする
      @mode = 'erase_pictograph'
    end
  end

  def check_erase
    @erased_pictographs = []
    @sequence_pictographs = []
    @existing_pictographs = []

    def check_sequence(x, y)
      origin_pictograph = stage.board[y][x]
      return if origin_pictograph == 0

      pictograph = origin_pictograph
      @sequence_pictographs.push({ x: x, y: y, pictograph: pictograph })
      stage.board[y][x] = 0

      direction = [[0, 1], [1, 0], [0, -1], [-1, 0]]
      direction.each do |d|
        next_x = x + d[0]
        next_y = y + d[1]
        next if next_x < 0 || next_x >= STAGE_COLS || next_y < 0 || next_y >= STAGE_ROWS
        next_pictograph = stage.board[next_y][next_x]
        next if next_pictograph == 0 || pictograph != next_pictograph
        check_sequence(next_x, next_y)
      end
    end

    0.upto(STAGE_ROWS - 1) do |y|
      0.upto(STAGE_COLS - 1) do |x|
        @sequence_pictographs = []
        check_sequence(x, y)
        if @sequence_pictographs.size < ERASE_PIC_COUNT
          @existing_pictographs << @sequence_pictographs
        else
          @erased_pictographs << @sequence_pictographs
        end
      end
    end
    @existing_pictographs = @existing_pictographs.flatten.uniq
    @existing_pictographs.each do |pic|
      stage.board[pic[:y]][pic[:x]] = pic[:pictograph]
    end

    @erased_pictographs = @erased_pictographs.flatten.uniq
    return @erased_pictographs.size > 0
  end

  def erase
    @erased_pictographs.each do |pic|
      stage.board[pic[:y]][pic[:x]] = 0
      stage.set_pic(pic[:x], pic[:y], 0)
    end
    @mode = 'fall_pictograph'
  end

  def fall
    (STAGE_ROWS - 1).downto(0) do |y|
      0.upto(STAGE_COLS - 1) do |x|
        next if stage.board[y][x] != 0
        dist = pointer = y
        # 落下地点より上にあるピクトグラムを探す
        while dist - 1 >= 0
          dist -= 1
          next if stage.board[dist][x] == 0
          swap_pic(x, dist, x, pointer)
          pointer -= 1
        end
      end
    end
    @mode = 'erase_pictograph'
  end

  private

  def window
    @window ||= JS.global[:window]
  end

  def swap_pic(x1, y1, x2, y2)
    pictograph = stage.board[y1][x1]
    stage.board[y1][x1] = stage.board[y2][x2]
    stage.board[y2][x2] = pictograph
    stage.set_pic(x1, y1, stage.board[y1][x1])
    stage.set_pic(x2, y2, stage.board[y2][x2])
  end
end

class Stage
  attr_accessor :element, :board, :pictographes

  def initialize
    @element = document.getElementById("stage")
    @board = init_board
  end

  def set_pic(x, y, pictograph_type)
    span_tag = document.getElementById("#{y}-#{x}")
    span_tag[:innerText] = pictograph_type == 0 ? '' : pictograph_type
    board[y][x] = pictograph_type
  end

  private

  def document
    @document ||= JS.global[:document]
  end

  def init_board
    [
      [0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0],
    ]
  end
end

class Pictograph
  attr_accessor :type

  def initialize
    @type = types.sample
  end

  private

  def types
    @types ||= ['😭', '😄', '😆', '😷', '🥺', '😊', '😴', '😎', '😜']
  end
end

class Player
  attr_accessor :key_status

  def initialize
    @key_status = { left: false, up: false, right: false, down: false }
    @touch_point = { xs: 0, ys: 0, xe: 0, ye: 0 }
  end

  def add_event_listener
    document = JS.global[:document]
    document.addEventListener('keydown') do |e|
      case e[:keyCode].to_i
      when 37 # 左向きキー
        @key_status[:left] = true
        e.preventDefault()
      when 38 # 上向きキー
        @key_status[:up] = true
        e.preventDefault()
      when 39 # 右向きキー
        @key_status[:right] = true
        e.preventDefault()
      when 40 # 下向きキー
        @key_status[:down] = true
        e.preventDefault()
      end
    end
    document.addEventListener('keyup') do |e|
      case e[:keyCode].to_i
      when 37 # 左向きキー
        @key_status[:left] = false
        e.preventDefault()
      when 38 # 上向きキー
        @key_status[:up] = false
        e.preventDefault()
      when 39 # 右向きキー
        @key_status[:right] = false
        e.preventDefault()
      when 40 # 下向きキー
        @key_status[:down] = false
        e.preventDefault()
      end
    end
    document.addEventListener('touchstart') do |e|
      @touch_point[:xs] = e[:touches][0][:clientX].to_i
      @touch_point[:ys] = e[:touches][0][:clientY].to_i
    end
    document.addEventListener('touchmove') do |e|
      if (e[:touches][0][:clientX].to_i - @touch_point[:xs]).abs >= 20 || (e[:touches][0][:clientY].to_i - @touch_point[:ys]).abs >= 20

        @touch_point[:xe] = e[:touches][0][:clientX].to_i
        @touch_point[:ye] = e[:touches][0][:clientY].to_i
        xs, ys, xe, ye = @touch_point.values
        gesture(xs, ys, xe, ye)

        @touch_point[:xs] = @touch_point[:xe]
        @touch_point[:ys] = @touch_point[:ye]
      end
    end
    document.addEventListener('touchend') do |e|
      @key_status[:up] = false
      @key_status[:down] = false
      @key_status[:left] = false
      @key_status[:right] = false
    end
  end

  def gesture xs, ys, xe, ye
    horizon_direction = xe - xs
    vertical_direction = ye - ys
    if horizon_direction.abs < vertical_direction.abs
      # 縦方向
      if vertical_direction < 0
        # up
        @key_status[:up] = true
        @key_status[:down] = false
        @key_status[:left] = false
        @key_status[:right] = false
      elsif 0 <= vertical_direction
        # down
        @key_status[:up] = false
        @key_status[:down] = true
        @key_status[:left] = false
        @key_status[:right] = false
      end
    else
      # 横方向
      if horizon_direction < 0
        # left
        @key_status[:up] = false
        @key_status[:down] = false
        @key_status[:left] = true
        @key_status[:right] = false
      elsif 0 <= horizon_direction
        # right
        @key_status[:up] = false
        @key_status[:down] = false
        @key_status[:left] = false
        @key_status[:right] = true
      end
    end
  end
end

window = JS.global[:window]
game = Game.new

window.requestAnimationFrame(lambda { |_| game.loop_action })
