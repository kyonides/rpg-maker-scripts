# * Large Door Fix VX * #
#   Scripter : Kyonides Arkanthes
#   2023-09-11

# - The file names of Door Character Sprites should begin with an @ symbol. - #
#   That symbol can be either the 1st or 2nd or even the 3rd character of the
#   filename. The fix will work as long as the @ symbol is there!

class Sprite_Character
  def update_bitmap
    if @tile_id != @character.tile_id or
       @character_name != @character.character_name or
       @character_index != @character.character_index
      @tile_id = @character.tile_id
      @character_name = @character.character_name
      @character_index = @character.character_index
      if @tile_id > 0
        sx = (@tile_id / 128 % 2 * 8 + @tile_id % 8) * 32;
        sy = @tile_id % 256 / 8 % 16 * 32;
        self.bitmap = tileset_bitmap(@tile_id)
        self.src_rect.set(sx, sy, 32, 32)
        self.ox = 16
        self.oy = 32
      else
        self.bitmap = Cache.character(@character_name)
        sign = @character_name[/^[\!\$]./]
        if sign != nil and sign.include?('$')
          @cw = bitmap.width / 3
          @ch = bitmap.height / 4
        else
          @cw = bitmap.width / 12
          @ch = bitmap.height / 8
        end
        self.ox = @character_name[/@/] ? 32 : @cw / 2
        self.oy = @ch
      end
    end
  end
end