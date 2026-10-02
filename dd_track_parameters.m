function p=dd_track_parameters(position)
% Air-core DD-to-DD design, position measured from track's left end [m].
% Constant-position model. No moving-inductance mechanical power approximation.
if nargin<1,position=.9144;end
r=fileparts(mfilename('fullpath'));d=load(fullfile(r,'design_dd_track','dd_parameters.mat'));
p.f=250e3;p.Vdc=100;p.Vtarget=60;p.RL=3;p.Lf=d.Lf;p.Cf=d.Cf;p.Cp=d.Cp;p.Cs=d.Cs;
p.Rcoil=d.Rcoil;p.Rf=.006;p.ESRf=.003;p.ESRp=.005;p.ESRs=.005;
p.RonTx=.005*1.6;p.RonSR=.002*1.6;p.bodyVf=.8;p.bodyRon=.01;p.Goff=1e-8;
p.bodyVfTx=2;p.bodyRonTx=.008;p.QossTx=145e-9;p.transitionTime=5e-9;
p.Cout=2200e-6;p.initialOutputVoltage=0;p.Ts=10e-9;p.deadTime=20e-9;p.srDeadTime=40e-9;p.srThreshold=.25;p.srEnabled=1;
p.softStart=.020;p.Kp=.012;p.Ki=15;p.position=position;
p.Lmat=zeros(5);for a=1:5,for b=1:5,p.Lmat(a,b)=interp1(d.x_grid,squeeze(d.L_grid(a,b,:)),position);end,end
p.u_nom=interp1(d.x_grid,d.u_grid,position);
assert(all(isfinite(p.Lmat(:))) && min(eig(p.Lmat))>0,'Position out of map or nonpassive inductance matrix.');
end
