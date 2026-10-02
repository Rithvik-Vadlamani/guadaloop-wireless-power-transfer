# Current DD track design

The current design is **four DD track pads and one DD pod receiver**, a **100 V maximum DC bus**, **60 V / 20 A output target**, **250 kHz**, and a **100 mm clear winding gap**. Each pad fits a 3 ft × 2 ft envelope; the four sections form the 12 ft track.

- Circuit: [DWPT_DD_4section_100V.slx](<DWPT_DD_4section_100V.slx>)
- Design explanation, tuning, test results and limits: [DD_TRACK_DESIGN.md](<DD_TRACK_DESIGN.md>)
- In MATLAB, run `show_dd_track` to open the circuit and saved waveform viewer.
- Run a seam test with `[metrics, waveforms] = run_dd_track(0.9144, 0.050, struct(), 'seam');`
- Run the verification suite with `validate_dd_track`.

The 94% target is assessed using hot-resistance assumptions and a declared switching/auxiliary loss estimate. It is not measured hardware efficiency. Fully switched tests are at fixed positions; the separate moving tests use a reduced model and illustrative speeds. Read the report's end-of-track, lateral-offset and speed limitations before using the values for construction.

The old `DWPT_250k_60V_1200W.slx` remains the earlier **50 V input / 10 mm gap / circular-coil** design. `DWPT_250k_60V.slx` is the earlier 120 W design. Neither represents the current four-section DD requirements. The original `DWPT.slx` is preserved.
