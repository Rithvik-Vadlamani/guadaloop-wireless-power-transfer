function validate_dd_track()
% Reproduce the final native switched-circuit verification suite.
r=fileparts(mfilename('fullpath'));d=jsondecode(fileread(fullfile(r,'design_dd_track','final_design.json')));
valid=d.x_m>=.4572 & d.x_m<=3.2004;ix=find(valid);[~,a]=max([d.cases(valid).max_modulation]);[~,b]=min([d.cases(valid).eta]);
cases={.4572,'center';.9144,'seam';d.x_m(ix(b)),'loss_worst';d.x_m(ix(a)),'voltage_worst';1.8288,'middle_seam';2.7432,'last_seam'};
for j=1:size(cases,1)
 m=run_dd_track(cases{j,1},.050,struct(),cases{j,2});
 assert(m.steady_state && m.regulated && ~m.gate_overlap,'Electrical validation failed: %s',cases{j,2});
 assert(m.eta_budget>=.94,'Estimated efficiency below target: %s',cases{j,2});
end
m=run_dd_track(.9144,.050,struct('Ts',5e-9),'seam_fine');assert(m.steady_state && m.regulated);
m=run_dd_track(0,.050,struct(),'entry_edge');assert(m.steady_state && ~m.regulated,'Expected end-of-track voltage limit was not observed');
p=dd_track_parameters(.9144);L=p.Lmat;L(1:4,5)=0;L(5,1:4)=0;
m=run_dd_track(.9144,.005,struct('Lmat',L),'zero_coupling');assert(abs(m.Vout)<.01,'Zero coupling test failed');
a=jsondecode(fileread(fullfile(r,'design_dd_track','seam_metrics.json')));b=jsondecode(fileread(fullfile(r,'design_dd_track','seam_fine_metrics.json')));
assert(abs(a.Vout/b.Vout-1)<.002 && abs(a.Pin_conduction/b.Pin_conduction-1)<.002,'Time-step convergence failed');
fprintf('FINAL VALIDATION PASSED: regulated steady states, loss estimates, gate timing, timestep refinement, zero coupling. End-of-track limit documented.\n');
end
