package;

import automation.Envelope;
import dials.Disk;
import dials.SettingsController;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.util.FlxColor;

class PlayState extends FlxState
{
	var settings:SettingsController;
	var actor:Actor;

	override public function create()
	{
		super.create();

		settings = new SettingsController(new DiskSys());
		settings.disk_load();
		var y_screen_center = FlxG.height * 0.5;
		actor = new Actor(0, y_screen_center);
		add(actor);
		
		settings.pad_add({
			name: "actor geometry",
			index_palette: 0,
			encoders: [
				VOLUME => {
					value: actor.scale.x,
					on_change: f -> actor.scale.x = f,
					name: "scale x",
					minimum: 1
				},
				PAN => {
					value: actor.scale.y,
					on_change: f -> actor.scale.y = f,
					name: "scale y",
					minimum: 1,
				},
				// FILTER => {
				// 	value: actor.x,
				// 	on_change: f -> actor.x = f,
				// 	name: "x",
				// },
				// RESONANCE => {
				// 	value: actor.y,
				// 	on_change: f -> actor.y = f,
				// 	name: "y",
				// }
			]
		});

		settings.pad_add({
			name: "actor jump",
			index_palette: 1,
			encoders: [
				VOLUME => {
					value: actor.envelope.attackTime,
					increment: 0.001,
					on_change: f -> actor.envelope.attackTime = f,
					name: " rise",
					minimum: 0.01
				},
				PAN => {
					value: actor.envelope.releaseTime,
					increment: 0.01,
					on_change: f -> actor.envelope.releaseTime = f,
					name: "fall",
					minimum: 0.001,
				},
				FILTER => {
					value: actor.jump_height,
					on_change: f -> actor.jump_height = f,
					name: "height",
				},
				// RESONANCE => {
				// 	value: actor.y,
				// 	on_change: f -> actor.y = f,
				// 	name: "y",
				// }
			]
		});

		settings.on_button_press = button -> switch button
		{
			// case BROWSER:
			// case PATUP:
			// case PATDOWN:
			// case GRIDLEFT:
			// case GRIDRIGHT:
			// case ALT:
			// case STOP:
			case TRACK1: actor.envelope.open();
			// case TRACK2:
			// case TRACK3:
			// case TRACK4:
			// case STEP:
			// case NOTE:
			// case DRUM:
			// case PERFORM:
			// case SHIFT:
			// case REC:
			// case PATTERN:
			// case PLAY:
			// case ENCODERMODE:
			case _:
		}

		settings.on_button_release = button -> switch button {
			// case BROWSER:
			// case PATUP:
			// case PATDOWN:
			// case GRIDLEFT:
			// case GRIDRIGHT:
			// case ALT:
			// case STOP:
			case TRACK1: actor.envelope.close();
			// case TRACK2:
			// case TRACK3:
			// case TRACK4:
			// case STEP:
			// case NOTE:
			// case DRUM:
			// case PERFORM:
			// case SHIFT:
			// case REC:
			// case PATTERN:
			// case PLAY:
			// case ENCODERMODE:
			case _:
		}

		actor.screenCenter();
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		if (FlxG.keys.justPressed.J)
		{
			actor.press();
		}
		if (FlxG.keys.justReleased.J)
		{
			actor.release();
		}
	}
}

class Actor extends FlxSprite
{
	public var envelope:Envelope;

	public var jump_height:Float = 200;

	var y_actor:Float;

	public function new(x:Float = 0, y:Float = 0)
	{
		super(x, y);
		y_actor = y;
		makeGraphic(1, 1, FlxColor.WHITE);
		var framesPerSecond = 60;
		envelope = new Envelope(framesPerSecond);
		envelope.releaseTime = 0.3;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		var amp_jump = envelope.nextAmplitude();
		y = y_actor - (jump_height * amp_jump);
	}

	public function press() {
		envelope.open();
	}

	public function release() {
		envelope.close();
	}
}
