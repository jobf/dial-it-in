package automation;

class WaveGenerate
{
	public static inline function sine(frequency:Float, position:Float, sampleRate:Float):Float
	{
		return Math.sin(2.0 * Math.PI * position * frequency / sampleRate);
	}

	public static inline function triangle(frequency:Float, position:Float, sampleRate:Float):Float
	{
		return Math.asin(sine(frequency, position, sampleRate)) * (1.0 / Math.PI);
	}

	public static inline function pulse(frequency:Float, position:Float, sampleRate:Float):Float
	{
		return Math.sin((position) * Math.PI * 2 / sampleRate * frequency) > 0 ? 1.0 : -1.0;
	}

	public static inline function saw(frequency:Float, position:Float, sampleRate:Float):Float
	{
		return (2 * (position % (sampleRate / frequency)) / (sampleRate / frequency) - 1);
	}
}

enum WaveShape
{
	SINE;
	TRI;
	PULSE;
	SAW;
}

typedef Oscillator = (frequency:Float, position:Float, sampleRate:Float) -> Float;

@:structInit
class LFO
{
	public var frequency:Float;
	var sampleRate:Int;
	var oscillator:Oscillator = (frequency:Float, position:Float, sampleRate:Float) -> 0;
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
		return oscillator(frequency, position, sampleRate);
	}
}
