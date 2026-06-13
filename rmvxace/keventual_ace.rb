# * KEventual ACE * # 
#   Scripter : Kyonides Arkanthes
#   v1.0.0 - 2025-12-01

# This script allows you to copy or delete or restore events at will.
# The Base Events can be either local or external.
# The events you want to Delete or Restore must be local.
# Without ever using the script calls I have listed below, nothing would ever
# change on the map.

# * Script Calls * #

# Note: You can use @event_x or @event_y for the current event's XY coordinates.

# - Add a copy of an Event present on the Current Map:
# copy_event(EventID, NewEventID, NewX, NewY)

# - Add a copy of an Event available on a Different Map:
# add_event(OtherMapID, EventID, NewEventID, NewX, NewY)

# - Delete any Event present on the Current Map:
#   The 2nd argument is either true or false. If true, it will never return.
# delete_event(EventID)
# delete_event(EventID, true)

# - Restore any Event that was once present on the Current Map:
# restore_event(EventID)

module KEventual
  @events = []
  @delete_events = []
  extend self
  attr_reader :events, :delete_events
  attr_accessor :need_refresh
end

class Game_Map
  alias :kyon_eventual_gm_map_init :initialize
  alias :kyon_eventual_gm_map_setup :setup
  def initialize
    kyon_eventual_gm_map_init
    @copy_events = {}
    @delete_events = {}
  end

  def setup_extra_events_hashes(map_id)
    @copy_events[map_id] ||= {}
    @delete_events[map_id] ||= {}
  end

  def setup(map_id)
    setup_extra_events_hashes(map_id)
    kyon_eventual_gm_map_setup(map_id)
    restore_extra_events
  end

  def restore_extra_events
    @events.merge!(@copy_events[@map_id])
    @delete_events[@map_id].keys.each {|event_id| @events.delete(event_id) }
  end

  def copy_event(event_or_id, new_id, ex, ey)
    return if @events[new_id]
    if event_or_id.is_a?(RPG::Event)
      event = Game_Event.new(@map_id, event_or_id)
    elsif @events[event_or_id]
      event = @events[event_or_id].dup
    else
      print "EventError: Event ID #{event_or_id} could not be found!"
      return
    end
    event.reset_copy(new_id, ex, ey)
    KEventual.need_refresh = true
    KEventual.events << event
    @copy_events[@map_id][new_id] = event
    @events[new_id] = event
    true
  end

  def no_map_error(other_map_id)
    error = "MapError: Map ##{other_map_id}"
    reason = " could not be found in the Data directory.\n"
    event_id = $game_map.interpreter.event_id
    event_name = @events[event_id].name
    event = "Called from event ##{event_id} alias #{event_name}"
    print error + reason + event
  end

  def add_event(other_map_id, event_id, new_id, ex, ey)
    begin
      other_map = load_data(sprintf("Data/Map%03d.rvdata2", other_map_id))
      event = other_map.events[event_id]
      copy_event(event, new_id, ex, ey)
    rescue
      no_map_error(other_map_id)
    end
  end

  def delete_event(event_id, forever=false)
    event = @events.delete(event_id)
    return unless event
    KEventual.need_refresh = true
    KEventual.delete_events << event_id
    @copy_events[@map_id].delete(event_id)
    @delete_events[@map_id][event_id] = event if forever
  end

  def restore_event(event_id)
    event = @delete_events[@map_id].delete(event_id)
    return false unless event
    @events[event_id] = event
    KEventual.need_refresh = true
  end

  def has_event?(event_id)
    @events.has_key?(event_id)
  end
end

class Game_Event
  def name
    @event.name
  end

  def reset_copy(event_id, ex, ey)
    @event.id = event_id
    @id = event_id
    moveto(ex, ey)
    refresh
  end
end

class Game_Interpreter
  attr_reader :event_id, :event_x, :event_y
  alias :kyon_eventual_inter_clear :clear
  alias :kyon_eventual_inter_setup :setup
  def clear
    kyon_eventual_inter_clear
    @event_x = 0
    @event_y = 0
  end

  def setup(list, event_id=0)
    kyon_eventual_inter_setup(list, event_id)
    return if event_id == 0
    event = $game_map.events[event_id]
    @event_x = event.x
    @event_y = event.y
  end

  def delete_event(event_id, forever=false)
    $game_map.delete_event(event_id, forever)
  end

  def restore_event(event_id)
    $game_map.restore_event(event_id)
  end

  def copy_event(event_or_id, new_id, ex, ey)
    $game_map.copy_event(event_or_id, new_id, ex, ey)
  end

  def add_event(other_map_id, event_id, new_id, ex, ey)
    $game_map.add_event(other_map_id, event_id, new_id, ex, ey)
  end
end

class Sprite_Character
  alias :kyon_eventual_sprt_char_init :initialize
  def initialize(viewport, character = nil)
    @character_id = character.id
    kyon_eventual_sprt_char_init(viewport, character)
  end

  def dispose_all
    self.bitmap.dispose if self.bitmap
    dispose
  end
  attr_reader :character_id
end

class Spriteset_Map
  alias :kyon_eventual_sprtst_map_up_char :update_characters
  def update_characters
    process_refresh
    kyon_eventual_sprtst_map_up_char
  end

  def process_refresh
    return unless KEventual.need_refresh
    player = @character_sprites.pop
    KEventual.need_refresh = nil
    ids = KEventual.delete_events
    if ids.any?
      list = @character_sprites.select {|cs| ids.include?(cs.character_id) }
      list.each {|cs| cs.dispose }
      @character_sprites -= list
      ids.clear
    end
    ids = KEventual.events
    if ids.any?
      ids.each do |event|
        @character_sprites << Sprite_Character.new(@viewport1, event)
      end
      ids.clear
    end
    @character_sprites << player
  end
end