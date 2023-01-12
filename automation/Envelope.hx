package automation;

enum EnvelopeState
{
	Closed;
	Attack;
	Sustain;
	Release;
}

class Envelope
{
	public var attackTime:Float = 0.001;
	public var releaseTime:Float = 1.5;

	var is_opening:Bool = false;
	var is_closing:Bool = false;
	public var amplitude:Ramp;
	public var state(default, null):EnvelopeState = Closed;
	public var has_sustain:Bool = true;

	public function new(sampleRate:Int)
	{
		amplitude = {
			sampleRate: sampleRate,
		}
	}

	public function open()
	{
		if(state == Closed){
			is_opening = true;
		}
	}


	public function close(?release:Float=null)
	{
		if(has_sustain){
			is_closing = true;
			trace('jump ramp end');
		}
		else{
			state = Release;
			trace('fall ramp end');
			amplitude.stop();
			is_closing = false;
			// on_finished();
		}
	}

	public function nextAmplitude():Float
	{
		switch state
		{
			case Closed:
				if (is_opening && amplitude.isFinished())
				{
					attack_start();
				}
			case Attack:
				if (amplitude.isFinished())
				{
					if(has_sustain){
						state = Sustain;
						trace('ramp start Sustain');
					}
					else{
						state = Release;
						trace('ramp start Release');
						amplitude.setRamp(0.0001, releaseTime);
						is_closing = false;
					}
				}
			case Sustain:
				if (is_closing)
				{
					state = Release;
					trace('ramp start Release');
					amplitude.setRamp(0.0001, releaseTime);
					is_closing = false;
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
		is_opening = false;
		is_closing = false;
		state = Attack;
		trace('ramp start Attack');
		amplitude.setRamp(1.0, attackTime);
	}

	public function now() {
		return amplitude.now();
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

	public function now():Float{
		return currentValue;
	}

	public function stop(){
		samplesRemaining = 0;
		// currentValue = 0;
	}

	public function isFinished()
	{
		return samplesRemaining <= 0;
	}

	public function get_time_remaining():Float {
		return samplesRemaining * sampleRate;
	}
}
