function results=validate_dwpt1200w(reuseSavedNominal)
%VALIDATE_DWPT250K Startup, gate timing, passivity, diode and step-size checks.
root=fileparts(mfilename('fullpath'));folder=fullfile(root,'design1200w');
if nargin<1,reuseSavedNominal=false;end
if reuseSavedNominal
    s=load(fullfile(folder,'nominal.mat'),'metrics');results.nominal=s.metrics;
else
    [out,metrics]=run_dwpt1200w(.03,struct(),false);
    results.nominal=metrics;
    save(fullfile(folder,'nominal.mat'),'out','metrics','-v7.3');
    fid=fopen(fullfile(folder,'nominal_metrics.json'),'w');
    fprintf(fid,'%s',jsonencode(metrics,PrettyPrint=true));fclose(fid);
    clear out
    plot_dwpt1200w();
end
cases={ 'body_diodes',struct('srEnabled',0),.03; ...
    'fine_step',struct('samplesPerPeriod',800),.03; ...
    'zero_coupling',struct('k',0),.001};
for j=1:size(cases,1)
    name=cases{j,1};[~,metrics]=run_dwpt1200w(cases{j,3},cases{j,2},false);
    results.(name)=metrics;
    save(fullfile(folder,[name '_metrics.mat']),'metrics');
    fid=fopen(fullfile(folder,[name '_metrics.json']),'w');
    fprintf(fid,'%s',jsonencode(metrics,PrettyPrint=true));fclose(fid);
end
for name=["nominal","body_diodes","fine_step"]
    a=results.(name);
    assert(abs(a.target_error_percent)<1,'Output outside 1%% target.');
    assert(~a.gate_overlap && a.minimum_tx_deadtime_s>=39.9e-9);
    if name~="body_diodes",assert(a.minimum_sr_deadtime_s>=39.9e-9);end
    assert(a.gross_energy_margin_J>=-1e-6,'Energy balance failed.');
    assert(a.rectifier_loss_W>=0 && a.Pin_W>a.Pload_W);
    assert(a.load_identity_relative_error<1e-8);
    assert(a.output_cap_power_fraction<0.005,'Output capacitor is still materially charging/discharging.');
end
assert(results.zero_coupling.maximum_output_voltage_V<1e-5);
assert(results.nominal.rectifier_loss_W<results.body_diodes.rectifier_loss_W);
results.step_change_output_percent=100*abs(results.fine_step.Vload_mean_V/results.nominal.Vload_mean_V-1);
results.step_change_input_power_percent=100*abs(results.fine_step.Pin_W/results.nominal.Pin_W-1);
assert(results.step_change_output_percent<1 && results.step_change_input_power_percent<1);
results.passed=true;
fid=fopen(fullfile(folder,'validation_results.json'),'w');
fprintf(fid,'%s',jsonencode(results,PrettyPrint=true));fclose(fid);
disp('All 250 kHz design checks passed.');
end
