function finish_runs()
r=fileparts(fileparts(mfilename('fullpath')));addpath(r);
cases={.4572,'center';1.65735,'loss_worst';1.7145,'voltage_worst';1.8288,'middle_seam';2.7432,'last_seam';0,'entry_edge'};
for j=1:size(cases,1)
 m=run_dd_track(cases{j,1},.05,struct(),cases{j,2});
 assert(m.steady_state && ~m.gate_overlap);
 if j<size(cases,1),assert(m.regulated && m.eta_budget>=.94);else,assert(~m.regulated);end
end
p=dd_track_parameters(.9144);L=p.Lmat;L(1:4,5)=0;L(5,1:4)=0;run_dd_track(.9144,.005,struct('Lmat',L),'zero_coupling');
plot_dd_track;final_qa;
fprintf('FINAL RUNS AND QA COMPLETE\n');
end
