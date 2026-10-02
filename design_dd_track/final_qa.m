function final_qa()
r=fileparts(fileparts(mfilename('fullpath')));addpath(r);m='DWPT_DD_4section_100V';load_system(fullfile(r,[m '.slx']));
q=find_system(m,'LookUnderMasks','all','FollowLinks','on','Name','MOSFET');assert(numel(q)==20,'Expected 16 TX and 4 receiver switches.');
bs=find_system(m,'SearchDepth',1,'Regexp','on','Name','^Section [1-4] bridge and LCC$');assert(numel(bs)==4);
p=dd_track_parameters();assert(p.Vdc==100 && p.f==250e3 && p.RL==3);assert(abs(p.Cf-100e-9)<1e-15);assert(min(eig(p.Lmat))>0);
for n={'build_dd_track.m','dd_track_parameters.m','run_dd_track.m','validate_dd_track.m','plot_dd_track.m','show_dd_track.m'}
 z=checkcode(fullfile(r,n{1}),'-id');fprintf('%s: %d code analyzer messages\n',n{1},numel(z));for k=1:numel(z),fprintf('  line %d: %s\n',z(k).line,z(k).message);end
end
set_param(m,'StopTime','.050');set_param([m '/bus_current'],'Decimation','1');save_system(m);
fprintf('Structural QA passed: four TX sections, one DD RX, 20 switches, reciprocal positive-definite magnetic matrix.\n');
end
