# * ChooseFoes XP * #
#   Not Exactly a Plug-n-Play Script
#   Scripter : Kyonides
#   0.9.0 - 2026-02-18

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
  ACCESSORY_ID = 33
  MAP_ACTOR_LVL = {}
  MAP_ACTOR_LVL[1] = 4
  MAP_ACTOR_LVL.default = 5
  TITLE = "Pick Your Foe"
  # ["Name", Volume or nil, Pitch or nil]
  BGM = ["052-Negative01", nil, nil]

  class Scene
    def initialize(cb)
      @callback = cb
      @list = $game_map.encounter_list
      @commands = @list.map {|n| $data_troops[n].name }
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
      @backdrop = Sprite.new
      @backdrop.bitmap = battle_bit
      @help_window = Window_Help.new
      @help_window.set_text(TITLE, 1)
      @command_window = Window_Command.new(240, @commands)
      @command_window.x = 200
      @command_window.y = 96
      @command_window.index = @list.index(n)
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
      @backdrop.bitmap.dispose
      @backdrop.dispose
    end

    def update
      @command_window.update
      if Input.trigger?(Input::B) or Input.trigger?(Input::C)
        $game_system.se_play($data_system.decision_se)
        @stage = nil
        n = @command_window.index
        $game_temp.battle_troop_id = @list[n]
        @callback.call
      end
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
  attr_accessor :choose_foes_mode
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