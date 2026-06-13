# * Change BattleBack VX * #
#   Scripter : Kyonides
#   2023-10-23

# This scriptlet allows you to manually change both the battleback and
# the battlefloor by using a script call BEFORE battle begins.

# - Change Battleback: Here's an Example:
# $game_temp.battleback = "WhyNotHAL-2000"

# - Change Battlefloor: Here's an Example:
# $game_temp.battlefloor = "YourBattleFloor"

class Game_Temp
  attr_accessor :battleback, :battlefloor
end

class Spriteset_Battle
  def create_battleback
    if $game_temp.battleback
      bitmap = Cache.picture($game_temp.battleback)
      $game_temp.battleback = nil
    else
      source = $game_temp.background_bitmap
      bitmap = Bitmap.new(640, 480)
      bitmap.stretch_blt(bitmap.rect, source, source.rect)
      bitmap.radial_blur(90, 12)
    end
    @battleback_sprite = Sprite.new(@viewport1)
    @battleback_sprite.bitmap = bitmap
    @battleback_sprite.ox = 320
    @battleback_sprite.oy = 240
    @battleback_sprite.x = 272
    @battleback_sprite.y = 176
    @battleback_sprite.wave_amp = 8
    @battleback_sprite.wave_length = 240
    @battleback_sprite.wave_speed = 120
  end

  def create_battlefloor
    @battlefloor_sprite = Sprite.new(@viewport1)
    if $game_temp.battlefloor
      @battlefloor_sprite.bitmap = Cache.picture($game_temp.battlefloor)
      $game_temp.battlefloor = nil
    else
      @battlefloor_sprite.bitmap = Cache.system("BattleFloor")
    end
    @battlefloor_sprite.x = 0
    @battlefloor_sprite.y = 192
    @battlefloor_sprite.z = 1
    @battlefloor_sprite.opacity = 128
  end
end