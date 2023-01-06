package dials;

import akaifirehx.fire.Control.Button;
import akaifirehx.fire.Control.EncoderMove;
import akaifirehx.fire.display.Canvas.OledCanvasImageSync;
import akaifirehx.midi.AkaiFireMidi;
import akaifirehx.midi.Ports;
import dials.Disk;
import dials.JSON;
import haxe.ds.ArraySort;

class SettingsController
{
	var disk:Disk;
	var fire:AkaiFireMidi;
	var index_pad_selected:Int = 0;
	var index_palette:Int = 0;
	var data:FileModel;
	var pads:Array<Pad>;
	var palette:Palette;
	
	public var on_button_press:Button->Void = button -> trace('$button pressed');
	public var on_button_release:Button->Void = button -> trace('$button released');
	public var canvas(default, null):OledCanvasImageSync;

	
	public function new(disk:Disk)
	{
		this.disk = disk;
		pads = [];
		palette = {};
		canvas = new OledCanvasImageSync(128, 64);

		var firePortConfig:PortConfig = {
			portName: 'FL STUDIO FIRE Jack 1',
			portNumber: 1
		}

		fire = new AkaiFireMidi(firePortConfig, firePortConfig, canvas);
		fire.events.onPadPress.add(index_pad -> setting_select(index_pad));
		fire.events.onEncoderIncrement.add(encoder -> setting_parameter_increase(encoder));
		fire.events.onEncoderDecrement.add(encoder -> setting_parameter_decrease(encoder));
		fire.events.onButtonPress.add(button -> button_press(button));
		fire.events.onButtonRelease.add(button -> button_release(button));
		fire.events.onButtonPress.add(button -> switch button
		{
			case REC: disk_save();
			case _:
		});
	}

	function button_press(button:Button)
	{
		on_button_press(button);
	}

	function button_release(button:Button){
		on_button_release(button);
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
		pads_show_colors();
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
		pad.index_palette = model_pad.index_palette;
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

	function pads_show_colors() {
		for (pad in pads) {
			var x = Grid.column(pad.index);
			var y = Grid.row(pad.index);
			fire.sendMessage(PadSingleColor(palette.colors[pad.index_palette], x, y));
		}
	}
}

@:structInit
class Pad
{
	public var index:Null<Int> = null;
	public var name:String = "";
	public var index_palette:Int = 0;

	public var encoders(default, null):Map<EncoderMove, Parameter> = [];


	public function change(encoder:EncoderMove, direction:Int)
	{
		// var
		encoders[encoder].change(direction);
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
	var increment:Float = 1;
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

	public function change(direction:Int)
	{
		value += increment * direction;
		changed();
	}

	public function set(value:Float)
	{
		this.value = value;
		changed();
	}
}

@:structInit
class Palette
{
	public var colors:Array<Int> = 
	[
		0x793516,
		0xa11898,
		0x0b0d68,
		0x2f935c,
		0x86910f,
		0x335b9e,
	];
}

class Grid{
	static var width:Int = 64;
	
	public static function index(column:Int, row:Int):Int {
		return column + width * row;
	}
	
	public static function column(index:Int):Int {
		return Std.int(index % width);
	}

	public static function row(index:Int):Int {
		return Std.int(index / width);
	}
}