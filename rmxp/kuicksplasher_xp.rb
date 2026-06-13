# * KuickSplasher XP * #
#   Scripter : Kyonides
#   v0.5.0 - 2023-03-16

# * Free as in beer * #

# After including this script in the Script Editor, go to the Main script and
# replace Scene_Title.new with KuickSplasher.new and save everything!

class KuickSplasher
  TRANSITION_SECONDS = 2 # It gotta be a low value
  DISPLAY_SECONDS = 10
  # PICTURES = ["Include", "as", "many", "pictures", "as", "needed"]
  PICTURES = ["backdrop circles blue", "mysterious coast"]
  def change_picture
    Graphics.freeze
    return if @images.empty?
    @backdrop.bitmap.dispose
    @backdrop.bitmap = RPG::Cache.title(@images.shift)
    @timer = Graphics.frame_rate * DISPLAY_SECONDS
    Graphics.transition(Graphics.frame_rate * TRANSITION_SECONDS)
  end

  def main
    $data_system = load_data("Data/System.rxdata")
    $game_system = Game_System.new
    @images = PICTURES.dup
    @backdrop = Sprite.new
    @backdrop.bitmap = Bitmap.new(32, 32)
    change_picture
    while @timer > 0
      Graphics.update
      Input.update
      update
      @timer -= 1
      change_picture if @timer == 0
    end
    $scene = Scene_Title.new
    @backdrop.bitmap.dispose
    @backdrop.dispose
  end

  def update
    if Input.trigger?(Input::B) or Input.trigger?(Input::C)
      $game_system.se_play($data_system.cancel_se)
      @timer = 1
    end
  end
end