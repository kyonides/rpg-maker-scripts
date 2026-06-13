# * KTurnAround XP * #
#   Scripter : Kyonides
#   2025-05-01

class Game_Player
  def update
    last_moving = moving?
    unless moving? or $game_system.map_interpreter.running? or
           @move_route_forcing or $game_temp.message_window_showing
      update_direction
    end
    last_real_x = @real_x
    last_real_y = @real_y
    super
    if @real_y > last_real_y and @real_y - $game_map.display_y > CENTER_Y
      $game_map.scroll_down(@real_y - last_real_y)
    end
    if @real_x < last_real_x and @real_x - $game_map.display_x < CENTER_X
      $game_map.scroll_left(last_real_x - @real_x)
    end
    if @real_x > last_real_x and @real_x - $game_map.display_x > CENTER_X
      $game_map.scroll_right(@real_x - last_real_x)
    end
    if @real_y < last_real_y and @real_y - $game_map.display_y < CENTER_Y
      $game_map.scroll_up(last_real_y - @real_y)
    end
    unless moving?
      if last_moving
        result = check_event_trigger_here([1,2])
        if result == false
          unless $DEBUG and Input.press?(Input::CTRL)
            if @encounter_count > 0
              @encounter_count -= 1
            end
          end
        end
      end
      if Input.trigger?(Input::C)
        check_event_trigger_here([0])
        check_event_trigger_there([0,1,2])
      end
    end
  end

  def update_direction
    new_dir = Input.dir4
    if @direction == new_dir
      case new_dir
      when 2
        move_down
      when 4
        move_left
      when 6
        move_right
      when 8
        move_up
      end
    else
      case new_dir
      when 2
        turn_down
      when 4
        turn_left
      when 6
        turn_right
      when 8
        turn_up
      end
    end
  end
end