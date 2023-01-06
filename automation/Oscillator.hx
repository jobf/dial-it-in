package automation;

class WaveGenerate
{
	public static inline function sine(frequencyHz:Float, position:Float, sampleRate:Float):Float
	{
		return Math.sin(2.0 * Math.PI * position * frequencyHz / sampleRate);
	}

	public static inline function triangle(frequencyHz:Float, position:Float, sampleRate:Float):Float
	{
		return Math.asin(sine(frequencyHz, position, sampleRate)) * (1.0 / Math.PI);
	}

	public static inline function pulse(frequencyHz:Float, position:Float, sampleRate:Float):Float
	{
		return Math.sin((position) * Math.PI * 2 / sampleRate * frequencyHz) > 0 ? 1.0 : -1.0;
	}

	public static inline function saw(frequencyHz:Float, position:Float, sampleRate:Float):Float
	{
		return (2 * (position % (sampleRate / frequencyHz)) / (sampleRate / frequencyHz) - 1);
	}
}

enum WaveShape
{
	SINE;
	TRI;
	PULSE;
	SAW;
}

typedef Oscillator = (frequencyHz:Float, position:Float, sampleRate:Float) -> Float;

@:structInit
class LFO
{
	public var frequency_hz:Float;
	var sampleRate:Int;
	var oscillator:Oscillator = (frequencyHz:Float, position:Float, sampleRate:Float) -> 0;
	var position:Float = 0;
	public var shape(default, set):WaveShape;

	function set_shape(shape:WaveShape):WaveShape
	{
		oscillator = switch shape
		{
			case SINE:
				WaveGenerate.sine;
			case TRI:
				WaveGenerate.triangle;
			case PULSE:
				WaveGenerate.pulse;
			case SAW:
				WaveGenerate.saw;
		}
		trace('LFO set shape $shape');
		return shape;
	}

	public function next():Float
	{
		position ++;
		return oscillator(frequency_hz, position, sampleRate);
	}
}
