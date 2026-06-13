# * Party Guard Option XP * #

class Game_Party
  def remove_state(state_id)
    @actors.each {|actor| actor.remove_state(state_id, true) }
  end
end

class Window_PartyCommand
  def initialize
    super(0, 0, 640, 64)
    self.contents = Bitmap.new(width - 32, height - 32)
    self.back_opacity = 160
    @commands = ["Fight", "Guard", "Escape"]
    @item_max = @commands.size
    @column_max = @item_max
    draw_item(0, normal_color)
    draw_item(1, $game_temp.battle_can_escape ? normal_color : disabled_color)
    self.active = false
    self.visible = false
    self.index = 0
  end
end

class Scene_Battle
  def update_phase2
    return unless Input.trigger?(Input::C)
    case @party_command_window.index
    when 0 # fight
      $game_system.se_play($data_system.decision_se)
      start_phase3
      return
    when 1 # guard
      $game_system.se_play($data_system.decision_se)
      $game_party.actors.each do |actor|
        actor.current_action.kind = 0
        actor.current_action.basic = 1
      end
      start_phase4
      return
    when 2 # escape
      unless $game_temp.battle_can_escape
        $game_system.se_play($data_system.buzzer_se)
        return
      end
      $game_system.se_play($data_system.decision_se)
      update_phase2_escape
    end
  end
end