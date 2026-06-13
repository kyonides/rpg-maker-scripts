# * KEnemy Slain ACE * #
#   Scripter : Kyonides
#   2026-06-11

# This scriptlet allows you to set custom enemy defeated messages.
# Just leave a note in the DB Enemy's notebox:
# WARNING: The string should always begin with an empty space.
# <defeat> cried out loud!</defeat>

# By default the scriptlet uses the Battle Log here known as :log
# You can set it to :window to display the message window instead.
# And you can call it to change the current display mode ingame.
#   EnemySlain.message_mode = :log *OR* :window

module KEnemySlain
  @message_mode = :log
  extend self
  attr_accessor :message_mode, :show_window
  attr_reader :text
  def log?
    @message_mode == :log
  end

  def window?
    @message_mode == :window
  end

  def set(string)
    @show_window = true
    @text = string
  end

  def clear
    @text = @show_window = nil
  end
end

module RPG
  class Enemy
    def process_collapse_note
      @note[/<defeat>(.*)<\/defeat>/i]
      line = $1 || ""
    end

    def collapse_note
      @collapse_note ||= process_collapse_note
    end
  end
end

class Game_Enemy
  def collapse_note
    enemy.collapse_note
  end
end

class Window_BattleLog
  def display_added_states(target)
    target.result.added_state_objects.each do |state|
      slain = nil
      if target.actor?
        state_msg = state.message1
      else
        state_msg = state.message2
        is_enemy = true
      end
      if state.id == target.death_state_id
        if is_enemy
          collapsed = target.collapse_note
          state_msg = collapsed unless collapsed.empty?
          slain = true
        end
        target.perform_collapse_effect
      end
      next if state_msg.empty?
      if slain and KEnemySlain.window?
        KEnemySlain.set(target.name + state_msg)
        next
      else
        replace_text(target.name + state_msg)
        wait
        wait_for_effect
      end
    end
  end
end

class Scene_Battle
  alias :kyon_enm_slain_scn_btl_app_itm_fx :apply_item_effects
  alias :kyon_enm_slain_scn_btl_inv_cntr_atk :invoke_counter_attack
  def apply_item_effects(target, item)
    kyon_enm_slain_scn_btl_app_itm_fx(target, item)
    return unless KEnemySlain.show_window
    $game_message.add(KEnemySlain.text)
    KEnemySlain.clear
  end

  def invoke_counter_attack(target, item)
    kyon_enm_slain_scn_btl_inv_cntr_atk(target, item)
    return unless KEnemySlain.show_window
    $game_message.add(KEnemySlain.text)
    KEnemySlain.clear
  end
end