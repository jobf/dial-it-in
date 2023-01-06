package dials;

import akaifirehx.fire.Control;
import dials.SettingsController;
import json2object.Error;
import json2object.JsonParser;
import json2object.JsonWriter;

class JSON
{
	public static function serialize(pages:Array<Page>):String
	{
		var models_page:Array<PageModel> = [];

		for (page in pages)
		{
			var model_page:PageModel = {
				pads: [],
				name: page.name,
				index: page.index
			}
			models_page.push(model_page);
			
			for (index => pad in page.pads)
			{
				var models_encoder:Array<EncoderModel> = [];
				for (enc in pad.encoders.keys())
				{
					models_encoder.push({
						value: pad.encoders[enc].value,
						encoder: enc
					});
				}
				model_page.pads.push({
					index: index,
					index_palette: pad.index,
					name: pad.name,
					encoders: models_encoder
				});
			}
		}

		var model_file:FileModel = {
			pages: models_page
		}

		var writer = new JsonWriter<FileModel>();
		var json:String = writer.write(model_file);
		return json;
	}

	public static function parse(json:String):FileModel
	{
		var errors = new Array<Error>();
		var data = new JsonParser<FileModel>(errors).fromJson(json, 'json-errors');

		if (errors.length > 0 || data == null)
		{
			for (error in errors)
			{
				trace(error);
			}
			return {
				pages: []
			}
		}

		return data;
	}
}

@:structInit
class FileModel
{
	public var pages:Array<PageModel>;
}

@:structInit
class EncoderModel
{
	public var encoder:EncoderMove;
	public var value:Float;
}

@:structInit
class PadModel
{
	public var index:Int;
	public var index_palette:Int;
	public var name:String;
	public var encoders:Array<EncoderModel>;
}

@:structInit
class PageModel
{
	public var index:Int;
	public var name:String;
	public var pads:Array<PadModel>;
}
