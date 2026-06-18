# * KPocket XP
#   Scripter : Kyonides Arkanthes
#   v1.0.6 - 2019-12-01

# This script allows the player to send specific items, no weapons nor armors
# included, to a pocket with a limited storage space. You can open this new menu
# via a script call or open the item menu and hitting the OPEN_BUTTON. If the
# player opened the new Pocket menu, the player will be able to replenish items
# or send them back to their inventory.

# Pressing the SEND_ITEM_BUTTON will send an item to the pocket. The amount is
# fixed based on the current value of the KPocket.item_limit variable.

# * Script Calls *

# $scene = KPocketItem.new
#   Opens the Pocket Menu!

# KPocket.slot_limit = Integer
#   Set a new slot limit for your pocket.

# KPocket.item_limit = Integer
#   Set a new limit for items of the same kind.

module KPocket
  SWITCH_ID = 1 # Switch that activates Pocket instead of Bag
  OPEN_BUTTON = Input::CTRL # Open KPocket Menu!
  SEND_ITEM_BUTTON = Input::SHIFT
  HELP_BUTTON = Input::Z
  HELP_BUTTON_TITLE = 'Available Buttons'
  HELP_BUTTONS = %w{SHIFT CTRL Z B}
  HELP_BUTTON_DATA = [
    'Send items to your pocket',
    'Open Pocket Menu',
    'Open this help window',
    'Cancel or Close any menu'
  ]
  SENT_ITEM_LABEL = "Sent %s %s to your pocket!"
  OPTIONS = ['Refill', 'To Bag', 'Cancel']
  OPEN_CLOSE_INFO = ['C: Show options', 'B: Close or Exit']
  @slot_limit = 10 # How many different items will be allowed?
  @item_limit = 10 # Maximum number of items of the same kind
  class << self
    attr_accessor :slot_limit, :item_limit, :open_item_menu, :show_pocket_msg
  end
end

unless $HIDDENCHEST

module Graphics
  def self.width() 640 end
  def self.height() 480 end
end

end

class Game_Party
  alias :kyon_pocket_gm_party_init :initialize
  def initialize
    kyon_pocket_gm_party_init
    @pocket = {}
    @pocket.default = 0
  end

  def to_pocket(item_id, n)
    @pocket[item_id] += n
    @pocket.delete(item_id) if @pocket[item_id] == 0
    gain_item(item_id, -n)
  end

  def pocket_can_use?(item_id)
    return if @pocket[item_id] == 0
    occasion = $data_items[item_id].occasion
    ($game_temp.in_battle and occasion < 2)
  end
  def pocket_number(item_id) @pocket[item_id] end
  attr_reader :pocket
end

class Window_Selectable
  def no_item?() @data[index] == nil end
end

class Window_Item
  alias :kyon_pocket_win_item_up_help :update_help
  def update_help
    kyon_pocket_win_item_up_help unless KPocket.show_pocket_msg
  end
end

class KItemPocketWindow < Window_Selectable
  def initialize
    wh = $game_temp.in_battle ? 256 : 352
    super(0, 64, 640, wh)
    @column_max = 2
    refresh
    self.index = 0
    self.back_opacity = 160 if $game_temp.in_battle
  end

  def refresh
    if self.contents != nil
      self.contents.dispose
      self.contents = nil
    end
    @data = []
    $game_party.pocket.keys.sort.each{|n| @data << $data_items[n] }
    @item_max = @data.size
    return if @item_max == 0
    self.contents = Bitmap.new(width - 32, row_max * 32)
    @item_max.times{|pos| draw_item(pos) }
  end

  def draw_item(index)
    item = @data[index]
    number = $game_party.pocket_number(item.id)
    can_use = $game_party.pocket_can_use?(item.id)
    c = self.contents
    c.font.color = can_use ? normal_color : disabled_color
    x = 4 + index % 2 * (288 + 32)
    y = index / 2 * 32
    rect = Rect.new(x, y, self.width / @column_max - 32, 32)
    c.fill_rect(rect, Color.new(0, 0, 0, 0))
    bitmap = RPG::Cache.icon(item.icon_name)
    opacity = c.font.color == normal_color ? 255 : 128
    c.blt(x, y + 4, bitmap, Rect.new(0, 0, 24, 24), opacity)
    c.draw_text(x + 28, y, 212, 32, item.name, 0)
    c.draw_text(x + 240, y, 16, 32, ":", 1)
    c.draw_text(x + 256, y, 24, 32, number.to_s, 2)
  end

  def update_help
    text = no_item? ? "" : @data[@index].description
    @help_window.set_text(text)
  end
  def item() @data[@index] || RPG::Item.new end
end

class KButtonInfoWindow < Window_Base
  def initialize(x, w)
    super(x, 64, w, 416)
    bit = Bitmap.new(width - 32, height - 32)
    bw = bit.width
    bit.font.size = 24
    bit.draw_text(0, 0, bw, 26, KPocket::HELP_BUTTON_TITLE, 1)
    bit.fill_rect(8, 27, bw - 14, 4, Color.new(0, 0, 0))
    bit.fill_rect(8, 28, bw - 16, 2, normal_color)
    bit.font.size = 22
    data = KPocket::HELP_BUTTON_DATA
    buttons = KPocket::HELP_BUTTONS
    buttons.size.times do |n|
      by = 34 + n * 24
      bit.draw_text(0, by, bw, 24, buttons[n])
      bit.draw_text(96, by, bw, 24, data[n])
    end
    self.contents = bit
  end
end

class BasicButtonInfoWindow < Window_Base
  def initialize
    super(0, Graphics.height - 64, Graphics.width, 64)
    self.contents = Bitmap.new(width - 32, height - 32)
    half = width / 2
    labels = KPocket::OPEN_CLOSE_INFO
    contents.draw_text(0, 0, half, 24, labels[0])
    contents.draw_text(half, 0, half, 24, labels[1])
  end
end

class Scene_Item
  alias :kyon_pocket_scn_item_main :main
  alias :kyon_pocket_scn_item_up :update
  alias :kyon_pocket_scn_item_up_item :update_item
  def main
    @button_info = KButtonInfoWindow.new(130, 380)
    @button_info.visible = false
    kyon_pocket_scn_item_main
    @button_info.dispose
  end

  def update
    kyon_pocket_scn_item_up
    update_help if @stage == :help
  end

  def update_item
    kyon_pocket_scn_item_up_item
    if Input.trigger?(KPocket::OPEN_BUTTON)
      if $game_party.pocket.empty?
        return $game_system.se_play($data_system.buzzer_se)
      end
      $game_system.se_play($data_system.decision_se)
      return $scene = KPocketItem.new
    elsif Input.trigger?(KPocket::SEND_ITEM_BUTTON)
      @item = @item_window.item
      return $game_system.se_play($data_system.buzzer_se) unless @item
      return send_item2pocket
    elsif Input.trigger?(KPocket::HELP_BUTTON)
      $game_system.se_play($data_system.decision_se)
      @item_window.active = false
      @button_info.z = 200
      @button_info.visible = true
      return @stage = :help
    elsif Input.trigger?(Input::C) or Input.dir4 > 0
      KPocket.show_pocket_msg = false
    end
  end

  def send_item2pocket
    item_id = @item.id
    packed = KPocket.item_limit - $game_party.pocket_number(item_id)
    return $game_system.se_play($data_system.buzzer_se) if packed == 0
    $game_system.se_play($data_system.decision_se)
    number = $game_party.item_number(item_id)
    number = packed if number > packed
    $game_party.to_pocket(item_id, number)
    KPocket.show_pocket_msg = true
    @item_window.refresh
    text = sprintf(KPocket::SENT_ITEM_LABEL, number, @item.name)
    @help_window.set_text(text, 1)
  end

  def update_help
    if Input.trigger?(Input::B) or Input.trigger?(Input::C)
      $game_system.se_play($data_system.cancel_se)
      @stage = nil
      @button_info.z = 0
      @button_info.visible = false
      @item_window.active = true
    end
  end
end

class KPocketItem
  def main
    @stage = :main
    @help_window = Window_Help.new
    @item_window = KItemPocketWindow.new
    @item_window.help_window = @help_window
    @button_window = BasicButtonInfoWindow.new
    @options = Window_Command.new(192, KPocket::OPTIONS)
    @options.visible = false
    @options.active = false
    @options.x = (Graphics.width - 192) / 2
    @options.y = (Graphics.height - 128) / 2
    Graphics.transition
    main_loop while @stage
    Graphics.freeze
    @options.dispose
    @button_window.dispose
    @help_window.dispose
    @item_window.dispose
  end

  def main_loop
    Graphics.update
    Input.update
    update
  end

  def update
    @item_window.update
    if @stage == :main
      update_item
    elsif @stage == :choose
      update_select
    end
  end

  def update_item
    if Input.trigger?(Input::B)
      $game_system.se_play($data_system.cancel_se)
      $scene = KPocket.open_item_menu ? Scene_Item.new : Scene_Map.new
      KPocket.open_item_menu = nil
      return @stage = nil
    elsif Input.trigger?(Input::C)
      if @item_window.no_item?
        return $game_system.se_play($data_system.buzzer_se)
      end
      @item_id = @item_window.item.id
      @current = $game_party.pocket_number(@item_id)
      full = $game_party.pocket.size == KPocket.slot_limit
      if full or KPocket.item_limit == @current
        return $game_system.se_play($data_system.buzzer_se)
      end
      $game_system.se_play($data_system.decision_se)
      @item_window.active = false
      @options.active = true
      @options.visible = true
      @stage = :choose
    end
  end

  def update_select
    @options.update
    if Input.trigger?(Input::B)
      return to_main
    elsif Input.trigger?(Input::C)
      pos = @options.index
      return to_main if pos == 2
      $game_system.se_play($data_system.decision_se)
      if pos == 0
        packed = KPocket.item_limit - @current
        number = [$game_party.item_number(@item_id), packed].min
        $game_party.to_pocket(@item_id, number)
      else
        $game_party.to_pocket(@item_id, -@current)
      end
      @item_window.refresh
      @item_window.active = true
      @options.visible = false
      @options.active = false
      @stage = :main
    end
  end

  def to_main
    $game_system.se_play($data_system.cancel_se)
    @options.visible = false
    @options.active = false
    @item_window.active = true
    @stage = :main
  end
end

class Scene_Battle
  def start_item_select
    pocket_enabled = $game_switches[KPocket::SWITCH_ID]
    @item_window = pocket_enabled ? KItemPocketWindow.new : Window_Item.new
    @item_window.help_window = @help_window
    return unless @actor_command_window
    @actor_command_window.active = false
    @actor_command_window.visible = false
  end
end