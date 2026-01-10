## Prime Number–Based Sound Synthesis and Performance

**Gasch Prime Synth** is a SuperCollider-based musical instrument that explores prime numbers as structural material for sound synthesis, tuning, spatialization, and musical interaction.

The system maps numerical properties of prime numbers—such as distribution, ordering, and geometric representations (e.g., Ulam spirals)—to musical parameters including pitch, timbre, rhythm, and spatial behavior.

Rather than functioning as an autonomous generative system, the instrument is designed as a **MIDI-driven performance interface**: prime-based processes are activated and shaped through real-time human gesture. Sound is produced exclusively in response to MIDI note-on events, emphasizing embodied interaction between performer and numerical structures.

This project is part of an artistic and research-oriented exploration of mathematical abstraction in music, combining algorithmic composition, digital signal processing, and interactive sound synthesis.


## Quickstart

### Requirements
- SuperCollider
- MIDI keyboard or controller (mandatory)

### Running the Gasch Prime Synth

1. Connect your MIDI keyboard before launching SuperCollider.
2. Open `src/GaschPrimeSynth.scd`.
3. Boot the audio server:
   ```supercollider
   s.boot;
4. Execute the code blocks in ascending order:
- BUS – audio routing and output
- PRIME – prime number generation and synthesis logic
- ULAM – Ulam spiral mapping and spatial logic
- MIDI – MIDI input handling (required)
- GUI – graphical user interface
  
5. Play notes on your MIDI keyboard.

---
```md
### Troubleshooting

**No sound**
- Make sure a MIDI keyboard is connected and detected.
- Ensure the **MIDI** block has been executed.
- Check that the SuperCollider server is running (`s.boot`).

**MIDI not detected**
- Evaluate `MIDIClient.init;`
- Verify your device appears in `MIDIClient.sources`.
