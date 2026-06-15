# * ChooseFoes XP * #
#   Not Exactly a Plug-n-Play Script
#   Scripter : Kyonides
#   1.1.0 - 2026-06-08

# Aliased Methods: Game_Party#initialize, Scene_Map#call_battle

# This scriptlet allows you to open a simple menu where you can choose your
# enemy's troops based on the current map's random enemy encounter list.
# They will be displayed on screen!

# The new MAP_ID_EXTRA_TROOP hash allows you to set a key-value pair of
# MapID => TroopID to add any given troop found in the Troops DB to that map.
# You can replace the TroopID with a :highest or :lowest or :random symbol.
# Notice: This is entirely optional. Use it only for maps that truly need it.

# Thanks to DerVVulfman's evil suggestion, your players might now face a whole
# new set of foes by using a very specific script call. Feel free to change
# the encounter list as many times as needed. Mwahahaha!!

# - AVAILABLE MODES: :accessory and :levels

# * Accessory Mode * #
# Setting a specific "Choose Foe" accessory is mandatory here!
# * Average Level Mode * #
# You must set a default level plus any specific map's average level.

# * Optional Script Calls * #

# * Change Current Mode:
# $game_party.choose_foes_mode = :your_mode

# * Replace Curent Map's Troop ID's:
# $game_party.new_map_troops(TroopID1, etc.)

module ChooseFoes
  MODE = :levels
  ACCESSORY_ID = 33
  MAP_ACTOR_LVL = {}
  MAP_ACTOR_LVL.default = 5
  MAP_ACTOR_LVL[1] = 4
  # MapID => [TroopID1, etc.] or [:highest] or [:lowest] or [:random]
  MAP_ID_EXTRA_TROOPS = {}
  MAP_ID_EXTRA_TROOPS.default = []
  MAP_ID_EXTRA_TROOPS[1] = [10, 11]
  TITLE = "Pick Your Foe"
  NO_TROOP = "No Troop"
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
    def initialize(cb, replace_troops)
      @callback = cb
      @trooper_max = 8
      @troop_max = $data_troops.size - 1
      @list = []
      map_id = $game_map.map_id
      if replace_troops
        @list += $game_party.map_troop_ids[map_id]
        @commands = @list.map {|n| $data_troops[n].name }
        n = rand(@list.size)
        @troop_id = @list[n]
      else
        @list += $game_map.encounter_list
        @commands = @list.map {|n| $data_troops[n].name }
        troop_ids = MAP_ID_EXTRA_TROOPS[map_id]
        if MAP_ID_EXTRA_TROOPS.has_key?(map_id)
          troop_ids.each {|n| set_extra_troops(n) }
        end
        @troop_id = $game_temp.battle_troop_id
      end
      @list.unshift(nil)
      @commands.unshift(NO_TROOP)
      @troop = Game_Troop.new
      @troop.setup(@troop_id)
      $game_system.se_play($data_system.battle_start_se)
      $game_system.bgm_stop
      bgm = BGM.compact
      bgm = RPG::AudioFile.new(*bgm)
      Audio.play_anon_bgm(bgm)
    end

    def set_extra_troops(troop_id)
      @commands << EXTRA_TROOP
      case troop_id
      when :lowest
        @list << $game_party.lowest_troop_id
      when :highest
        @list << $game_party.highest_troop_id
      when :random
        @list << $game_party.random_troop_id
      when 1..troop_id
        n = [@troop_max, troop_id].min
        @list << n
      end
    end

    def main
      @stage = true
      fn = $game_map.battleback_name
      bb = RPG::Cache.battleback(fn)
      battle_bit = Bitmap.new(640, 480)
      battle_bit.stretch_blt(battle_bit.rect, bb, bb.rect)
      enemies = @troop.enemies
      @backdrop = Sprite.new
      @backdrop.bitmap = battle_bit
      @vp = Viewport.new(0, 0, 640, 320)
      @vp.z = 200
      @battlers = []
      @trooper_max.times do |n|
        battler = Sprite_Battler.new(@vp, enemies[n])
        battler.change(enemies[n])
        @battlers << battler
      end
      @help_window = Window_Help.new
      @help_window.set_text(TITLE, 1)
      @command_window = TroopWindow.new(240, @commands)
      @command_window.x = 200
      @command_window.y = 320
      @command_window.index = @list.index(@troop_id)
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
        troop_id = @list[i]
        if troop_id
          @troop.setup(troop_id)
        else
          @troop.empty!
        end
        enemies = @troop.enemies
        @trooper_max.times do |n|
          sbattler = @battlers[n]
          sbattler.change(enemies[n])
        end
      end
      if Input.trigger?(Input::B) or Input.trigger?(Input::C)
        $game_system.se_play($data_system.decision_se)
        @stage = nil
        n = @command_window.index
        troop_id = @list[n]
        if troop_id
          $game_temp.battle_troop_id = troop_id
          @callback.call
          return
        else
          $game_temp.battle_calling = false
          $game_temp.menu_calling = false
          $game_temp.menu_beep = false
          $game_temp.battle_troop_id = 0
          $game_player.make_encounter_count
          $game_player.straighten
          $game_map.autoplay
          $scene = Scene_Map.new
        end
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
    @map_troop_ids = {}
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

  def new_map_troops?(map_id)
    @map_troop_ids.has_key?(map_id)
  end

  def new_map_troops(*troop_ids)
    n = $game_map.map_id
    @map_troop_ids[n] = troop_ids.flatten
  end
  attr_accessor :choose_foes_mode, :map_troop_ids
  attr_reader :defeated_troop_ids
end

class Game_Troop
  def empty!
    @enemies = []
  end
end

class Sprite_Battler
  def change(battler)
    @battler = battler
    unless @battler
      self.bitmap = nil
      loop_animation(nil)
      return
    end
    @battler_name = @battler.battler_name
    @battler_hue = @battler.battler_hue
    self.bitmap = RPG::Cache.battler(@battler_name, @battler_hue)
    @width = self.bitmap.width
    @height = self.bitmap.height
    self.ox = @width / 2
    self.oy = @height
    self.x = @battler.screen_x
    self.y = @battler.screen_y
    self.z = @battler.screen_z
  end
end

class Scene_Map
  alias :kyon_chs_foes_scn_mp_cll_btl :call_battle
  def call_battle
    list = $game_map.encounter_list
    if list.size < 2
      kyon_chs_foes_scn_mp_cll_btl
      return
    else
      cb = method(:kyon_chs_foes_scn_mp_cll_btl)
      map_id = $game_map.map_id
      if $game_party.new_map_troops?(map_id)
        $scene = ChooseFoes::Scene.new(cb, true)
      elsif $game_party.choose_foes?
        $scene = ChooseFoes::Scene.new(cb, false)
      end
    end
  end
end