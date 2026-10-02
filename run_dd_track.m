function [metrics,compact]=run_dd_track(position,stopTime,overrides,label)
% Run native switched circuit from zero stored energy, then audit steady state.
% position: receiver center [m] from track beginning. E.g. .4572 center, .9144 seam.
if nargin<1,position=.9144;end
if nargin<2,stopTime=.050;end
if nargin<3,overrides=struct();end
if nargin<4,label='seam';end
root=fileparts(mfilename('fullpath'));m='DWPT_DD_4section_100V';load_system(fullfile(root,[m '.slx']));
p=dd_track_parameters(position);for k=string(fieldnames(overrides))',assert(isfield(p,k),'Unknown parameter');p.(k)=overrides.(k);end
assert(p.Vdc<=100 && p.Vdc>0,'Input cannot exceed 100 V.');
validateattributes(stopTime,{'numeric'},{'scalar','real','finite','positive'});
for field=["f","RL","Lf","Cf","Cp","Cs","Rcoil","Rf","ESRf","ESRp","ESRs","RonTx","RonSR","Cout","Ts","softStart"]
 validateattributes(p.(field),{'numeric'},{'scalar','real','finite','positive'});
end
assert(isequal(size(p.Lmat),[5 5]) && all(isfinite(p.Lmat),'all') && norm(p.Lmat-p.Lmat','fro')<1e-12 && min(eig(p.Lmat))>0,'Inductance matrix must be symmetric positive definite.');
N=1/(p.f*p.Ts);assert(abs(N-round(N))<1e-8 && mod(round(N),4)==0,'Use an integer multiple of four samples per carrier.');
for deadTime=[p.deadTime p.srDeadTime]
 assert(deadTime>=p.Ts && deadTime<.1/p.f && abs(deadTime/p.Ts-round(deadTime/p.Ts))<1e-8,'Resolve dead time with integer solver steps.');
end
assert(all(p.u_nom>=0) && max(p.u_nom)>0,'Invalid phase-shift feedforward weights.');

in=Simulink.SimulationInput(m);for k=string(fieldnames(p))',in=in.setVariable(k,p.(k),'Workspace',m);end
in=in.setBlockParameter([m '/bus_current'],'Decimation','1');
in=in.setModelParameter('StopTime',num2str(stopTime,17),'SimscapeLogType','none');
Simulink.sdi.clear;timer=tic;out=sim(in);metrics.wall_seconds=toc(timer);
% MATLAB Function column-vector outputs can be stored channels-by-1-by-time.
names=out.who;signals=struct();
for kk=1:numel(names)
 z=out.(names{kk});if ~isa(z,'timeseries'),continue;end
 dat=z.Data;nt=numel(z.Time);
 if size(dat,1)~=nt && size(dat,ndims(dat))==nt
  dat=permute(dat,[ndims(dat),1:ndims(dat)-1]);dat=reshape(dat,nt,[]);
  z=timeseries(dat,z.Time);
 end
 signals.(names{kk})=z;
end
out=signals;clear signals;
t=out.output_voltage.Time;v=out.output_voltage.Data(:);a=max(0,stopTime-.020);q=t>=a;tq=t(q);avg=@(x)trapz(tq,x)/(tq(end)-tq(1));
metrics.position_m=position;metrics.window_s=[tq(1) tq(end)];metrics.Vout=avg(v(q));metrics.Iout=metrics.Vout/p.RL;metrics.Pout=avg(v(q).^2/p.RL);
ti=out.bus_current.Time;qi=ti>=a;ip=out.bus_current.Data(:);metrics.Pin_conduction=trapz(ti(qi),p.Vdc*ip(qi))/(ti(find(qi,1,'last'))-ti(find(qi,1)));metrics.eta_conduction=metrics.Pout/metrics.Pin_conduction;
metrics.Vpp=max(v(q))-min(v(q));metrics.Vmax=max(v);metrics.capacitor_power_W=.5*p.Cout*(v(end)^2-v(find(q,1))^2)/(tq(end)-tq(1));
metrics.Vmean_last_half=mean(v(t>=stopTime-.0025));metrics.Vmean_previous_half=mean(v(t>=stopTime-.005 & t<stopTime-.0025));
metrics.capacitor_trend_power_W=.5*p.Cout*(mean(v(t>=stopTime-.0025).^2)-mean(v(t>=stopTime-.005 & t<stopTime-.0025).^2))/.0025;
metrics.steady_state=abs(metrics.capacitor_trend_power_W)<.002*max(metrics.Pout,1) && abs(metrics.Vmean_last_half-metrics.Vmean_previous_half)<.06;
metrics.regulated=abs(metrics.Vout-60)<.3;metrics.modulation=mean(out.modulation.Data(q,:),1);
g=out.tx_gates.Data;metrics.gate_overlap=any(g(:,1:2:end)>0.5 & g(:,2:2:end)>0.5,'all') || any(out.sr_positive.Data(:)>0.5 & out.sr_negative.Data(:)>0.5);
assert(~metrics.gate_overlap,'Gate overlap');
metrics.min_tx_deadtime_s=Inf;
for j=1:2:16
 metrics.min_tx_deadtime_s=min(metrics.min_tx_deadtime_s,dead(t,g(:,j),g(:,j+1)));
end
metrics.min_sr_deadtime_s=dead(t,out.sr_positive.Data(:),out.sr_negative.Data(:));
names=fieldnames(out);compact=struct();
for k=1:numel(names)
 x=out.(names{k});if ~isa(x,'timeseries'),continue;end
 dat=x.Data;ti=x.Time;qi=ti>=a;if size(dat,1)~=numel(ti),continue;end
 avgi=@(z)trapz(ti(qi),z)/(ti(find(qi,1,'last'))-ti(find(qi,1)));
 if ~contains(names{k},{'gates','modulation','sr_','reference'})
  metrics.([names{k} '_rms'])=sqrt(avgi(dat(qi,:).^2));metrics.([names{k} '_peak'])=max(abs(dat),[],1);
 end
 stride=max(1,round(1e-6/(ti(2)-ti(1))));idx=unique([1:stride:numel(ti),find(ti>=stopTime-100/p.f)']);compact.(names{k})=timeseries(dat(idx,:),ti(idx));
end
% Datasheet-anchored switching estimate from actual gate/current samples.
% Capacitance is NOT in native switch model. Charge-based bound Qoss*V per
% hard turn-on counts both devices of a leg; soft events need sufficient charge.
Q=p.QossTx;tr=p.transitionTime;capLoss=0;overlapLoss=0;hardCount=0;onCount=0;
for k=1:4
 ii=out.(sprintf('lf%d_current',k)).Data(:);
 for j=1:4
  gate=g(:,4*(k-1)+j)>.5;
  on=find(diff([false;gate])==1 & t>=a);off=diff([false;gate])==-1 & t>=a;
  currents=ii(on);direction=[1 -1 -1 1];hard=direction(j)*currents>0;
  residual=ones(size(currents));residual(~hard)=max(0,1-abs(currents(~hard))*p.deadTime/(2*Q));
  capLoss=capLoss+sum(p.Vdc*Q*residual.^2)/(tq(end)-tq(1));
  overlapLoss=overlapLoss+.5*p.Vdc*tr*(sum(abs(currents).*residual)+sum(abs(ii(off))))/(tq(end)-tq(1));
  hardCount=hardCount+sum(hard);onCount=onCount+numel(on);
 end
end
nactive=sum(metrics.modulation>.003);
metrics.TX_capacitive_estimate_W=capLoss;metrics.TX_overlap_estimate_W=overlapLoss;
metrics.TX_hard_turnon_fraction=hardCount/max(onCount,1);
metrics.allowance_TX_switch_W=capLoss+overlapLoss;metrics.allowance_RX_switch_W=4;
metrics.gate_power_W=p.f*(4*26e-9*5*nactive+4*152e-9*10);
metrics.aux_power_W=3;metrics.output_cap_ESR_allowance_W=1;
metrics.extra_allowance_W=metrics.allowance_TX_switch_W+metrics.allowance_RX_switch_W+metrics.gate_power_W+4;
metrics.Pin_budget=metrics.Pin_conduction+metrics.extra_allowance_W;
metrics.eta_budget=metrics.Pout/metrics.Pin_budget;
metrics.additional_loss_margin_to_94_W=metrics.Pout/.94-metrics.Pin_budget;
metrics.eta_if_transition_time_doubled=metrics.Pout/(metrics.Pin_budget+overlapLoss);
metrics.parameters=p;disp(rmfield(metrics,'parameters'));
folder=fullfile(root,'design_dd_track');fid=fopen(fullfile(folder,[label '_metrics.json']),'w');fprintf(fid,'%s',jsonencode(metrics,PrettyPrint=true));fclose(fid);
save(fullfile(folder,[label '_waveforms.mat']),'compact','metrics','-v7');
clear out;Simulink.sdi.clear;
end
function gap=dead(t,a,b)
gap=Inf;a=a>.5;b=b>.5;
for k=1:2
 rise=find(diff([false;a])==1);fall=find(diff([false;b])==-1);
 if numel(fall)>=2 && ~isempty(rise),last=interp1(t(fall),t(fall),t(rise),'previous',NaN);valid=isfinite(last);if any(valid),gap=min(gap,min(t(rise(valid))-last(valid)));end,end
 x=a;a=b;b=x;
end
end
