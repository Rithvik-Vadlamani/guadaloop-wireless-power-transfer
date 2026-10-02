# Four-section DD-to-DD wireless power design

100 V maximum DC input · 60 V / 20 A DC output target · 250 kHz · 100 mm clear winding gap

This is the final **simulation design for the stated assumptions**, with a native Simscape circuit, DD geometry calculations and reproducible tests. It is not a released PCB or a measured 94%-efficient prototype. The tested in-track operating points produce approximately 60 V and 20 A. Their DC-to-DC efficiency estimates, including the declared semiconductor and auxiliary loss model, range from **95.01% to 95.44%**. Detailed loss estimates and sensitivity results are below. A speed limit is not established because the actual maximum speed is still unspecified.

Open [the Simulink circuit](<DWPT_DD_4section_100V.slx>) or run `show_dd_track` in MATLAB. Earlier DWPT models were preserved.

![final circuit.png](<design_dd_track/final_circuit.png>)

## Requirements and coverage

| Item | Design basis |
|---|---|
| Track | Four sections, each 914.4 × 609.6 mm; total 3657.6 × 609.6 mm (12 × 2 ft) |
| Track winding | One bipolar DD pad per section; four pads total |
| Pod winding | One matching bipolar DD pad, same 914.4 × 609.6 mm maximum envelope |
| Air gap | 100 mm between facing winding surfaces; 109 mm between conductor center planes with the assumed 9 mm bundle |
| Supply | 100 V DC maximum; 1.2 kW output requires 1.277 kW input at 94%, or 12.77 A average at 100 V |
| Output | 60 V regulated across a 3 Ω test load, giving 20 A and 1200 W |
| Carrier | 250 kHz, fixed |
| Compensation | Four primary LCC branches, one series-compensated receiver: LCC-S |
| Rectifier | Four actively gated silicon MOSFETs with retained body-diode paths |
| Handover | Adjacent transmitters share power with aligned fundamental phases and position-dependent weights |
| Efficiency boundary | DC input bus through rectifier DC output, plus declared gate/auxiliary allowances; excludes upstream AC/DC supply |

The verified nominal travel region is from the first pad center at **0.4572 m** to the last pad center at **3.2004 m**. That is **2.7432 m / 9 ft of receiver-center travel with the complete 3 ft receiver over the 12 ft track**. The field extends beyond this region, but the same power is not available at arbitrary overhang. At the physical entrance, x = 0, the native simulation reaches **40.34 V / 13.45 A** with the input capped at 100 V. Full-power travel with the receiver center spanning all 12 ft would require an end treatment, longer magnetic track, smaller receiver, or separate end compensation. The four given sections alone do not establish that capability.

## DD winding design

![dd pod geometry.png](<design_dd_track/dd_pod_geometry.png>)

![dd geometry.png](<design_dd_track/dd_geometry.png>)

Each pad contains **two D lobes, three turns per lobe, connected in series with opposite circulation**. Viewed from the same side, one lobe circulates clockwise and the other counterclockwise; the adjacent central straight conductors carry current in the same direction. This produces the intended bipolar DD field. The lobes are side by side across the 2 ft width, with the central straight conductors along the direction of travel. The receiver has the same shape and orientation.

| Winding quantity | Value |
|---|---:|
| Maximum pad envelope | 914.4 × 609.6 mm |
| Actual outer winding footprint, including bundle | 864.4 × 559.6 mm |
| Outer edge margin | 25 mm on each side |
| Turns | 3 per D lobe, 6 loop contributions in series |
| Turn pitch | 14 mm |
| Finished litz bundle diameter assumed | 9 mm |
| Candidate conductor construction | 6000 strands × 0.0635 mm copper (42 AWG strand size) |
| Copper cross-section | 19.00 mm² |
| Estimated conductor length per DD pad, including 0.4 m leads | 11.642 m |
| Estimated self-inductance per DD pad | 21.9583 µH |
| Aligned mutual inductance at 100 mm surface gap | 4.7026 µH |
| Aligned coupling coefficient | 0.2142 |
| Mutual inductance from each adjacent TX at a seam | 1.6585 µH |
| Each seam coupling coefficient | 0.0755 |
| Modeled hot AC winding resistance | 19.580 mΩ per complete DD pad |

The resistance estimate uses copper at 80 °C and an assumed AC/DC resistance ratio of 1.5. It includes lead length in resistance, but lead geometry is not included in the field calculation. The bundle construction and its finished diameter need a litz supplier's confirmation; the strand count is a design candidate, not a catalog part. Strand-level skin effect alone does not predict bundle proximity losses. [New England Wire's litz guidance](https://www.newenglandwire.com/wp-content/uploads/2017/12/NE-Wire-Litz-Wire-Brochure-2024.pdf) is the construction reference.

The field calculation compares DD orientations using the same pad space. Longitudinal polarization passes through a coupling null and then changes sign as the receiver moves. Transverse polarization gives a positive overlap region between adjacent sections, allowing constructive handover. This calculation is specific to the air-core geometry here; published DD/DDQ results are useful context, not substitute measurements for these pads. [DD coil study](https://www.mdpi.com/2079-9292/10/20/2528).

The numerical method is the Neumann line integral, summing every signed conductor-segment interaction. It includes TX-to-TX coupling and all four TX-to-RX mutual terms. Self-inductance uses a regularized round-conductor kernel with analytical same-segment terms. Resolution sweeps at 30, 60, 120 and 240 subdivisions estimate self-inductance as 21.567, 21.530, 21.758 and 21.958 µH; the last change is about 0.92%. Mutual inductance converges more tightly. A separate coaxial circular-loop benchmark agrees with the elliptic-integral solution to about **0.00135%**. [NIST reference](https://dlmf.nist.gov/19.34).

This is a magnetoquasistatic **air-core filament calculation**, not ferrite/shield/vehicle-body FEM. It omits ferrite, conducting chassis/track metal, shields, interturn capacitance, manufacturing tolerance and mechanical deflection. Any of those can change inductance, coupling and loss. The inductance matrices used in the sweep are symmetric and positive definite. The electrical model therefore has a reciprocal, passive magnetic energy store.

At the middle seam, the same field model also checks lateral displacement:

| Lateral offset | Required modulation for 60 V | Voltage feasible below 100 V input? |
|---|---:|---|
| 0 mm | 0.745 | Yes |
| 25 mm | 0.780 | Yes |
| 50 mm | 0.900 | Yes |
| 100 mm | 1.827 | No |

These are fundamental estimates, not native switched misalignment tests. The 100 mm lateral-offset case exceeds the input-voltage limit; the nominal native results assume lateral alignment.

## Final compensation values and connections

Let ω = 2π × 250,000 rad/s. For each primary LCC branch:

- `Cf = 1 / (ω² Lf)`
- `Cp = 1 / [ω² (LTX − Lf)]`
- Receiver: `Cs = 1 / (ω² LRX)`

| Component | Quantity | Nominal value | Modeled series resistance |
|---|---:|---:|---:|
| Lf compensation inductor | 4 | 4.052847 µH | 6 mΩ hot AC maximum design value |
| Cf shunt compensation capacitor | 4 | 100.000000 nF | 3 mΩ effective bank ESR |
| Cp primary series capacitor | 4 | 22.634766 nF | 5 mΩ effective bank ESR |
| DD primary winding | 4 | 21.958256 µH | 19.580 mΩ |
| DD pod winding | 1 | 21.958256 µH | 19.580 mΩ |
| Cs receiver series capacitor | 1 | 18.457055 nF | 5 mΩ effective bank ESR |
| Output capacitor bank | 1 | 2200 µF | 1 W ripple-loss allowance, separate from native ideal capacitance |
| Load used for rated test | 1 | 3 Ω | 1200 W at 60 V |

For section j, bridge output A goes through Lf to node X. Cf connects X to bridge output B. The second path is X → Cp → DD track winding → B. Repeat this for all four bridges on the common DC bus. The DD receiver feeds Cs in series, then the AC terminals of the synchronous bridge. The DC terminals feed the 2200 µF capacitor bank and the load. The common DC bus does **not** galvanically connect to the receiver.

The LCC network transforms the bridge drive into a controlled primary-coil current. At resonance, a first-harmonic approximation is `I_TX,rms ≈ Ubridge,1,rms/(ω Lf)`. Receiver induced voltages add as `ω Σ(Mj Ij)` with their phases. For a single aligned active section, the ideal DC gain is approximately `Vout ≈ Vdc × M/Lf × sin(α/2)`, where α is the full-bridge phase shift. This is a tuning relationship; the native switched circuit supplies the reported voltage/current results. It includes winding resistance, tank ESR, channel conduction and dead-time reverse conduction.

A separate air-core Lf candidate uses **5 circular turns, 225.6 mm outer diameter, 90.2 mm inner opening, 14.67 mm pitch**, and the same 9 mm litz bundle. The calculated conductor length with leads is 2.88 m and the hot AC estimate is 4.84 mΩ, leaving some margin to the 6 mΩ model value. This inductor is a separate component: position/orient it so coupling to the transfer pad and neighboring Lf coils is negligible, then measure it installed. Its physical mounting space below/beside the track has not been specified.

## Switches, drivers and control

The final transmitter choice is **16 EPC2304 200 V GaN FETs**, four per bridge. They are enhancement-mode GaN devices, not silicon MOSFETs. The receiver remains **four IPT020N10N5 100 V silicon MOSFETs**. The GaN choice addresses transmitter switching loss at 250 kHz; it does not change the requested MOSFET rectifier.

The GaN model uses 8 mΩ hot on-resistance, a 2 V + 8 mΩ reverse-conduction proxy, and 20 ns commanded interlock. Datasheet anchors are 5 mΩ maximum at 25 °C, 145 nC maximum output charge at 100 V, 26 nC maximum gate charge, 5 V gate drive and zero reverse-recovery charge. The 1.6 hot-resistance multiplier and 5 ns switching-overlap time are explicit design assumptions. [EPC2304 datasheet](https://epc-co.com/epc/Portals/0/epc/documents/datasheets/EPC2304_datasheet.pdf).

Use **two LMG1210 half-bridge drivers per TX bridge**, eight total, with 5 V gate drive and independent PWM inputs. This is a 200 V driver family with adjustable dead time. The model's logic gates do not simulate driver propagation mismatch or the PCB gate loop. [TI LMG1210](https://www.ti.com/product/LMG1210).

The receiver model uses 3.2 mΩ hot on-resistance per switch and 40 ns interlock. The IPT020N10N5 datasheet provides a 2 mΩ maximum on-resistance at 10 V gate drive and a 152 nC maximum gate charge under its stated conditions. Use **two UCC27282 half-bridge drivers** with a regulated 10 V receiver bias supply; its supply/startup implementation is an additional hardware circuit, not a block-level result proven here. [MOSFET datasheet](https://www.infineon.com/assets/row/public/documents/24/49/infineon-ipt020n10n5-datasheet-en.pdf), [TI UCC27282](https://www.ti.com/product/UCC27282).

All transmitters share one 250 kHz timebase. The PWM centers the positive and negative voltage pulses so changing one bridge's phase shift does not rotate its fundamental phase relative to the other bridges. A position-based weighting map suppresses weakly coupled sections, smoothly adds the adjacent section, and gives equal contributions at a seam. A common voltage PI multiplier corrects the feedforward map; its gains are Kp = 0.012 V⁻¹ and Ki = 15 V⁻¹s⁻¹, with a 20 ms voltage-reference ramp and anti-windup. These are simulation gains, subject to controller and sensing-delay validation. In the native circuit, `dd_track_parameters(position)` fixes the weighting vector for each steady-state run; the reduced moving script updates the vector with position.

A section with zero commanded voltage holds both low-side switches on. Its LCC network remains physically connected, and the model includes any induced current. It is not treated as an open-circuit coil. Turning all its devices off is not an equivalent hardware state because reverse paths remain available.

The SR controller senses receiver AC-current polarity. For positive current it turns on one diagonal; for negative current it turns on the other. It turns off near zero current, waits the specified interlock and then enables the correct diagonal. MOSFETs **reduce** rectifier loss; they do not eliminate it. For example, 22.2 A RMS through two 3.2 mΩ channels gives about 3.16 W of channel conduction, before reverse conduction, gate and switching loss.

## Native switched-circuit results

![switched results.png](<design_dd_track/switched_results.png>)

These are actual Simscape runs using the complete five-winding inductance matrix and all 20 semiconductor channel/reverse-path models. Startup begins with zero energy in the output capacitor and resonant elements. The DC source is ideal and already available at 100 V. Each rated run lasts 50 ms; steady-state powers are averaged over its final 20 ms. Full carrier switching remains in the solver. Most logged waveforms are sampled every 20 ns to bound file size. DC-bus current is retained at every solver step so input-power integration does not alias the switching edges.

| Test | Receiver x [m] | Mean Vout [V] | Mean Iout [A] | Input incl. loss estimate [W] | Estimated efficiency | Steady? |
|---|---:|---:|---:|---:|---:|---|
| TX1 center | 0.4572 | 59.9986 | 19.9995 | 1262.89 | 95.02% | Yes |
| TX1/TX2 seam | 0.9144 | 59.9995 | 19.9998 | 1257.31 | 95.44% | Yes |
| Predicted high-loss position | 1.6574 | 59.9991 | 19.9997 | 1262.96 | 95.01% | Yes |
| Highest required modulation | 1.7145 | 59.9989 | 19.9996 | 1258.23 | 95.37% | Yes |
| TX2/TX3 seam | 1.8288 | 59.9995 | 19.9998 | 1257.31 | 95.44% | Yes |
| TX3/TX4 seam | 2.7432 | 59.9995 | 19.9998 | 1257.31 | 95.44% | Yes |
| Seam, 5 ns solver step | 0.9144 | 59.9979 | 19.9993 | 1258.40 | 95.35% | Yes |
| Track entrance, half-pad overhang | 0.0000 | 40.3377 | 13.4459 | 575.53 | 94.24% | Yes |

All nominal in-track tests must satisfy ±0.3 V mean output error, no simultaneous complementary gates, less than 0.06 V change between the final two 2.5 ms mean-voltage windows, and less than 0.2% of load power represented by the trend in average output-capacitor energy. Endpoint capacitor-energy changes are also reported; bounded PWM/control ripple can make a single endpoint pair differ even when the mean is steady. These checks distinguish sustained input power from briefly discharging a precharged output capacitor.

Refining the solver from 10 ns to 5 ns at the seam changes mean output voltage by **0.00267%** and modeled input power by **0.09648%**. A zero-mutual-coupling run checks that the receiver cannot obtain rated power without the magnetic link. The last-seam test exercises TX4 as well as the earlier sections.

The native model is a **constant-position** circuit per run. It does not pretend that a fixed coupling coefficient validates a moving pod. The following separate reduced model uses the spatial coupling map with the output capacitor and voltage PI dynamics.

![moving handover.png](<design_dd_track/moving_handover.png>)

| Illustrative speed | Minimum DC output | Maximum DC output | Largest voltage deviation |
|---|---:|---:|---:|
| 1 m/s | 59.9762 V | 60.0302 V | 0.050% |
| 10 m/s | 59.9293 V | 60.0751 V | 0.125% |

These speed examples are not user requirements or a certified speed limit. The reduced model solves the fundamental AC network quasi-statically, retains motional `dL/dt` in the impedance, and integrates output-capacitor and PI states. It starts energized at 60 V. It omits full resonant-envelope transients, device switching, controller transport delay, position-sensor error and gate-driver dynamics. A speed-dependent, fully switched handover test remains necessary once maximum speed and sensing/communication timing are known.

## Efficiency calculation and limits

At 1200 W output and 94% efficiency, the **entire allowed loss is 76.60 W**. This includes both sides of the transfer system within the defined DC boundary.

The native model accounts for winding copper loss, Lf winding loss, compensation-capacitor ESR, switch-channel conduction and reverse conduction during dead time. The additional transmitter switching estimate uses actual switch events and Lf current from the native run. Hard turn-on uses `Vbus × Qoss` per half-bridge transition as a charge-based capacitive-loss allowance for the two devices. Favorable current direction is credited only to the extent that the dead-time current can supply `2 × Qoss`; incomplete commutation retains a residual capacitive penalty. A 5 ns voltage/current overlap estimate is added at turn-off and at non-soft turn-on. GaN reverse recovery is zero in this estimate.

This is a **postprocessed engineering loss estimate**, not a manufacturer SPICE model with nonlinear Coss and extracted PCB parasitics. A further 4 W receiver-switching allowance, gate-drive energy `Σ Qg Vg f`, 3 W auxiliary allowance, and 1 W output-capacitor loss allowance are included. There is no fixed “94% efficiency” block in the simulation.

The remaining loss margin to 94% at the tested nominal positions is **13.60 to 19.27 W**. Doubling the assumed switching-overlap time produces an estimated minimum efficiency of **94.19%**. These figures show why the target cannot be guaranteed from ideal switches or room-temperature resistance alone.

The spatial fundamental sweep uses a separate preliminary 15 W switching allowance per active TX bridge rather than the waveform-derived estimate. It checks 129 positions along the 12 ft track; sensitivity results below are restricted to the fully-on-track receiver region. They are **not** a worst-case tolerance-stack certification, and their efficiencies should not be substituted for the native table.

| Fundamental sensitivity case | Largest required modulation | Lowest budget efficiency | Voltage feasible at stated bus? |
|---|---:|---:|---|
| nominal | 0.906 | 94.81% | Yes |
| 90V_bus | 1.007 | 94.81% | No |
| caps_minus_1pct | 0.925 | 94.81% | Yes |
| caps_plus_1pct | 0.907 | 94.81% | Yes |
| Rac_plus_50pct | 0.911 | 94.27% | Yes |
| coupling_minus_20pct | 1.131 | 94.69% | No |

A modulation above 1 means the requested voltage is unattainable with the stated input limit. Efficiency entries in such rows describe the hypothetical requested operating point, not an achievable 100 V solution. The resistance perturbation scales both transfer-winding and Lf resistance. The capacitor perturbation moves all compensation capacitances together; independent component combinations are not exhausted. Installed coupling and hot AC resistance therefore remain acceptance measurements, followed by capacitor trimming and a device/thermal loss test.

## Component stress and implementation requirements

The receiver resonant capacitor sees hundreds of volts RMS and approximately 1.5 kV during startup in these tests, even though its DC output is 60 V. Use resonant capacitor banks whose **250 kHz RMS-current, AC-voltage and dissipation ratings** satisfy the measured stress; a DC voltage marking alone is insufficient.

The accompanying `component_stress.csv` lists the maximum RMS and startup peak across the rated native tests. Size all four identical branches to the largest value across the branches; the table does not imply that an untested pad-center location has lower stress. The output capacitor bank needs at least 12 A RMS ripple capability and approximately 10 mΩ or less effective ESR to support its 1 W loss allowance. Start procurement sizing around: Lf ≥ 65 A peak with hot AC resistance ≤ 6 mΩ; transfer-pad insulation ≥ 2 kV peak; Cs bank ≥ 1 kV RMS / 2 kV peak / 25 A RMS at 250 kHz; Cp banks ≥ 600 V RMS / 1 kV peak / 20 A RMS; Cf banks ≥ 350 V RMS / 630 V peak / 40 A RMS. These are minimum design targets to be checked against the exported stresses and supplier curves, not certified part selections.

Provide local DC-bus film decoupling at each bridge and a bulk input capacitor bank, receiver output bypassing, current sensing, thermal sensing, bus/output overvoltage protection and hardware gate interlock. The supplied model idealizes the input bus and sensor/driver timing; it does not design PCB parasitics, EMI filtering, protection thresholds, cooling, insulation clearances, foreign-object detection or vehicle-metal shielding. The 20 A test is a resistive rated-load test; a battery or regulated constant-power pod load needs its own load/control validation.

## Files and reproduction

- [DWPT_DD_4section_100V.slx](<DWPT_DD_4section_100V.slx>): complete native circuit; default position is the first seam.
- [build_dd_track.m](<build_dd_track.m>): reconstructs the circuit from the preserved native templates.
- [dd_track_parameters.m](<dd_track_parameters.m>): final parameter set and position lookup.
- [run_dd_track.m](<run_dd_track.m>): run, measure, estimate switching losses, and save compact results.
- [validate_dd_track.m](<validate_dd_track.m>): rated positions, all three seams, solver refinement, entry limit and zero-coupling tests.
- [show_dd_track.m](<show_dd_track.m>): MATLAB circuit/results viewer.
- [+ddtrack/FiveWindings.ssc](<+ddtrack/FiveWindings.ssc>): reciprocal five-winding magnetic component, including all cross-couplings.
- [design_dd_track/final_design.json](<design_dd_track/final_design.json>): authoritative geometry, position map and fundamental results.
- [design_dd_track/finalize_geometry.py](<design_dd_track/finalize_geometry.py>): regenerate DD geometry and tuning data.
- [design_dd_track/compensation_coil.py](<design_dd_track/compensation_coil.py>): numerical Lf winding candidate.
- [design_dd_track/moving_envelope.py](<design_dd_track/moving_envelope.py>): reduced moving-handover examples.
- [design_dd_track/tolerance_sweep.py](<design_dd_track/tolerance_sweep.py>): explicit electrical sensitivity cases.

From this project folder in MATLAB R2026b:

```matlab
show_dd_track
[m, waveforms] = run_dd_track(0.9144, 0.050, struct(), 'seam');
validate_dd_track
```

To rebuild the custom component and circuit:

```matlab
ssc_build('ddtrack');
build_dd_track;
validate_dd_track;
plot_dd_track;
```

Python geometry tools require NumPy, SciPy and Matplotlib. Run `finalize_geometry.py`, then `compensation_coil.py`, `tolerance_sweep.py` and `moving_envelope.py`; rebuilding the MATLAB model embeds the regenerated parameters. Values in the files are intentionally more precise than purchasable components so the tuning equations are reproducible. Actual coils must be measured and capacitor banks trimmed at 250 kHz.
