# * Large Door Fix XP * #
#   Scripter : Kyonides Arkanthes
#   2023-09-11

# - The file names of Door Character Sprites should begin with an @ symbol. - #
#   That symbol can be either the 1st or 2nd or even the 3rd character of the
#   filename. The fix will work as long as the @ symbol is there!

class Sprite_Character
  def update
    super
    update_bitmap
    update_visible
    update_src_rect
    update_screen
    update_animation
  end

  def update_bitmap
    if @tile_id != @character.tile_id or
       @character_name != @character.character_name or
       @character_hue != @character.character_hue
      @tile_id = @character.tile_id
      @character_name = @character.character_name
      @character_hue = @character.character_hue
      if @tile_id >= 384
        self.bitmap = RPG::Cache.tile($game_map.tileset_name,
          @tile_id, @character.character_hue)
        self.src_rect.set(0, 0, 32, 32)
        self.ox = 16
        self.oy = 32
      else
        c = @character
        self.bitmap = RPG::Cache.character(c.character_name, c.character_hue)
        @cw = bitmap.width / 4
        @ch = bitmap.height / 4
        # Large Door Fix
        self.ox = @character_name[/@/] ? 32 : @cw / 2
        self.oy = @ch
      end
    end
  end

  def update_visible
    self.visible = !@character.transparent
  end

  def update_src_rect
    if @tile_id == 0
      sx = @character.pattern * @cw
      sy = (@character.direction - 2) / 2 * @ch
      self.src_rect.set(sx, sy, @cw, @ch)
    end
  end

  def update_screen
    self.x = @character.screen_x
    self.y = @character.screen_y
    self.z = @character.screen_z(@ch)
    self.opacity = @character.opacity
    self.blend_type = @character.blend_type
    self.bush_depth = @character.bush_depth
  end

  def update_animation
    if @character.animation_id != 0
      animation = $data_animations[@character.animation_id]
      animation(animation, true)
      @character.animation_id = 0
    end
  end
end