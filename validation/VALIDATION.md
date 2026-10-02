# DWPT validation summary

Validated in MATLAB/Simulink R2026b on this Mac.

## Final model and solver

Use `DWPT_fixed.slx`. The original `DWPT.slx` is retained.
The final configuration uses Simscape local implicit trapezoidal integration and a global fixed-step ode3 solver. Step: 2.94117647059e-08 s, or 400 steps per 85 kHz switching period. The global solver integrates the diagnostic/filter states; the local solver integrates the electrical network.

## Full 70 ms simulation

Results averaged from 68.823529 to 70.000000 ms (100 switching cycles):

| Quantity | Result |
|---|---:|
| Mean load voltage | 27.378851 V |
| Mean load current | 0.912628 A |
| Mean DC input power | 32.547756 W |
| Mean load power | 24.986715 W |
| Window power efficiency | 76.769395% |
| Load-voltage peak-to-peak over window | 3.508463 mV |

The peak-to-peak number includes any residual settling over that window. The plotted response approaches a plateau; this is not a formal proof of steady state or a hardware efficiency measurement.

## Completed checks

- The native model compiles and completes the full 70 ms run.
- Halving the step from 400 to 800 samples/period in a **5 ms startup comparison** changes load power by 0.018088% and input power by 0.026945%. Both are below the 1% acceptance threshold. The refined-step test was not repeated over the full 70 ms duration.
- Load power agrees with time-averaged Vload²/RL to relative error 1.42e-16.
- With M1 = M2 = 0, the 2 ms test gives exactly zero receiver voltage/current/power.
- A nonphysical mutual inductance is rejected before simulation.
- Direct Ts overrides are rejected; change f or samplesPerPeriod instead.
- All four delivered MATLAB source files pass Code Analyzer with zero findings.
- Static SLX inspection found zero remaining SPS block references, zero conversion helper parameter expressions, and zero disabled library links. ZIP integrity passed.

## Evidence and reproduction

Run `validate_dwpt` to repeat the physical/numerical checks. Run `repair_dwpt` only to regenerate the repaired SLX from the intermediate conversion. The build can print library-parameter override notices when increasing measurement history buffers; the saved final model contains no disabled library links.

- `full_run_metrics.json`: full-run measurements and parameters.
- `checks.json`: baseline/refined and zero-coupling measurements.
- `startup_response.png`: voltage/current startup plots.
- `load_trace.csv`: decimated plot trace, not the raw waveform used for metrics or ripple calculations.
- `final_validation.log` and `delivery_check.log`: execution evidence.
- `history/`: preliminary solver experiments and failed conversion/initialization attempts. These are historical diagnostics, not results for the delivered configuration.

The old SPS model cannot serve as a validated waveform baseline in the installed release. Numerical checks establish that the repaired model runs consistently under the tested conditions; they do not establish that its coil, semiconductor, or load parameters represent a particular physical prototype. No motion model or control system was added.

Original file SHA-256 (for future identification): `9e1465d10721d791d0e09c68f3f6e76b7e85f4081c6162ff23bbda5786e610bf`
