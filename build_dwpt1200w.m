function build_dwpt1200w()
%BUILD_DWPT250K Copy the repaired model into a single-TX LCC-S / synchronous RX.
root=fileparts(mfilename('fullpath'));
if bdIsLoaded('DWPT_250k_60V_1200W')
    assert(strcmp(get_param('DWPT_250k_60V_1200W','Dirty'),'off'), ...
        'Save unsaved edits before rebuilding; rebuilding replaces the new model copy.');
    close_system('DWPT_250k_60V_1200W',0);
end
load_system(fullfile(root,'DWPT_fixed.slx'));
save_system('DWPT_fixed',fullfile(root,'DWPT_250k_60V_1200W.slx'));
close_system('DWPT_fixed',0);
m='DWPT_250k_60V_1200W';load_system(fullfile(root,[m '.slx']));
w=get_param(m,'ModelWorkspace');clear(w);
p=dwpt1200w_parameters();
for k=string(fieldnames(p))',assignin(w,k,p.(k));end
set_param(m,'StopTime','0.03','Solver','ode3','SolverType','Fixed-step','FixedStep','Ts');
% Rebuild the conserving nets explicitly to avoid dangling deleted branches.
blocks=find_system(m,'SearchDepth',1,'Type','Block');lines=[];
for j=1:numel(blocks)
    ph=get_param(blocks{j},'PortHandles');
    for h=[ph.LConn ph.RConn]
        l=get_param(h,'Line');
        if l==-1,continue;end
        parent=get_param(l,'LineParent');
        while parent~=-1,l=parent;parent=get_param(l,'LineParent');end
        lines(end+1)=l; %#ok<AGROW>
    end
end
for l=unique(lines)
    try
        kind=get_param(l,'Type');
    catch
        continue;
    end
    if strcmp(kind,'line'),delete_line(l);end
end
removed={'Mosfet4','Mosfet5','Mosfet6','Mosfet7','S5','S6','S7','S8', ...
    'CT2','CP2','LT2','Io5','V M2','Scope14'};
set_param([m '/Scope5'],'NumInputPorts','2');
for j=1:numel(removed),delete_block([m '/' removed{j}]);end
% Delete the original pulse sources and their signal branches.
for name={'S1','S2','S3','S4'}
    ph=get_param([m '/' name{1}],'PortHandles');l=get_param(ph.Outport,'Line');
    if l~=-1,delete_line(l);end
    delete_block([m '/' name{1}]);
end
% Remove obsolete, now unused power-estimation blocks.
for name={'Mean','Mean1','Mean2'},delete_block([m '/' name{1}]);end
% Replace the three-winding block with exactly two coupled windings.
delete_block([m '/M']);b=[m '/Coupled Coils'];
add_block('built-in/SubSystem',b,'Position',[1910 850 2000 1000]);
port(b,'TX plus',1,'Left',[20 30 50 50]);
port(b,'TX minus',2,'Right',[300 30 330 50]);
port(b,'RX plus',3,'Left',[20 180 50 200]);
port(b,'RX minus',4,'Right',[300 180 330 200]);
add_block('fl_lib/Electrical/Electrical Elements/Mutual Inductor',[b '/Mutual Inductor'], ...
    'L1','LP1','L2','LS','k','k','Position',[140 85 200 145]);
add_block('fl_lib/Electrical/Electrical Elements/Resistor',[b '/TX winding resistance'], ...
    'R','RP1','Position',[70 30 110 60]);
add_block('fl_lib/Electrical/Electrical Elements/Resistor',[b '/RX winding resistance'], ...
    'R','RS','Position',[70 180 110 210]);
wire(b,'TX plus','RConn',1,'TX winding resistance','LConn',1);
wire(b,'TX winding resistance','RConn',1,'Mutual Inductor','LConn',1);
wire(b,'Mutual Inductor','LConn',2,'TX minus','RConn',1);
wire(b,'RX plus','RConn',1,'RX winding resistance','LConn',1);
wire(b,'RX winding resistance','RConn',1,'Mutual Inductor','RConn',1);
wire(b,'Mutual Inductor','RConn',2,'RX minus','RConn',1);
% Replace diode bridge with four N-channel MOSFETs, each retaining its body diode.
delete_block([m '/Universal Bridge']);b=[m '/Synchronous Rectifier'];
add_block('built-in/SubSystem',b,'Position',[3090 745 3260 925]);
port(b,'AC A',1,'Left',[20 95 50 115]);
port(b,'AC B',2,'Left',[20 195 50 215]);
port(b,'DC plus',3,'Right',[480 30 510 50]);
port(b,'DC minus',4,'Right',[480 275 510 295]);
add_block('simulink/Ports & Subsystems/In1',[b '/Positive current gates'],'Position',[20 340 50 360]);
add_block('simulink/Ports & Subsystems/In1',[b '/Negative current gates'],'Port','2','Position',[20 390 50 410]);
for j=1:4
    qb=[b '/Q' num2str(j)];
    add_block([m '/Mosfet'],qb,'Position',[180+130*mod(j-1,2) 60+140*floor((j-1)/2) 240+130*mod(j-1,2) 120+140*floor((j-1)/2)]);
    set_param(qb,'OpenFcn','');
    set_param([qb '/MOSFET'],'Rds','RonSR','Goff','Goff', ...
        'diode_Vf','bodyVf','diode_Ron','bodyRon','diode_Goff','Goff');
end
% Q1/Q2 upper devices: D=DC+, S=AC. Q3/Q4 lower: D=AC, S=DC-.
wire(b,'DC plus','RConn',1,'Q1','LConn',1);
wire(b,'DC plus','RConn',1,'Q2','LConn',1);
wire(b,'AC A','RConn',1,'Q1','RConn',1);
wire(b,'AC A','RConn',1,'Q3','LConn',1);
wire(b,'AC B','RConn',1,'Q2','RConn',1);
wire(b,'AC B','RConn',1,'Q4','LConn',1);
wire(b,'DC minus','RConn',1,'Q3','RConn',1);
wire(b,'DC minus','RConn',1,'Q4','RConn',1);
add_line(b,'Positive current gates/1','Q1/1','autorouting','on');
add_line(b,'Positive current gates/1','Q4/1','autorouting','on');
add_line(b,'Negative current gates/1','Q2/1','autorouting','on');
add_line(b,'Negative current gates/1','Q3/1','autorouting','on');
add_block([m '/Io3'],[m '/Rectifier DC current'],'Position',[3360 708 3385 732]);
add_block([m '/Io3'],[m '/TX coil current'],'Position',[1950 780 1975 804]);
% Restore all remaining physical node groups from the untouched fixed copy.
nets=jsondecode(fileread(fullfile(root,'design1200w','source_physical_nets.json')));
for j=1:numel(nets)
    ends=nets{j};handles=[];
    for q=1:numel(ends)
        name=ends(q).block;idx=ends(q).index;side=ends(q).side;
        if any(strcmp(name,removed)),continue;end
        if strcmp(name,'M')
            if idx==2,continue;end
            name='Coupled Coils';
            if idx==1 && strcmp(side,'lconn'),name='TX coil current';end
            if idx==3,idx=2;end
        elseif strcmp(name,'Universal Bridge')
            name='Synchronous Rectifier';
            if strcmp(side,'rconn') && idx==1,name='Rectifier DC current';end
        end
        ph=get_param([m '/' name],'PortHandles');
        if strcmp(side,'lconn'),h=ph.LConn(idx);else,h=ph.RConn(idx);end
        handles(end+1)=h; %#ok<AGROW>
    end
    for q=2:numel(handles),add_line(m,handles(1),handles(q),'autorouting','on');end
end
wire(m,'Synchronous Rectifier','RConn',1,'Rectifier DC current','LConn',1);
wire(m,'TX coil current','RConn',1,'Coupled Coils','LConn',1);
set_param([m '/LT1/Resistor'],'R','RT1');
set_param([m '/Cd2/Capacitor'],'c','Cout','v_specify','off', ...
    'vc_specify','on','vc_priority','High','vc','initialOutputVoltage');
for name={'Cp1','CT1','Cs'}
    set_param([m '/' name{1} '/Capacitor'],'vc_specify','on','vc_priority','High','vc','0');
end
set_param([m '/LT1/Inductor'],'i_L_specify','on','i_L_priority','High','i_L','0');
set_param([m '/Coupled Coils/Mutual Inductor'], ...
    'i1_specify','on','i1_priority','High','i1','0', ...
    'i2_specify','on','i2_priority','High','i2','0');
% A mean-square signal is mathematically nonnegative; guard roundoff at zero.
bs=find_system(m,'SearchDepth',1,'Regexp','on','Name','^RMS');
for j=1:numel(bs)
    sq=[bs{j} sprintf('/RMS\nMeasurement/Total RMS/Sqrt')];
    ph=get_param(sq,'PortHandles');l=get_param(ph.Inport,'Line');
    src=get_param(l,'SrcPortHandle');dst=get_param(l,'DstPortHandle');
    parent=get_param(sq,'Parent');delete_line(l);
    clamp=[parent '/Nonnegative mean square'];pos=get_param(sq,'Position');
    add_block('simulink/Discontinuities/Saturation',clamp, ...
        'LowerLimit','0','UpperLimit','inf','Position',pos+[-70 0 -70 0]);
    cp=get_param(clamp,'PortHandles');add_line(parent,src,cp.Inport,'autorouting','on');
    for h=dst'
        if h==ph.Inport,add_line(parent,cp.Outport,h,'autorouting','on');
        else,add_line(parent,src,h,'autorouting','on');end
    end
end
for name={'Mosfet','Mosfet1','Mosfet2','Mosfet3'}
    set_param([m '/' name{1} '/MOSFET'],'Rds','RonTx','Goff','Goff', ...
        'diode_Vf','bodyVf','diode_Ron','bodyRon','diode_Goff','Goff');
end
set_param([m sprintf('/Analog\nFilter Design1')],'Wlo','2*pi*f');
% Phase-shift control: voltage feedback is sampled, phase changes once per cycle.
pwm=[m '/Inverter control'];
chart(pwm,fileread(fullfile(root,'design1200w','pwm_control.m')), ...
    {'f','Ts','Vtarget','Vavailable','softStart','deadTime','Kp','Ki','closedLoop'},[1000 1400 1190 1570]);
add_block('simulink/Sources/Digital Clock',[m '/Switching clock'],'SampleTime','Ts','Position',[760 1410 820 1440]);
add_block('simulink/Discrete/Unit Delay',[m '/Voltage sample'],'SampleTime','Ts','InitialCondition','0','Position',[850 1500 900 1535]);
add_line(m,'Switching clock/1','Inverter control/1','autorouting','on');
add_line(m,'Uo2/1','Voltage sample/1','autorouting','on');
add_line(m,'Voltage sample/1','Inverter control/2','autorouting','on');
for j=1:4
    names={'Mosfet','Mosfet2','Mosfet1','Mosfet3'};
    add_line(m,['Inverter control/' num2str(j)],[names{j} '/1'],'autorouting','on');
end
add_line(m,'Inverter control/1','Scope13/1','autorouting','on');
sr=[m '/Synchronous rectifier control'];
chart(sr,fileread(fullfile(root,'design1200w','sr_control.m')), ...
    {'Ts','srDeadTime','srThreshold','srEnabled'},[2700 1680 2910 1800]);
add_block('simulink/Discrete/Unit Delay',[m '/Receiver current sample'], ...
    'SampleTime','Ts','InitialCondition','0','Position',[2580 1720 2630 1755]);
add_line(m,'Is2/1','Receiver current sample/1','autorouting','on');
add_line(m,'Receiver current sample/1','Synchronous rectifier control/1','autorouting','on');
add_line(m,'Synchronous rectifier control/1','Synchronous Rectifier/1','autorouting','on');
add_line(m,'Synchronous rectifier control/2','Synchronous Rectifier/2','autorouting','on');
logSignal(m,'Rectifier DC current/1','rect_dc_current',750);
logSignal(m,'Is2/1','rect_ac_current',800);
logSignal(m,'V M3/1','rect_ac_voltage',850);
logSignal(m,'Inverter control/5','modulation',900);
logSignal(m,'Inverter control/6','voltage_reference',950);
logSignal(m,'Synchronous rectifier control/1','sr_positive',1000);
logSignal(m,'Synchronous rectifier control/2','sr_negative',1050);
logSignal(m,'TX coil current/1','tx_coil_current',1350);
logSignal(m,'Io2/1','tx_input_current',1400);
logSignal(m,'V M1/1','comp_inductor_voltage',1450);
voltageProbe(m,'CP1 voltage','Cp1','LConn',1,'Cp1','RConn',1,1500);
voltageProbe(m,'CT1 voltage','CT1','LConn',1,'CT1','RConn',1,1550);
voltageProbe(m,'CS voltage','Cs','LConn',1,'Cs','RConn',1,1600);
voltageProbe(m,'TX coil voltage','Coupled Coils','LConn',1,'Coupled Coils','RConn',1,1650);
voltageProbe(m,'RX coil voltage','Coupled Coils','LConn',2,'Coupled Coils','RConn',2,1700);
for j=1:4,logSignal(m,['Inverter control/' num2str(j)],['tx_gate' num2str(j)],1050+j*50);end
note=Simulink.Annotation(m,sprintf('Single TX LCC-S | 250 kHz | 60 V / 1200 W target\n50 V input; 3 ohm load; 9.887 uH TX/RX; k=0.695 estimated\nMOSFET synchronous rectifier; phase-shift control; 20 ms soft start'));
note.Position=[810 350];note.FontSize=14;
geometry=Simulink.Annotation(m,'10 mm clear winding gap | 5-turn, 300/200 mm OD/ID coils | 914.4 x 609.6 mm maximum envelope');
geometry.Position=[810 425];geometry.FontSize=12;
% Preallocate measurement history for the longer power-averaging window.
delays=find_system(m,'LookUnderMasks','all','FollowLinks','on', ...
    'MatchFilter',@Simulink.match.allVariants,'BlockType','TransportDelay');
for j=1:numel(delays)
    set_param(delays{j},'BufferSize','2^nextpow2(samplesPerPeriod*averageCycles+1024)');
end
set_param(m,'SimulationCommand','update');
save_system(m);
fprintf('Saved and compiled %s\n',m);
end
function port(parent,name,num,side,pos)
add_block('built-in/PMIOPort',[parent '/' name],'Port',num2str(num),'Side',side,'Position',pos);
end
function wire(parent,a,sideA,idxA,b,sideB,idxB)
pa=get_param([parent '/' a],'PortHandles');pb=get_param([parent '/' b],'PortHandles');
add_line(parent,pa.(sideA)(idxA),pb.(sideB)(idxB),'autorouting','on');
end
function chart(path,code,parameters,pos)
add_block('simulink/User-Defined Functions/MATLAB Function',path,'Position',pos);
r=sfroot;c=r.find('-isa','Stateflow.EMChart','Path',path);c.Script=code;
for j=1:numel(parameters)
    d=Stateflow.Data(c);d.Name=parameters{j};d.Scope='Parameter';
end
end
function logSignal(m,source,name,y)
add_block('simulink/Sinks/To Workspace',[m '/' name], ...
    'VariableName',name,'SaveFormat','Timeseries','MaxDataPoints','inf', ...
    'Position',[4300 y 4430 y+30]);
add_line(m,source,[name '/1'],'autorouting','on');
end

function voltageProbe(m,name,a,sa,ia,b,sb,ib,y)
add_block([m '/V M1'],[m '/' name],'Position',[3500 y 3530 y+40]);
wire(m,a,sa,ia,name,'LConn',1);
wire(m,b,sb,ib,name,'LConn',2);
logSignal(m,[name '/1'],strrep(lower(name),' ','_'),y);
end
