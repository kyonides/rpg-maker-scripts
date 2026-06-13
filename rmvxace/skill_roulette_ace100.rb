# * Skill Roulette ACE * #
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

class Game_Battler
  def skill_roulette_effects(item)
    item.effects.each {|effect| item_global_effect_apply(effect) }
  end
end

class Scene_Battle
  def use_roulette_skill(item)
    @skill_max ||= $data_skills.size
    @log_window.display_use_item(@subject, item)
    @subject.use_item(item)
    refresh_status
    skill_id = item.roulette_skill_id
    if skill_id == 0 or @skill_max < skill_id
      text = sprintf(SkillRoulette::FAIL_MESSAGE, item.name)
      @log_window.add_text(text)
      return
    end
    use_new_skill(skill_id)
  end

  def use_new_skill(skill_id)
    action = @subject.current_action
    action.set_skill(skill_id)
    item = action.item
    @subject.skill_roulette_effects(item)
    targets = action.make_targets.compact
    show_animation(targets, item.animation_id)
    targets.each {|target| item.repeats.times { invoke_item(target, item) } }
  end

  alias :kyon_skill_roulette_scn_btl_use_item :use_item
  def use_item
    item = @subject.current_action.item
    if item.roulette_note?
      use_roulette_skill(item)
      return
    else
      kyon_skill_roulette_scn_btl_use_item
    end
  end
end