package dials;

import akaifirehx.fire.Control;
import dials.SettingsController;
import json2object.Error;
import json2object.JsonParser;
import json2object.JsonWriter;

class JSON
{
	public static function serialize(pads:Array<Pad>):String
	{
		var models_pad:Array<PadModel> = [];
		for (index => pad in pads)
		{
			var models_encoder:Array<EncoderModel> = [];
			for (enc in pad.encoders.keys())
			{
				models_encoder.push({
					value: pad.encoders[enc].value,
					encoder: enc
				});
			}
			models_pad.push({
				index: index,
				index_palette: pad.index,
				name: pad.name,
				encoders: models_encoder
			});
		}
		var a = [];
		var model_file:FileModel = {
			pads: models_pad
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
				pads: []
			}
		}

		return data;
	}
}

@:structInit
class FileModel
{
	public var pads:Array<PadModel>;
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
