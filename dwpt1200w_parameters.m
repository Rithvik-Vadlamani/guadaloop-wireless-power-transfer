function p = dwpt1200w_parameters()
%DWPT1200W_PARAMETERS Provisional 50 V -> regulated 60 V, 1200 W LCC-S design.
% Transfer coil values and k are electrical design targets, not measured coils.
p.f = 250e3;
p.Vdc = 50; p.Vtarget = 60; p.RL = 3;
p.LP1 = 9.886589184213721e-6; p.LS = p.LP1; p.k = 0.6951182030563081;
p.M1 = p.k*sqrt(p.LP1*p.LS);
p.Mdesign = p.M1;
p.voltageHeadroom = 1.15;
p.LT1 = p.M1*p.Vdc/(p.Vtarget*p.voltageHeadroom);
p.CT1 = 1/((2*pi*p.f)^2*p.LT1);
p.CP1 = 1/((2*pi*p.f)^2*(p.LP1-p.LT1));
p.CS = 1/((2*pi*p.f)^2*p.LS);
p.RP1 = 0.017102114204228414; p.RS = p.RP1; p.RT1 = 0.010;
p.Cout = 2200e-6; p.initialOutputVoltage = 0;
p.RonTx = 0.003; p.RonSR = 0.003;
p.bodyVf = 0.8; p.bodyRon = 0.01; p.Goff = 1e-8;
p.samplesPerPeriod = 400; p.Ts = 1/(p.f*p.samplesPerPeriod);
p.deadTime = 40e-9; p.srDeadTime = 40e-9;
p.srThreshold = 0.25; p.srEnabled = 1;
p.softStart = 20e-3;
p.Kp = 0.015; p.Ki = 20; p.closedLoop = 1;
p.averageCycles = 1250;
p.Vavailable = p.Vdc*p.M1/p.LT1;
end
