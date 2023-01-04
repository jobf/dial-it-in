package dials;

import akaifirehx.fire.Control.EncoderMove;
import akaifirehx.midi.AkaiFireMidi;
import akaifirehx.midi.Ports;
import dials.Disk;
import dials.JSON;
#if imagedisplay
import akaifirehx.fire.display.Canvas.ImageCanvas as PixelCanvas;
#else
import akaifirehx.fire.display.Canvas.OledCanvas as PixelCanvas;
#end

class SettingsController
{
	var disk:Disk;
	var fire:AkaiFireMidi;
	var index_pad_selected:Int = 0;

	var pads:Array<Pad>;

	public function new(disk:Disk)
	{
		this.disk = disk;
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
		fire.events.onButtonPress.add(button -> switch button
		{
			// case BROWSER:
			// case PATUP:
			// case PATDOWN:
			// case GRIDLEFT:
			// case GRIDRIGHT:
			// case ALT:
			// case STOP:
			// case TRACK1:
			// case TRACK2:
			// case TRACK3:
			// case TRACK4:
			// case STEP:
			// case NOTE:
			// case DRUM:
			// case PERFORM:
			// case SHIFT:
			case REC: disk_save();
			// case PATTERN:
			// case PLAY:
			// case ENCODERMODE:
			case _:
		});
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

	var disk_file_path:String = "settings.json";

	public function disk_save():Void
	{
		var json:String = JSON.serialize(pads);

		disk.save(json, disk_file_path);
	}

	public function disk_load():Void
	{
		var json = disk.load(disk_file_path);

		var data:FileModel = JSON.parse(json);

		for (model_pad in data.pads)
		{
			for (model_enc in model_pad.encoders)
			{
				if (model_pad.index < pads.length)
				{
					var pad = pads[model_pad.index];
					if (pad.encoders.exists(model_enc.encoder))
					{
						pad.encoders[model_enc.encoder].set(model_enc.value);
					}
				}
			}
		}
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

	function changed():Void
	{
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

	public function change(increment:Int)
	{
		value += increment;
		changed();
	}

	public function set(value:Float)
	{
		this.value = value;
		changed();
	}
}
