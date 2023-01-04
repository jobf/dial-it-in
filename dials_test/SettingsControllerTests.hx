import dials.SettingsController;
import utest.Assert;
import utest.Test;

class SettingsControllerTests extends Test
{
	function test_load_from_json()
	{
		// need a value to bind to
		var value:Float = 0;

		// init class that is being tested
		var settings = new SettingsController(new DiskMock());

		// add pad with an encoder bound to the value
		settings.pad_add({
			name: "test_pad",
			encoders: [
				VOLUME => {
					value: value,
					on_change: f -> value = f,
					name: "test_encoder",
				}
			]
		});

		// assert that the value is still zero because the settings were not loaded yet
		Assert.equals(0, value);

		// load the configuration from disk
		settings.disk_load();

		// assert that the value is now 1 because the settings were loaded
		Assert.equals(100, value);
	}

	function test_load_from_json_when_pad_added()
	{
		// need a value to bind to
		var value:Float = 0;

		// init class that is being tested
		var settings = new SettingsController(new DiskMock());

		// load the configuration from disk
		settings.disk_load();

		// assert that the value is still zero because no bindings exist yet
		Assert.equals(0, value);

		// add pad with an encoder bound to the value
		settings.pad_add({
			name: "test_pad",
			encoders: [
				VOLUME => {
					value: value,
					on_change: f -> value = f,
					name: "test_encoder",
				}
			]
		});

		// assert that the value is now 1 because the pad value was loaded from settings
		Assert.equals(100, value);
	}
}
