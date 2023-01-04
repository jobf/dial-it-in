package dials;

#if !web
import sys.FileSystem;
import sys.io.File;
#end

class Disk
{
	public static function save(json:String, disk_file_path:String):Void
	{
		#if !web
		File.saveContent(disk_file_path, json);
		trace('saved to $disk_file_path');
		#end
	}

	public static function load(disk_file_path:String):String
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
