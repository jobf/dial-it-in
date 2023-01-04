package;

import akaifirehx.fire.Control.EncoderMove;
import akaifirehx.midi.AkaiFireMidi;
import akaifirehx.midi.Ports;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.util.FlxColor;
#if imagedisplay
import akaifirehx.fire.display.Canvas.ImageCanvas as PixelCanvas;
#else
import akaifirehx.fire.display.Canvas.OledCanvas as PixelCanvas;
#end

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

class SettingsController
{
	var fire:AkaiFireMidi;
	var index_pad_selected:Int = 0;

	var pads:Array<Pad>;

	public function new()
	{
		pads = [];
		var canvas = new PixelCanvas();

		var firePortConfig:PortConfig = {
			portName: 'FL STUDIO FIRE Jack 1',
			portNumber: 1
		}

		fire = new AkaiFireMidi(firePortConfig, firePortConfig, canvas);
		fire.events.onPadPress.add(index_pad -> setting_select(index_pad));
		fire.events.onEncoderIncrement.add(encoder -> setting_parameter_increase(encoder));
		fire.events.onEncoderDecrement.add(encoder -> setting_parameter_decrease(encoder));
	}

	function setting_select(index_pad:Int)
	{
		if (pads.length > index_pad)
		{
			index_pad_selected = index_pad;
			fire_refresh_display();
			trace('change pad to $index_pad_selected');
		}
	}

	function fire_refresh_display()
	{
		fire.sendMessage(DisplayClear(false));
		fire.sendMessage(DisplaySetText(pads[index_pad_selected].name, 1, 1, false));
		var y = 12;
		for (encoder in pads[index_pad_selected].encoders.keys())
		{
			var enc = pads[index_pad_selected].encoders[encoder];
			var text_encoder = '${enc.name} ${enc.value}';
			fire.sendMessage(DisplaySetText(text_encoder, 1, y, false));
			y += 12;
		}
		fire.sendMessage(DisplayShow);
	}

	function setting_parameter_increase(encoder:EncoderMove)
	{
		pads[index_pad_selected].change(encoder, 1);
		fire_refresh_display();
	}

	function setting_parameter_decrease(encoder:EncoderMove)
	{
		pads[index_pad_selected].change(encoder, -1);
		fire_refresh_display();
	}

	public function pad_add(pad:Pad)
	{
		pads.push(pad);
	}
}

@:structInit
class Pad
{
	public var name(default, null):String;

	public var encoders(default, null):Map<EncoderMove, Parameter> = [];

	public function change(encoder:EncoderMove, increment:Int)
	{
		encoders[encoder].change(increment);
	}
}

@:structInit
class Parameter
{
	public var value(default, null):Float;
	public var name(default, null):String;

	var minimum:Float = 0;
	var maximum:Float = 1000;
	var on_change:Float->Void;

	public function change(increment:Int)
	{
		value += increment;
		if (value > maximum)
		{
			value = maximum;
		}
		if (value < minimum)
		{
			value = minimum;
		}
		on_change(value);
		// trace('change $name by $increment to $value');
	}
}
