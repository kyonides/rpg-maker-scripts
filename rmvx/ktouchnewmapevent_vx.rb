# * KTouchNewMapEvent VX
#   Scripter : Kyonides Arkanthes
#   2022-09-29 - Edited 2026-06-17

# * Plug & Play Script * #

# This scriptlet allows you to run an event after being transferred to another
# map. It will run even if the trigger were the Player Touch or Event Touch one.

# * Aliased Method: Game_Event#initialize

class Game_Player
  attr_reader :new_x, :new_y
end

class Game_Event
  alias :kyon_touch_new_map_event_init :initialize
  def initialize(map_id, event)
    kyon_touch_new_map_event_init(map_id, event)
    check_shared_location
  end

  def touch_trigger?
    [1, 2].include?(@trigger)
  end

  def player_new_x?
    $game_temp.player_new_x == @x
  end

  def player_new_y?
    $game_temp.player_new_y == @y
  end

  def check_shared_location
    start if touch_trigger? and player_new_x? and player_new_y?
  end
end