# * Large Door Fix ACE * #
#   Scripter : Kyonides Arkanthes
#   2023-09-11

# - The file names of Door Character Sprites should begin with an @ symbol. - #
#   That symbol can be either the 1st or 2nd or even the 3rd character of the
#   filename. The fix will work as long as the @ symbol is there!

class Sprite_Character
  alias :kyon_door_fix_sprite_char_set_char_bmap :set_character_bitmap
  def set_character_bitmap
    kyon_door_fix_sprite_char_set_char_bmap
    self.ox = 32 if @character_name[/@/]
  end
end