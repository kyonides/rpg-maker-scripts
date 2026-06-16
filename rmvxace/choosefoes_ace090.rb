# * ChooseFoes ACE * #
#   Not Exactly a Plug-n-Play Script
#   Scripter : Kyonides
#   0.9.0 - 2026-06-16

# This scriptlet allows you to open a simple menu where you can choose your
# enemy's troops based on the current map's random enemy encounter list.

# - AVAILABLE MODES: :accessory and :levels

# * Accessory Mode * #
# Setting a specific "Choose Foe" accessory is mandatory here!
# * Average Level Mode * #
# You must set a default level plus any specific map's average level.

# * Optional Script Call * #
# $game_party.choose_foes_mode = :your_mode

module ChooseFoes
  MODE = :levels
  ACCESSORY_ID = 53
  MAP_ACTOR_LVL = {}
  MAP_ACTOR_LVL[1] = 4
  MAP_ACTOR_LVL.default = 5
  TITLE = "Pick Your Foe"
  @list = [] # Leave this array alone!
  extend self
  attr_accessor :list

  class Scene
    def initialize
      @list = $game_map.encounter_list.map(&:troop_id)
      @commands = @list.map {|n| $data_troops[n].name }
      ChooseFoes.list = @commands
    end

    def main
      BattleManager.play_battle_bgm
      @stage = true
      bn1 = $game_map.battleback1_name
      if bn1
        @backdrop = Sprite.new
        @backdrop.bitmap = Cache.battleback1(bn1)
      end
      bn2 = $game_map.battleback2_name
      if bn2
        @floor = Sprite.new
        @floor.bitmap = Cache.battleback2(bn2)
      end
      @help_window = Window_Help.new(1)
      @help_window.set_text(TITLE)
      @command_window = TroopListWindow.new(182, 80)
      Input.update
      Graphics.transition(Graphics.frame_rate)
      while @stage
        Graphics.update
        Input.update
        update
      end
      Graphics.freeze
      @command_window.dispose
      @help_window.dispose
      if bn2
        @floor.bitmap.dispose
        @floor.dispose
      end
      if bn1
        @backdrop.bitmap.dispose
        @backdrop.dispose
      end
    end

    def update
      @command_window.update
      if Input.trigger?(:B) or Input.trigger?(:C)
        Sound.play_battle_start
        @stage = nil
        n = @command_window.index
        troop_id = @list[n]
        ChooseFoes.list.clear
        BattleManager.setup(troop_id)
        BattleManager.save_bgm_and_bgs
        SceneManager.goto(Scene_Battle)
      end
    end
  end
end

class Game_BaseItem
  attr_reader :item_id
end

class Game_Actor
  FOES_ACCESSORY_ID = ChooseFoes::ACCESSORY_ID
  def armor_ids
    list = @equips.select(&:is_armor?)
    list.map(&:item_id)
  end

  def can_pick_foes?
    return false if FOES_ACCESSORY_ID == 0
    armor_ids.include?(FOES_ACCESSORY_ID)
  end
end

class Game_Party
  alias :kyon_chs_foes_gm_pty_init :initialize
  def initialize
    kyon_chs_foes_gm_pty_init
    @choose_foes_mode = ChooseFoes::MODE
  end

  def choose_foes_with_accessory?
    members.find {|a| a.can_pick_foes? } != nil
  end

  def choose_foes_level_avg?
    actors = members
    avg_level = actors.inject(0) {|t, a| t + a.level }
    avg_level /= actors.size
    map_level = ChooseFoes::MAP_ACTOR_LVL[$game_map.map_id]
    avg_level >= map_level
  end

  def choose_foes?
    case @choose_foes_mode
    when :accessory
      return choose_foes_with_accessory?
    when :levels
      return choose_foes_level_avg?
    end
  end
  attr_accessor :choose_foes_mode
end

class Game_Player
  def encounter
    return false if $game_map.interpreter.running?
    return false if $game_system.encounter_disabled
    return false if @encounter_count > 0
    make_encounter_count
    list = $game_map.encounter_list
    if list.size > 1 and $game_party.choose_foes?
      SceneManager.call(ChooseFoes::Scene)
      return false
    end
    troop_id = make_encounter_troop_id
    return false unless $data_troops[troop_id]
    BattleManager.setup(troop_id)
    BattleManager.on_encounter
    return true
  end
end

class TroopListWindow < Window_Command
  def make_command_list
    @list = ChooseFoes.list
  end

  def window_width
    180
  end

  def process_handling
    if Input.trigger?(:B) or Input.trigger?(:C)
      deactivate
    end
  end

  def draw_item(n)
    change_color(normal_color, true)
    draw_text(item_rect_for_text(n), @list[n], 0)
  end
end