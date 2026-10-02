m='DWPT_250k_60V_1200W';load_system(m);
delays=find_system(m,'LookUnderMasks','all','FollowLinks','on', ...
    'MatchFilter',@Simulink.match.allVariants,'BlockType','TransportDelay');
for j=1:numel(delays)
    set_param(delays{j},'BufferSize','2^nextpow2(samplesPerPeriod*averageCycles+1024)');
end
geometry=Simulink.Annotation(m,'10 mm clear winding gap | 5-turn, 300/200 mm OD/ID coils | 914.4 x 609.6 mm maximum envelope');
geometry.Position=[810 425];geometry.FontSize=12;
set_param(m,'SimulationCommand','update');save_system(m);
assert(numel(find_system(m,'SearchDepth',1,'Regexp','on','Name','^Mosfet[0-9]*$'))==4);
assert(numel(find_system([m '/Synchronous Rectifier'],'SearchDepth',1,'Regexp','on','Name','^Q[1-4]$'))==4);
for f={'dwpt1200w_parameters.m','build_dwpt1200w.m','run_dwpt1200w.m','validate_dwpt1200w.m','plot_dwpt1200w.m','coil_sizing1200w.m'}
    messages=checkcode(f{1},'-id');
    if ~isempty(messages),disp(f{1});disp(messages);end
    assert(isempty(messages),'Code Analyzer findings remain.');
end
disp('Updated display buffers, compiled the model, confirmed 4 TX + 4 RX MOSFETs; Code Analyzer clean.');
