package flixel;

import dials.SettingsController;
import flixel.util.FlxColor;


class Fill extends FlxSprite
{
	public function new(x:Float = 0, y:Float = 0)
	{
		super(x, y);
		makeGraphic(1, 1, FlxColor.WHITE);
	}
}

class SettingsDisplay extends FlxSprite{

	var settings:SettingsController;
	var grid_width:Int = 128;
	var grid_height:Int = 64;

	public function new(x:Float = 0, y:Float = 0, settings:SettingsController)
		{
			super(x, y);
			this.settings = settings;
			makeGraphic(grid_width, grid_height, FlxColor.WHITE);
		}
	
		override function update(elapsed:Float)
		{

			@:privateAccess
			var pixels = settings.canvas.image.getPixels();
			for (i => pixel in pixels) {
				graphic.bitmap.setPixel(grid_column(i), grid_row(i), pixel);
			}
			super.update(elapsed);
		}

		function grid_index(column:Int, row:Int):Int {
			return column + grid_width * row;
		}
		
		function grid_column(index:Int):Int {
			return Std.int(index % grid_width);
		}
	
		function grid_row(index:Int):Int {
			return Std.int(index / grid_width);
		}
}