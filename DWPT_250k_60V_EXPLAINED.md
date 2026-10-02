# Single-transmitter 250 kHz / 60 V model

The new `DWPT_250k_60V.slx` is a separate copy of `DWPT_fixed.slx`. It removes the second transmitter, replaces the receiver diode bridge with four gated MOSFETs, and changes the resonant network to a 250 kHz LCC-S design. The original models remain available.

## Operating assumptions

The input remains 50 V DC and the load remains 30 ohms. Therefore 60 V output means 2 A and 120 W. There is one receiver in this model. The electrical design assumes two 50 uH coils and coupling k = 0.25, giving mutual inductance M = 12.5 uH. These are design targets, not measurements of existing coils. Air gap, lateral travel, available dimensions and required power were not supplied; the physical winding example below is conditional on those assumptions.

## How power moves through the circuit

1. A four-MOSFET transmitter bridge converts 50 V DC into a phase-shifted 250 kHz waveform. Both bridge legs use 50% nominal duty with dead time. Their relative phase controls the fundamental voltage and delivered power.
2. The transmitter LCC network consists of a series compensation inductor Lf, a shunt capacitor Cf, and a series capacitor Cp before the transmitter coil Lp. It cancels reactance at the design frequency and establishes the coil current/voltage transfer relationship.
3. A two-winding mutual-inductor block couples Lp to receiver coil Ls. Series resistors represent the assumed AC copper losses. The removed transmitter has no remaining coupled winding.
4. Receiver capacitor Cs series-resonates with Ls. The receiver is **series compensated**, so the full topology is LCC-S, rather than LCC on both sides.
5. Four receiver MOSFETs form an active full bridge. For positive AC current, Q1/Q4 conduct; for negative current, Q2/Q3 conduct. Their intrinsic body diodes remain available during startup and blanking.
6. A 470 uF output capacitor smooths the rectified current, and the 30 ohm load consumes power. Output-voltage feedback adjusts the transmitter phase to hold 60 V.

```mermaid
flowchart LR
  DC[50 V DC] --> INV[Phase-shift full bridge]
  INV --> LCC[Lf + Cf + Cp]
  LCC --> TX[TX coil: 50 uH]
  TX -. M = 12.5 uH .-> RX[RX coil: 50 uH]
  RX --> CS[Series Cs]
  CS --> SR[Four-MOSFET rectifier]
  SR --> OUT[470 uF + 30 ohm load]
  OUT -->|Voltage feedback| PI[60 V reference + PI]
  PI -->|Phase command| INV
  CS -->|AC current sign| GATE[Blanking + SR gate logic]
  GATE --> SR
```

## Resonant design

Let omega = 2*pi*250,000 = 1.570796e6 rad/s. With Lp = Ls = 50 uH and M = 12.5 uH, the nominal first-harmonic design uses:

- Cf = 1/(omega^2 Lf)
- Cp = 1/[omega^2 (Lp - Lf)]
- Cs = 1/(omega^2 Ls)
- Vout approximately equals Vin*(M/Lf)*sin(alpha/2), where alpha is the bridge phase displacement from 0 to pi.

The last expression assumes resonance, fundamental-dominated coil current, ideal rectification and a smoothed DC output. The equivalent AC load is approximately 8*Rload/pi^2 = 24.317 ohms. These equations select initial component values; the switched simulation includes conduction losses and feedback. See the [LCC-S analysis and experimental study](https://ietresearch.onlinelibrary.wiley.com/doi/10.1049/pel2.12718).

We select 10% voltage headroom: the lossless maximum output is 66 V. Thus Lf = M*50/66 = 9.469697 uH. This leaves control margin to compensate for losses at the nominal coupling.

| Element | Model value | Purpose |
|---|---:|---|
| Lp / Ls | 50 / 50 uH | Transfer coils |
| M / k | 12.5 uH / 0.25 | Nominal magnetic coupling |
| Lf (`LT1`) | 9.469697 uH | Series compensation inductor |
| Cf (`CT1`) | 42.798068 nF | Shunt compensation capacitor |
| Cp (`CP1`) | 9.999549 nF | Transmitter series compensation |
| Cs (`CS`) | 8.105695 nF | Receiver series compensation |
| Output capacitor | 470 uF | DC smoothing |
| TX / RX winding resistance | 0.20 / 0.20 ohm | Assumed AC copper loss |
| Lf resistance | 0.07 ohm | Assumed compensation copper loss |
| TX / RX MOSFET on resistance | 10 / 10 milliohm | Conduction model per device |
| Body diode | 0.8 V + 10 milliohm | Forward conduction model |

Rounded real capacitors must be selected and retuned against measured installed inductances. Changing frequency or coils in a simulation override does not automatically retune the network. At lower coupling, the bridge can run out of available voltage: feedback cannot guarantee 60 V for arbitrary gaps, alignment or loads.

## Gate control and startup

The output reference ramps from 0 to 60 V over 20 ms. A PI controller updates once per 4 us switching period, with proportional gain 0.015 and integral gain 20, plus nominal feedforward and anti-windup. It maps modulation to phase using alpha = 2*asin(modulation). These gains are tested for the stated nominal operating point, not a wide-range hardware control design.

Transmitter dead time is 40 ns, with a complementary-gate interlock. The receiver uses the measured AC current delayed one 10 ns simulation step, a +/-0.10 A threshold, and 40 ns stable-polarity blanking. This avoids simultaneous diagonal commands and provides commutation time. Actual gate-driver delay, noise and reverse-current behavior require a hardware controller design.

All energy storage starts explicitly unenergized. The output capacitor starts at 0 V. This is essential: unconstrained initial conditions previously allowed a nonphysical energized startup. The model uses a native Simscape local implicit trapezoidal solver and a 10 ns global step (400 samples per carrier period). Measurement-only RMS blocks clamp tiny negative mean-square roundoff before taking a square root.

## Why MOSFET rectification reduces, but does not eliminate, loss

A conducting diode pair loses approximately 2*Vf*I, plus resistive loss. Two conducting MOSFET channels instead lose approximately 2*Rds(on)*Irms^2. With low on-resistance this is much smaller, but nonzero. Body diodes still conduct during blanking. The simulation compares identical hardware with receiver gates enabled versus disabled; the disabled case rectifies through the MOSFET body diodes, rather than modeling a separately selected commercial diode bridge.

The reported efficiency includes the specified winding/inductor resistances, MOSFET channel conduction and simplified diode conduction. It **does not predict total hardware efficiency**: gate-drive power, switching overlap, nonlinear capacitance, reverse recovery, temperature variation, ferrite/shield loss, capacitor ESR and wiring parasitics are not fully modeled. A real device selection and driver design are still required. TI discusses the role of synchronous rectification and dead time in its [rectifier design guidance](https://www.ti.com/document-viewer/lit/html/SSZTAG1/GUID-9503CF74-B400-405E-A939-EB2B9F614650).

## Conditional physical coil example

LCC tuning specifies inductances; it does not uniquely specify a coil diameter or turn count. `coil_sizing250k.m` supplies an approximate realizable air-core starting geometry, assuming identical aligned circular transfer coils, no nearby metal, and no ferrite:

| Winding | Turns | Outer diameter | Inner diameter | Estimated L |
|---|---:|---:|---:|---:|
| TX transfer coil | 22 | 150 mm | 50 mm | approximately 50 uH |
| RX transfer coil | 22 | 150 mm | 50 mm | approximately 50 uH |
| Lf compensation coil | 12 | 88 mm | 33 mm | approximately 9.47 uH |

The assumed litz bundle is 250 strands of 0.0635 mm copper (42 AWG), about 0.792 mm^2 total copper area and an assumed 1.6 mm finished bundle diameter. Supplier insulation and construction determine the actual diameter. This is a geometric/conduction starting point, not a validated thermal current rating. Keep the compensation inductor sufficiently separated from the transfer coils so the model's assumption of negligible unintended coupling is valid.

Self-inductance uses the circular current-sheet expression L = mu0*N^2*davg/2 * [ln(2.46/rho) + 0.2*rho^2], with rho = (Dout-Din)/(Dout+Din). A Wheeler estimate is also reported as a cross-check. The [Mohan et al. paper](https://web.stanford.edu/~boyd/papers/pdf/inductance_expressions.pdf) presents the current-sheet expression; its original validation concerns planar integrated inductors, so its quoted accuracy should not be transferred directly to these large litz windings.

Mutual inductance is estimated by summing coaxial circular-filament pairs using complete elliptic integrals, consistent with the [NIST mutual-inductance expression](https://dlmf.nist.gov/19.34). This geometry gives M = 12.5 uH at an estimated 44.9 mm perfectly aligned gap. It does not account for lateral offset, ferrite, shielding or chassis metal. The conductor strand size is consistent with the [New England Wire litz construction guidance](https://www.newenglandwire.com/wp-content/uploads/2018/08/NEWT-Benefits-of-Preformed-Litz_FINAL.pdf) for this frequency range.

Measure installed self/mutual inductances, AC resistance, self-resonance and temperature rise before finalizing the coil or capacitors. Voltage ratings must cover reactive voltages and startup stress, which can greatly exceed the 60 V DC output.

## Running and modifying the design

From this folder in MATLAB R2026b:

```matlab
open_system('DWPT_250k_60V.slx')
[out, metrics] = run_dwpt250k();
```

The model contains its own parameter workspace. `dwpt250k_parameters.m` is the reproducible parameter source. For a permanent redesign, edit that file and run `build_dwpt250k`; this regenerates the new model from `DWPT_fixed.slx` and replaces any manual edits to the new copy. Controller templates and the physical-net map reside in `design250k` and are required to rebuild.

```matlab
[out, metrics] = run_dwpt250k(0.03, struct('srEnabled',0)); % body diode comparison
[out, metrics] = run_dwpt250k(0.03, struct('k',0.20));      % changed gap/coupling
coil_sizing250k();                                        % geometry estimates
validate_dwpt250k();                                      % rerun all checks
plot_dwpt250k();                                          % export saved waveforms
```

Power measurements average instantaneous voltage times current over the last 100 complete carrier periods. Rectifier input power is measured at its AC terminals, and output power at its DC terminals before the smoothing capacitor. This keeps capacitor charging separate from rectifier dissipation. The script also checks gate overlap/dead time, load power consistency and a necessary whole-run energy-balance condition.

## Nominal simulation results

The 30 ms run includes the entire 20 ms startup ramp and 10 ms settling. Final averages use 29.6–30.0 ms. The nominal result is 60.0131 V, 2.0004 A and 120.0525 W, with 123.5518 W input. The **conduction-model efficiency** is 97.1678%; this is not a prediction of measured hardware efficiency. Rectifier loss is 0.1082 W. Output ripple is approximately 1.8 mV peak-to-peak with the ideal 470 uF capacitor; real capacitor ESR increases ripple.

Maximum output during startup is 60.7509 V. Transmitter complementary gates maintain at least 40 ns off time, and the observed receiver diagonal blanking is at least 60 ns. No complementary gate overlap occurs. Integrated source energy is 2.9577 J; load energy is 2.0032 J and output-capacitor energy increase is 0.8464 J. The remaining positive 0.1081 J covers modeled losses and energy in the resonant network; this is a necessary passivity check, not a complete component-by-component energy accounting.

| Quantity | Final RMS | Maximum absolute value over startup and steady state |
|---|---:|---:|
| TX transfer coil current | 2.777 A | 3.922 A |
| Lf/input current | 2.987 A | 7.242 A |
| RX current | 2.233 A | 5.430 A |
| Cp voltage | 176.79 V | 255.51 V |
| Cf voltage | 57.87 V | 118.66 V |
| Cs voltage | 175.25 V | 424.50 V |
| TX coil terminal voltage | 218.67 V | 328.43 V |
| RX coil terminal voltage | 180.85 V | 484.63 V |
| Lf assembly terminal voltage | 46.14 V | 132.07 V |

These are stresses from one simulated operating condition, not final component ratings. In particular, selecting receiver compensation capacitors for only 60 V would be incorrect. Capacitor AC current/voltage capability at 250 kHz, startup margin, insulation and off-nominal conditions all matter. Winding temperature and component tolerances have not been validated.

The waveform exports are `design250k/startup.png` and `design250k/steady_state.png`. Full numerical results are in `design250k/nominal_metrics.json`; additional verification is recorded in `design250k/validation_results.json`. Older development runs are isolated in `design250k/development_history` and do not describe the final model.

### Receiver loss comparison

With the same 30 ms startup, but the receiver gates disabled, body diodes alone produce 60.0003 V and 120.0013 W at the load. Rectifier dissipation is 3.2996 W and input power is 126.7552 W. Enabling synchronous rectification reduces the modeled rectifier dissipation by approximately 96.7%, to 0.1082 W. The controller uses slightly more phase displacement in the diode case to overcome its larger voltage drop. This comparison isolates the benefit within the stated conduction model; it is not a loss comparison against every possible diode/device technology.

Saved nominal waveforms retain 1 us startup samples and all 10 ns samples in the final 100 cycles to reduce file size. Numerical metrics and gate checks are computed before this display-only reduction.

For example, the geometric estimate at a 50 mm gap is M = 10.94 uH. The lossless maximum output would then be only about 57.8 V with this fixed Lf and 50 V input. This analytical estimate illustrates why a different required gap would require redesign, rather than relying only on feedback.

At the nominal point, the three modeled winding resistances account for approximately 3.17 W using I_rms^2*R (TX coil, RX coil and Lf). Total input minus load power is approximately 3.50 W. Thus reducing rectifier loss does not remove the dominant copper losses from this particular design.

### Completed verification

All automated checks passed in MATLAB R2026b. Halving the step from 10 ns to 5 ns (400 to 800 samples/cycle) gave 60.003269 V output. Average output changed by 0.01642% and input power by 0.01132%. Both resolutions passed target-voltage, gate-overlap, dead-time, load-identity and necessary energy-balance checks. With coupling set to zero, maximum receiver output was 4.27e-20 V, effectively numerical zero.

A first attempt to save all finer-step waveforms exhausted disk space after the simulation completed. The incomplete file was removed; verification was rerun successfully using small per-case metric files. The final verification record is `design250k/verification.log` and `design250k/validation_results.json`.
