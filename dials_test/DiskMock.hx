import dials.Disk;
import dials.JSON;
import json2object.JsonWriter;

class DiskMock implements Disk
{
	public function new() {}

	public function save(json:String, disk_file_path:String) {}

	public function load(disk_file_path:String):String
	{
		var pad:PadModel = {
			index: 0,
			name: "test_pad",
			encoders: [
				{
					value: 100,
					encoder: VOLUME
				}
			]
		}

		var file:FileModel = {
			pads: [pad]
		}

		var writer = new JsonWriter<FileModel>();
		var json:String = writer.write(file);

		return json;
	}
}
