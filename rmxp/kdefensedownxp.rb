# * KDefenseDown XP
#   Scripter : Kyonides Arkanthes
#   2020-08-09

# This scriptlet allows you to reduce a hero's or monster's PDEF or MDEF.
# If the target was inflicted with a PDEF- or MDEF- state, it will lose some
# percent of that stat every single turn till the state wears off.
# The state's PDEF Rate or MDEF Rate will be substracted from your target's
# PDEF or MDEF as plain points. I find it incovenient to use percents there.
# You cannot remove the effect by simply removing the state.
# Use a specific item or skill to heal your hero or wait till battle is over.
# Configure the KDefDown module's Constants to let the script find your new
# states, skills and items. Set any value to 0 if you don't need it.

module KDefDown
  PDEF_STATE = 17
  MDEF_STATE = 18
  PDEF_SKILL = 10
  MDEF_SKILL = 11
  PDEF_ITEM = 33
  MDEF_ITEM = 34
end

class Game_Battler
  alias :kyon_defdown_gm_btl_init :initialize
  alias :kyon_defdown_gm_btl_rcvr :recover_all
  alias :kyon_defdown_gm_btl_rstb :remove_states_battle
  alias :kyon_defdown_gm_btl_sde :slip_damage_effect
  alias :kyon_defdown_gm_btl_skef :skill_effect
  alias :kyon_defdown_gm_btl_itef :item_effect
  alias :kyon_defdown_gm_btl_pdef :pdef
  alias :kyon_defdown_gm_btl_mdef :mdef
  def initialize
    kyon_defdown_gm_btl_init
    clear_pdef_mdef_minus
  end

  def clear_pdef_mdef_minus
    @pdef_minus = 0
    @mdef_minus = 0
  end

  def remove_pdef_minus
    remove_state(KDefDown::PDEF_STATE)
    @pdef_minus = 0
  end

  def remove_mdef_minus
    remove_state(KDefDown::MDEF_STATE)
    @mdef_minus = 0
  end

  def recover_all
    kyon_defdown_gm_btl_rcvr
    remove_pdef_minus
    remove_mdef_minus
  end

  def remove_states_battle
    kyon_defdown_gm_btl_rstb
    clear_pdef_mdef_minus
  end

  def slip_damage_effect
    result = kyon_defdown_gm_btl_sde
    if state?(KDefDown::PDEF_STATE)
      self.pdef_minus += $data_skills[KDefDown::PDEF_STATE].pdef_rate
      result |= true
    end
    if state?(KDefDown::MDEF_STATE)
      self.mdef_minus += $data_skills[KDefDown::MDEF_STATE].mdef_rate
      result |= true
    end
    result
  end

  def skill_effect(user, skill)
    if skill.id == KDefDown::PDEF_SKILL
      result = rand(100) < skill.hit
      remove_pdef_minus if result
      return result
    elsif skill.id == KDefDown::MDEF_SKILL
      result = rand(100) < skill.hit
      remove_mdef_minus if result
      return result
    end
    kyon_defdown_gm_btl_skef(user, skill)
  end

  def item_effect(item)
    if item.id == KDefDown::PDEF_ITEM
      remove_pdef_minus
      return true
    elsif item.id == KDefDown::MDEF_ITEM
      remove_mdef_minus
      return true
    end
    kyon_defdown_gm_btl_itef(item)
  end

  def pdef
    [kyon_defdown_gm_btl_pdef - @pdef_minus, 0].max
  end

  def mdef
    [kyon_defdown_gm_btl_mdef - @mdef_minus, 0].max
  end

  def pdef_minus=(minus)
    @pdef_minus = [@pdef_minus + minus, 0].max
  end

  def mdef_minus=(minus)
    @mdef_minus = [@mdef_minus + minus, 0].max
  end
  attr_reader :pdef_minus, :mdef_minus
end