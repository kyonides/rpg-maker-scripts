# * No Guard Option VX * #
#   Scripter : Kyonides Arkanthes
#   2023-05-11

class Window_ActorCommand
  def setup(actor)
    klass = actor.class
    opt2 = klass.skill_name_valid ? klass.skill_name : Vocab.skill
    @commands = [Vocab.attack, opt2, Vocab.item]
    @item_max = @commands.size
    refresh
    self.index = 0
  end
end

class Scene_Battle
  def update_actor_command_selection
    if Input.trigger?(Input::B)
      Sound.play_cancel
      prior_actor
    elsif Input.trigger?(Input::C)
      case @actor_command_window.index
      when 0  # Attack
        Sound.play_decision
        @active_battler.action.set_attack
        start_target_enemy_selection
      when 1  # Skill
        Sound.play_decision
        start_skill_selection
      when 2  # Item
        Sound.play_decision
        start_item_selection
      end
    end
  end
end