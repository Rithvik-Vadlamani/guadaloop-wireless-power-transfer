# What if the clear air gap increases to 100 mm?

This is a separate sensitivity check. The delivered 10 mm model and its parameters remain unchanged. The assumed coils are the same aligned air-core, five-turn circular windings, 300 mm OD / 200 mm ID, with 6 mm bundle thickness. Clear gaps of 10 and 100 mm correspond to winding center-plane spacings of 16 and 106 mm.

Self-inductance is held at 9.886589 uH for each coil. Mutual inductance is recalculated by summing coaxial circular-filament integrals for the actual turn-center radii. It is an analytical geometry estimate, not an electromagnetic or hardware measurement.

Mutual inductance falls from 6.872348 uH to 1.886735 uH; coupling falls from 0.695118 to 0.190838. Mutual inductance is 27.45% of its nominal value.

With the original Lf = 4.979962 uH, the ideal first-harmonic maximum DC output is Vin*M/Lf. At 50 V input, the 100 mm-gap value is 18.943 V. The voltage controller saturates at full phase shift when asked for 60 V.

Keeping that LCC network gives an ideal lower bound of 158.37 V input for 60 V output, before losses and regulation margin. Preserving the original 15% ideal voltage headroom corresponds to 182.12 V input. Neither is a validated operating voltage for the existing hardware assumptions.

Alternatively, retaining 50 V input and the same ideal headroom would require Lf approximately 1.367199 uH, plus recalculated Cf and Cp. Maintaining the same receiver induced voltage requires roughly 3.64 times the transmitter coil current, since induced voltage is proportional to omega*M*I_TX. The transmitter winding's own I-squared-R loss would therefore rise by roughly 13.27 times if its AC resistance remained unchanged. These are redesign estimates, not a validated alternative model.

The sensitivity simulation changes only k (and its derived mutual inductance), retaining 50 V input, the 3 ohm load, original LCC components, 250 kHz switching and the synchronous rectifier. Results are saved in gap100mm_metrics.json.

## Switched simulation result

At 100 mm clear gap, the existing circuit produced **18.7442 V, 6.2481 A and 117.115 W**, with 119.004 W input. The mean modulation command was 1.000000 (1 means full drive). Metrics average the last 5 ms of a 30 ms startup simulation. The output capacitor's average energy contribution was negligible. This does not validate 60 V / 20 A operation at 100 mm; it demonstrates the loss of voltage capability in the existing 50 V-input design.
