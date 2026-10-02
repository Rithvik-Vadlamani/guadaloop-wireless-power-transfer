function repair_dwpt()
%REPAIR_DWPT Reproduce repairs on the MathWorks-converted copy.
root = fileparts(mfilename('fullpath'));
source = fullfile(root,'converted','DWPT_simscape.slx');
assert(isfile(source),'Run spsConversionAssistant(''DWPT'',''converted'') first.');
load_system(source);
save_system('DWPT_simscape',fullfile(root,'DWPT_fixed.slx'));
close_system('DWPT_simscape',0);
m = 'DWPT_fixed'; load_system(fullfile(root,[m '.slx']));
set_param(m,'InitFcn','','Solver','ode3','SolverType','Fixed-step', ...
    'FixedStep','Ts','RelTol','1e-4','AbsTol','1e-6','StopTime','0.07', ...
    'ReturnWorkspaceOutputs','on');
p = dwpt_parameters(); w = get_param(m,'ModelWorkspace');
for k = string(fieldnames(p))', assignin(w,k,p.(k)); end
if getSimulinkBlockHandle([m '/powergui']) ~= -1, delete_block([m '/powergui']); end
% Local implicit trapezoidal integration handles the stiff electrical network.
% Global ode3 integrates only the continuous diagnostic/filter states.
set_param([m '/Solver Configuration1'],'UseLocalSolver','on', ...
    'LocalSolverChoice','NE_TRAPEZOIDAL_ADVANCER','LocalSolverSampleTime','Ts');
% Each galvanically isolated circuit needs its own voltage reference.
refs=find_system(m,'SearchDepth',1,'Regexp','on','Name','^High Z');
for j=1:numel(refs),delete_block(refs{j});end
add_block('fl_lib/Electrical/Electrical Elements/Electrical Reference', ...
    [m '/Source reference'],'Position',[700 930 730 960]);
add_block('fl_lib/Electrical/Electrical Elements/Electrical Reference', ...
    [m '/Receiver reference'],'Position',[3650 1020 3680 1050]);
ph=get_param([m '/Source reference'],'PortHandles');
a=get_param([m '/DC Voltage Source'],'PortHandles');
add_line(m,a.LConn(1),ph.LConn(1),'autorouting','on');
ph=get_param([m '/Receiver reference'],'PortHandles');
a=get_param([m '/Cd2'],'PortHandles');
add_line(m,a.RConn(1),ph.LConn(1),'autorouting','on');
% Direct native parameters avoid obsolete conversion helper expressions and
% undefined, inactive SPS mask variables Lf, Lt, M.
b = [m '/M/Coupled Lines'];
set_param(b,'La','LP1','Lb','LP2','Lc','LS','Lmab','0', ...
    'Lmac','M1','Lmbc','M2','Lm','0','Ra','RP1','Rb','RP2', ...
    'Rc','RS','Rm','0','Rmab','0','Rmac','0','Rmbc','0');
for k = 0:7
    if k==0, name='Mosfet'; else, name=['Mosfet' num2str(k)]; end
    set_param([m '/' name '/MOSFET'],'Rds','0.09','Goff','1e-5', ...
        'diode_Vf','3.3','diode_Ron','0.01','diode_Goff','1e-5');
end
for k=1:4
    set_param([m '/Universal Bridge/Diode' num2str(k)], ...
        'Vf','1.5','Ron','0.03','Goff','1e-5');
end
set_param([m '/DC Voltage Source/DC Voltage Source'],'v0','Vdc');
set_param([m '/R4/Resistor'],'R','RL');
% The conversion defaults RMS blocks to 60 Hz: restore intended window.
bs=find_system(m,'SearchDepth',1,'Regexp','on','Name','^RMS');
for k=1:numel(bs)
    set_param([bs{k} sprintf('/RMS\nMeasurement')], ...
        'F','f/averageCycles','InitialRMS','0','Ts','0');
end
% Correct real power: average the instantaneous product v(t)*i(t).
% Keep the existing displays and scopes, but replace their feeding subsystem.
fixPower(m,'Product4','From2/1','From3/1',[2380 1407 2440 1447]);
fixPower(m,'Product1','From1/1','From4/1',[2880 1377 2940 1417]);
% Allocate delay history for the high switching frequency and long RMS window.
% Break only the measurement links so their internal buffer can be configured.
for k=1:numel(bs)
    set_param([bs{k} sprintf('/RMS\nMeasurement')],'LinkStatus','inactive');
end
delays=find_system(m,'LookUnderMasks','all','FollowLinks','on','MatchFilter',@Simulink.match.allVariants,'BlockType','TransportDelay');
for k=1:numel(delays),set_param(delays{k},'BufferSize','262144');end
% Empty diagnostic scope ports carry no useful information.
set_param([m '/Scope13'],'NumInputPorts','1');
set_param([m '/Scope14'],'NumInputPorts','1');
add_line(m,'S1/1','Scope13/1','autorouting','on');
add_line(m,'S5/1','Scope14/1','autorouting','on');
% Log source and load signals with explicit names for reproducible metrics.
logSignal(m,'Idc/1','dc_current',[4300 500 4400 530]);
logSignal(m,'V M/1','dc_voltage',[4300 550 4400 580]);
logSignal(m,'Io4/1','load_current',[4300 600 4400 630]);
logSignal(m,'Uo2/1','load_voltage',[4300 650 4400 680]);
% Preserve intentionally customized measurement blocks as local copies.
custom=find_system(m,'LookUnderMasks','all','FollowLinks','off', ...
    'MatchFilter',@Simulink.match.allVariants,'LinkStatus','inactive');
for k=1:numel(custom),set_param(custom{k},'LinkStatus','none');end
set_param(m,'SimulationCommand','update');
save_system(m);
fprintf('Saved and compiled %s\n',fullfile(root,[m '.slx']));
end
function fixPower(m,name,current,voltage,pos)
b=[m '/' name]; ph=get_param(b,'PortHandles');
for h=ph.Inport, l=get_param(h,'Line'); if l~=-1,delete_line(l);end,end
% Replacing the block drops outgoing branches: remember their destinations.
l=get_param(ph.Outport,'Line'); dst=get_param(l,'DstPortHandle');
delete_line(l); delete_block(b);
add_block('built-in/SubSystem',b,'Position',pos);
add_block('simulink/Ports & Subsystems/In1',[b '/Current'],'Position',[20 25 50 45]);
add_block('simulink/Ports & Subsystems/In1',[b '/Voltage'],'Port','2','Position',[20 80 50 100]);
add_block('simulink/Math Operations/Product',[b '/Instantaneous power'],'Position',[90 35 120 75]);
add_block('eeGeneralControl/Moving Average',[b '/Average power'], ...
    'f','f/averageCycles','Ts','0','x0','0','Position',[160 30 240 80]);
add_block('simulink/Ports & Subsystems/Out1',[b '/Watts'],'Position',[280 45 310 65]);
add_line(b,'Current/1','Instantaneous power/1');
add_line(b,'Voltage/1','Instantaneous power/2');
add_line(b,'Instantaneous power/1','Average power/1');
add_line(b,'Average power/1','Watts/1');
add_line(m,current,[name '/1'],'autorouting','on');
add_line(m,voltage,[name '/2'],'autorouting','on');
ph=get_param(b,'PortHandles');
for h=dst',add_line(m,ph.Outport,h,'autorouting','on');end
end
function logSignal(m,source,name,pos)
add_block('simulink/Sinks/To Workspace',[m '/' name], ...
    'VariableName',name,'SaveFormat','Timeseries','MaxDataPoints','inf','Position',pos);
add_line(m,source,[name '/1'],'autorouting','on');
end
