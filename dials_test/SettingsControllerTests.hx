import dials.JSON;
import dials.SettingsController;
import utest.Assert;
import utest.Test;

class SettingsControllerTests extends Test
{
	function test_load_from_json()
	{
		// init class that is being tested
		var settings = new SettingsController(new DiskMock([
			{
				index: 0,
				name: "test_pad",
				encoders: [
					{
						value: 100,
						encoder: VOLUME
					}
				]
			}
		]));

		// need a value to bind to
		var value:Float = 0;

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
		// init class that is being tested
		var settings = new SettingsController(new DiskMock([
			{
				index: 0,
				name: "test_pad",
				encoders: [
					{
						value: 100,
						encoder: VOLUME
					}
				]
			}
		]));

		// need a value to bind to
		var value:Float = 0;

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

	function test_pads_are_correctly_ordered()
	{
		// set up pad models data in wrong order
		var models_pad:Array<PadModel> = [
			{
				index: 1,
				name: "test_pad_1",
				encoders: []
			},
			{
				index: 2,
				name: "test_pad_2",
				encoders: []
			},
			{
				index: 0,
				name: "test_pad_0",
				encoders: []
			}
		];

		// init settings
		var settings = new SettingsController(new DiskMock(models_pad));

		// load the configuration from disk
		settings.disk_load();

		// bind pads (otherwise the data is only in models)
		settings.pad_add({
			name: 'test_pad_2',
			encoders: []
		});
		settings.pad_add({
			name: 'test_pad_0',
			encoders: []
		});
		settings.pad_add({
			name: 'test_pad_1',
			encoders: []
		});

		// assert 0 is actually in the 0 index
		@:privateAccess
		Assert.equals("test_pad_0", settings.pads[0].name);

		// assert 1 is actually in the 1 index
		@:privateAccess
		Assert.equals("test_pad_1", settings.pads[1].name);

		// assert 2 is actually in the 2 index
		@:privateAccess
		Assert.equals("test_pad_2", settings.pads[2].name);
	}
}
