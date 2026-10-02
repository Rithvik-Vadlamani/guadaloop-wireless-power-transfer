function [out, metrics] = run_dwpt(stopTime, overrides, makePlot)
%RUN_DWPT Simulate repaired circuit and calculate time-weighted real power.
% [out,metrics] = run_dwpt();               % original 70 ms duration
% [out,metrics] = run_dwpt(0.005);          % short startup check
% [out,metrics] = run_dwpt(0.07,struct('M2',40e-6));
% Circuit parameters are in dwpt_parameters.m; all quantities use SI units.
if nargin<1,stopTime=0.07;end
if nargin<2,overrides=struct();end
if nargin<3,makePlot=true;end
validateattributes(stopTime,{'numeric'},{'scalar','real','finite','positive'});
p=dwpt_parameters();
for k=string(fieldnames(overrides))'
    assert(isfield(p,k),'DWPT:UnknownParameter','Unknown parameter: %s',k);
    assert(~ismember(k,["Ts","Fs"]),'DWPT:DerivedParameter', ...
        'Set f or samplesPerPeriod; %s is derived.',k);
    p.(k)=overrides.(k);
end
for k=string(fieldnames(p))'
    validateattributes(p.(k),{'numeric'},{'scalar','real','finite'},mfilename,k);
    if ~ismember(k,["M1","M2"]),assert(p.(k)>0,'%s must be positive',k);end
end
validateattributes(p.averageCycles,{'numeric'},{'integer','positive'});
assert(stopTime>=1/p.f,'Simulation must cover at least one switching period.');
assert(mod(p.samplesPerPeriod,200)==0,'samplesPerPeriod must be a multiple of 200.');
p.Ts=1/(p.f*p.samplesPerPeriod);p.Fs=1/p.Ts;
L=[p.LP1 0 p.M1;0 p.LP2 p.M2;p.M1 p.M2 p.LS];
[~,flag]=chol(L);assert(flag==0,'DWPT:InvalidCoupling','Inductance matrix must be positive definite.');
root=fileparts(mfilename('fullpath'));m='DWPT_fixed';
load_system(fullfile(root,[m '.slx']));
in=Simulink.SimulationInput(m);
for k=string(fieldnames(p))',in=in.setVariable(k,p.(k),'Workspace',m);end
in=in.setModelParameter('StopTime',num2str(stopTime,17));
out=sim(in);
t=out.load_voltage.Time;v=out.load_voltage.Data(:);
i=out.load_current.Data(:);vi=out.dc_voltage.Data(:);ii=out.dc_current.Data(:);
assert(isequal(t,out.load_current.Time,out.dc_voltage.Time,out.dc_current.Time), ...
    'Measurement time bases differ.');
assert(all(isfinite([t;v;i;vi;ii])),'Nonfinite simulation results.');
% Final integer number of switching periods, at most 100 and at most 20%
% of the run. These are window metrics, not a claim of steady state.
n=max(1,min(p.averageCycles,floor(0.2*stopTime*p.f)));
a=max(t(1),t(end)-n/p.f);b=t(end);
q=[a;t(t>a & t<b);b];
vq=interp1(t,v,q);iq=interp1(t,i,q);
vinq=interp1(t,vi,q);iinq=interp1(t,ii,q);
avg=@(x)trapz(q,x)/(b-a);
metrics.window_s=[a b];metrics.cycles=n;
metrics.Vload_mean_V=avg(vq);metrics.Vload_rms_V=sqrt(avg(vq.^2));
metrics.Iload_mean_A=avg(iq);metrics.Pin_W=avg(vinq.*iinq);
metrics.Pload_W=avg(vq.*iq);
metrics.load_identity_relative_error=abs(metrics.Pload_W-avg(vq.^2)/p.RL)/max(metrics.Pload_W,eps);
metrics.efficiency_percent=NaN;
if metrics.Pin_W>eps,metrics.efficiency_percent=100*metrics.Pload_W/metrics.Pin_W;end
metrics.Vload_peak_to_peak_V=max(vq)-min(vq);
metrics.parameters=p;
disp(rmfield(metrics,'parameters'));
if makePlot
    figure('Name','DWPT: source and load measurements');
    tiledlayout(3,1);
    nexttile;plot(t*1e3,v);ylabel('Load voltage [V]');grid on;
    nexttile;plot(t*1e3,i);ylabel('Load current [A]');grid on;
    nexttile;plot(t*1e3,vi.*ii,t*1e3,v.*i);
    ylabel('Instantaneous power [W]');xlabel('Time [ms]');
    legend('DC source','Load');grid on;
end
end
