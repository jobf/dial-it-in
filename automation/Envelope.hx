package automation;

enum EnvelopeState
{
	Closed;
	Attack;
	Release;
}

class Envelope
{
	public var attackTime:Float = 0.001;
	public var releaseTime:Float = 1.5;

	var is_triggered:Bool = false;
	var amplitude:Ramp;
	var state:EnvelopeState = Closed;

	public function new(sampleRate:Int)
	{
		amplitude = {
			sampleRate: sampleRate,
		}
	}

	public function trigger()
	{
		is_triggered = true;
	}

	public function nextAmplitude():Float
	{
		switch state
		{
			case Closed:
				if (is_triggered && amplitude.isFinished())
				{
					attack_start();
				}
			case Attack:
				if (amplitude.isFinished())
				{
					state = Release;
					trace('ramp start Release');
					amplitude.setRamp(0.0001, releaseTime);
				}
			case Release:
				if (amplitude.isFinished())
				{
					state = Closed;
					trace('ramp end');
					on_finished();
				}
		}

		return amplitude.nextValue();
	}

	public var on_finished:Void->Void = () -> trace('on_finished');

	function attack_start()
	{
		is_triggered = false;
		state = Attack;
		trace('ramp start Attack');
		amplitude.setRamp(1.0, attackTime);
	}
}

@:structInit
class Ramp
{
	var sampleRate:Int;
	var targetValue:Float = 0.0001;
	var currentValue:Float = 0.0001;
	var increment:Float = 0.0;
	var samplesRemaining:Int = 0;

	public function setRamp(targetValue:Float, durationSeconds:Float):Void
	{
		increment = (targetValue - currentValue) / (sampleRate * durationSeconds);
		this.targetValue = targetValue;
		samplesRemaining = Math.ceil(sampleRate * durationSeconds);
		trace('currentValue $currentValue targetvalue $targetValue duration $durationSeconds increment $increment samplesRemaining $samplesRemaining');
	}

	public function nextValue():Float
	{
		if (samplesRemaining > 0)
		{
			currentValue += increment;
			samplesRemaining--;
			if (samplesRemaining <= 0)
			{
				currentValue = targetValue;
				trace('finished $currentValue');
			}
		}

		return currentValue;
	}

	public function isFinished()
	{
		return samplesRemaining <= 0;
	}
}
