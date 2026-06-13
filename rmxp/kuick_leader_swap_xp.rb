# * Kuick Leader Swap XP * #
#   Scripter : Kyonides
#   v1.1.3 - 2025-09-29

# * Script Calls * #

# - Set a Temporary Leader!
#   RememberLeaderIndex? stands for a boolean value: true or false.
#   This new leader becomes permanent if RememberLeaderIndex? is false.
# $game_party.temp_leader(PartyIndex, RememberLeaderIndex?)

# - Restore the Previous Leader! (If Any!)
# $game_party.restore_leader

# - Set a Leader by Actor's ID!
# $game_party.set_leader_by_id(ActorID)

# - Set a Leader Randomly!
# $game_party.set_random_leader!

# * L & R Button-Related Script Calls * #
# - Prevent the player from Swapping the current Leader:
# $game_party.keep_leader!

# - Reenable the player to Swap the current Leader:
# $game_party.swap_leader!

# - Check Current Keep Leader State:
# $game_party.keep_leader (Returns: true or false)

class Game_Party
  def leader
    @actors[0]
  end

  def keep_leader!
    @keep_leader = true
  end

  def swap_leader!
    @keep_leader = false
    nil
  end

  def change_leader(n)
    return if @keep_leader or @actors.empty?
    if n < 0
      @actors.unshift @actors.pop
    else
      @actors << @actors.shift
    end
  end

  def set_leader_by_id(actor_id)
    actor = $game_actors[actor_id]
    n = @actors.index(actor)
    swap_leader(n) if n and n != 0
  end

  def set_random_leader!
    n = rand(@actors.size)
    swap_leader(n) if n and n != 0
  end

  def temp_leader(n, remember)
    @temp_leader_index = n if remember
    swap_leader(n)
  end

  def restore_leader
    swap_leader(@temp_leader_index) if @temp_leader_index
    @temp_leader_index = nil
  end
  private
  def swap_leader(n)
    @actors[0], @actors[n] = @actors[n], @actors[0]
    $game_player.refresh
  end
  attr_accessor :keep_leader
end

class Game_Player
  alias :kyon_kuick_leader_swap_gm_plyr_up :update
  def update
    kyon_kuick_leader_swap_gm_plyr_up
    if Input.trigger?(Input::L)
      $game_party.change_leader(-1)
      refresh
      return
    elsif Input.trigger?(Input::R)
      $game_party.change_leader(1)
      refresh
    end
  end
end