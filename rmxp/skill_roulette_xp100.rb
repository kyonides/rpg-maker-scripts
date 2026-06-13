# * Skill Roulette XP * #
#   Scripter : Kyonides
#   v1.0.0 - 2023-06-16

# Stop choosing a skill on your own, let the Skill Roulette do it for you!

# Warning: The scriptlet does not include any GUI of its own at all.

# * Instructions * #

# Configure the Constant by adding as many Random Skills as needed!

# RANDOM_SKILLS[SkillID1] = [SkillID2, SkillID3, etc.]

module SkillRoulette
  RANDOM_SKILLS = {} # Leave it alone!
  RANDOM_SKILLS[81] = [7, 10, 13, 16, 19, 22]
  FAIL_MESSAGE = "Casting of %s skill failed!"
end

class RPG::Skill
  def roulette_list?
    SkillRoulette::RANDOM_SKILLS.has_key?(@id)
  end

  def roulette_skill_id
    skills = SkillRoulette::RANDOM_SKILLS[@id]
    return 0 if skills.empty?
    skills[rand(skills.size)]
  end
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
    skill_id = skill.roulette_skill_id
    if skill_id == 0 or @skill_max < skill_id
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
    skill = $data_skills[@active_battler.current_action.skill_id]
    if skill.roulette_list?
      use_roulette_skill(skill)
      return
    else
      kyon_skill_roulette_scn_btl_mk_sk_act_res
    end
  end
end