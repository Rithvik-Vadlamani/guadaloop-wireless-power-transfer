function p = dwpt_parameters()
%DWPT_PARAMETERS Original circuit values in SI units, plus simulation settings.
% Edit these values and run run_dwpt to apply them to DWPT_fixed.
p.f = 85e3;                 % Inverter switching frequency [Hz]
p.samplesPerPeriod = 400;   % 49.5% pulse = 198 steps; dead time = 2 steps
p.Ts = 1/(p.f*p.samplesPerPeriod);
p.Fs = 1/p.Ts;
p.LP1 = 437.3e-6; p.LP2 = 420.6e-6; p.LS = 306e-6;
p.LT1 = 98e-6; p.LT2 = 99.5e-6;
p.CP1 = 9.03e-9; p.CP2 = 9.23e-9;
p.CT1 = 55e-9; p.CT2 = 54e-9; p.CS = 12.5e-9;
p.M1 = 94e-6; p.M2 = 0;    % Fixed-position coupling; no motion law supplied
p.RP1 = 1.4; p.RP2 = 1.4; p.RS = 1.3;
p.RL = 30; p.Vdc = 50;
p.averageCycles = 100;     % Display averaging window, 1.176 ms
end
