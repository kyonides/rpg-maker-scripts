# * KItemDesc XP Zilsel Version
#   Scripter : Kyonides Arkanthes
#   v1.0.2 - 2019-11-24

# This scriptlet allows you to show custom icons and comments in the Inventory
# Menu scene. It will show the party leader's opinion on a given item.
# Place large icons in the Graphics/Pictures directory if you ever use them!
# You may also allow the player to check out his or her skills on the same menu
# by activating a global switch via an event command. It can be deactivated at
# any given time!

module KItemDesc
  INCLUDE_SKILLS_SWITCH_ID = 1
  PICTURE_X = 12
  PICTURE_Y = 12
  PICTURE_CENTER_X = true # true - Ignores X coordinate, false - uses X
  PICTURE_CENTER_Y = true # true - Ignores Y coordinate, false - uses Y
  COMMENTS_Y = 180
  ACTOR_OPINION_LABEL = "%s's Opinion"
  # Comments may include newlines alias \n if needed.
  DEFAULT_COMMENT = "The hero has nothing to say\nabout this"
  @comments = {} # There's no need to edit this line.
  # [[Kind, ID]] = { ActorID => "Hero's comment on current item", etc. }
  # Kind Options - :item, :weapon, :armor, :skill - Check the following example.
  @comments[[:item, 1]] = {
    1 => "You know, I'll never need potions\nfor I'm invincible!"
  }
  @comments.default = {} # Do not touch this! It will eat you alive!
  def self.comments() @comments end
end

class Game_Party
  def leader() @actors[0] end
end

class ItemDescWindow < Window_Base
  include KItemDesc
  def initialize
    super(320, 64, 320, 416)
    self.contents = Bitmap.new(width - 32, height - 32)
  end

  def refresh(new_item)
    return if @item == new_item
    @item = new_item
    c = self.contents
    c.clear
    return if @item.nil?
    lid = $game_party.leader.id
    name = $game_party.leader.name
    key = [@item.type, @item.id]
    comments = KItemDesc.comments[key][lid] || DEFAULT_COMMENT
    comments = comments.split("\n")
    text = sprintf(ACTOR_OPINION_LABEL, name)
    icon_name = @item.icon_name
    begin
      bit = RPG::Cache.picture(icon_name)
    rescue
      bit = RPG::Cache.icon(icon_name)
    end
    rect = Rect.new(0, 0, bit.width, bit.height)
    icon_x = PICTURE_CENTER_X ? 288 / 2 - bit.width / 2 : PICTURE_X
    icon_y = PICTURE_CENTER_Y ? COMMENTS_Y / 2 - bit.height / 2 : PICTURE_Y
    c.blt(icon_x, icon_y, bit, rect)
    c.draw_text(0, COMMENTS_Y, 288, 24, text)
    comments.size.times do |n|
      c.draw_text(0, COMMENTS_Y + 28 + n * 24, 288, 24, comments[n])
    end
  end
end

module RPG
  class Item
    def type() :item end
  end

  class Weapon
    def type() :weapon end
  end

  class Armor
    def type() :armor end
  end

  class Skill
    def type() :skill end
  end
end

class Game_Party
  def item_keys() @items.keys.sort end
  def weapon_keys() @weapons.keys.sort end
  def armor_keys() @armors.keys.sort end
  def skills() @actors.map{|a| a.skills } end
  def skill_number(item_id) skills.select{|n| n == item_id}.size end
end

class Window_Item
  alias :kyon_itemdesc_win_item_up_help :update_help
  def initialize
    battle = $game_temp.in_battle
    w = battle ? 640 : 320
    super(0, 64, w, 416)
    refresh
    self.index = 0
    return unless battle
    @column_max = 2
    self.y = 64
    self.height = 256
    self.back_opacity = 160
  end

  def refresh
    if self.contents != nil
      self.contents.dispose
      self.contents = nil
    end
    @data = []
    $game_party.item_keys.each{|i| @data << $data_items[i] }
    unless $game_temp.in_battle
      $game_party.weapon_keys.each{|i| @data << $data_weapons[i] }
      $game_party.armor_keys.each{|i| @data << $data_armors[i] }
      if $game_switches[KItemDesc::INCLUDE_SKILLS_SWITCH_ID]
        $game_party.skills.each{|i| @data << $data_skills[i] }
      end
    end
    @item_max = @data.size
    if @item_max > 0
      self.contents = Bitmap.new(width - 32, row_max * 32)
      @item_max.times{|i| draw_item(i) }
    end
    @desc_window.refresh(@data[@index]) if @desc_window
  end

  def draw_item(index)
    item = @data[index]
    number = current_item_number(item.type, item.id)
    usable = (item.type == :item and $game_party.item_can_use?(item.id))
    self.contents.font.color = usable ? normal_color : disabled_color
    x = 4 + index % @column_max * (288 + 32)
    y = index / @column_max * 32
    rect = Rect.new(x, y, self.width / @column_max - 32, 32)
    self.contents.fill_rect(rect, Color.new(0, 0, 0, 0))
    bitmap = RPG::Cache.icon(item.icon_name)
    opacity = self.contents.font.color == normal_color ? 255 : 128
    self.contents.blt(x, y + 4, bitmap, Rect.new(0, 0, 24, 24), opacity)
    self.contents.draw_text(x + 28, y, 212, 32, item.name, 0)
    self.contents.draw_text(x + 240, y, 16, 32, ":", 1)
    self.contents.draw_text(x + 256, y, 24, 32, number.to_s, 2)
  end

  def current_item_number(item_type, item_id)
    case item_type
    when :item
      $game_party.item_number(item_id)
    when :weapon
      $game_party.weapon_number(item_id)
    when :armor
      $game_party.armor_number(item_id)
    when :skill
      $game_party.skill_number(item_id)
    end
  end

  def desc_window=(new_window)
    @desc_window = new_window
    @desc_window.refresh(@data[@index])
  end

  def update_help
    kyon_itemdesc_win_item_up_help
    @desc_window.refresh(@data[@index]) if @desc_window
  end
end

class Scene_Item
  def main
    @item_desc = ItemDescWindow.new
    @help_window = Window_Help.new
    @item_window = Window_Item.new
    @item_window.help_window = @help_window
    @item_window.desc_window = @item_desc
    @target_window = Window_Target.new
    @target_window.visible = false
    @target_window.active = false
    Graphics.transition
    main_loop until $scene != self
    Graphics.freeze
    @item_desc.dispose
    @help_window.dispose
    @item_window.dispose
    @target_window.dispose
  end

  def main_loop
    Graphics.update
    Input.update
    update
  end
end