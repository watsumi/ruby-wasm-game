require 'js'

STAGE_ROWS = 12.freeze
STAGE_COLS = 6.freeze
FALLING_SPEED = 0.4.freeze

class Game
  attr_accessor :is_over, :stage, :mode, :pos_x, :pos_y

  def initialize
    @is_over = false
    @stage = Stage.new
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
    if @pos_y + 1 < STAGE_ROWS && stage.board[@pos_y + 1][@pos_x] == 0
      # 下のマスが空いている場合は、下に移動する
      pictograph = stage.board[@pos_y][@pos_x]
      stage.board[@pos_y][@pos_x] = 0
      stage.set_pic(@pos_x, @pos_y, 0)
      stage.board[@pos_y + 1][@pos_x] = pictograph
      stage.set_pic(@pos_x, @pos_y + 1, pictograph)
      @pos_y += 1
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

window = JS.global[:window]
game = Game.new

window.requestAnimationFrame(lambda { |_| game.loop_action })
