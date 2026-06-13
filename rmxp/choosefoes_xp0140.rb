# * ChooseFoes XP * #
#   Not Exactly a Plug-n-Play Script
#   Scripter : Kyonides
#   0.14.0 - 2026-05-09

# Aliased Methods: Game_Party#initialize, Scene_Map#call_battle

# This scriptlet allows you to open a simple menu where you can choose your
# enemy's troops based on the current map's random enemy encounter list.
# They will be displayed on screen!

# The new MAP_ID_EXTRA_TROOP hash allows you to set a key-value pair of
# MapID => TroopID to add any given troop found in the Troops DB to that map.
# You can replace the TroopID with a :highest or :lowest or :random symbol.
# Notice: This is entirely optional. Use it only for maps that truly need it.

# - AVAILABLE MODES: :accessory and :levels

# * Accessory Mode * #
# Setting a specific "Choose Foe" accessory is mandatory here!
# * Average Level Mode * #
# You must set a default level plus any specific map's average level.

# * Optional Script Call * #
# $game_party.choose_foes_mode = :your_mode

module ChooseFoes
  MODE = :levels
  ACCESSORY_ID = 33
  MAP_ACTOR_LVL = {}
  MAP_ACTOR_LVL[1] = 4
  MAP_ACTOR_LVL.default = 5
  # MapID => TroopID or :highest or :lowest TroopID ever defeated or :random
  MAP_ID_EXTRA_TROOP = { 1 => 11 }
  TITLE = "Pick Your Foe"
  EXTRA_TROOP = "Special Troop"
  # ["Name", Volume or nil, Pitch or nil]
  BGM = ["052-Negative01", nil, nil]

  class TroopWindow < Window_Selectable
    def initialize(width, commands)
      line_max = [commands.size, 4].min + 1
      @commands = commands
      super(0, 0, width, line_max * 32)
      @item_max = commands.size
      @cw = width - 32
      @rect = Rect.new(4, 0, @cw - 8, 32)
      self.contents = Bitmap.new(@cw, @item_max * 32)
      refresh
      self.index = 0
      @last_index = 0
    end

    def refresh
      self.contents.clear
      @item_max.times {|n| draw_item(n, normal_color) }
    end

    def draw_item(n, color)
      self.contents.font.color = color
      @rect.y = 32 * n
      self.contents.draw_text(@rect, @commands[n])
    end

    def update
      super
      @change_troop = false
      if @index != @last_index
        @last_index = @index
        @change_troop = true
      end
    end
    attr_reader :change_troop
  end

  class Scene
    def initialize(cb)
      @callback = cb
      map_id = $game_map.map_id
      extra_troop_id = MAP_ID_EXTRA_TROOP[map_id]
      troops = $data_troops.size - 1
      @list = $game_map.encounter_list.dup
      @commands = @list.map {|n| $data_troops[n].name }
      if MAP_ID_EXTRA_TROOP.has_key?(map_id)
        @commands << EXTRA_TROOP
        case extra_troop_id
        when :lowest
          @list << $game_party.lowest_troop_id
        when :highest
          @list << $game_party.highest_troop_id
        when :random
          @list << $game_party.random_troop_id
        when 1..extra_troop_id
          n = [troops, extra_troop_id].min
          @list << n
        end
      end
      n = $game_temp.battle_troop_id
      @troop = Game_Troop.new
      @troop.setup(n)
      $game_system.se_play($data_system.battle_start_se)
      $game_system.bgm_stop
      bgm = BGM.compact
      bgm = RPG::AudioFile.new(*bgm)
      Audio.play_anon_bgm(bgm)
    end

    def main
      @stage = true
      fn = $game_map.battleback_name
      bb = RPG::Cache.battleback(fn)
      battle_bit = Bitmap.new(640, 480)
      battle_bit.stretch_blt(battle_bit.rect, bb, bb.rect)
      n = $game_temp.battle_troop_id
      enemies = @troop.enemies
      @backdrop = Sprite.new
      @backdrop.bitmap = battle_bit
      @vp = Viewport.new(0, 0, 640, 320)
      @vp.z = 200
      @battlers = []
      8.times do |n|
        battler = Sprite_Battler.new(@vp, enemies[n])
        battler.update
        battler.opacity = 255
        @battlers << battler
      end
      @help_window = Window_Help.new
      @help_window.set_text(TITLE, 1)
      @command_window = TroopWindow.new(240, @commands)
      @command_window.x = 200
      @command_window.y = 320
      @command_window.index = @list.index(n)
      Input.update
      Graphics.transition(Graphics.frame_rate)
      while @stage
        Graphics.update
        Input.update
        update
      end
      Graphics.freeze
      dispose
    end

    def update
      @command_window.update
      if @command_window.change_troop
        i = @command_window.index
        @troop.setup(@list[i])
        enemies = @troop.enemies
        8.times do |n|
          sbattler = @battlers[n]
          sbattler.change(enemies[n])
        end
      end
      if Input.trigger?(Input::B) or Input.trigger?(Input::C)
        $game_system.se_play($data_system.decision_se)
        @stage = nil
        n = @command_window.index
        $game_temp.battle_troop_id = @list[n]
        @callback.call
      end
    end

    def dispose
      @battlers.each do |s|
        s.bitmap.dispose if s.bitmap
        s.dispose
      end
      @command_window.dispose
      @help_window.dispose
      @vp.dispose
      @backdrop.bitmap.dispose
      @backdrop.dispose
    end
  end
end

module Audio
  def self.play_anon_bgm(bgm)
    if !bgm or bgm.name.empty?
      bgm_stop
    else
      bgm_play("Audio/BGM/" + bgm.name, bgm.volume, bgm.pitch)
    end
    Graphics.frame_reset
  end
end

class Game_Actor
  def can_pick_foes?
    ChooseFoes::ACCESSORY_ID == @armor4_id and @armor4_id > 0
  end
end

class Game_Party
  alias :kyon_chs_foes_gm_pty_init :initialize
  def initialize
    kyon_chs_foes_gm_pty_init
    @choose_foes_mode = ChooseFoes::MODE
    @defeated_troop_ids = []
  end

  def choose_foes_with_accessory?
    @actors.find {|a| a.can_pick_foes? } != nil
  end

  def choose_foes_level_avg?
    avg_level = @actors.inject(0) {|t, a| t + a.level }
    avg_level /= @actors.size
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

  def lowest_troop_id
    @defeated_troop_ids.min || 1
  end

  def highest_troop_id
    @defeated_troop_ids.max || 1
  end

  def random_troop_id
    n = rand(@defeated_troop_ids.size)
    @defeated_troop_ids[n] || 1
  end
  attr_accessor :choose_foes_mode
end

class Sprite_Battler
  def change(battler)
    @battler = battler
    unless @battler
      self.bitmap = nil
      loop_animation(nil)
      return
    end
    if @battler.battler_name != @battler_name or
       @battler.battler_hue != @battler_hue
      @battler_name = @battler.battler_name
      @battler_hue = @battler.battler_hue
      self.bitmap = RPG::Cache.battler(@battler_name, @battler_hue)
      @width = bitmap.width
      @height = bitmap.height
      self.ox = @width / 2
      self.oy = @height
    end
  end
end

class Scene_Map
  alias :kyon_chs_foes_scn_mp_cll_btl :call_battle
  def call_battle
    list = $game_map.encounter_list
    if list.size > 1 and $game_party.choose_foes?
      cb = method(:kyon_chs_foes_scn_mp_cll_btl)
      $scene = ChooseFoes::Scene.new(cb)
    else
      kyon_chs_foes_scn_mp_cll_btl
    end
  end
end