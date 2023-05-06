require 'js'

STAGE_ROWS = 12.freeze
STAGE_COLS = 6.freeze
FALLING_SPEED = 0.4.freeze

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
      create_pictograph
    when 'move_pictograph'
      move_pictograph
    end
    sleep(FALLING_SPEED)
    window.requestAnimationFrame(lambda { |_| loop_action })
  end

  def create_pictograph
    if stage.board[0][2] == 0
      stage.set_pic(2, 0, Pictograph.new.type)
      @mode = 'move_pictograph'
    else
      @is_over = true
    end
  end

  def move_pictograph
    if @player.key_status[:left] && @pos_x - 1 >= 0 && stage.board[@pos_y][@pos_x - 1] == 0
      # 左をクリックしていて、左のマスが空いている場合は、左に移動する
      pictograph = stage.board[@pos_y][@pos_x]
      stage.board[@pos_y][@pos_x] = 0
      stage.set_pic(@pos_x, @pos_y, 0)
      stage.board[@pos_y][@pos_x - 1] = pictograph
      stage.set_pic(@pos_x - 1, @pos_y, pictograph)
      @pos_x -= 1
    elsif @player.key_status[:right] && @pos_x + 1 < STAGE_COLS && stage.board[@pos_y][@pos_x + 1] == 0
      # 右をクリックしていて、右のマスが空いている場合は、右に移動する
      pictograph = stage.board[@pos_y][@pos_x]
      stage.board[@pos_y][@pos_x] = 0
      stage.set_pic(@pos_x, @pos_y, 0)
      stage.board[@pos_y][@pos_x + 1] = pictograph
      stage.set_pic(@pos_x + 1, @pos_y, pictograph)
      @pos_x += 1
    elsif @pos_y + 1 < STAGE_ROWS && stage.board[@pos_y + 1][@pos_x] == 0
      # 下のマスが空いている場合は、下に移動する
      pictograph = stage.board[@pos_y][@pos_x]
      stage.board[@pos_y][@pos_x] = 0
      stage.set_pic(@pos_x, @pos_y, 0)
      stage.board[@pos_y + 1][@pos_x] = pictograph
      stage.set_pic(@pos_x, @pos_y + 1, pictograph)
      @pos_y += 1
      if @player.key_status[:down] && @pos_y + 1 < STAGE_ROWS && stage.board[@pos_y + 1][@pos_x] == 0
        # 下をクリックしていて、下のマスが空いている場合は、下に移動する
        pictograph = stage.board[@pos_y][@pos_x]
        stage.board[@pos_y][@pos_x] = 0
        stage.set_pic(@pos_x, @pos_y, 0)
        stage.board[@pos_y + 1][@pos_x] = pictograph
        stage.set_pic(@pos_x, @pos_y + 1, pictograph)
        @pos_y += 1
      end
    else
      # 下のマスが空いていない場合は、現在の位置に固定する
      # TODO: 4つ以上の同じ絵文字がつながったら消す
      @mode = 'create_pictograph'
      @pos_x = 2
      @pos_y = 0
    end
  end

  private

  def window
    @window ||= JS.global[:window]
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
    @types ||= ['😭', '😄', '👨', '‍👩', '‍👧', '‍👦']
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
