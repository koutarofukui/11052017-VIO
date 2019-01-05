

s.boot;
s.reboot;
s.stop;
Server.killAll;


Server.local.options.sampleRate = 44100;
Server.local.options.sampleRate = 96000;
s.latency = 0.001;

(

var winenv, r, seq, tempo;
~gauss.free;
~delayFX.free;
~combFX.free;
~allpassFX.free;
~mixerFX.free;
~rlpf.free;


~granularSynth_1.free;
~granularSynth_2.free;

~bus_pulseSpeed_1.free;
~bus_dur_1.free;
~bus_rate_1.free;

~bus_LFO.free;
~bus_Trig.free;

~bus_pulseSpeed_2.free;
~bus_dur_2.free;
~bus_rate_2.free;

~bus_pulseSpeed_3.free;
~bus_dur_3.free;
~bus_rate_3.free;


~bus_kpFilterFreq.free;


tempo = 125;
~tempo2FreqRate = 120/tempo;
~tempo2MsRate = tempo/120;
// *//
~grainBuffer_1 = Buffer.read(s, "/Users/koutarofukui/Desktop/11052017@VIO/161021_002_16_mono.wav");
~grainBuffer_2 = Buffer.read(s, "/Users/koutarofukui/Desktop/11052017@VIO/RunningWaterLow_mono.wav");
// */
//

// ~grainBuffer_1 = Buffer.read(s, "C:/Users/kouta/Desktop/11052017@VIO/161021_002_16_mono.wav");
// ~grainBuffer_2 = Buffer.read(s, "C:/Users/kouta/Desktop/11052017@VIO/RunningWaterLow_mono.wav");

// a custom envelope
winenv = Env([0, 1, 0], [0.5, 0.5], [8, -8]);
~envWinBuffer = Buffer.sendCollection(s, winenv.discretize, 1);
//Modulation Synth

SynthDef(\envelope, { arg i_outbus=0;
    var env, envctl;

    // make a dummy 8 segment envelope
    env = Env.newClear(8);

    // create a control argument array
    envctl = \env.kr( env.asArray );

    ReplaceOut.kr(i_outbus, EnvGen.kr(envctl, doneAction: 2));
}).add;

SynthDef(\LFO, { arg i_outbus=0, freq = 2, min = 0.001, max = 2000;
    var env;

	ReplaceOut.kr(i_outbus, SinOsc.kr(freq, 0).range(min, max));
}).add;



//Audio Instrument Synth

SynthDef(\grainBuf, {|fxout = 0, pulse = 0, rate = 1, pan, pos, dur = 0.1, gate = 1, amp = 1, sndbuf, envbuf, pModSel = 0, modAmount = 0.0|
	var env, freqdev, source, trig;
	trig = Impulse.kr(pulse);

    pan = LFNoise2.kr(2);
	pos = LFNoise2.kr(1).range(0, 1);
    env = EnvGen.kr(
        Env.adsr(0, 0, 1, 6, 1),
        gate,
        levelScale: amp,
        doneAction: 2);

	Out.ar([0, fxout],
		GrainBuf.ar(2, trig, dur, sndbuf, rate + (TRand.kr(0, 20, trig)*modAmount),
            pos, 2, pan, envbuf) * env)

}).add;

SynthDef(\grainSine, {|fxout = 0, pulse = 0, rate = 1, atk = 0, pan, pos, dur = 0.01, gate = 1, amp = 0.75, sndbuf, envbuf, pModSel = 0, modAmount = 0.0|
	var env, freqdev, source, trig;
	trig = Impulse.kr(pulse);

    pan = LFNoise2.kr(2);
	pos = LFNoise2.kr(3).range(0, 100);
    env = EnvGen.kr(
		Env.adsr(atk, 0, 1, 0),
        gate,
        levelScale: amp,
        doneAction: 2);

	Out.ar([0, fxout],
		GrainSin.ar(2, trig, dur, rate + pos, pan, envbuf) * env);

}).add;


SynthDef(\gauss, {|fxout = 0,freq = 15000, gate = 1, atk = 0, dur =2, width, modFreq_1 = 0.05, modFreq_2 = 2 |
	var osc, env, modOsc_1, modOsc_2;
	modOsc_1 = SinOsc.ar(modFreq_1).range(0.01, 0.3);
	modOsc_2 = SinOsc.ar(modFreq_2).range(0.006, 0.01);
	env = EnvGen.ar(Env.adsr(atk,0, 1,  0.25), gate,  doneAction: 2);
	dur = SinOsc.ar(modFreq_1* [1, 1.1]).range(0.0006, 0.01);
    width = SinOsc.ar(modFreq_2 * [1, 1.1]).range(0.01, 0.3);
    osc   = LFGauss.ar(dur, width) * 0.45;
	Out.ar([0, 1, fxout],
		osc * env)

}).add;



SynthDef(\ring, {|fxout = 0, pulse = 1, dur = 8, gate = 1,atk = 0, rel = 0|
	var trig, osc, env, adsr, pos;

	    trig = Impulse.kr(pulse);
	env = Decay.kr(trig, 0.3, 0.25, 0);
	adsr = EnvGen.kr(Env([0, 1, 0],[dur]), gate, doneAction:2);
	pos = LFNoise2.kr(2);
	osc = Limiter.ar(
		Mix.fill(8, {

			Ringz.ar( SinOsc.ar(env * 220 + 55, 0, 0.25) * env,
				exprand(1000.0,5000.0) ,
				0.25
			)
		}),
		0.9, 0.01);
	Out.ar([0, fxout],
		Pan2.ar(osc*adsr*0.3, pos) )

}).add;



//a = Synth(\gauss,[\modFreq_1, 45.0.rand,   \modFreq_2, 3.0.rand]);

SynthDef(\basic, {|fxout = 0,freq = 15000, gate = 1|
	var osc, env;
	env = EnvGen.ar(Env.perc(0.01, 0.25),  doneAction: 2);
	osc = Limiter.ar(Ringz.ar(RLPF.ar(Pulse.ar(freq, 0.5, 0.2),freq*1.5, 0.5), freq*4, 0.5)/6, 0.95, 0.001) ;
	osc = Pan2.ar(osc, 0);
	Out.ar([0, 1, fxout],
		osc * env)

}).add;

SynthDef(\KSpluck, { arg midiPitch = 69, delayDecay = 1.0, fb = 0.25, filterFreq = 200;
	var burstEnv, att = 0, dec = 0.001, signalOut, delayTime, mouseX, mouseY;
	mouseX = MouseX.kr(100, 11000);
	mouseY = MouseY.kr(0.0001, 0.99);
	delayTime = [midiPitch, midiPitch+12].midicps.reciprocal;

	signalOut = BPF.ar(Pulse.ar(LFSaw.kr(8, 0, 20, 20)+ 5, mouseY, 0.5), filterFreq, 0.999);
	signalOut = CombL.ar(signalOut, delayTime*2, delayTime, delayDecay, add: signalOut) + LocalIn.ar(2);
	signalOut = DelayN.ar(signalOut, 0.25, 0.25);
	LocalOut.ar(signalOut * fb);
	//DetectSilence.ar(signalOut, doneAction:2);
	Out.ar(0, signalOut)
	}
).add;

SynthDef(\fm, {|fxout = 0,freq = 15000, gate = 1, attack = 1, decay = 1, dur = 8, amp = 0.5|
	var osc,modOsc, env, line;
	line = Line.kr(freq, freq*2, dur);
	env = EnvGen.ar(Env([0, 1, 0], [dur/2, dur/2]), gate,  doneAction: 2);
	osc = SinOsc.ar(line + SinOsc.ar(line*1.5, 0, 440), 0, amp);
	osc = Pan2.ar(osc*env, 0);
	Out.ar([0, fxout],
		osc)

}).add;

//FX

SynthDef("rlpf",{ arg out=[0, 1],ffreq = 2000,rq=0.9;
	    ReplaceOut.ar( out, RLPF.ar( In.ar(out, 2), ffreq, rq) )
}).add;


///////////////////
SynthDef("preDelay", { arg inbus = 16, fb = 0.3, delayTime = 0.25;
	var local;
	local = In.ar(inbus, 2) + LocalIn.ar(2);
	local = DelayN.ar(local, ~tempo2MsRate*1, ~tempo2MsRate*delayTime);
	LocalOut.ar(local * fb);
    ReplaceOut.ar(
        4,
        local
    )
}).add;

SynthDef("combs", {
    ReplaceOut.ar(
        6,

		Mix.arFill(7, {
			CombL.ar(In.ar(18, 2)*0.75,
				0.125,
				LFNoise1.kr(Rand(0, 0.1), 0.04, 0.05),
				8)
		})
    )
}).add;

SynthDef("allpass", { arg gain = 0.85;
    var source;
    source = In.ar(20, 2);
    8.do({source = AllpassN.ar(source, 0.050, [Rand(0, 0.05), Rand(0, 0.05)], 8) });
    ReplaceOut.ar(8, source * gain)
}).add;

SynthDef("theMixer", { arg master = 0.8, delayVol = 0.75, combVol = 0.75, allpassVol = 0.75;
    ReplaceOut.ar(
        0,
		Limiter.ar(Mix.ar([In.ar(0, 2), In.ar(2, 2), In.ar(4, 2) * delayVol, In.ar(6, 2) * combVol, In.ar(8, 2) * allpassVol]) * master, 0.99, 0.001)
    )
}).add;




seq.size;

~bus_pulseSpeed_1 = Bus.control(s, 1);
~bus_dur_1 = Bus.control(s, 1);
~bus_rate_1 = Bus.control(s, 1);

~bus_LFO = Bus.control(s, 1);
~bus_Trig = Bus.control(s, 1);

~bus_pulseSpeed_2 = Bus.control(s, 1);
~bus_dur_2 = Bus.control(s, 1);
~bus_rate_2 = Bus.control(s, 1);

~bus_pulseSpeed_3 = Bus.control(s, 1);
~bus_dur_3 = Bus.control(s, 1);
~bus_rate_3 = Bus.control(s, 1);


~bus_kpFilterFreq = Bus.control(s, 1);

~delayFX = Synth.tail(s, "preDelay");
~combFX = Synth.tail(s, "combs");
~allpassFX = Synth.tail(s, "allpass");
~mixerFX = Synth.tail(s, "theMixer", ["master", 0.84]);


// [1, 2, 0.5, 0.25, 0.5, 0.25, 2, 0.125, 0.375, 0.75, 0.25].sum;
r = Routine {|a|
	var seq, seq_2;
	seq = [1, 2, 0.5, 0.25, 0.5, 0.25, 2, 0.125, 0.375, 0.75, 0.25];
	seq.sum;

	"start".postln;
	6.do({ arg a;
		var pitch;
		pitch = 4.rand* 7+ 12;
		Synth(\fm, [\freq, pitch.midicps, \dur, 16*~tempo2MsRate, \fxout, 16, \amp, 0.2]);
		(4*~tempo2MsRate).wait;
    });

	6.do({ arg a;
		var pitch, pitch_2, pitch_3;
		pitch = 4.rand* 7+ 12;
		Synth(\fm, [\freq, pitch.midicps, \dur, 16*~tempo2MsRate, \fxout, 16, \amp, 0.2]);
		pitch_2 = 4.rand* 7+ 24;
		Synth(\fm, [\freq, pitch_2.midicps, \dur, 16*~tempo2MsRate, \fxout, 16, \amp, 0.2]);
		pitch_3 = 4.rand* 7+ 48;
		Synth(\fm, [\freq, pitch_3.midicps, \dur, 16*~tempo2MsRate, \fxout, 16, \amp, 0.3]);
		(4*~tempo2MsRate).wait;
    });
	4.do({ arg a;
		var pitch, pitch_2;
		pitch = 4.rand* 7+ 12;
		Synth(\fm, [\freq, pitch.midicps, \dur, 16*~tempo2MsRate, \fxout, 16, \amp, 0.2]);
		pitch_2 = 4.rand* 7+ 24;
		Synth(\fm, [\freq, pitch_2.midicps, \dur, 16*~tempo2MsRate, \fxout, 16, \amp, 0.3]);
		(4*~tempo2MsRate).wait;
    });

	(4*~tempo2MsRate).wait;


	~bus_pulseSpeed.set(10*~tempo2MsRate);
	~bus_dur.set(0.1);

	~granularSynth_1 = Synth(\grainBuf, [pulse: 10*~tempo2MsRate, dur:0.1,  \sndbuf, ~grainBuffer_1, \envbuf, ~envWinBuffer]); //1
	//introSeq = [1, 2, 0.5, 0.25, 0.5, 0.25, 2];
    8.do({ arg a;

		~granularSynth_1.set(\rate, 2.0.rand + 0.5);
		(0.125*~tempo2MsRate).wait;
    });
	~granularSynth_1.set(\pulse, ~bus_pulseSpeed_1.asMap, \dur, ~bus_dur_1.asMap);

	~granularSynth_1.set(\rate, 2*~tempo2MsRate);

	Synth(\envelope, [i_outbus: ~bus_pulseSpeed_1, env: Env([10, 5, 20, 10], [4*~tempo2MsRate, 0, 5*~tempo2MsRate], \exp)]);
	Synth(\envelope, [i_outbus: ~bus_dur_1, env: Env([0.1, 0.5, 0.1, 0.05], [4*~tempo2MsRate, 0, 5*~tempo2MsRate], \exp)]);

	4*~tempo2MsRate.wait;
	~granularSynth_1.set(\envbuf, -1);
	//~rlpf = Synth.after(x,"rlpf",[\ffreq, 200000, \out,[0, 1]]);
	//~rlpf.set("ffreq", 200400);
	//~rlpf.set("ffreq", 1800);

	8*~tempo2MsRate.wait;
	Synth(\envelope, [i_outbus: ~bus_pulseSpeed_1, env: Env([20, 5, 20, 5, 20, 5], [1*~tempo2MsRate, 1*~tempo2MsRate, 1*~tempo2MsRate, 1*~tempo2MsRate, 1*~tempo2MsRate], \exp)]);

	6*~tempo2MsRate.wait;
	~bus_pulseSpeed_1.set(6*~tempo2MsRate);
	//~rlpf.set("ffreq", 400);
	~bus_dur_1.set(0.125);
	4*~tempo2MsRate.wait;
	//~rlpf.set("ffreq", 5800);
	Synth(\envelope, [i_outbus: ~bus_pulseSpeed_1, env: Env([6, 20], [8*~tempo2MsRate], \exp)]);
	8.do({ arg a;
		~bus_dur_1.set(0.125/8);
		~granularSynth_1.set(\rate, 32.0.rand + 0.5);
		(0.125*~tempo2MsRate).wait;
    });
	~granularSynth_1.set(\rate, 1, \fxout, 16);

	~granularSynth_1.set(\envbuf, ~envWinBuffer);
	~bus_dur_1.set(0.125/2);


	//~rlpf.set("ffreq", 10800);
	8.do({ arg a;

		~granularSynth_1.set(\rate, 0.125 * a);
		0.5*~tempo2MsRate.wait;
    });
	~granularSynth_1.set(\gate, 0); //1
	(6*~tempo2MsRate).wait;
	~granularSynth_1.free;
	~granularSynth_1 = Synth(\grainBuf, [pulse: ~bus_pulseSpeed_1.asMap, dur:~bus_dur_1.asMap,  \sndbuf, ~grainBuffer_1, \envbuf, ~envWinBuffer, \fxout, 0]); //2
	~bus_pulseSpeed_1.set(10*~tempo2MsRate);
	~bus_dur_1.set(0.5);
	//~rlpf.set("ffreq", 20800);
	"busRate_Change".postln;
	8.do({
		~scr = [0, 1, 2, 3, 4, 5, 6, 7].scramble;
		8.do({ arg a;
			var selNum, scramble, output, speed;
			output = 0;
			scramble = ~scr[a];
			~granularSynth_1.set(\rate, 64.0.rand + 1, \fxout, output);
			speed = (6*3.rand + 10)*~tempo2MsRate;
			~bus_pulseSpeed_1.set(speed);
			~bus_dur_1.set(0.125/2*~tempo2MsRate * 16.rand + 0.125/4*~tempo2MsRate);
			if(seq[scramble] == 0.125, { ~granularSynth_1.set(\rate, 30.0.rand + 1, \fxout, output);});
			if(seq[scramble] == 0.25, { ~granularSynth_1.set(\rate, 30.0.rand + 1, \fxout, output);});
			if(seq[scramble] == 0.375, { ~granularSynth_1.set(\rate, 30.0.rand + 1, \fxout, output);});
			if(seq[scramble] == 0.5, { ~granularSynth_1.set(\rate, 30.0.rand + 1, \fxout, output);});
			if(seq[scramble] == 0.75, { ~granularSynth_1.set(\rate, ~bus_rate_1.asMap ); Synth(\envelope, [i_outbus: ~bus_rate_1, env: Env([1, 30], [seq[scramble]*~tempo2MsRate], \exp)])} );//
			if(seq[scramble] == 1, {
				~granularSynth_1.set(\modAmount, 0.5);
				~granularSynth_1.set(\rate, ~bus_pulseSpeed_1.asMap );
				Synth(\envelope, [i_outbus: ~bus_pulseSpeed_1, env: Env([speed, 30.rand], [seq[scramble]*~tempo2MsRate], \exp)])
			},
			{~granularSynth_1.set(\modAmount, 0)}
			);
			if(seq[scramble] == 2, { ~granularSynth_1.set(\rate, 30.0.rand + 1, \fxout, output); Synth(\envelope, [i_outbus: ~bus_pulseSpeed_1, env: Env([20, 5], [seq[scramble]*~tempo2MsRate], \exp)])});
			/*switch(seq[selNum],
				2, "")*/

			(seq[scramble] * ~tempo2MsRate).wait;


		});
	});
	//~granularSynth_1.set(\gate, 0);
	~tempo2MsRate*2.wait;

	"Second Grain".postln;
	//~granularSynth_1 = Synth(\grainBuf, [pulse: ~bus_pulseSpeed_1.asMap, dur:~bus_dur_1.asMap,  \sndbuf, ~grainBuffer_1, \envbuf, ~envWinBuffer]);
	~granularSynth_2 = Synth(\grainBuf, [pulse: ~bus_pulseSpeed_2.asMap, dur:~bus_dur_2.asMap,  \sndbuf, ~grainBuffer_2, \envbuf, ~envWinBuffer]);
	8.do({
		~scr = [0, 1, 2, 3, 4, 5, 6, 7].scramble.postln;
		8.do({ arg a;
			var selNum, scramble, output;
			output = 0;
			scramble = ~scr[a];
			~granularSynth_1.set(\rate, 30.0.rand + 0.5, \fxout, output);

			~bus_pulseSpeed_1.set(16.rand * 2 + 4);
			~bus_dur_1.set(0.125/2*~tempo2MsRate * 16.rand + 0.125/4*~tempo2MsRate);

			~granularSynth_2.set(\rate, 20.0.rand + 0.125/2, \fxout, 0);
			~bus_pulseSpeed_2.set(8.rand * 2 + 4);
			~bus_dur_2.set(0.125/2*~tempo2MsRate * 16.rand + 0.125*~tempo2MsRate);

			if(seq[scramble] == 0.125, { });
			if(seq[scramble] == 0.25, { });
			if(seq[scramble] == 0.375, { });
			if(seq[scramble] == 0.5, { });
			if(seq[scramble] == 0.75, { });
			if(seq[scramble] == 1, { });
			if(seq[scramble] == 2, {
				~granularSynth_1.set(\pulse, ~bus_pulseSpeed_1.asMap);
				Synth(\envelope, [i_outbus: ~bus_pulseSpeed_1, env: Env([16.rand, 16.rand], [seq[scramble]*~tempo2MsRate], \exp)])
			});
			/*switch(seq[selNum],
				2, "")*/

			(seq[scramble] * ~tempo2MsRate).wait;


		});
	});

	~granularSynth_1.set(\gate, 0);
	~granularSynth_2.set(\gate, 0);

	(~tempo2MsRate*4).wait;


	"FX_Section".postln;
~granularSynth_1.free;
	~granularSynth_2.free;
~granularSynth_1 = Synth(\grainBuf, [pulse: ~bus_pulseSpeed_1.asMap, dur:~bus_dur_1.asMap,  \sndbuf, ~grainBuffer_1, \envbuf, ~envWinBuffer]);
	~granularSynth_2 = Synth(\grainBuf, [pulse: ~bus_pulseSpeed_2.asMap, dur:~bus_dur_2.asMap,  \sndbuf, ~grainBuffer_2, \envbuf, ~envWinBuffer]);
	4.do({
		~scr = [0, 1, 2, 3, 4, 5, 6, 7].scramble.postln;
		8.do({ arg a;
			var selNum, scramble, output_1, output_2;
			output_1 = ((3.rand)*2 + 16).postln;
			output_2 = ((3.rand)*2 + 16).postln;
			scramble = ~scr[a];
			~granularSynth_1.set(\rate, 30.0.rand + 1, \fxout, output_1);
			~bus_pulseSpeed_1.set((8.rand * 2 + 4)*~tempo2MsRate);
			~bus_dur_1.set(0.125/2 * 16.rand *~tempo2MsRate + 0.125/8*~tempo2MsRate);

			~granularSynth_2.set(\rate, 20.0.rand + 0.125/2, \fxout, output_2, \modAmount, 1.0.rand);
			~bus_pulseSpeed_2.set((8.rand * 2 + 4)*~tempo2MsRate);
			~bus_dur_2.set(0.125*~tempo2MsRate * 16.rand + 0.125/8*~tempo2MsRate);

			if(seq[scramble] == 0.125, { });
			if(seq[scramble] == 0.25, { });
			if(seq[scramble] == 0.375, { });
			if(seq[scramble] == 0.5, { });
			if(seq[scramble] == 0.75, { });
			if(seq[scramble] == 1, { });
			if(seq[scramble] == 2, {
				/*~granularSynth_1.set(\pulse, ~bus_pulseSpeed_1.asMap);
				Synth(\envelope, [i_outbus: ~bus_pulseSpeed_1, env: Env([16.rand, 16.rand], [seq[scramble]*~tempo2MsRate], \exp)]);
				~granularSynth_2.set(\pulse, ~bus_pulseSpeed_2.asMap);
				Synth(\envelope, [i_outbus: ~bus_pulseSpeed_2, env: Env([16.rand, 16.rand], [seq[scramble]*~tempo2MsRate], \exp)]);*/
			});


			(seq[scramble] * ~tempo2MsRate).wait;


		});
	});
	~granularSynth_1.set(\gate, 0);
	~granularSynth_2.set(\gate, 0);
	(2*~tempo2MsRate).wait;


	//doube time
	"doube time".postln;
	~granularSynth_1.free;
	~granularSynth_2.free;
	~granularSynth_1 = Synth(\grainBuf, [pulse: ~bus_pulseSpeed_1.asMap, dur:~bus_dur_1.asMap,  \sndbuf, ~grainBuffer_1, \envbuf, ~envWinBuffer]);
	~granularSynth_2 = Synth(\grainBuf, [pulse: ~bus_pulseSpeed_2.asMap, dur:~bus_dur_2.asMap,  \sndbuf, ~grainBuffer_2, \envbuf, ~envWinBuffer]);

	4.do({
		~scr = [0, 1, 2, 3, 4, 5, 6, 7].scramble;
		8.do({ arg a;
			var selNum, scramble, output_1, output_2;
			output_1 = ((3.rand)*2 + 16);
			output_2 = ((3.rand)*2 + 16);

			scramble = ~scr[a];
			~granularSynth_1.set(\rate, 30.0.rand + 1, \fxout, output_1);
			~bus_pulseSpeed_1.set(16.rand * 2 + 2);
			~bus_dur_1.set(0.125*~tempo2MsRate * 8.rand + 0.125/16*~tempo2MsRate);

			~granularSynth_2.set(\rate,  40.0.rand + 0.125/8, \fxout, output_2, \envbuf, -1);
			~bus_pulseSpeed_2.set(16.rand * 2 + 2);
			~bus_dur_2.set(0.125*~tempo2MsRate * 8.rand + 0.125/16*~tempo2MsRate);

			if(seq[scramble] == 0.125, { });
			if(seq[scramble] == 0.25, { });
			if(seq[scramble] == 0.375, { });
			if(seq[scramble] == 0.5, { });
			if(seq[scramble] == 0.75, { });
			if(seq[scramble] == 1, {
				/*~granularSynth_1.set(\pulse, ~bus_dur_1.asMap);
				Synth(\envelope, [i_outbus: ~bus_dur_1, env: Env([0.25.rand, 0.25.rand], [(seq[scramble]*4*~tempo2MsRate])])*/
			});
			if(seq[scramble] == 2, {
				/*~granularSynth_1.set(\pulse, ~bus_pulseSpeed_1.asMap);
				Synth(\envelope, [i_outbus: ~bus_pulseSpeed_1, env: Env([10.rand, 10.rand], [(seq[scramble]*4*~tempo2MsRate], \exp)]);
				~granularSynth_2.set(\pulse, ~bus_pulseSpeed_2.asMap);
				Synth(\envelope, [i_outbus: ~bus_pulseSpeed_2, env: Env([8.rand, 8.rand], [seq[scramble]*4*~tempo2MsRate], \exp)]);*/
			});
			/*switch(seq[selNum],
				2, "")*/
			~synthA = Synth(\basic, [freq: (24.rand + 24).midicps, fxout: 18]);
			(seq[scramble]*4 * ~tempo2MsRate).wait;


		});
	});

	~granularSynth_1.set(\gate, 0);
	~granularSynth_2.set(\gate, 0);



	(1*~tempo2MsRate).wait;
	~granularSynth_1.free;
	~granularSynth_2.free;

	"FilterStart".postln;
	~granularSynth_1 = Synth(\grainBuf, [pulse: ~bus_pulseSpeed_1.asMap, dur:~bus_dur_1.asMap,  \sndbuf, ~grainBuffer_1, \envbuf, ~envWinBuffer]);
	//~granularSynth_2 = Synth(\grainBuf, [pulse: ~bus_pulseSpeed_2.asMap, dur:~bus_dur_2.asMap,  \sndbuf, ~grainBuffer_2, \envbuf, ~envWinBuffer]);

	~granularSynth_1.set(\rate, 30.0.rand + 1, \fxout, [16, 20]);
	Synth(\envelope, [i_outbus: ~bus_pulseSpeed_1, env: Env([10, 5, 20, 10], [4*~tempo2MsRate, 4, 4*~tempo2MsRate], \exp)]);
	~rlpf = Synth.after(~granularSynth_1,"rlpf",[\ffreq, 20000, \rq, 0.3, \out,[0, 1]]);
	~filterEnv = [200, 5000].wrapExtend(3);

	Synth(\envelope, [i_outbus: ~bus_LFO, env: Env(~filterEnv, [4*~tempo2MsRate], \exp)]);
	~rlpf.set(\ffreq, ~bus_LFO.asMap);
	(16*~tempo2MsRate).wait;

	~filterEnv = [200, 8000].wrapExtend(4);
	Synth(\envelope, [i_outbus: ~bus_LFO, env: Env(~filterEnv, [4*~tempo2MsRate], \exp)]);
	(16*~tempo2MsRate).wait;

	//doube time
	~granularSynth_2 = Synth(\grainBuf, [pulse: ~bus_pulseSpeed_2.asMap, dur:~bus_dur_2.asMap,  \sndbuf, ~grainBuffer_2, \envbuf, ~envWinBuffer, \modAmount, 1]);


	32.do({
		~scr = [0, 1, 2, 3, 4, 5, 6, 7].scramble;
		8.do({ arg a;
			var selNum, scramble, output_1, output_2, output_3;
			output_1 = ((3.rand)*2 + 16);
			output_2 = ((3.rand)*2 + 16);
			output_3 = (20);

			scramble = ~scr[a];
			~granularSynth_1.set(\rate, 20.0.rand + 1, \fxout, output_1, \modAmount, 1.0.rand);
			~bus_pulseSpeed_1.set(24.rand * 2*~tempo2MsRate  + 4);
			~bus_dur_1.set(0.125/2*~tempo2MsRate * 12.rand + 0.125/8*~tempo2MsRate);

			~granularSynth_2.set(\rate, 20.0.rand + 0.125/2, \fxout, output_2, \modAmount, 1.0.rand);
			~bus_pulseSpeed_2.set((24.rand * 2 + 4) *~tempo2MsRate/4 );
			~bus_dur_2.set(0.25*~tempo2MsRate * 12.rand + 0.125/8*~tempo2MsRate);


			if(seq[scramble] == 0.125, { ~granularSynth_2.set(\envbuf, ~envWinBuffer)}, { ~granularSynth_2.set(\envbuf, -1)});
			if(seq[scramble] == 0.25, { ~granularSynth_2.set(\envbuf, ~envWinBuffer)}, { ~granularSynth_2.set(\envbuf, -1)});
			if(seq[scramble] == 0.375, { });
			if(seq[scramble] == 0.5, { ~granularSynth_2.set(\envbuf, ~envWinBuffer)}, { ~granularSynth_2.set(\envbuf, -1)});
			if(seq[scramble] == 0.75, { });
			if(seq[scramble] == 1, {  ~synthA = Synth(\basic, [freq: (24.rand + 24).midicps, fxout: 18]);},
			{~granularSynth_1.set(\pModSel, 0)});
			if(seq[scramble] == 2, { /*~granularSynth_1.set(\pulse, ~bus_pulseSpeed_1.asMap); Synth(\envelope, [i_outbus: ~bus_pulseSpeed_1, env: Env([20.rand, 20.rand], [(seq[scramble]*4*~tempo2MsRate], \exp)]); */~synthA = Synth(\basic, [freq: (24.rand + 24).midicps, fxout: 18]);});
			/*switch(seq[selNum],
				2, "")*/

			(seq[scramble]/6 * ~tempo2MsRate).wait;


		});
	});

	1.do({
		~scr = [0, 1, 2, 3, 4, 5, 6, 7].scramble;
		8.do({ arg a;
			var selNum, scramble, output_1, output_2;
			output_1 = ((3.rand)*2 + 16);
			output_2 = ((3.rand)*2 + 16);

			scramble = ~scr[a];
			~granularSynth_1.set(\rate, 30.0.rand + 1, \fxout, output_1);
			~bus_pulseSpeed_1.set(8.rand * 2 + 2);
			~bus_dur_1.set(0.125*~tempo2MsRate * 16.rand + 0.125/8*~tempo2MsRate);

			~granularSynth_2.set(\rate, \rate, 40.0.rand + 0.125/8, \fxout, output_2, \envbuf, -1);
			~bus_pulseSpeed_2.set(16.rand * 2 + 2);
			~bus_dur_2.set(0.125*~tempo2MsRate * 16.rand + 0.125/8*~tempo2MsRate);



			if(seq[scramble] == 0.125, { });
			if(seq[scramble] == 0.25, { });
			if(seq[scramble] == 0.375, { });
			if(seq[scramble] == 0.5, { });
			if(seq[scramble] == 0.75, { });
			if(seq[scramble] == 1, {Synth(\envelope, [i_outbus: ~bus_dur_1, env: Env([0.25.rand, 0.25.rand], [0.5*~tempo2MsRate])]) });
			if(seq[scramble] == 2, { ~granularSynth_1.set(\pulse, ~bus_pulseSpeed_1.asMap);
				Synth(\envelope, [i_outbus: ~bus_pulseSpeed_1, env: Env([10.rand, 10.rand], [0.5*~tempo2MsRate], \exp)])
			});
			/*switch(seq[selNum],
				2, "")*/
			~synthA = Synth(\basic, [freq: (24.rand + 24).midicps, fxout: 18]);
			(seq[scramble]*2 * ~tempo2MsRate).wait;


		});
	});

	~gauss = Synth(\gauss,[\modFreq_1, 45.0.rand,   \modFreq_2, 3.0.rand, \atk, 8*~tempo2MsRate]);
	(10*~tempo2MsRate).wait;

	"sinGrain ".postln;
	~sineGranularSynth_1 = Synth(\grainSine, [pulse: ~bus_pulseSpeed_3.asMap, rate:~bus_rate_3.asMap,  dur:~bus_dur_3.asMap,  \envbuf, ~envWinBuffer, \fxout, 0]);
	//~gauss.free;

	64.do({
		~scr = [0, 1, 2, 3, 4, 5, 6, 7].scramble;
		8.do({ arg a;

			var selNum, scramble, output_1, output_2, output_3;
			output_1 = ((3.rand)*2 + 16);
			output_2 = ((3.rand)*2 + 16);
			output_3 = ((3.rand)*2 + 16);

			scramble = ~scr[a];
			~gauss.set(\modFreq_1, 45.0.rand,   \modFreq_2, 3.0.rand,  \atk, seq[scramble]/8 * ~tempo2MsRate);
			~granularSynth_1.set(\rate, 20.0.rand + 1, \fxout, output_1, \modAmount, 1.0.rand);
			~bus_pulseSpeed_1.set(12.rand * 2 + 4);
			~bus_dur_1.set(0.125/2*~tempo2MsRate * 8.rand + 0.125/4*~tempo2MsRate);

			~granularSynth_2.set(\rate, 20.0.rand + 0.125/2, \fxout, output_2, \modAmount, 1.0.rand);
			~bus_pulseSpeed_2.set((12.rand * 2 + 4) *~tempo2MsRate );
			~bus_dur_2.set(0.25*~tempo2MsRate * 8.rand + 0.125/4*~tempo2MsRate);

			~sineGranularSynth_1.set(\rate, 3000.rand + 110, \fxout, output_3, \modAmount, 1.0.rand, \atk, seq[scramble]/6 * ~tempo2MsRate, \amp, 0.4);
			~bus_pulseSpeed_3.set((24.rand * 2 + 0.125)*~tempo2MsRate);
			~bus_dur_3.set(0.1.rand);

			if(seq[scramble] == 0.125, { ~granularSynth_2.set(\envbuf, ~envWinBuffer)}, { ~granularSynth_2.set(\envbuf, -1)});
			if(seq[scramble] == 0.25, { ~granularSynth_2.set(\envbuf, ~envWinBuffer)}, { ~granularSynth_2.set(\envbuf, ~envWinBuffer)});
			if(seq[scramble] == 0.375, { });
			if(seq[scramble] == 0.5, { ~granularSynth_2.set(\envbuf, ~envWinBuffer)}, { ~granularSynth_2.set(\envbuf, -1)});
			if(seq[scramble] == 0.75, { });
			if(seq[scramble] == 1, {  ~granularSynth_1.set(\pModSel, 1, \modAdd, 300, \modMul, 300);~synthA = Synth(\basic, [freq: (24.rand + 24).midicps, fxout: 18]);},
			{~granularSynth_1.set(\pModSel, 0)});
			if(seq[scramble] == 2, { ~granularSynth_1.set(\pulse, ~bus_pulseSpeed_1.asMap);  Synth(\envelope, [i_outbus: ~bus_pulseSpeed_1, env: Env([20.rand, 20.rand], [0.5*~tempo2MsRate], \exp)]);~synthA = Synth(\basic, [freq: (24.rand + 24).midicps, fxout: 18]);});
			/*switch(seq[selNum],
				2, "")*/

			(seq[scramble]/6 * ~tempo2MsRate).wait;


		});
	});

	~sineGranularSynth_1.set(\gate, 0);
	~gauss.free;
	"pre ".postln;

	~granularSynth_2.set(\rate, 0.5, \fxout, 16, \pulse, 6*~tempo2MsRate, \dur,~bus_dur_2.asMap, \modAmount, 0.125, \envbuf, ~envWinBuffer);

	Synth(\envelope, [i_outbus: ~bus_dur_2, env: Env([0.01, 1], [16*~tempo2MsRate], \exp)]);

	(8*~tempo2MsRate).wait;
	8.do({ arg a;
		~synthA = Synth(\basic, [freq: (3.rand*12 + 12).midicps, fxout: 18]);
		~granularSynth_1.set(\pulse, (0.25+8.rand)*~tempo2MsRate , \fxout, 16);
		(4*~tempo2MsRate).wait;
    });

	"~karplus".postln;

	(16*~tempo2MsRate).wait;


	~karplus = Synth(\KSpluck, [\midiPitch, 24, \delayDecay, 0.5, \filterFreq, 200]);

	~granularSynth_2.set(\gate, 0);
	~granularSynth_1.set(\gate, 0);

	(32*~tempo2MsRate).wait;
	"FilterPart2_Start".postln;
	~granularSynth_1.free;
	~granularSynth_2.free;

	~granularSynth_1 = Synth(\grainBuf, [pulse: 10, dur:~bus_dur_1.asMap,  \sndbuf, ~grainBuffer_1, \envbuf, ~envWinBuffer]);


	~granularSynth_1.set(\rate, 1, \fxout, 16, \pulse, 10, \dur, 0.125);
	/*Synth(\envelope, [i_outbus: ~bus_pulseSpeed_1, env: Env([10, 5, 20, 10], [4*~tempo2MsRate, 4, 4*~tempo2MsRate], \exp)]);*/
	// ~rlpf = Synth.after(~granularSynth_1,"rlpf",[\ffreq, 20000, \rq, 0.9, \out,[0, 1]]);
	~filterEnv = [200, 5000].wrapExtend(4);
	Synth(\envelope, [i_outbus: ~bus_LFO, env: Env(~filterEnv, [4*~tempo2MsRate], \exp)]);
	~rlpf.set(\ffreq, ~bus_LFO.asMap);
	(16*~tempo2MsRate).wait;

	~filterEnv = [5000, 800].wrapExtend(4);
	Synth(\envelope, [i_outbus: ~bus_LFO, env: Env(~filterEnv, [4*~tempo2MsRate], \exp)]);

	//Synth(\envelope, [i_outbus: ~bus_kpFilterFreq, env: Env([200, 2000], [2], \exp)]);

	/////////////////////////////////
	"~bus_kpFilterFreq".postln;
seq_2 = [1, 2, 3, 4, 6];
	//seq.sum;
	~bus_pulseSpeed_1.set(20*~tempo2MsRate);
	~granularSynth_1.set(\pulse, ~bus_pulseSpeed_1.asMap, \dur,~bus_dur_1.asMap, \sndbuf, ~grainBuffer_1, \envbuf, ~envWinBuffer);
	~karplus.set(\filterFreq, ~bus_kpFilterFreq.asMap);

	2.do({
		~scr = [0, 1, 2, 3, 4].scramble.postln;
		5.do({ arg a;
			var selNum, scramble, output;
			output = 0;
			scramble = ~scr[a];
			Synth(\envelope, [i_outbus: ~bus_kpFilterFreq, env: Env([200, 5000], [seq_2[scramble]*~tempo2MsRate], \exp)]);

			if(seq[scramble] == 1, { ~karplus.set(\midiPitch, 36);}, {~karplus.set(\midiPitch, 24)}
			);
			if(seq[scramble] == 2, { });
			if(seq[scramble] == 3, {
				~karplus.set(\midiPitch, 36);}, {~karplus.set(\midiPitch, 24)});
			if(seq[scramble] == 4, { });
			if(seq[scramble] == 6, { });


			(seq_2[scramble] * ~tempo2MsRate).wait;


		});
	});

	~karplus.set(\midiPitch, 48);
	(4*~tempo2MsRate).wait;

	~filterEnv = [200, 5000].wrapExtend(4);
	Synth(\envelope, [i_outbus: ~bus_LFO, env: Env(~filterEnv, [4*~tempo2MsRate], \exp)]);
	~rlpf.set(\ffreq, ~bus_LFO.asMap);
	(16*~tempo2MsRate).wait;

	~filterEnv = [5000, 800].wrapExtend(4);
	Synth(\envelope, [i_outbus: ~bus_LFO, env: Env(~filterEnv, [4*~tempo2MsRate], \exp)]);
	~karplus.set(\midiPitch, 24);

	6.do({
		b.free;
		b = {Mix.arFill(24,{SinOsc.ar([440,441]*(4.0/3**rrand(1,6))*(0.5** rrand(1,8)),0,1.0/18)})}.play;
		~scr = [0, 1, 2, 3, 4].scramble.postln;
		5.do({ arg a;
			var selNum, scramble, output;
			output = 0;
			scramble = ~scr[a];
			seq_2[scramble].postln;
			Synth(\envelope, [i_outbus: ~bus_kpFilterFreq, env: Env([200, 5000], [seq_2[scramble]*~tempo2MsRate], \exp)]);
			Synth(\envelope, [i_outbus: ~bus_LFO, env: Env([5000.rand+ 200, 5000.rand + 200], [seq_2[scramble]], \exp)]);
			Synth(\envelope, [i_outbus: ~bus_dur_1, env: Env([2.rand, 2.rand], [seq_2[scramble]], \exp)]);

			if(seq[scramble] == 1, { ~karplus.set(\midiPitch, 36);}, {~karplus.set(\midiPitch, 24)});
			if(seq[scramble] == 2, {
				Synth(\fm, [\freq, (6.rand* 7+ 12).midicps, \dur, 8*~tempo2MsRate, \amp, 0.2*1.5, \fxout, 16])
			});
			if(seq[scramble] == 3, {~karplus.set(\midiPitch, 36);}, {~karplus.set(\midiPitch, 24)});
			if(seq[scramble] == 4, {
				Synth(\fm, [\freq, (6.rand* 7+ 12).midicps, \dur, 8*~tempo2MsRate, \amp, 0.2*1.5,  \fxout, 16])
			});
			if(seq[scramble] == 6, {
				Synth(\fm, [\freq, (4.rand* 7+ 12).midicps, \dur, 8*~tempo2MsRate, \amp, 0.2*1.5, \fxout, 18])
			});


			~synthA = Synth(\basic, [freq: (3.rand*12 + 12).midicps, fxout: 18]);
			(seq_2[scramble] * ~tempo2MsRate).wait;


		});
	});

	(4 * ~tempo2MsRate).wait;

	8.do({
		b.free;
		b = {Mix.arFill(24,{SinOsc.ar([440,441]*(4.0/3**rrand(1,6))*(0.5** rrand(1,8)), 0 ,1.0/15)})}.play;
		~scr = [0, 1, 2, 3, 4].scramble;
		5.do({ arg a;
			var selNum, scramble, output;
			output = 0;
			scramble = ~scr[a];
			seq_2[scramble].postln;
			Synth(\envelope, [i_outbus: ~bus_kpFilterFreq, env: Env([200, 5000], [(seq_2[scramble]/2*~tempo2MsRate)], \exp)]);
			Synth(\envelope, [i_outbus: ~bus_LFO, env: Env([5000.rand+ 200, 5000.rand + 200], [(seq_2[scramble]/2*~tempo2MsRate)], \exp)]);
			Synth(\envelope, [i_outbus: ~bus_dur_1, env: Env([2.rand, 2.rand], [seq_2[scramble]], \exp)]);

			if(seq[scramble] == 1, { ~karplus.set(\midiPitch, 36);}, {~karplus.set(\midiPitch, 24)});
			if(seq[scramble] == 2, { Synth(\fm, [\freq, (6.rand* 7+ 12).midicps, \dur, 8*~tempo2MsRate, \amp, 0.3*1.5, \fxout, 16])});
			if(seq[scramble] == 3, {~karplus.set(\midiPitch, 36);}, {~karplus.set(\midiPitch, 24)});
			if(seq[scramble] == 4, {Synth(\fm, [\freq, (6.rand* 7+ 12).midicps, \dur, 8*~tempo2MsRate, \amp, 0.3*1.5,  \fxout, 16])});
			if(seq[scramble] == 6, {Synth(\fm, [\freq, (4.rand* 7+ 12).midicps, \dur, 8*~tempo2MsRate, \amp, 0.3*1.5, \fxout, 18])});


			~synthA = Synth(\basic, [freq: (3.rand*12 + 12).midicps, fxout: 18]);
			(seq_2[scramble]/2 * ~tempo2MsRate).wait;


		});
	});

	"~ringKick".postln;


	12.do({
		b.free;
		b = {Mix.arFill(24,{SinOsc.ar([440,441]*(4.0/3**rrand(1,6))*(0.5** rrand(1,8)), 0 ,1.0/15)})}.play;
		~scr = [0, 1, 2, 3, 4].scramble.postln;
		Synth(\ring, [pulse: ~bus_Trig.asMap, \dur, 12*~tempo2MsRate, fxout:0]);
		Synth(\envelope, [i_outbus: ~bus_Trig, env: Env([25.rand, 25.rand], [12*~tempo2MsRate ], \exp)]);

		5.do({ arg a;
			var selNum, scramble, output;
			output = 0;
			scramble = ~scr[a];
			seq_2[scramble].postln;
			Synth(\envelope, [i_outbus: ~bus_kpFilterFreq, env: Env([200, 5000], [(seq_2[scramble]/2*~tempo2MsRate)], \exp)]);
			Synth(\envelope, [i_outbus: ~bus_LFO, env: Env([5000.rand+ 200, 5000.rand + 200], [(seq_2[scramble]/2*~tempo2MsRate)], \exp)]);
			Synth(\envelope, [i_outbus: ~bus_dur_1, env: Env([2.rand, 2.rand], [seq_2[scramble]], \exp)]);

			//Synth(\envelope, [i_outbus: ~bus_Trig, env: Env([10.rand, 10.rand], [(seq_2[scramble]/2*~tempo2MsRate)], \exp)]);




			if(seq[scramble] == 1, { ~karplus.set(\midiPitch, 36);}, {~karplus.set(\midiPitch, 24)});
			if(seq[scramble] == 2, { Synth(\fm, [\freq, (6.rand* 7+ 12).midicps, \dur, 8*~tempo2MsRate, \amp, 0.3*1.5, \fxout, 16])});
			if(seq[scramble] == 3, {~karplus.set(\midiPitch, 36); Synth(\fm, [\freq, (6.rand* 7+ 12).midicps, \dur, 8*~tempo2MsRate, \amp, 0.3*1.5, \fxout, 16]);}, {~karplus.set(\midiPitch, 24)});
			if(seq[scramble] == 4, {Synth(\fm, [\freq, (6.rand* 7+ 12).midicps, \dur, 8*~tempo2MsRate, \amp, 0.3*1.5,  \fxout, 16])});
			if(seq[scramble] == 6, {Synth(\fm, [\freq, (4.rand* 7+ 12).midicps, \dur, 8*~tempo2MsRate, \amp, 0.3*1.5, \fxout, 18])});


			~synthA = Synth(\basic, [freq: (3.rand*12 + 12).midicps, fxout: 18]);
			(seq_2[scramble]/2 * ~tempo2MsRate).wait;


		});
	});

	b.free;
	b = {Mix.arFill(24,{SinOsc.ar([440,441]*(4.0/3**rrand(1,6))*(0.5** rrand(1,8)),0,1.0/15)})}.play;
	(16*~tempo2MsRate).wait;
	b.free;
	~synthA = Synth(\basic, [freq: 24.midicps, fxout: 18]);
	~karplus.free;

	4.do({ arg a;
		var pitch;
		pitch = 6.rand* 7+ 12;
		Synth(\fm, [\freq, pitch.midicps, \dur, 16*~tempo2MsRate, \amp, 0.125, \fxout, 18]);
		(4*~tempo2MsRate).wait;
    });
	4.do({ arg a;
		var pitch, pitch_2, pitch_3;
		pitch = 4.rand* 7+ 12;
		Synth(\fm, [\freq, pitch.midicps, \dur, 16*~tempo2MsRate, \fxout, 16, \amp, 0.2]);
		pitch_2 = 4.rand* 7+ 24;
		Synth(\fm, [\freq, pitch_2.midicps, \dur, 16*~tempo2MsRate, \fxout, 16, \amp, 0.2]);
		pitch_3 = 4.rand* 7+ 48;
		Synth(\fm, [\freq, pitch_3.midicps, \dur, 16*~tempo2MsRate, \fxout, 16, \amp, 0.2]);
		(4*~tempo2MsRate).wait;
    });
	2.do({ arg a;
		var pitch, pitch_2;
		pitch = 4.rand* 7+ 12;
		Synth(\fm, [\freq, pitch.midicps, \dur, 16*~tempo2MsRate, \fxout, 16, \amp, 0.2]);
		pitch_2 = 4.rand* 7+ 24;
		Synth(\fm, [\freq, pitch_2.midicps, \dur, 16*~tempo2MsRate, \fxout, 16, \amp, 0.2]);
		(4*~tempo2MsRate).wait;
    });


	"The End".postln;
	~granularSynth_2.set(\gate, 0);
	~granularSynth_1.set(\gate, 0);
	~karplus.free;
	~rlpf.free;

}.play;


)

s.meter;


seq[scramble]