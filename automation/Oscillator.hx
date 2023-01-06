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

class WaveTable
{
	var tables:Map<WaveShape, Array<Float>> = [];

	public function new(sampleRate:Int)
	{
		tables[SINE] = [for (n in 0...sampleRate) WaveGenerate.sine(1, n, sampleRate)];
		tables[SAW] = [for (n in 0...sampleRate) WaveGenerate.saw(1, n, sampleRate)];
		tables[TRI] = [for (n in 0...sampleRate) WaveGenerate.triangle(1, n, sampleRate)];
		tables[PULSE] = [for (n in 0...sampleRate) WaveGenerate.pulse(1, n, sampleRate)];
	}

	public function get(shape:WaveShape, position:Int):Float {
		return tables[shape][position];
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
	public var shape:WaveShape;

	var sampleRate:Int;
	var oscillator:WaveTable;
	var position:Int = 0;

	public function next():Float
	{
		position++;
		position = (position % sampleRate);
		return oscillator.get(shape, position) * frequency;
	}
}
