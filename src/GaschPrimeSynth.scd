/*
Título: Gasch Prime Synth
Desarrollador: Pablo Gallegos Noreña, a.k.a. Gasch

Descripción:
Desarrollé un sintetizador basado en números primos en SuperCollider que integra:
●	Ondas primas (espectros de armónicos primos)
●	Notas con frecuencia prima
●	Secuencias rítmicas primas con visualización en tiempo real mediante espirales de Ulam
●	Cambios de modo y base numérica
●	Controles de timbre, secuencia y ecualización
●	Compatibilidad MIDI
Todo esto está implementado en código sin necesidad de bibliotecas externas ni samples.

Ejecución:
Paso 1: Conectar dispositivo MIDI.
Paso 2: Ejecutar en orden ascendente los 5) bloques de código (BUS, PRIME, ULAM, MIDI, GUI).
Paso 3: Listo!
*/
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////





//-----------------------------------------------------------------------------------------------------------------------
// 1) BUS, FX, OUT, REC
//-----------------------------------------------------------------------------------------------------------------------
(
// BUS
~volBus = Bus.control(s, 1);
~volBus.set(0.1);
~mainBus = Bus.audio(s, 2);
~finalBus = Bus.audio(s, 2);

// FX: REVERB & EQ
SynthDef(\primeEQ, { |inbus, outbus=0,
	revMix=0.13,
	lowFreq=200,    lowGain=0,
	midFreq=1000,   midGain=0,
	mhFreq=4000,    mhGain=0,
	highFreq=10000, highGain=0
|
	var dry, fx, sig, pos;
	dry = In.ar(inbus, 2);
	fx = FreeVerb2.ar(
		dry[0], dry[1],
		1.0,    // internal mix
		0.9,    // room size
		1.0     // damping
	);
	// Crossfade DRY/FX:
	pos = (revMix * 2) - 1;
	sig = XFade2.ar(dry, fx, pos);
	// EQ
	sig = BLowShelf.ar(sig, lowFreq, 1, lowGain);
	sig = BPeakEQ.ar(sig, midFreq, 1, midGain);
	sig = BPeakEQ.ar(sig, mhFreq, 1, mhGain);
	sig = BHiShelf.ar(sig, highFreq, 1, highGain);
	Out.ar(outbus, sig);
}).add;

// Synth OUT (0)
SynthDef(\primeOutput, { |inbus|
	var sig = In.ar(inbus, 2);
	Out.ar(0, sig);
}).add;

// REC
SynthDef(\primeRecorder, { |bufnum, inbus=0|
	var in = In.ar(inbus, 2);
	DiskOut.ar(bufnum, in);
}).add;
~isRecording = false;
~recFilePath = nil;
~recBuf      = nil;
~recSynth    = nil;

// FX & OUT INIT
if(~eqSynth.notNil) { ~eqSynth.free };
~eqSynth = Synth(\primeEQ, [
	\inbus, ~mainBus,
	\outbus, ~finalBus.index,
	\revMix, 0.2,    // punto de partida
	\lowFreq, 200,
	\lowGain, 0,
	\midFreq, 1000,
	\midGain, 0,
	\mhFreq, 4000,
	\mhGain, 0,
	\highFreq, 10000,
	\highGain, 0
], addAction:\addToHead);

if(~outputSynth.notNil) { ~outputSynth.free };
~outputSynth = Synth(\primeOutput, [\inbus, ~finalBus.index], addAction:\addToTail);
)





//-----------------------------------------------------------------------------------------------------------------------
// 2) PRIME NUMBERS, PRIME HARMONICS, JITTER, MODES, INIT VALUES
//-----------------------------------------------------------------------------------------------------------------------
(
// COMPLEX PRIMES (4k – 1)
~lim = 10000;
~primoscomplejos = Array.new(10000);
~k = 1;
~n = 1;
while({ ~n <= ~lim }, {
	~n = 4 * ~k - 1;
	~raiz = ~n.sqrt.roundUp;
	~primo = true;

	for(2, ~raiz, { |i|
		if(~n % i == 0) { ~primo = false };
	});

	if(~primo == true) { ~primoscomplejos.add(~n) };
	~k = ~k + 1;
});
~primoscomplejos = ~primoscomplejos.select(_.notNil); // nil cleaning
~complexPrimeSet = ~primoscomplejos.as(Set); // Conjunto para la escalera rítmica (para reemplazar .isPrime)

// SPECTRAL PRIME HARMONICS
~maxHarm = 50;  // Max harmonics
~nHarm   = 30;  // Active harmonics
// PRIME HARMONIC LISTS
~updateHarmonics = {
	// Natural Primes
	~primeHarm_normal = [1] ++ (0..(~maxHarm-1)).collect(_.nthPrime);
	// Complex Primes
	~primeHarm_complex = [1] ++ ~primoscomplejos.copyRange(0, ~maxHarm-1);
};
~updateHarmonics.(); // Init lists

// SYNTHDEFS
~buildSynthDefs = {
	// Natural Primes Percusive Synth --------------------
	SynthDef(\primeSynthNormalPerc, { |freq=100, amp=1, relTime=0.3, volbus, outbus|
		var sig, env, click, envClick, master, harmonics, amps;

		master = In.kr(volbus);
		harmonics = ~primeHarm_normal;
		amps      = ~amps_normal;
		sig = Klang.ar(`[harmonics, amps], freq);
		click = SinOsc.ar(freq * 2, 0, 0.25);
		envClick = EnvGen.kr(Env.perc(0.005, 0.02));
		click = click * envClick;
		env = EnvGen.kr(
			Env.perc(0.02, relTime),
			1,
			doneAction:2
		);
		sig = (sig + click) * env * amp * master * 0.1;
		Out.ar(outbus, sig ! 2);
	}).add;
	// Natural Primes Sustain Synth --------------------
	SynthDef(\primeSynthNormalSustain, { |freq=100, amp=1, gate=1, relTime=0.3, volbus, outbus|
		var sig, env, click, envClick, master, harmonics, amps;

		master = In.kr(volbus);
		harmonics = ~primeHarm_normal;
		amps      = ~amps_normal;
		sig = Klang.ar(`[harmonics, amps], freq);
		click = SinOsc.ar(freq * 2, 0, 0.25);
		envClick = EnvGen.kr(Env.perc(0.005, 0.02));
		click = click * envClick;
		env = EnvGen.kr(
			Env.asr(0.02, 1.0, relTime),
			gate,
			doneAction:2
		);
		sig = (sig + click) * env * amp * master * 0.1;
		Out.ar(outbus, sig ! 2);
	}).add;
	// Complex Primes Percusive Synth --------------------
	SynthDef(\primeSynthComplexPerc, { |freq=100, amp=1, relTime=0.3, volbus, outbus|
		var sig, env, click, envClick, master, harmonics, amps;

		master = In.kr(volbus);
		harmonics = ~primeHarm_complex;
		amps      = ~amps_complex;
		sig = Klang.ar(`[harmonics, amps], freq);
		click = SinOsc.ar(freq * 2, 0, 0.25);
		envClick = EnvGen.kr(Env.perc(0.005, 0.02));
		click = click * envClick;
		env = EnvGen.kr(
			Env.perc(0.02, relTime),
			1,
			doneAction:2
		);
		sig = (sig + click) * env * amp * master * 0.1;
		Out.ar(outbus, sig ! 2);
	}).add;
	// Complex Primes Sustain Synth --------------------
	SynthDef(\primeSynthComplexSustain, { |freq=100, amp=1, gate=1, relTime=0.3, volbus, outbus|
		var sig, env, click, envClick, master, harmonics, amps;

		master = In.kr(volbus);
		harmonics = ~primeHarm_complex;
		amps      = ~amps_complex;
		sig = Klang.ar(`[harmonics, amps], freq);
		click = SinOsc.ar(freq * 2, 0, 0.25);
		envClick = EnvGen.kr(Env.perc(0.005, 0.02));
		click = click * envClick;
		env = EnvGen.kr(
			Env.asr(0.02, 1.0, relTime),
			gate,
			doneAction:2
		);
		sig = (sig + click) * env * amp * master * 0.1;
		Out.ar(outbus, sig ! 2);
	}).add;
};
~buildSynthDefs.(); // Init synthdefs

// JITTER & AMPS UPDATE
~jitterAmt = 0.0;
~updateAmps = {
	var len    = ~maxHarm + 1;
	var active = ~nHarm.clip(1, ~maxHarm); // Active Harmonics
	~amps_normal  = Array.fill(len, 0.0);
	~amps_complex = Array.fill(len, 0.0);
	~amps_normal[0]  = 1.0;
	~amps_complex[0] = 1.0;

	// ACTIVE PRIME HARMONICS
	(1..active).do { |i|
		var pn = ~primeHarm_normal[i];
		var pc = ~primeHarm_complex[i];
		var jitterN = 1 + rrand(~jitterAmt.neg, ~jitterAmt);
		var jitterC = 1 + rrand(~jitterAmt.neg, ~jitterAmt);
		~amps_normal[i]  = (1 / pn) * jitterN;
		~amps_complex[i] = (1 / pc) * jitterC;
	};
	~amps_normal  = ~amps_normal.normalizeSum;
	~amps_complex = ~amps_complex.normalizeSum;
	~buildSynthDefs.(); // Init synthdefs
};
~updateAmps.(); // Init amps

// MODES
~useComplex  = false; // false = Natural Primes, true = Complex Primes
~useRoutine  = true;  // true = Prime Sequence, false = Single Note

// FINDING THE NEAREST PRIME FUNCTION
~nearestPrimeFreq = { |freq|
	var f = freq.round.asInteger;

	if(~useComplex.not) {
		// Natural Mode
		var up  = f.nextPrime;
		var dn  = f.prevPrime;
		if(dn.isNil) {
			up
		} {
			if( (up - f).abs < (f - dn).abs ) { up } { dn }
		};
	} {
		// Complex Mode
		var closest = ~primoscomplejos[0];
		var minDiff = (closest - f).abs;
		~primoscomplejos.do { |p|
			var d = (p - f).abs;
			if(d < minDiff) {
				minDiff = d;
				closest = p;
			};
		};
		closest;
	};
};

// INIT VALUES
~lista = (0, 1..65521);
~lista = ~lista.mirror;
~cantHarm = 7;   // Prime Sequence Harmonics
~velConst = 7;  // Prime Sequence Velocity
~durRut   = 65521; // Prime Sequence Duration
~relTime = 0.9;  // Synth Release Time
)





//-----------------------------------------------------------------------------------------------------------------------
// 3) ULAM SPIRAL
//-----------------------------------------------------------------------------------------------------------------------
(
~visSide    = 45;                         // Cells per side
~visN       = ~visSide * ~visSide;       // Total cells
~visColorIx = Array.fill(~visN, -1);     // -1 = empty cell, 0..9 = color
~visIndex   = 0;
~visCoords  = Array.newClear(~visN);
~visView    = nil;
~primeColors = [
	Color.new255(255,   0,   0),   // red
	Color.new255(255, 128,   0),   // orange
	Color.new255(255, 255,   0),   // yellow
	Color.new255(190, 255,   0),   // yellowgreen
	Color.new255(  0, 200,   0),   // green
	Color.new255(  0, 180, 160),   // aqua
	Color.new255( 90, 180, 255),   // light blue
	Color.new255(  0,   0, 255),   // blue
	Color.new255(160,   0, 200),   // puple
	Color.new255(255,   0, 150)    // pink
];
~nextColorIndex = 0; // Next sequence global index

// BUILD SPIRAL
~buildSpiralCoords = {
	var center = ((~visSide - 1) / 2).floor;
	var x = center;
	var y = center;
	var dirs = [
		Point(1, 0),    // right
		Point(0, -1),   // up
		Point(-1, 0),   // left
		Point(0, 1)     // down
	];
	var dirIndex = 0;
	var stepLen = 1;
	var idx = 0;

	~visCoords[0] = Point(x, y);
	while({ idx < (~visN - 1) }, {
		2.do {
			stepLen.do {
				if(idx >= (~visN - 1)) { ^nil };
				x = x + dirs[dirIndex].x;
				y = y + dirs[dirIndex].y;
				idx = idx + 1;
				~visCoords[idx] = Point(x, y);
			};
			dirIndex = (dirIndex + 1) % 4;
		};
		stepLen = stepLen + 1;
	});
};
~buildSpiralCoords.(); // Init spiral
)





//-----------------------------------------------------------------------------------------------------------------------
// 4) MIDI
//-----------------------------------------------------------------------------------------------------------------------
(
MIDIClient.init;
MIDIIn.connectAll;

// Prime Sequence Mode
~voicesRut      = IdentityDictionary.new;  // note -> Routine
~voicesRutColor = IdentityDictionary.new;  // note -> Color Index

// Single Note Mode
~voicesSust      = IdentityDictionary.new; // note -> Synth (Sustain)
~voicesSustColor = IdentityDictionary.new; // note -> Color Index
~voicesSustCell  = IdentityDictionary.new; // note -> Cell Index

// For gain control
~activeNotes = 0;

MIDIdef.noteOn(\primeOn, { |vel, note|
	var freqPrimo, baseAmp, ampScale, r, synth, freqNorm;
	var mults, allMults, num;
	var seq;
	var synthNamePerc, synthNameSust;
	var colorIdx;
	var cellIndex;

	// Asign Natural/Complex Prime Frequency to MIDI Note Frequency
	freqPrimo = ~nearestPrimeFreq.(note.midicps);
	~activeNotes = (~activeNotes ? 0) + 1; // Update active note counter

	// Normalize active notes amps by frequency
	freqNorm = (freqPrimo / 440).max(0.25);
	ampScale = ( (~activeNotes * freqNorm).sqrt ).reciprocal;
	baseAmp   = vel.linlin(1, 127, 0.05, 1.0) * ampScale;

	// Init synths
	synthNamePerc = if(~useComplex.not, { \primeSynthNormalPerc }, { \primeSynthComplexPerc });
	synthNameSust = if(~useComplex.not, { \primeSynthNormalSustain }, { \primeSynthComplexSustain });

	if(~useRoutine.not) {
		// ---------------------- SINGLE NOTE MODE ----------------------
		synth = Synth(synthNameSust, [
			\freq,    freqPrimo,
			\amp,     baseAmp,
			\volbus,  ~volBus.index,
			\outbus,  ~mainBus.index,
			\relTime, ~relTime,
			\gate,    1
		]);
		~voicesSust[note] = synth;

		// Coloring
		colorIdx = ~nextColorIndex;
		~nextColorIndex = (~nextColorIndex + 1) % ~primeColors.size;
		~voicesSustColor[note] = colorIdx;
		// Finding free cells
		cellIndex = (0..(~visN-1)).detect { |i|
			~voicesSustCell.values.includes(i).not
		};
		if(cellIndex.isNil) { cellIndex = 0 };
		~voicesSustCell[note] = cellIndex;
		~visColorIx[cellIndex] = colorIdx;
		{
			if(~visView.notNil) { ~visView.refresh };
		}.defer;
	} {
		// ---------------------- PRIME SEQUENCE MODE ----------------------
		// Refresh canvas
		~visColorIx = Array.fill(~visN, -1);
		~visIndex   = 0;
		{
			if(~visView.notNil) { ~visView.refresh };
		}.defer;

		allMults = if(~useComplex.not) {
			~primeHarm_normal;
		} {
			~primeHarm_complex;
		};
		num = min(~cantHarm, allMults.size);
		mults = allMults.copyRange(0, num-1);

		// Prime Sequence Harmonic Rotation
		seq = Pseq(freqPrimo * mults, inf).asStream;
		// Coloring
		colorIdx = ~nextColorIndex;
		~nextColorIndex = (~nextColorIndex + 1) % ~primeColors.size;

		r = Routine {
			var newIndex, baseWait, waitTime;

			~durRut.do { |i|
				var val = ~lista[i];
				var isPrimeLike = false;

				if(~useComplex.not) {
					if(val.isPrime) {
						isPrimeLike = true;
						Synth(synthNamePerc, [
							\freq,    seq.next,
							\amp,     baseAmp,
							\volbus,  ~volBus.index,
							\outbus,  ~mainBus.index,
							\relTime, ~relTime
						]);
					};
				} {
					if(~complexPrimeSet.includes(val)) {
						isPrimeLike = true;
						Synth(synthNamePerc, [
							\freq,    seq.next,
							\amp,     baseAmp,
							\volbus,  ~volBus.index,
							\outbus,  ~mainBus.index,
							\relTime, ~relTime
						]);
					};
				};

				newIndex = (~visIndex + 1) % ~visN;
				if(newIndex == 0) {
					~visColorIx = Array.fill(~visN, -1);
					{
						if(~visView.notNil) { ~visView.refresh };
					}.defer;
				};

				~visIndex = newIndex;
				if(isPrimeLike) {
					~visColorIx[~visIndex] = colorIdx;
					{
						if(~visView.notNil) { ~visView.refresh };
					}.defer;
				};

				// Base wait time determined my frequency and velocity constant
				baseWait = freqPrimo.reciprocal * ~velConst;
				// Failsafe
				waitTime = max(baseWait, 0.005);
				waitTime.wait;
			};
		}.play;

		~voicesRut[note]      = r;
		~voicesRutColor[note] = colorIdx;
	};
});

MIDIdef.noteOff(\primeOff, { |vel, note|
	var r = ~voicesRut[note];
	var s = ~voicesSust[note];
	var cell;

	~activeNotes = max(0, ((~activeNotes ? 1) - 1)); // Update active note counter
	// Stop routine
	if (r.notNil) {
		r.stop;
		~voicesRut.removeAt(note);
		~voicesRutColor.removeAt(note);
	};
	// Stop note and wipe cell
	if (s.notNil) {
		s.set(\gate, 0);
		~voicesSust.removeAt(note);
		cell = ~voicesSustCell[note];
		if(cell.notNil) {
			~visColorIx[cell] = -1;
			~voicesSustCell.removeAt(note);
			~voicesSustColor.removeAt(note);
			{
				if(~visView.notNil) { ~visView.refresh };
			}.defer;
		};
	};
});
)





//-----------------------------------------------------------------------------------------------------------------------
// 5) GUI
//-----------------------------------------------------------------------------------------------------------------------
(
var w,
	leftPanel, rightPanel, topRow,
	sliderVol, txtVol,
	sliderHarmSeq, txtHarmSeq,
	sliderNHarm, txtNHarm,
	sliderConst, txtConst,
	sliderDur, txtDur,
	btnModo, primeVals, primeListBig,
	btnRoutine,
	txtJitter, sliderJitter, jitterMax,
	txtRel, sliderRel, relMin, relMax,
	// Reverb
	txtRevMix, sliderRevMix,
	// EQ
	sliderLow, sliderMid, sliderMidHigh, sliderHigh,
	txtLowVal, txtMidVal, txtMidHighVal, txtHighVal,
	lblLow, lblMid, lblMidHigh, lblHigh,
	// Titles
	txtTimbreTitle, txtSeqTitle, txtEQTitle,
	// Ulam Spiral
	txtVis, visView,
	// EQ Panel
	eqPanel,
	// EQ Layout
	sliderWidth, sliderHeight, totalWidth, spacing,
	x1, x2, x3, x4, topY, nameY, valueY,
	// REC
	recRow, btnRec;

// Slider lists
primeVals    = [1, 2, 3, 5, 7, 11, 13, 17, 19];
primeListBig = [1] ++ (2..65521).select(_.isPrime);
jitterMax    = 1.0;
// Release ranges
relMin = 0.01;
relMax = 1.0;
// EQ Layout
sliderWidth  = 50;
sliderHeight = 80;
totalWidth   = 440;
spacing      = (totalWidth - (4 * sliderWidth)) / 5;
x1 = spacing;
x2 = x1 + sliderWidth + spacing;
x3 = x2 + sliderWidth + spacing;
x4 = x3 + sliderWidth + spacing;
nameY  = 0;
topY   = nameY + 18 + 5;
valueY = topY + sliderHeight + 8;

// Main Window
w = Window("Gasch Prime Synth", Rect(200, 200, 1180, 780));
w.view.background = Color.grey(0.9);

// Left Panel for Faders
leftPanel = CompositeView(w, Rect(10, 10, 460, 740));
leftPanel.background = Color.clear;
leftPanel.decorator = FlowLayout(leftPanel.bounds);

// -------- MODE BUTTONS --------
topRow = CompositeView(leftPanel, Rect(0, 0, 440, 90));
topRow.background = Color.clear;

// Natural/Complex Primes Button
btnModo = Button(topRow, Rect(0, 10, 210, 70));
btnModo.states = [
	["Natural Primes", Color.white, Color.new255(0, 110, 255)],
	["Complex Primes", Color.black, Color.new255(255, 170, 0)]
];
btnModo.value = if(~useComplex, 1, 0);
btnModo.action = { |b| ~useComplex = (b.value == 1) };

// Mode Button
btnRoutine = Button(topRow, Rect(220, 10, 210, 70));
btnRoutine.states = [
	["Prime Sequence Mode", Color.white, Color.new255(0, 170, 0)],
	["Single Note Mode", Color.white, Color.new255(200, 0, 0)]
];
btnRoutine.value = if(~useRoutine, 0, 1);
btnRoutine.action = { |b|
	~useRoutine = (b.value == 0);
	~visColorIx = Array.fill(~visN, -1); // Clean visuals
	~visIndex   = 0;
	{ if(~visView.notNil) { ~visView.refresh } }.defer;

	if(~useRoutine.not) {
		~voicesRut.valuesDo({ |r| r.stop });
		~voicesRut.clear;
		~voicesRutColor.clear;
	};
};

// -------- VOLUME FADER --------
txtVol = StaticText(leftPanel, Rect(0,0,440,20));
txtVol.string = "Volume: " ++ ~volBus.getSynchronous;

sliderVol = Slider(leftPanel, Rect(0,0,440,20));
sliderVol.value = 0.1;
sliderVol.action = { |sl|
	~volBus.set(sl.value);
	txtVol.string = "Volume: " ++ sl.value.round(0.001);
};

// ---------------- TIMBRE TITLE ----------------
txtTimbreTitle = StaticText(leftPanel, Rect(0,0,440,24));
txtTimbreTitle.string = "TIMBRE";
txtTimbreTitle.font = Font("Monaco", 15);
txtTimbreTitle.align = \left;

// -------- SPECTRAL HARMONICS FADER --------
txtNHarm = StaticText(leftPanel, Rect(0,0,440,20));
txtNHarm.string = "Active Spectral Prime Harmonics: " ++ ~nHarm;

sliderNHarm = Slider(leftPanel, Rect(0,0,440,20));
sliderNHarm.value = ((~nHarm - 3) / (50 - 3));
sliderNHarm.action = { |sl|
	~nHarm = (sl.value * (50 - 3)).round + 3;
	~updateAmps.();
	txtNHarm.string = "Active Spectral Prime Harmonics: " ++ ~nHarm;
};

// -------- JITTER FADER --------
txtJitter = StaticText(leftPanel, Rect(0,0,440,20));
txtJitter.string = "Harmonics' Amplitudes Jitter: " ++ ~jitterAmt.round(0.001);

sliderJitter = Slider(leftPanel, Rect(0,0,440,20));
sliderJitter.value = (~jitterAmt / jitterMax).clip(0,1);
sliderJitter.action = { |sl|
	~jitterAmt = sl.value * jitterMax;
	txtJitter.string = "Harmonics' Amplitudes Jitter: " ++ ~jitterAmt.round(0.001);
	~updateAmps.();
};

// -------- RELEASE FADER --------
txtRel = StaticText(leftPanel, Rect(0,0,440,20));
txtRel.string = "Release time (s): " ++ ~relTime.round(0.01);

sliderRel = Slider(leftPanel, Rect(0,0,440,20));
sliderRel.value = ((~relTime - relMin) / (relMax - relMin)).clip(0,1);
sliderRel.action = { |sl|
	~relTime = relMin + (relMax - relMin) * sl.value;
	txtRel.string = "Release time (s): " ++ ~relTime.round(0.01);
};

// -------- REVERB FADER --------
txtRevMix = StaticText(leftPanel, Rect(0,0,440,20));
txtRevMix.string = "Reverb (DRY/WET): 0.13";

sliderRevMix = Slider(leftPanel, Rect(0,0,440,20));
sliderRevMix.value = 0.13;
sliderRevMix.action = { |sl|
	var mix = sl.value.clip(0,1);
	txtRevMix.string = "Reverb (DRY/WET): " ++ mix.round(0.01);
	if(~eqSynth.notNil) { ~eqSynth.set(\revMix, mix); };
};

// ---------------- PRIME SEQUENCE TITLE ----------------
txtSeqTitle = StaticText(leftPanel, Rect(0,0,440,24));
txtSeqTitle.string = "PRIME SEQUENCE";
txtSeqTitle.font = Font("Monaco", 15);
txtSeqTitle.align = \left;

// -------- SEQUENCE VELOCITY FADER --------
txtConst = StaticText(leftPanel, Rect(0,0,440,20));
txtConst.string = "Sequence Velocity: " ++ ~velConst;

sliderConst = Slider(leftPanel, Rect(0,0,440,20));
sliderConst.value = (~velConst - 1) / 19;

sliderConst.action = { |sl|
	~velConst = (sl.value * 19).round + 1;
	txtConst.string = "Sequence Velocity: " ++ ~velConst;
};

// -------- PRIME HARMONICS PER SEQUENCE FADER --------
txtHarmSeq = StaticText(leftPanel, Rect(0,0,440,20));
txtHarmSeq.string = "Prime Harmonics Per Sequence: " ++ ~cantHarm;

sliderHarmSeq = Slider(leftPanel, Rect(0,0,440,20));
sliderHarmSeq.value = primeVals.indexOf(~cantHarm) / (primeVals.size - 1);
sliderHarmSeq.action = { |sl|
	var idx = (sl.value * (primeVals.size - 1)).round;
	~cantHarm = primeVals[idx];
	txtHarmSeq.string = "Prime Harmonics Per Sequence: " ++ ~cantHarm;
};

// -------- SEQUENCE DURATION FADER --------
txtDur = StaticText(leftPanel, Rect(0,0,440,20));
txtDur.string = "Sequence Duration: " ++ ~durRut;

sliderDur = Slider(leftPanel, Rect(0,0,440,20));
sliderDur.value = primeListBig.indexOf(~durRut) / (primeListBig.size - 1);
sliderDur.action = { |sl|
	var idx = (sl.value * (primeVals.size - 1)).round;
	~durRut = primeListBig[idx];
	txtDur.string = "Sequence Duration: " ++ ~durRut;
};

// ---------------- EQUALIZER TITLE ----------------
txtEQTitle = StaticText(leftPanel, Rect(0,0,440,24));
txtEQTitle.string = "EQUALIZER";
txtSeqTitle.font = Font("Monaco", 15);
txtEQTitle.align = \left;

eqPanel = CompositeView(leftPanel, Rect(0,0,440,230));
eqPanel.background = Color.clear;

// -------- 200 HZ FADER --------
lblLow = StaticText(eqPanel, Rect(x1 - 25, nameY, sliderWidth + 50, 18));
lblLow.align = \center;
lblLow.string = "200 Hz";

sliderLow = Slider(eqPanel, Rect(x1, topY, sliderWidth, sliderHeight));
sliderLow.orientation = \vertical;
sliderLow.value = 0.5;

txtLowVal = StaticText(eqPanel, Rect(x1 - 25, valueY, sliderWidth + 50, 18));
txtLowVal.align = \center;
txtLowVal.string = "0.0 dB";

sliderLow.action = { |sl|
	var db = (sl.value * 2 - 1) * 18;
	txtLowVal.string = db.round(0.1).asString ++ " dB";
	if(~eqSynth.notNil) { ~eqSynth.set(\lowGain, db); };
};

// -------- 1000 HZ FADER --------
lblMid = StaticText(eqPanel, Rect(x2 - 25, nameY, sliderWidth + 50, 18));
lblMid.align = \center;
lblMid.string = "1000 Hz";

sliderMid = Slider(eqPanel, Rect(x2, topY, sliderWidth, sliderHeight));
sliderMid.orientation = \vertical;
sliderMid.value = 0.5;

txtMidVal = StaticText(eqPanel, Rect(x2 - 25, valueY, sliderWidth + 50, 18));
txtMidVal.align = \center;
txtMidVal.string = "0.0 dB";

sliderMid.action = { |sl|
	var db = (sl.value * 2 - 1) * 18;
	txtMidVal.string = db.round(0.1).asString ++ " dB";
	if(~eqSynth.notNil) { ~eqSynth.set(\midGain, db); };
};

// -------- 4000 HZ FADER --------
lblMidHigh = StaticText(eqPanel, Rect(x3 - 25, nameY, sliderWidth + 50, 18));
lblMidHigh.align = \center;
lblMidHigh.string = "4000 Hz";

sliderMidHigh = Slider(eqPanel, Rect(x3, topY, sliderWidth, sliderHeight));
sliderMidHigh.orientation = \vertical;
sliderMidHigh.value = 0.5;

txtMidHighVal = StaticText(eqPanel, Rect(x3 - 25, valueY, sliderWidth + 50, 18));
txtMidHighVal.align = \center;
txtMidHighVal.string = "0.0 dB";

sliderMidHigh.action = { |sl|
	var db = (sl.value * 2 - 1) * 18;
	txtMidHighVal.string = db.round(0.1).asString ++ " dB";
	if(~eqSynth.notNil) { ~eqSynth.set(\mhGain, db); };
};

// -------- 10000 HZ FADER --------
lblHigh = StaticText(eqPanel, Rect(x4 - 25, nameY, sliderWidth + 50, 18));
lblHigh.align = \center;
lblHigh.string = "10000 Hz";

sliderHigh = Slider(eqPanel, Rect(x4, topY, sliderWidth, sliderHeight));
sliderHigh.orientation = \vertical;
sliderHigh.value = 0.5;

txtHighVal = StaticText(eqPanel, Rect(x4 - 25, valueY, sliderWidth + 50, 18));
txtHighVal.align = \center;
txtHighVal.string = "0.0 dB";

sliderHigh.action = { |sl|
	var db = (sl.value * 2 - 1) * 18;
	txtHighVal.string = db.round(0.1).asString ++ " dB";
	if(~eqSynth.notNil) { ~eqSynth.set(\highGain, db); };
};

// Right Panel for Ulam Spiral
rightPanel = CompositeView(w, Rect(500, 10, 660, 740));
rightPanel.background = Color.clear;
rightPanel.decorator = FlowLayout(rightPanel.bounds);

txtVis = StaticText(rightPanel, Rect(0,0,640,20));
txtVis.string = "ULAM SPIRAL";
txtVis.font = Font("Monaco", 15);
visView = UserView(rightPanel, Rect(0,0,640,640));
~visView = visView;
visView.background = Color.white;
visView.clearOnRefresh = true;

visView.drawFunc = { |view|
	Pen.use {
		var b = view.bounds;
		var width  = b.width;
		var height = b.height;
		var cellW = width  / ~visSide;
		var cellH = height / ~visSide;

		Pen.fillColor = Color.white;
		Pen.fillRect(Rect(0, 0, width, height));

		~visN.do { |i|
			var coord = ~visCoords[i];
			var clrIx = ~visColorIx[i];
			var x = coord.x * cellW;
			var y = coord.y * cellH;
			var rect = Rect(x, y, cellW, cellH);

			Pen.fillColor = if(clrIx >= 0,
				{ ~primeColors[clrIx] },
				{ Color.black.alpha_(0.08) }
			);
			Pen.fillRect(rect);
			Pen.strokeColor = Color.black.alpha_(0.1);
			Pen.strokeRect(rect);
		};
	};
};

// Inferior Row for REC Button
recRow = CompositeView(rightPanel, Rect(0, 0, 640, 40));
recRow.background = Color.clear;
btnRec = Button(recRow, Rect(640-60, 5, 50, 30));
btnRec.states = [
	["REC", Color.white, Color.black], // OFF
	["REC", Color.white, Color.red]    // REC
];
btnRec.value = if(~isRecording, 1, 0);

// ---------------- Recording Location ----------------
btnRec.action = { |b|
	if(b.value == 1) {
		// REC
		if(~isRecording.not) {
			var dir, fname, fullPath;

			// Create Folder in Desktop
			dir = Platform.userHomeDir ++ "/Desktop/GaschPrimeSynth_Recordings";
			File.mkdir(dir);
			fname = "GaschPrimeSynth_REC_" ++ Date.localtime.stamp ++ ".wav";
			fullPath = (dir ++ "/" ++ fname).standardizePath;
			~recFilePath = fullPath;

			("Recording at: " ++ fullPath).postln;

			if(~recSynth.notNil) { ~recSynth.free; ~recSynth = nil; };
			if(~recBuf.notNil) {
				~recBuf.close;
				~recBuf.free;
				~recBuf = nil;
			};
			~recBuf = Buffer.alloc(s, 65536, 2);
			~recBuf.write(
				fullPath,
				"wav",
				"int16",
				0, 0, true
			);

			// REC Synth after EQ
			~recSynth = Synth(\primeRecorder, [
				\bufnum, ~recBuf.bufnum,
				\inbus,  ~finalBus.index
			], ~eqSynth, \addAfter);
			~isRecording = true;
		};
	} {
		// STOP REC
		if(~isRecording) {
			if(~recSynth.notNil) {
				~recSynth.free;
				~recSynth = nil;
			};
			if(~recBuf.notNil) {
				~recBuf.close;
				~recBuf.free;
				~recBuf = nil;
			};
			("Grabación terminada: " ++ (~recFilePath ? "desconocido")).postln;
			~isRecording = false;
		};
	};
};

w.front;
~visView.refresh;
)