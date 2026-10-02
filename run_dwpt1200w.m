function [out, metrics] = run_dwpt1200w(stopTime, overrides, makePlot)
%RUN_DWPT250K Simulate the single-TX, 250 kHz, synchronous-rectifier model.
% [out,metrics] = run_dwpt1200w();
% [out,metrics] = run_dwpt1200w(0.03,struct('srEnabled',0)); % body-diode comparison
% Overrides change hardware/conditions without automatically retuning capacitors.
if nargin<1,stopTime=0.03;end
if nargin<2,overrides=struct();end
if nargin<3,makePlot=true;end
validateattributes(stopTime,{'numeric'},{'scalar','real','finite','positive'});
p=dwpt1200w_parameters();
for k=string(fieldnames(overrides))'
    assert(isfield(p,k),'DWPT250k:UnknownParameter','Unknown parameter: %s',k);
    assert(~ismember(k,["Ts","M1","Vavailable","Mdesign","voltageHeadroom"]), ...
        'DWPT250k:DerivedParameter','%s is derived; change its inputs instead.',k);
    p.(k)=overrides.(k);
end
for k=string(fieldnames(p))'
    validateattributes(p.(k),{'numeric'},{'scalar','real','finite'},mfilename,k);
end
positive=["f","Vdc","Vtarget","RL","LP1","LS","LT1","CT1","CP1","CS", ...
    "RP1","RS","RT1","Cout","RonTx","RonSR","bodyRon","Goff","softStart"];
for k=positive,assert(p.(k)>0,'%s must be positive.',k);end
assert(p.k>=0 && p.k<1,'Coupling k must be in [0,1).');
assert(p.LT1<p.LP1,'LCC compensation requires LT1 < LP1.');
assert(mod(p.samplesPerPeriod,200)==0 && p.samplesPerPeriod>=200);
validateattributes(p.averageCycles,{'numeric'},{'integer','positive'});
assert(p.initialOutputVoltage>=0 && p.bodyVf>=0 && p.srThreshold>=0 && p.Kp>=0 && p.Ki>=0);
assert(ismember(p.closedLoop,[0 1]) && ismember(p.srEnabled,[0 1]));
p.Ts=1/(p.f*p.samplesPerPeriod);
p.M1=p.k*sqrt(p.LP1*p.LS);
p.Vavailable=p.Vdc*p.Mdesign/p.LT1;
assert(stopTime>=1/p.f);
for d=[p.deadTime p.srDeadTime]
    assert(d>=p.Ts && d<0.1/p.f,'Dead time must resolve at least one step and be <10%% period.');
    assert(abs(d/p.Ts-round(d/p.Ts))<1e-8,'Dead time must be an integer number of steps.');
end
root=fileparts(mfilename('fullpath'));m='DWPT_250k_60V_1200W';
load_system(fullfile(root,[m '.slx']));
in=Simulink.SimulationInput(m);
for k=string(fieldnames(p))',in=in.setVariable(k,p.(k),'Workspace',m);end
in=in.setModelParameter('StopTime',num2str(stopTime,17));
timer=tic;out=sim(in);metrics.wall_seconds=toc(timer);
t=out.load_voltage.Time;v=out.load_voltage.Data(:);
assert(all(isfinite(v)),'Nonfinite output voltage.');
n=max(1,min(p.averageCycles,floor(0.2*stopTime*p.f)));
a=max(t(1),t(end)-n/p.f);b=t(end);
q=[a;t(t>a & t<b);b];
sample=@(name)interp1(out.(name).Time,out.(name).Data(:),q);
avg=@(x)trapz(q,x)/(b-a);
vq=sample('load_voltage');iq=sample('load_current');
metrics.window_s=[a b];metrics.cycles=n;
metrics.Vload_mean_V=avg(vq);metrics.Iload_mean_A=avg(iq);
metrics.Pload_W=avg(vq.*iq);
metrics.Pin_W=avg(sample('dc_voltage').*sample('dc_current'));
metrics.efficiency_percent=NaN;
if metrics.Pin_W>eps,metrics.efficiency_percent=100*metrics.Pload_W/metrics.Pin_W;end
metrics.rectifier_input_W=avg(sample('rect_ac_voltage').*sample('rect_ac_current'));
metrics.rectifier_output_W=avg(vq.*sample('rect_dc_current'));
metrics.rectifier_loss_W=metrics.rectifier_input_W-metrics.rectifier_output_W;
metrics.Vload_peak_to_peak_V=max(vq)-min(vq);
metrics.maximum_output_voltage_V=max(v);
metrics.target_error_percent=100*(metrics.Vload_mean_V-p.Vtarget)/p.Vtarget;
metrics.modulation=avg(sample('modulation'));
metrics.load_identity_relative_error=abs(metrics.Pload_W-avg(vq.^2)/p.RL)/max(metrics.Pload_W,eps);
metrics.gate_overlap=false;
for pair={ {'tx_gate1','tx_gate2'}, {'tx_gate3','tx_gate4'}, {'sr_positive','sr_negative'} }
    names=pair{1};x=out.(names{1});y=out.(names{2});
    assert(isequal(x.Time,y.Time),'Gate time bases differ.');
    metrics.gate_overlap=metrics.gate_overlap || any(x.Data(:)>0.5 & y.Data(:)>0.5);
end
assert(~metrics.gate_overlap,'Simultaneous complementary gate conduction.');
for name=["tx_coil_current","tx_input_current","rect_ac_current","cp1_voltage", ...
        "ct1_voltage","cs_voltage","tx_coil_voltage","rx_coil_voltage","comp_inductor_voltage"]
    values=sample(name);
    metrics.([char(name) '_rms'])=sqrt(avg(values.^2));
    metrics.([char(name) '_peak_all'])=max(abs(out.(name).Data(:)));
end
metrics.input_energy_J=trapz(out.dc_voltage.Time,out.dc_voltage.Data(:).*out.dc_current.Data(:));
metrics.load_energy_J=trapz(t,v.*out.load_current.Data(:));
metrics.output_cap_energy_increase_J=0.5*p.Cout*(v(end)^2-p.initialOutputVoltage^2);
metrics.gross_energy_margin_J=metrics.input_energy_J-metrics.load_energy_J-metrics.output_cap_energy_increase_J;
metrics.minimum_tx_deadtime_s=min(deadtime(out.tx_gate1,out.tx_gate2),deadtime(out.tx_gate3,out.tx_gate4));
metrics.minimum_sr_deadtime_s=deadtime(out.sr_positive,out.sr_negative);
metrics.output_cap_mean_power_W=0.5*p.Cout*(vq(end)^2-vq(1)^2)/(b-a);
metrics.output_cap_power_fraction=abs(metrics.output_cap_mean_power_W)/max(metrics.Pload_W,eps);
metrics.parameters=p;
disp(rmfield(metrics,'parameters'));
if makePlot
    figure('Name','250 kHz LCC-S: regulated 60 V with synchronous rectification');
    tiledlayout(3,1);
    nexttile;plot(t*1e3,v);hold on;plot(out.voltage_reference.Time*1e3,out.voltage_reference.Data,'--');
    ylabel('Output [V]');legend('Load','Reference');grid on;
    nexttile;plot(out.load_current.Time*1e3,out.load_current.Data);ylabel('Load [A]');grid on;
    nexttile;plot(out.modulation.Time*1e3,out.modulation.Data);ylabel('Modulation');xlabel('Time [ms]');grid on;
end
end

function gap=deadtime(a,b)
x=a.Data(:)>0.5;y=b.Data(:)>0.5;t=a.Time;
gap=Inf;
for direction=1:2
    rising=find(diff([false;x])==1);
    falling=find(diff([false;y])==-1);
    if numel(falling)>=2 && ~isempty(rising)
        lastFall=interp1(t(falling),t(falling),t(rising),'previous',NaN);
        valid=isfinite(lastFall);
        if any(valid),gap=min(gap,min(t(rising(valid))-lastFall(valid)));end
    end
    temp=x;x=y;y=temp;
end
end
