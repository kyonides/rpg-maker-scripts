# * KBribe XP
#   Scripter : Kyonides Arkanthes
#   v1.3.0 - 2025-09-28
# * Non Plug & Play Script * #

# Now you can bribe your foes during battles!
# You can learn how much it might cost the party to bribe a given foe.
# Just check out the skill description to find it out. ;)
# It is also possible to exclude certain monsters like bosses if needed.

# In the KBribe module you can find several CONSTANTS where you can set the
# initial values for the hit rate, damage percent, etc.

# * Script Calls * #
# Boolean stands for true or false

# - First Step: Shorten the Script Call!
# bribe = $game_party.bribe

# - Second Step: Choose your favorite call!
# bribe.hit = Percent
# bribe.gold_percent = Percent
# bribe.dmg_percent = Percent
# bribe.gold = Coins
# bribe.show_dmg_pop = Boolean
# bribe.attempts_max = Number
# bribe.calc_type = :percent
# bribe.calc_type = :fixed

# - Allow or Disallow Clearing Bribes Counter
# $game_system.battle_end_clear_bribes = Boolean

module KBribe
  SKILL_ID = 81
  # Bribing Hero's Failure Animation
  ANIMATION_ID     = 101
  START_HIT_RATE   = 33
  START_GOLD_PERC  = 5
  FAILURE_DMG_PERC = 25
  START_GOLD_MIN   = 50
  DEF_FAILED_GOLD  = 50
  # Types: :percent or :fixed
  START_CALC_TYPE  = :percent
  MAX_ATTEMPTS     = 3
  SHOW_DMG_POP_UP  = true
  CURRENCY_SYMBOL_FIRST = false
  BATTLE_END_CLEAR_BRIBES = true
  SKILL_COST_TEXT  = "Est. Cost: "
  SUCCESS_LABEL    = "Bribed"
  # Add as many MonsterID's as needed
  EXCLUDE_BOSSES = []
  @battlers = []
  @escaped = []
  extend self
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
    bribe = $game_party.bribe
    @battlers.size.times do |n|
      btlr = @battlers[n]
      btlr.damage_pop = bribe.show_dmg_pop
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

  def set_bribe_estimate
    @amount = $game_party.calculate_bribe
  end

  def exclude?(mob_id)
    !EXCLUDE_BOSSES.include?(mob_id)
  end

  class Bribe
    def initialize
      @hit = START_HIT_RATE
      @dmg_percent = FAILURE_DMG_PERC
      @gold_percent = START_GOLD_PERC
      @gold = START_GOLD_MIN
      @show_dmg_pop = SHOW_DMG_POP_UP
      @calc_type = START_CALC_TYPE
      @attempts_max = MAX_ATTEMPTS
      @attempts = 0
      @attempts_total = 0
      @failed_gold = 0
    end

    def enabled?
      @attempts < @attempts_max
    end

    def percentage?
      @calc_type == :percent
    end

    def fixed_amount?
      @calc_type == :fixed
    end

    def add_attempt
      @attempts += 1
      @attempts_total += 1
    end

    def failed!
      @failed_gold += DEF_FAILED_GOLD
    end

    def clear
      @attempts = @failed_gold = 0
    end

    def check_clear
      clear if $game_system.battle_end_clear_bribes
    end
    attr_accessor :hit, :dmg_percent, :show_dmg_pop, :gold_percent, :gold
    attr_accessor :failed_gold, :attempts, :attempts_max, :attempts_total
    attr_accessor :calc_type
  end
end

class Game_System
  alias :kyon_bribe_gm_sys_init :initialize
  def initialize
    kyon_bribe_gm_sys_init
    @battle_end_clear_bribes = KBribe::BATTLE_END_CLEAR_BRIBES
  end
  attr_accessor :battle_end_clear_bribes
end

class Game_Party
  alias :kyon_bribe_gm_pty_init :initialize
  def initialize
    kyon_bribe_gm_pty_init
    @bribe = KBribe::Bribe.new
  end

  def calculate_bribe
    amount = (@gold / 100 * @bribe.gold_percent).round
    amount += amount * (rand(25) + 1) / 100
  end

  def pay_bribe!
    return false unless @bribe.enabled?
    amount = @bribe.percentage? ? calculate_bribe : @bribe.gold
    return false if amount > @gold
    @bribe.add_attempt
    if rand(100) < @bribe.hit
      lose_gold(amount)
      return true
    else
      @bribe.failed!
      return false
    end
  end
  attr_reader :bribe
end

class Game_Battler
  alias :kyon_bribe_gm_btlr_skill_fx :skill_effect
  def bribe_failed(user)
    user.damage = (user.hp / 100 * $game_party.bribe.dmg_percent).round
    user.hp -= user.damage
  end

  def check_bribe(user)
    if KBribe.exclude?(@enemy_id)
      bribe_failed(user)
      return
    end
    hit = $game_party.pay_bribe!
    if hit
      KBribe.add(self, hit)
      @damage = KBribe::SUCCESS_LABEL
    else
      bribe_failed(user)
    end
  end

  def skill_effect(user, skill)
    return check_bribe(user) if self.enemy? and KBribe::SKILL_ID == skill.id
    kyon_bribe_gm_btlr_skill_fx(user, skill)
  end

  def actor?
    @actor_id != nil
  end

  def enemy?
    @enemy_id != nil
  end
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
  alias :kyon_backfire_scn_btl_btl_end :battle_end
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

  def battle_end(result)
    $game_party.bribe.check_clear
    kyon_backfire_scn_btl_btl_end(result)
  end
end