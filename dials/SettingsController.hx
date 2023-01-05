package dials;

import akaifirehx.fire.Control.EncoderMove;
import akaifirehx.midi.AkaiFireMidi;
import akaifirehx.midi.Ports;
import dials.Disk;
import dials.JSON;
import haxe.ds.ArraySort;
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
	var data:FileModel;
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

		for (info in pads[index_pad_selected].encoders_list())
		{
			fire.sendMessage(DisplaySetText(info, 1, y, false));
			y += 12;
		}
		fire.sendMessage(DisplayShow);
	}

	function setting_parameter_increase(encoder:EncoderMove)
	{
		if (pads[index_pad_selected].encoders.exists(encoder))
		{
		pads[index_pad_selected].change(encoder, 1);
		fire_refresh_display();
		}
	}

	function setting_parameter_decrease(encoder:EncoderMove)
	{
		if (pads[index_pad_selected].encoders.exists(encoder))
		{
		pads[index_pad_selected].change(encoder, -1);
		fire_refresh_display();
		}
	}

	public function pad_add(pad:Pad)
	{
		if (data != null && data.pads != null)
		{
			var models_matching = data.pads.filter(model -> model.name == pad.name);
			if (models_matching.length > 0)
			{
				var model_pad = models_matching[0];
				pad_set_from_model(pad, model_pad);
			}
		}
		if (pad.index == null)
		{
			pad.index = pads.length;
		}
		pads.push(pad);

		var encoder_count = [for (k in pad.encoders.keys()) k].length;
		trace('added pad ${pad.name} ${pad.index} with $encoder_count encoders');

		pads_sort();
	}

	var disk_file_path:String = "settings.json";

	public function disk_save():Void
	{
		var json:String = JSON.serialize(pads);

		disk.save(json, disk_file_path);
	}

	function pad_set_from_model(pad:Pad, model_pad:PadModel)
	{
		pad.name = model_pad.name;
		pad.index = model_pad.index;
		trace('setting up pad ${pad.name} ${pad.index}');
		for (model_enc in model_pad.encoders)
		{
			if (pad.encoders.exists(model_enc.encoder))
			{
				pad.encoders[model_enc.encoder].set(model_enc.value);
				trace('set encoder value');
			}
		}
	}

	public function disk_load():Void
	{
		var json = disk.load(disk_file_path);
		trace('loaded json');
		data = JSON.parse(json);
		trace('parsed json');

		for (model_pad in data.pads)
		{
			trace('setting up model ${model_pad.index}:${model_pad.name}');
			var pads_matching = pads.filter(pad -> pad.name == model_pad.name);
			if (pads_matching.length > 0)
			{
				trace('set existing pad in pads array');
				var pad = pads_matching[0];
				pad_set_from_model(pad, model_pad);
			}
		}

		trace('loaded ${data.pads.length} models');

		pads_sort();
	}

	function pads_sort()
	{
		if (pads.length > 0)
		{
			trace('total pads is ${pads.length}');

			ArraySort.sort(pads, (pad1, pad2) ->
			{
				if (pad1.index > pad2.index)
				{
					return 1;
				}
				if (pad1.index < pad2.index)
				{
					return -1;
				}
				return 0;
			});
		}
	}
}

@:structInit
class Pad
{
	public var index:Null<Int> = null;

	public var name:String = "";

	public var encoders(default, null):Map<EncoderMove, Parameter> = [];

	public function change(encoder:EncoderMove, increment:Int)
	{
		encoders[encoder].change(increment);
	}

	function encoder_format_info(encoder:EncoderMove):String
	{
		if (encoders.exists(encoder))
		{
			var enc = encoders[encoder];
			return '${enc.name} ${enc.value}';
		}

		return "";
	}

	public function encoders_list():Array<String>
	{
		return [
			encoder_format_info(VOLUME),
			encoder_format_info(PAN),
			encoder_format_info(FILTER),
			encoder_format_info(RESONANCE)
		];
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
