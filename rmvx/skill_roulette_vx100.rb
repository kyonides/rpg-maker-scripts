# * Skill Roulette VX * #
#   Scripter : Kyonides
#   v1.0.0 - 2023-06-16

# Stop choosing a skill on your own, let the Skill Roulette do it for you!

# Warning: The scriptlet does not include any GUI of its own at all.

# * Instructions * #

# Pick a skill in the DB and leave a note: <roulette 12 32 43>
# Actually, you can add as many numbers as needed!

module SkillRoulette
  REGEX = /<roulette (.+)>/i
  FAIL_MESSAGE = "Casting of %s skill failed miserably!"
end

class RPG::Skill
  def roulette_note?
    note[SkillRoulette::REGEX] != nil
  end

  def skill_roulette_pool
    note[SkillRoulette::REGEX]
    return [] unless $1
    list = $1.scan(/\d+/i)
    list.map{|n_str| n_str.to_i }
  end

  def roulette_skill_id
    skills = skill_roulette_pool
    return 0 if skills.empty?
    skills[rand(skills.size)]
  end
end

class Scene_Battle
  def use_roulette_skill(skill)
    @skill_max ||= $data_skills.size
    text = @active_battler.name + skill.message1
    @message_window.add_instant_text(text)
    unless skill.message2.empty?
      wait(10)
      @message_window.add_instant_text(skill.message2)
    end
    skill_id = skill.roulette_skill_id
    if skill_id == 0 or @skill_max < skill_id
      wait(5)
      text = sprintf(SkillRoulette::FAIL_MESSAGE, skill.name)
      @message_window.add_instant_text(text)
      return
    end
    use_new_skill(skill, skill_id)
  end

  def use_new_skill(skill, target_skill_id)
    target_skill = $data_skills[target_skill_id]
    targets = @active_battler.action.make_targets
    display_animation(targets, target_skill.animation_id)
    @active_battler.mp -= @active_battler.calc_mp_cost(skill)
    $game_temp.common_event_id = skill.common_event_id
    for target in targets
      target.skill_effect(@active_battler, target_skill)
      display_action_effects(target, target_skill)
    end
  end

  alias :kyon_skill_roulette_scn_btl_exec_act_skill :execute_action_skill
  def execute_action_skill
    skill = @active_battler.action.skill
    if skill.roulette_note?
      use_roulette_skill(skill)
      return
    else
      kyon_skill_roulette_scn_btl_exec_act_skill
    end
  end
end