package;

import dials.SettingsController;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.util.FlxColor;

class PlayState extends FlxState
{
	var settings:SettingsController;

	override public function create()
	{
		super.create();
		var a = new Actor();
		a.screenCenter();
		add(a);

		settings = new SettingsController();

		var index_actor_geometry_pad:Pad = {
			name: "actor geometry",
			encoders: [
				VOLUME => {
					value: a.scale.x,
					on_change: f -> a.scale.x = f,
					name: "scale x",
					minimum: 1
				},
				PAN => {
					value: a.scale.y,
					on_change: f -> a.scale.y = f,
					name: "scale y",
					minimum: 1,
				}
			]
		}
		settings.pad_add(index_actor_geometry_pad);

		settings.disk_load();
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
	}
}

class Actor extends FlxSprite
{
	public function new(x:Float = 0, y:Float = 0)
	{
		super(x, y);
		makeGraphic(1, 1, FlxColor.WHITE);
	}
}
