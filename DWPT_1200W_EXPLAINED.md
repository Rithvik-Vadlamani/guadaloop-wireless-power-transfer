# Revised requirement: 60 V, 20 A, 250 kHz, 10 mm gap

This revision supersedes the earlier **120 W** design for your stated operating point. The new file is `DWPT_250k_60V_1200W.slx`; the original, repaired, and 120 W models remain available. The target is **1,200 W at the rectifier DC output**, with a 3 ohm test load, one transmitter and one synchronous receiver rectifier. The DC input is still assumed to be 50 V.

The available space is 3 ft by 2 ft per coil (914.4 by 609.6 mm). This is treated as a maximum envelope, not a requirement to fill the entire area. The model assumes the coils are aligned and stationary. A continuous power-transfer corridor over the full envelope or lateral-motion tolerance would require a different geometry and coupling map.

## What changed from the 120 W model

- Load changed from 30 ohms to 3 ohms: 60/3 = 20 A and 60*20 = 1,200 W.
- The coil geometry and coupling now use the specified 10 mm gap.
- Both transfer inductances, mutual inductance and all LCC-S capacitors were recalculated.
- Copper cross-section increased by a factor of ten to about 7.92 mm^2.
- Output capacitance increased from 470 uF to 2,200 uF.
- Effective MOSFET on resistance changed from 10 to 3 milliohms per switch as a device-design target. It is not a measured value or a selected part number.
- The second transmitter remains removed. Four receiver MOSFETs remain controlled according to AC current polarity with blanking.

Simply changing the load in the old design would not validate the new power requirement.

## Candidate winding dimensions

Each TX/RX transfer coil is a single-layer circular air-core winding:

| Feature | Value |
|---|---:|
| Turns | 5 |
| Outer diameter | 300 mm / 11.81 in |
| Inner diameter | 200 mm / 7.87 in |
| Assumed finished litz bundle diameter | 6 mm |
| Turn center pitch | 11 mm |
| Copper construction target | 2,500 strands of 0.0635 mm wire (42 AWG) |
| Copper cross-section | Approximately 7.92 mm^2 |
| Winding conductor length, excluding leads | Approximately 3.93 m |
| Estimated DC resistance at 20 C | 8.55 milliohms |
| Assumed AC resistance at 250 kHz | 17.10 milliohms |

Both coils fit comfortably inside the supplied 914.4 by 609.6 mm envelope. The dimensions are a candidate design, not a unique solution or a demonstrated optimum. Finished bundle diameter, lead length and AC resistance depend on actual litz construction, insulation, termination and installation.

**Gap convention:** 10 mm is interpreted as clear space between winding surfaces. With 6 mm thick windings, the winding center planes are 16 mm apart. If your 10 mm is instead measured center-to-center, this coupling estimate must be changed.

The circular current-sheet approximation gives **Lp = Ls = 9.886589 uH**. Summing the mutual inductance of the coaxial turn pairs at 16 mm center-plane separation gives **M = 6.872348 uH**, hence **k = 0.695118**. Self-inductance uses the [Mohan current-sheet expression](https://web.stanford.edu/~boyd/papers/pdf/inductance_expressions.pdf); its integrated-inductor accuracy claims do not establish accuracy for these large litz windings. The mutual calculation uses the circular-loop relationship described by [NIST](https://dlmf.nist.gov/19.34). The 42 AWG strand size falls within the manufacturer's guidance for 200–350 kHz in the [New England Wire preformed-litz note](https://www.newenglandwire.com/wp-content/uploads/2018/08/NEWT-Benefits-of-Preformed-Litz_FINAL.pdf).

No ferrite, shield, chassis metal, misalignment, inter-turn capacitance or thermal behavior is included in these estimates. The factor of two from DC to AC resistance is an explicit engineering assumption, not a loss calculation. Installed inductance, coupling, AC resistance, self-resonant frequency and temperature rise must be measured or validated with an electromagnetic/thermal model before fabrication release.

## LCC-S tuning

The transmitter has series Lf, shunt Cf, series Cp, and coil Lp. The receiver has coil Ls and series capacitor Cs before its rectifier. Thus this is **LCC-S**, with LCC compensation on the transmitter and series compensation on the receiver.

At omega = 2*pi*250,000 rad/s:

- Cf = 1/(omega^2*Lf)
- Cp = 1/[omega^2*(Lp-Lf)]
- Cs = 1/(omega^2*Ls)
- Ideal fundamental approximation: Vout = Vin*(M/Lf)*sin(alpha/2)

Alpha is the transmitter bridge phase shift. A 15% voltage margin is used, so the ideal full-phase output is 69 V and Lf = M*50/69 = **4.979962 uH**. Actual operation uses voltage feedback to reach 60 V with the modeled losses. The first-harmonic equivalent AC load at the nominal DC load is 8*3/pi^2 = **2.4317 ohms**.

These are nominal tuning relationships, not a guarantee of load-independent operation with arbitrary losses or coupling. Changes in measured inductance or installed geometry require retuning. The switched simulation provides the nominal operating-point check; component tolerances and motion are not swept.

## Control and loss model

Power passes through the transmitter full bridge, LCC network, coupled coils, receiver series capacitor, four-MOSFET rectifier and output smoothing capacitor to the load. A 20 ms voltage-reference ramp and PI controller adjust transmitter phase once per switching cycle. The frequency remains fixed at 250 kHz.

Transmitter dead time is 40 ns. The receiver senses AC current with a one-step sample delay and uses a +/-0.25 A polarity threshold plus 40 ns stable-polarity blanking. Positive current commands Q1/Q4; negative current commands Q2/Q3. Body diodes provide a commutation path while the channels are off. All capacitors and inductors start unenergized.

The model's 20 A output is the current through the nominal 3 ohm load. It is **not** a constant-current charging controller or a 20 A current limiter. For a battery or changing load, a suitable current-control/protection stage is still needed.

MOSFET conduction loss is approximately I_rms^2*Rds(on), and two channels conduct in the receiver path at a time. Winding losses and body-diode blanking losses remain. The model includes assumed copper resistance, channel resistance and simplified body-diode conduction; it does not fully model switching overlap, gate-drive power, nonlinear capacitance, reverse recovery, capacitor ESR, temperature, core/shield losses or wiring parasitics. Reported efficiency is therefore a **conduction-model result**, not a certified hardware efficiency.

The 50 V source must supply more than 24 A continuously to deliver 1,200 W after losses. A physical supply, MOSFETs, drivers, capacitors, connectors and winding cooling must be selected against RMS, peak, startup and temperature requirements. Compensation-component voltages can be far above the 60 V DC output.

## Reproducing the model

Run these from the project folder in MATLAB R2026b:

```matlab
open_system('DWPT_250k_60V_1200W.slx')
[out,metrics] = run_dwpt1200w();
coil_sizing1200w();
```

`dwpt1200w_parameters.m` is the parameter source. The model also contains its own parameter workspace. After intentional parameter changes, `build_dwpt1200w` rebuilds the new model from `DWPT_fixed.slx` and replaces manual edits in the new copy. It refuses to discard unsaved edits in an already open new model.

`validate_dwpt1200w` reruns nominal, body-diode-only, smaller-step and zero-coupling cases. `plot_dwpt1200w` plots the saved nominal results. Numerical metrics use full-resolution samples; the saved nominal visual record is compacted to 1 us during startup and full resolution for the last 100 carrier cycles.

## Exact nominal electrical values

| Element | Value |
|---|---:|
| Lp / Ls | 9.886589 uH each |
| M | 6.872348 uH |
| Lf | 4.979962 uH |
| Cf (CT1) | 81.383091 nF |
| Cp (CP1) | 82.599462 nF |
| Cs | 40.993383 nF |

A separate air-core Lf candidate is five turns, 253.84 mm outer diameter and 101.54 mm inner diameter, using the same assumed litz bundle. Its estimated DC resistance is 6.078 milliohms; the model assumes 10 milliohms AC resistance. It must be placed/oriented so its unintended coupling to the transfer coils is negligible, as assumed by the circuit model. This placement is not yet a mechanical layout.

Power and RMS stress measurements use the final **1,250 complete carrier cycles (5 ms)**. The output capacitor's average charging/discharging power is reported separately and must be less than 0.5% of load power in the validation suite. This prevents a short capacitor-discharge interval from being mistaken for exceptionally high efficiency. The stored plots retain only the last 100 cycles at full temporal resolution; the metrics are calculated from the full simulation before that reduction.

## Measured nominal simulation results

Over 25–30 ms, output is **59.99936 V, 19.99979 A and 1199.97 W**. Input power is 1227.36 W, corresponding to 24.547 A average from the assumed 50 V source. Conduction-model efficiency is 97.769%. The output capacitor contributes 0.654 W over this interval, 0.0545% of load power; it is not carrying a material fraction of the 1.2 kW load.

Maximum output during startup is 60.774 V. The final 5 ms voltage excursion is 0.155 V peak-to-peak, including residual control variation as well as carrier ripple. Gate overlap is absent, and observed TX/SR dead time is at least 40 ns.

Receiver rectifier dissipation is **3.035 W with synchronous channels**, compared with **41.923 W through body diodes only**, a 92.76% reduction. The comparison uses the same MOSFET body-diode model with the gates disabled, not a separately optimized commercial diode bridge.

| Component quantity | Final RMS | Maximum absolute value during full run |
|---|---:|---:|
| TX transfer coil current | 5.140 A | 6.743 A |
| Lf/input current | 30.755 A | 58.050 A |
| RX current | 22.309 A | 42.466 A |
| Cp voltage | 39.012 V | 59.706 V |
| Cf voltage | 240.796 V | 454.223 V |
| Cs voltage | 345.995 V | 652.756 V |
| TX coil terminal voltage | 247.301 V | 458.636 V |
| RX coil terminal voltage | 347.398 V | 712.889 V |

These are simulated stresses, not recommended component ratings. In particular, the LCC inductor carries substantially more current than the TX transfer coil; they cannot be sized from the same current figure. Capacitor AC-current capability at 250 kHz and startup voltage stress both matter.

## Verification completed

The nominal 3 ohm / 1.2 kW run, body-diode comparison, 5 ns finer-step run, and zero-coupling run passed all checks. Halving the time step changed mean output voltage by 0.00220% and input power by 0.00111%. The finer-step output was 59.99804 V. The zero-coupling receiver remained effectively at zero volts. Gate-overlap/dead-time, load-power identity, necessary whole-run energy balance and output-capacitor power-fraction checks passed.

Results are saved in `design1200w/validation_results.json`, with per-case metric files and `verification.log`. Startup and switching plots are `design1200w/startup.png` and `design1200w/steady_state.png`. Longer display-averaging windows caused automatically expanded measurement-history buffers during validation; the final model preallocates those buffers. This is a display-memory setting, not a change to the electrical network or controls.
