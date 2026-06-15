# * KBribe XP
#   Scripter : Kyonides Arkanthes
#   v1.0.0 - 2022-07-14
# * Non Plug & Play Script * #

# Now you can bribe your foes during battles!
# You can learn how much it might cost the party to bribe a given foe.
# Just check out the skill description to find it out. ;)
# It is also possible to exclude certain monsters like bosses if needed.

# In the KBribe module you can find several CONSTANTS where you can set the
# initial values for the hit rate, damage percent, etc.

# * Script Calls * #

# $game_party.bribe_hit = Percent
# $game_party.bribe_gold_percent = Percent
# $game_party.bribe_dmg_percent = Percent
# $game_party.bribe_gold_min = Coins
# $game_party.bribe_show_dmg_pop = true  or  false

module KBribe
  SKILL_ID = 81
  # Bribing Hero's Failure Animation
  ANIMATION_ID = 101
  START_HIT_RATE = 33
  START_GOLD_PERCENT = 5
  FAILURE_DMG_PERCENT = 25
  GOLD_MIN = 50
  SHOW_DMG_POP_UP = true
  CURRENCY_SYMBOL_FIRST = false
  SKILL_COST_TEXT = "Est. Cost: "
  SUCCESS_LABEL = "Bribed"
  # Add as many MonsterID's as needed
  EXCLUDE_BOSSES = []
  extend self
  @battlers = []
  @escaped = []
  def add(battler, do_escape)
    @battlers << battler
    @escaped << do_escape
  end

  def battlers_reaction
    @battlers.each do |btlr|
      btlr.animation_id = ANIMATION_ID
      btlr.animation_hit = true
    end
  end

  def hurt!
    @battlers.size.times do |n|
      btlr = @battlers[n]
      btlr.damage_pop = $game_party.bribe_show_dmg_pop
      btlr.escape if @escaped[n]
    end
    @battlers.clear
    @escaped.clear
  end

  def skill_description
    text = " " + KBribe::SKILL_COST_TEXT
    if CURRENCY_SYMBOL_FIRST
      text += $data_system.words.gold + @amount.to_s
    else
      text += @amount.to_s + $data_system.words.gold
    end
  end
  def set_bribe_estimate() @amount = $game_party.calculate_bribe end
  def exclude?(mob_id) !EXCLUDE_BOSSES.include?(mob_id) end
end

class Game_Party
  alias :kyon_bribe_gm_pty_init :initialize
  def initialize
    kyon_bribe_gm_pty_init
    @bribe_hit = KBribe::START_HIT_RATE
    @bribe_gold_percent = KBribe::START_GOLD_PERCENT
    @bribe_dmg_percent = KBribe::FAILURE_DMG_PERCENT
    @bribe_gold_min = KBribe::GOLD_MIN
    @bribe_show_dmg_pop = KBribe::SHOW_DMG_POP_UP
  end

  def calculate_bribe
    amount = (@gold / 100 * @bribe_gold_percent).round
    amount += amount * (rand(25) + 1) / 100
  end

  def pay_bribe!
    return false if @bribe_gold_min > @gold
    amount = calculate_bribe
    lose_gold(amount)
    true
  end
  attr_accessor :bribe_hit, :bribe_gold_percent
  attr_accessor :bribe_dmg_percent, :bribe_gold_min, :bribe_show_dmg_pop
end

class Game_Battler
  alias :kyon_bribe_gm_btlr_skill_fx :skill_effect
  def check_bribe(user)
    hit = $game_party.pay_bribe!
    hit |= rand(100) < $game_party.bribe_hit
    hit |= KBribe.exclude?(@enemy_id)
    if hit
      KBribe.add(self, hit)
      @damage = KBribe::SUCCESS_LABEL
    else
      user.damage = (user.hp / 100 * $game_party.bribe_dmg_percent).round
      user.hp -= user.damage
    end
  end

  def skill_effect(user, skill)
    return check_bribe(user) if self.enemy? and KBribe::SKILL_ID == skill.id
    kyon_bribe_gm_btlr_skill_fx(user, skill)
  end
  def actor?() @actor_id != nil end
  def enemy?() @enemy_id != nil end
end

class Window_Skill
  def update_help
    a_skill = self.skill
    if a_skill.nil?
      @text = ""
    else
      @text = a_skill.description.dup
      @text += KBribe.skill_description if KBribe::SKILL_ID == a_skill.id
    end
    return if @text == @last_text
    @help_window.set_text(@text)
    @last_text = @text
  end
end

class Scene_Battle
  alias :kyon_backfire_scn_btl_start_skill_sel :start_skill_select
  alias :kyon_backfire_scn_btl_up_ph4_s4 :update_phase4_step4
  alias :kyon_backfire_scn_btl_up_ph4_s5 :update_phase4_step5
  def start_skill_select
    kyon_backfire_scn_btl_start_skill_sel
    KBribe.set_bribe_estimate
  end

  def update_phase4_step4
    kyon_backfire_scn_btl_up_ph4_s4
    KBribe.battlers_reaction
  end

  def update_phase4_step5
    kyon_backfire_scn_btl_up_ph4_s5
    KBribe.hurt!
  end
end