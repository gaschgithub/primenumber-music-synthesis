/*
Gasch Prime Synth (entry point)
Run blocks top-to-bottom: BUS → PRIME → ULAM → MIDI → GUI
MIDI keyboard required.
*/

~gpsRoot = thisProcess.nowExecutingPath.dirname;
~gpsLoad = { |rel| (~gpsRoot +/+ rel).load };

// ------------------------------------------------------
// 1) BUS, FX, OUT, REC
// ------------------------------------------------------
(
~gpsLoad.("audio/bus_fx_out_rec.scd");
)

// ------------------------------------------------------
// 2) PRIME (generation, synthdefs, harmonics/amps, tuning)
// ------------------------------------------------------
(
~gpsLoad.("primes/complex_primes.scd");
~gpsLoad.("primes/harmonics_amps.scd");
~gpsLoad.("primes/prime_synthdefs.scd");
~gpsLoad.("primes/prime_tuning.scd");
)

// ------------------------------------------------------
// 3) ULAM SPIRAL
// ------------------------------------------------------
(
~gpsLoad.("visual/ulam_spiral.scd");
)

// ------------------------------------------------------
// 4) MIDI
// ------------------------------------------------------
(
~gpsLoad.("performance/midi_engine.scd");
)

// ------------------------------------------------------
// 5) GUI
// ------------------------------------------------------
(
~gpsLoad.("ui/gui.scd");
)
