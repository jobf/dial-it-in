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

	function test_encoders_are_listed_in_correct_order()
	{
		var pad_test:Pad = {
			name: "test_pad",
			encoders: [
				VOLUME => {
					value: 100,
					on_change: f -> return,
					name: "test_encoder_0",
				},
				PAN => {
					value: 0,
					on_change: f -> return,
					name: "test_encoder_1",
				},
				FILTER => {
					value: 0.5,
					on_change: f -> return,
					name: "test_encoder_2",
				},
				RESONANCE => {
					value: 1000,
					on_change: f -> return,
					name: "test_encoder_3",
				},
			]
		}

		var encoder_infos:Array<String> = pad_test.encoders_list();

		Assert.equals("test_encoder_0 100", encoder_infos[0]);
		Assert.equals("test_encoder_1 0", encoder_infos[1]);
		Assert.equals("test_encoder_2 0.5", encoder_infos[2]);
		Assert.equals("test_encoder_3 1000", encoder_infos[3]);
	}

	function test_encoders_are_listed_even_empty()
	{
		var pad_test:Pad = {
			name: "test_pad",
			encoders: [
				VOLUME => {
					value: 100,
					on_change: f -> return,
					name: "test_encoder_0",
				},
				RESONANCE => {
					value: 1000,
					on_change: f -> return,
					name: "test_encoder_3",
				},
			]
		}

		var encoder_infos:Array<String> = pad_test.encoders_list();

		Assert.equals("test_encoder_0 100", encoder_infos[0]);
		Assert.equals("", encoder_infos[1]);
		Assert.equals("", encoder_infos[2]);
		Assert.equals("test_encoder_3 1000", encoder_infos[3]);
	}
}
