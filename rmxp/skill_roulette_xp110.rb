# * Skill Roulette XP * #
#   Scripter : Kyonides
#   v1.1.0 - 2026-05-31

# * WARNING: The scriptlet does not include any GUI of its own at all. * #

# Stop choosing a skill on your own, let the Skill Roulette do it for you!
# Actors' and Troopers' Initial Roulette Level: 1.

# * Instructions * #

# Configure the Constant by adding as many Random Skills as needed!

# RANDOM_SKILLS[SkillID][RouletteLevel] = [SkillID2, SkillID3, etc.]

# * Script Call * #
# - Change an Actor's Roulette Level AT ANY TIME:
# actor = $game_party.actors[Index]
# actor.roulette_level = Number

# - Change an Enemy's Roulette Level IN BATTLE:
# enemy = $game_troop.enemies[Index]
# enemy.roulette_level = Number

module SkillRoulette
  RANDOM_SKILLS = {} # Leave this line alone!
  RANDOM_SKILLS[81] = skills = {}
  skills[1] = [7, 10, 13, 16]
  skills[2] = [19, 22, 24, 27]
  skills[3] = [30, 33, 36, 40]
  FAIL_MESSAGE = "Casting of %s skill failed!"
  UNKNOWN_SKILL = "Unknown"
end

class RPG::Skill
  def roulette_list?
    SkillRoulette::RANDOM_SKILLS.has_key?(@id)
  end

  def roulette_skill_id(battler_lvl)
    rlt_skills = SkillRoulette::RANDOM_SKILLS[@id]
    return 0 if rlt_skills.empty?
    skills = []
    skill_ids = rlt_skills.sort
    skill_ids.each {|lvl, ids| skills += ids if battler_lvl <= lvl }
    return 0 if skills.empty?
    skills[rand(skills.size)]
  end
end

class Game_Battler
  alias :kyon_skill_roulette_gm_btlr_init :initialize
  def initialize
    kyon_skill_roulette_gm_btlr_init
    @roulette_level = 1
  end
  attr_accessor :roulette_level
end

class Scene_Battle
  def roulette_skill_fail(skill_name)
    10.times { Graphics.update }
    text = sprintf(SkillRoulette::FAIL_MESSAGE, skill_name)
    @help_window.set_text(text, 1)
    @phase4_step = 1
  end

  def use_roulette_skill(skill)
    @skill_max ||= $data_skills.size
    @active_battler.sp -= skill.sp_cost
    @status_window.refresh
    @help_window.set_text(skill.name, 1)
    skill_id = skill.roulette_skill_id(@active_battler.roulette_level)
    if skill_id == 0
      roulette_skill_fail(SkillRoulette::UNKNOWN_SKILL)
      return
    elsif @skill_max < skill_id
      roulette_skill_fail(skill.name)
      return
    end
    target_skill = $data_skills[skill_id]
    @animation1_id = target_skill.animation1_id
    @animation2_id = target_skill.animation2_id
    @common_event_id = target_skill.common_event_id
    set_target_battlers(target_skill.scope)
    @target_battlers.each {|t| t.skill_effect(@active_battler, target_skill) }
  end

  alias :kyon_skill_roulette_scn_btl_mk_sk_act_res :make_skill_action_result
  def make_skill_action_result
    skill_id = @active_battler.current_action.skill_id
    skill = $data_skills[skill_id]
    if skill.roulette_list?
      use_roulette_skill(skill)
      return
    end
    kyon_skill_roulette_scn_btl_mk_sk_act_res
  end
end