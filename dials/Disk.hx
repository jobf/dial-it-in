package dials;

#if !web
import sys.FileSystem;
import sys.io.File;
#end
using DateTools;

interface Disk
{
	public function save(json:String, disk_file_path:String):Void;
	public function load(disk_file_path:String):String;
}

class DiskSys implements Disk
{
	public function new() {}

	public function save(json:String, disk_file_path:String):Void
	{
		
		#if !web
		if (FileSystem.exists(disk_file_path)) {
			File.copy(disk_file_path, disk_file_path + '_${Date.now().format("%Y-%m-%d_%H:%M:%S")}');
		}
		File.saveContent(disk_file_path, json);
		trace('saved to $disk_file_path');
		#end
	}

	public function load(disk_file_path:String):String
	{
		#if !web
		if (FileSystem.exists(disk_file_path))
		{
			var json = File.getContent(disk_file_path);
			trace('loaded from $disk_file_path');
			return json;
		}
		#end

		return "";
	}
}
