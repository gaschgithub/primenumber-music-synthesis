## Quickstart (5 minutes)

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
### Expected Result

After executing all blocks and playing the MIDI keyboard:
- Sound is produced only on MIDI note-on events.
- Pitch, timbre, and spatial behavior are determined by prime number mappings.
- The GUI opens and updates according to the current prime-based mode.

### Troubleshooting

**No sound**
- Make sure a MIDI keyboard is connected and detected.
- Ensure the **MIDI** block has been executed.
- Check that the SuperCollider server is running (`s.boot`).

**MIDI not detected**
- Evaluate `MIDIClient.init;`
- Verify your device appears in `MIDIClient.sources`.

**Server does not boot**
- Check audio device settings in SuperCollider preferences.
