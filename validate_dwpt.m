function validate_dwpt()
%VALIDATE_DWPT End-to-end physical and numerical checks of the repaired model.
root=fileparts(mfilename('fullpath'));folder=fullfile(root,'validation');
if ~isfolder(folder),mkdir(folder);end
for f=["dwpt_parameters.m","repair_dwpt.m","run_dwpt.m","validate_dwpt.m"]
    issues=checkcode(fullfile(root,f),'-id');
    fprintf('%s: %d code analyzer findings\n',f,numel(issues));
    for k=1:numel(issues),disp(issues(k));end
end
[~,baseline]=run_dwpt(0.005,struct(),false);
[~,finer]=run_dwpt(0.005,struct('samplesPerPeriod',800),false);
convergence=abs(finer.Pload_W-baseline.Pload_W)/max(finer.Pload_W,eps);
assert(convergence<0.01,'Load power changed by more than 1%% when step was halved.');
inputConvergence=abs(finer.Pin_W-baseline.Pin_W)/max(finer.Pin_W,eps);
assert(inputConvergence<0.01,'Input power changed by more than 1%% when step was halved.');
[out,full]=run_dwpt(0.07,struct(),false);
assert(full.Pin_W>0 && full.Pload_W>0 && full.efficiency_percent<100);
assert(full.load_identity_relative_error<1e-6);
save(fullfile(folder,'full_run_metrics.mat'),'full');
fid=fopen(fullfile(folder,'full_run_metrics.json'),'w');
fprintf(fid,'%s',jsonencode(full,PrettyPrint=true));fclose(fid);
% Export a compact plot and sampled trace; don't retain multi-million-point logs.
t=out.load_voltage.Time;v=out.load_voltage.Data(:);i=out.load_current.Data(:);
idx=unique([1:100:numel(t),numel(t)]);
f=figure('Visible','off');tiledlayout(2,1);
nexttile;plot(t(idx)*1e3,v(idx));ylabel('Load voltage [V]');grid on;
nexttile;plot(t(idx)*1e3,i(idx));ylabel('Load current [A]');xlabel('Time [ms]');grid on;
exportgraphics(f,fullfile(folder,'startup_response.png'),'Resolution',160);close(f);
writetable(table(t(idx),v(idx),i(idx),'VariableNames',{'time_s','load_voltage_V','load_current_A'}), ...
    fullfile(folder,'load_trace.csv'));
clear out t v i;
[~,uncoupled]=run_dwpt(0.002,struct('M1',0,'M2',0),false);
assert(uncoupled.Pload_W<1e-6,'Uncoupled receiver unexpectedly receives power.');
% Invalid mutual inductance must be rejected before running Simulink.
rejected=false;
try
    run_dwpt(0.001,struct('M1',1),false);
catch e
    rejected=strcmp(e.identifier,'DWPT:InvalidCoupling');
end
assert(rejected,'Invalid coupling was not rejected.');
save(fullfile(folder,'checks.mat'),'baseline','finer','uncoupled','convergence','inputConvergence','rejected');
fid=fopen(fullfile(folder,'checks.json'),'w');
fprintf(fid,'%s',jsonencode(struct('baseline',baseline,'finer',finer, ...
    'uncoupled',uncoupled,'power_relative_change',convergence,'input_power_relative_change',inputConvergence, ...
    'invalid_coupling_rejected',rejected),PrettyPrint=true));fclose(fid);
fprintf('ALL VALIDATION CHECKS PASSED. Relative convergence change: %.6g\n',convergence);
end
