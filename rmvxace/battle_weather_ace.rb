# * BattleWeather ACE * #
# - A Plug & Play Script - #
#   Scripter : Kyonides
#   2023-10-23

class Spriteset_Battle
  alias :battle_weather_sprtst_bttl_disp :dispose
  def initialize
    create_viewports
    create_battleback1
    create_battleback2
    create_enemies
    create_actors
    create_weather
    create_pictures
    create_timer
    update
  end

  def create_weather
    @weather = Spriteset_Weather.new(@viewport2)
  end

  def dispose
    dispose_weather
    battle_weather_sprtst_bttl_disp
  end

  def dispose_weather
    @weather.dispose
  end

  def update
    update_battleback1
    update_battleback2
    update_enemies
    update_actors
    update_weather
    update_pictures
    update_timer
    update_viewports
  end

  def update_weather
    @weather.type = $game_map.screen.weather_type
    @weather.power = $game_map.screen.weather_power
    @weather.ox = $game_map.display_x * 32
    @weather.oy = $game_map.display_y * 32
    @weather.update
  end
end