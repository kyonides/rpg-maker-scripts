# * Weaponless Aktor XP * #
# * Weaponless & Armorless Actor's Base Stats for XP * # 
#   Scripter : Kyonides Arkanthes
#   2024-01-02

# * How to Configure the Script * #

# If you want to set Aluxes's or Basil's Base ATK to any value other than zero,
# go type something like this:

# ATK  = { 1 => 5, 2 => 4, etc. }

# Aluxes' ID is 1 and Basil's is 2.
# It is the same procedure for any of the 4 weaponless stats.

# * How to Set a Default Value * #

# Let us say that you want to set a different Base ATK value for anybody else
# other than Aluxes and Basil. Then type anything like the following line:

# ATK.default = 2

# This means that Gloria and Hilda would get 3 ATK points even if they forgot
# to bring any staff or rod with them!

# * Other Script Calls * #

# - Step 1: Find an Actor - 2 Methods
# actor = $game_actors[ActorID]
# actor = $game_party.actors[Position]

# - Step 2: Change any of his or her initial stats:
# actor.init_atk += 10
# actor.init_pdef += 10
# actor.init_mdef += 10
# actor.init_eva += 10

module WeaponlessAktor
  ATK  = { 1 => 5 }
  PDEF = { 1 => 5 }
  MDEF = { 1 => 5 }
  EVA  = { 1 => 5 }
  ATK.default = 0
  PDEF.default = 0
  MDEF.default = 0
  EVA.default = 0
end

class Game_Actor
  alias :kyon_gm_act_base_stats_setup :setup
  alias :kyon_gm_act_base_stats_base_atk :base_atk
  alias :kyon_gm_act_base_stats_base_pdef :base_pdef
  alias :kyon_gm_act_base_stats_base_mdef :base_mdef
  alias :kyon_gm_act_base_stats_base_eva :base_eva
  def setup(actor_id)
    @init_atk  = WeaponlessAktor::ATK[actor_id]
    @init_pdef = WeaponlessAktor::PDEF[actor_id]
    @init_mdef = WeaponlessAktor::MDEF[actor_id]
    @init_eva  = WeaponlessAktor::EVA[actor_id]
    kyon_gm_act_base_stats_setup(actor_id)
  end

  def base_atk
    kyon_gm_act_base_stats_base_atk + @init_atk
  end

  def base_pdef
    kyon_gm_act_base_stats_base_pdef + @init_pdef
  end

  def base_mdef
    kyon_gm_act_base_stats_base_mdef + @init_mdef
  end

  def base_eva
    kyon_gm_act_base_stats_base_eva + @init_eva
  end
  attr_accessor :init_atk, :init_pdef, :init_mdef, :init_eva
end