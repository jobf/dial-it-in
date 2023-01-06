package;

import automation.Envelope;
import automation.Oscillator;
import dials.Disk;
import dials.SettingsController;
import flixel.FlxG;
import flixel.FlxState;
import flixel.Graphics;

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
		add(actor.graphic);
		
		settings.pad_add({
			name: "actor geometry",
			index_palette: 0,
			encoders: [
				VOLUME => {
					value: actor.graphic.scale.x,
					on_change: f -> actor.graphic.scale.x = f,
					name: "scale x",
					minimum: 1
				},
				PAN => {
					value: actor.graphic.scale.y,
					on_change: f -> actor.graphic.scale.y = f,
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
					name: "rise",
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
				RESONANCE => {
					value: actor.y_wobble,
					on_change: f -> actor.y_wobble = f,
					name: "y wobble",
				}
			]
		});


		settings.pad_add({
			name: "actor wobble",
			index_palette: 2,
			encoders: [
				// VOLUME => {
				// 	value: actor.envelope.attackTime,
				// 	increment: 0.001,
				// 	on_change: f -> actor.envelope.attackTime = f,
				// 	name: "rise",
				// 	minimum: 0.01
				// },
				// PAN => {
				// 	value: actor.envelope.releaseTime,
				// 	increment: 0.01,
				// 	on_change: f -> actor.envelope.releaseTime = f,
				// 	name: "fall",
				// 	minimum: 0.001,
				// },
				FILTER => {
					value: actor.jump_height,
					on_change: f -> actor.lfo.frequency = f,
					increment: 0.01,
					name: "speed",
				},
				RESONANCE => {
					value: actor.y_wobble,
					on_change: f -> actor.y_wobble = f,
					name: "depth",
				}
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
			case TRACK1: actor.press();
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

		actor.graphic.screenCenter();
		add(new SettingsDisplay(settings));
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

		actor.update(elapsed);
	}
}

class Actor
{
	public var envelope:Envelope;
	public var lfo:LFO;
	public var graphic:Fill;
	public var jump_height:Float = 200;
	public var y_wobble:Float = 200;
	var x:Float;
	var y:Float;
	var oscillate_y:Float;


	public function new(x:Float = 0, y:Float = 0)
	{
		this.x = x;
		this.y = y;
		graphic = new Fill(x, y);
		var framesPerSecond = 60;
		envelope = new Envelope(framesPerSecond);
		envelope.releaseTime = 0.3;
		lfo = {
			shape: SINE,
			sampleRate: framesPerSecond,
			frequency: 1
		};
		lfo.shape = SINE;
	}

	public function update(elapsed:Float)
	{
		var amp_jump = envelope.nextAmplitude();
		var amp_wobble = lfo.next();
		var jump = -(jump_height * amp_jump);
		var wobble = amp_wobble * y_wobble;
		graphic.y = y + jump + wobble;
	}

	public function press() {

		// trace('oscillate_y ${amp_wobble * 500}');
		envelope.open();
	}

	public function release() {
		envelope.close();
	}
}