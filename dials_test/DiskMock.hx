import dials.Disk;
import dials.JSON;
import json2object.JsonWriter;

class DiskMock implements Disk
{
	var file:FileModel;

	public function new(pads:Array<PadModel>)
	{
		file = {
			pads: pads
		}
	}

	public function save(json:String, disk_file_path:String) {}

	public function load(disk_file_path:String):String
	{
		var writer = new JsonWriter<FileModel>();
		var json:String = writer.write(file);

		return json;
	}
}
