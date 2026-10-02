function p = dwpt250k_parameters()
%DWPT250K_PARAMETERS Provisional 50 V -> regulated 60 V, 120 W LCC-S design.
% Transfer coil values and k are electrical design targets, not measured coils.
p.f = 250e3;
p.Vdc = 50; p.Vtarget = 60; p.RL = 30;
p.LP1 = 50e-6; p.LS = 50e-6; p.k = 0.25;
p.M1 = p.k*sqrt(p.LP1*p.LS);
p.Mdesign = p.M1;
p.voltageHeadroom = 1.10;
p.LT1 = p.M1*p.Vdc/(p.Vtarget*p.voltageHeadroom);
p.CT1 = 1/((2*pi*p.f)^2*p.LT1);
p.CP1 = 1/((2*pi*p.f)^2*(p.LP1-p.LT1));
p.CS = 1/((2*pi*p.f)^2*p.LS);
p.RP1 = 0.20; p.RS = 0.20; p.RT1 = 0.07;
p.Cout = 470e-6; p.initialOutputVoltage = 0;
p.RonTx = 0.01; p.RonSR = 0.01;
p.bodyVf = 0.8; p.bodyRon = 0.01; p.Goff = 1e-8;
p.samplesPerPeriod = 400; p.Ts = 1/(p.f*p.samplesPerPeriod);
p.deadTime = 40e-9; p.srDeadTime = 40e-9;
p.srThreshold = 0.10; p.srEnabled = 1;
p.softStart = 20e-3;
p.Kp = 0.015; p.Ki = 20; p.closedLoop = 1;
p.averageCycles = 100;
p.Vavailable = p.Vdc*p.M1/p.LT1;
end
