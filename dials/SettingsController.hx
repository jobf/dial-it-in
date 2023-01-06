package dials;

import akaifirehx.fire.Control;
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
	var index_page:Int = 0;
	var data:FileModel;
	var pages:Array<Page>;
	var palette:Palette;
	var index_increment_modifier:Int = 4;
	var increment_modifiers:Array<Float> = [0.001, 0.01, 0.1, 0.5, 1.0, 1.1, 1.5, 2.0, 5.0, 10.0];

	public var on_button_press:Button->Void = button -> trace('$button pressed');
	public var on_button_release:Button->Void = button -> trace('$button released');
	public var canvas(default, null):OledCanvasImageSync;

	public function new(disk:Disk)
	{
		this.disk = disk;
		pages = [];
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
			case PATUP: increment_modifier_change(1);
			case PATDOWN: increment_modifier_change(-1);
			case GRIDLEFT: index_page_change(-1);
			case GRIDRIGHT: index_page_change(1);
			case _:
		});
	}


	function button_press(button:Button)
	{
		on_button_press(button);
	}

	function button_release(button:Button)
	{
		on_button_release(button);
	}

	function setting_select(index_pad:Int)
	{
		if (pages[index_page].pads.length > index_pad)
		{
			index_pad_selected = index_pad;
			fire_refresh_display();
			trace('change pad to $index_pad_selected');
		}
	}

	function fire_refresh_display()
	{
		fire.sendMessage(DisplayClear(false));

		fire.sendMessage(DisplaySetText(pages[index_page].pads[index_pad_selected].name, 0, 0, true));
		fire.sendMessage(DisplaySetText('x${increment_modifiers[index_increment_modifier]}', 88, 0, true));

		var y = 12;

		for (info in pages[index_page].pads[index_pad_selected].encoders_list())
		{
			fire.sendMessage(DisplaySetText(info, 1, y, false));
			y += 12;
		}

		fire.sendMessage(DisplayShow);
	}

	function setting_parameter_increase(encoder:EncoderMove)
	{
		if (pages[index_page].pads[index_pad_selected].encoders.exists(encoder))
		{
			pages[index_page].pads[index_pad_selected].change(encoder, 1, increment_modifiers[index_increment_modifier]);
			fire_refresh_display();
		}
	}

	function setting_parameter_decrease(encoder:EncoderMove)
	{
		if (pages[index_page].pads[index_pad_selected].encoders.exists(encoder))
		{
			pages[index_page].pads[index_pad_selected].change(encoder, -1, increment_modifiers[index_increment_modifier]);
			fire_refresh_display();
		}
	}

	function increment_modifier_change(direction:Int)
	{
		var index_next = index_increment_modifier + direction;
		index_increment_modifier = (index_next % increment_modifiers.length + increment_modifiers.length) % increment_modifiers.length;
		fire_refresh_display();
	}

	function index_page_change(direction:Int) {
		pads_clear_colors(pages[index_page].pads);
		var index_next = index_page + direction;
		index_page = (index_next % pages.length + pages.length) % pages.length;
		trace('changed to page $index_page');
		fire_refresh_display();
		pads_show_colors(pages[index_page].pads);
	}

	public function page_add(page:Page)
	{
		if (page.index == null)
		{
			page.index = pages.length;
		}
		pages.push(page);
	}

	public function pad_add(pad:Pad, index_page:Int)
	{
		if (index_page > pages.length)
		{
			trace('cannot add pad, page does not exist');
			return;
		}

		if (data != null && data.pages[index_page] != null)
		{
			var models_matching = data.pages[index_page].pads.filter(model -> model.name == pad.name);
			if (models_matching.length > 0)
			{
				var model_pad = models_matching[0];
				pad_set_from_model(pad, model_pad);
			}
		}
		if (pad.index == null)
		{
			pad.index = pages[index_page].pads.length;
		}

		pages[index_page].pads.push(pad);

		var encoder_count = [for (k in pad.encoders.keys()) k].length;
		trace('added pad ${pad.name} ${pad.index} with $encoder_count encoders');

		pads_sort(pages[index_page].pads);
		pads_show_colors(pages[index_page].pads);
	}

	var disk_file_path:String = "settings.json";

	public function disk_save():Void
	{
		var json:String = JSON.serialize(pages);

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
		for (model_page in data.pages)
		{
			var pages_matching = pages.filter(page -> page.name == model_page.name);
			if (pages_matching.length > 0)
			{
				trace('set existing page in pages array');
				var page = pages_matching[0];
				page.index = model_page.index;
				page.name = model_page.name;
				page.pads = [];
				for (model_pad in model_page.pads)
				{
					trace('setting up model ${model_pad.index}:${model_pad.name}');
					var pads_matching = page.pads.filter(pad -> pad.name == model_pad.name);
					if (pads_matching.length > 0)
					{
						trace('set existing pad in pads array');
						var pad = pads_matching[0];
						pad_set_from_model(pad, model_pad);
					}
				}
				pads_sort(page.pads);
			}
		}
		
		pages_sort(pages);

		trace('loaded ${data.pages.length} pages');
	}

	function pages_sort(pages:Array<Page>) {
		if (pages.length > 0)
			{
				trace('total pages is ${pages.length}');
	
				ArraySort.sort(pages, (page1, page2) ->
				{
					if (page1.index > page2.index)
					{
						return 1;
					}
					if (page1.index < page2.index)
					{
						return -1;
					}
					return 0;
				});
			}
	}

	function pads_sort(pads:Array<Pad>)
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

	function pads_show_colors(pads:Array<Pad>)
	{
		for (pad in pads)
		{
			pad_set_color(pad);
		}
	}

	function pads_clear_colors(pads:Array<Pad>) {
		for (pad in pads) {
			pad_set_color(pad, 0x000000);
		}
	}

	function pad_set_color(pad:Pad, ?color_override:Int=null){
		var x = Grid.column(pad.index);
		var y = Grid.row(pad.index);
		var color = color_override == null ? palette.colors[pad.index_palette] : color_override;
		fire.sendMessage(PadSingleColor(color, x, y));
	}
}

@:structInit
class Page
{
	public var name:String;
	public var index:Null<Int> = null;
	public var pads:Array<Pad> = [];
}

@:structInit
class Pad
{
	public var index:Null<Int> = null;
	public var name:String = "";
	public var index_palette:Int = 0;

	public var encoders(default, null):Map<EncoderMove, Parameter> = [];

	public function change(encoder:EncoderMove, direction:Int, increment_modifier:Float)
	{
		encoders[encoder].change(direction, increment_modifier);
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

	public function change(direction:Int, increment_modifier:Float)
	{
		value += (increment * increment_modifier) * direction;
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
	public var colors:Array<Int> = [
		0x793516,
		0xa11898,
		0x0b0d68,
		0x2f935c,
		0x86910f,
		0x335b9e,
	];
}

class Grid
{
	static var width:Int = 64;

	public static function index(column:Int, row:Int):Int
	{
		return column + width * row;
	}

	public static function column(index:Int):Int
	{
		return Std.int(index % width);
	}

	public static function row(index:Int):Int
	{
		return Std.int(index / width);
	}
}
