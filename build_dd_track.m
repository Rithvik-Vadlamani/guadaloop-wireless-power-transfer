function build_dd_track()
% Native Simscape switched four-transmitter DD-to-DD LCC-S circuit.
root=fileparts(mfilename('fullpath'));m='DWPT_DD_4section_100V';src='DWPT_250k_60V_1200W';
if bdIsLoaded(m),assert(strcmp(get_param(m,'Dirty'),'off'),'Save edits first.');close_system(m,0);end
load_system(fullfile(root,[src '.slx']));load_system('fl_lib');load_system('ddtrack_lib');new_system(m);
p=dd_track_parameters();w=get_param(m,'ModelWorkspace');for k=string(fieldnames(p))',assignin(w,k,p.(k));end
set_param(m,'SolverType','Fixed-step','Solver','ode3','FixedStep','Ts','StopTime','.050','ReturnWorkspaceOutputs','on','SignalLogging','off');
add_block([src '/DC Voltage Source'],[m '/100 V DC bus'],'Position',[40 340 90 400]);
add_block([src '/Io3'],[m '/Bus current'],'Position',[150 200 190 230]);
wire(m,'100 V DC bus','RConn',1,'Bus current','LConn',1);
add_block([src '/Source reference'],[m '/DC reference'],'Position',[80 1040 110 1070]);wire(m,'100 V DC bus','LConn',1,'DC reference','LConn',1);
add_block([src '/Solver Configuration1'],[m '/Solver'],'Position',[30 1100 100 1140]);wire(m,'DC reference','LConn',1,'Solver','RConn',1);
set_param([m '/Solver'],'UseLocalSolver','on','LocalSolverChoice','NE_TRAPEZOIDAL_ADVANCER','LocalSolverSampleTime','Ts');
libblocks=find_system('ddtrack_lib','SearchDepth',1,'Type','Block');
add_block(libblocks{1},[m '/Four DD track pads and DD receiver'],'Lmat','Lmat','Rw','Rcoil','Position',[980 160 1130 980]);
for k=1:4
 name=sprintf('Section %d bridge and LCC',k);b=[m '/' name];y=100+220*(k-1);
 add_block('built-in/SubSystem',b,'Position',[360 y 650 y+170]);
 port(b,'DC plus',1,'Left',[30 50 50 70]);port(b,'DC minus',2,'Left',[30 330 50 350]);
 port(b,'Coil plus',3,'Right',[780 100 800 120]);port(b,'Coil minus',4,'Right',[780 290 800 310]);
 add_block('simulink/Ports & Subsystems/In1',[b '/Gates'],'Position',[30 420 60 440]);
 add_block('simulink/Signal Routing/Demux',[b '/Gate split'],'Outputs','4','Position',[110 400 115 480]);add_line(b,'Gates/1','Gate split/1');
 for j=1:4
  q=[b '/Q' num2str(j)];add_block([src '/Mosfet'],q,'Position',[200+140*floor((j-1)/2) 70+170*mod(j-1,2) 260+140*floor((j-1)/2) 130+170*mod(j-1,2)]);
  set_param(q,'OpenFcn','');set_param([q '/MOSFET'],'Rds','RonTx','Goff','Goff','diode_Vf','bodyVfTx','diode_Ron','bodyRonTx','diode_Goff','Goff');
  add_line(b,['Gate split/' num2str(j)],['Q' num2str(j) '/1'],'autorouting','on');
 end
 wire(b,'DC plus','RConn',1,'Q1','LConn',1);wire(b,'DC plus','RConn',1,'Q3','LConn',1);
 wire(b,'DC minus','RConn',1,'Q2','RConn',1);wire(b,'DC minus','RConn',1,'Q4','RConn',1);
 wire(b,'Q1','RConn',1,'Q2','LConn',1);wire(b,'Q3','RConn',1,'Q4','LConn',1);
 add_block([src '/Io3'],[b '/Lf current'],'Position',[440 60 475 90]);
 add_block('fl_lib/Electrical/Electrical Elements/Inductor',[b '/Lf'],'L','Lf','i_L_specify','on','i_L_priority','High','i_L','0','Position',[510 60 560 100]);
 resistor(b,'Lf resistance','Rf',[580 60 620 100]);
 capacitor(b,'Cf','Cf',[640 190 680 230]);resistor(b,'Cf ESR','ESRf',[570 190 610 230]);
 capacitor(b,'Cp','Cp',[690 60 730 100]);resistor(b,'Cp ESR','ESRp',[640 60 680 100]);
 wire(b,'Q1','RConn',1,'Lf current','LConn',1);wire(b,'Lf current','RConn',1,'Lf','LConn',1);wire(b,'Lf','RConn',1,'Lf resistance','LConn',1);
 wire(b,'Lf resistance','RConn',1,'Cp ESR','LConn',1);wire(b,'Cp ESR','RConn',1,'Cp','LConn',1);wire(b,'Cp','RConn',1,'Coil plus','RConn',1);
 wire(b,'Lf resistance','RConn',1,'Cf ESR','LConn',1);wire(b,'Cf ESR','RConn',1,'Cf','LConn',1);wire(b,'Cf','RConn',1,'Q3','RConn',1);wire(b,'Q3','RConn',1,'Coil minus','RConn',1);
 add_block('simulink/Ports & Subsystems/Out1',[b '/Input current'],'Position',[500 420 530 440]);add_line(b,'Lf current/1','Input current/1','autorouting','on');
 wire(m,'Bus current','RConn',1,name,'LConn',1);wire(m,'100 V DC bus','LConn',1,name,'LConn',2);
 sensor=sprintf('TX%d current',k);add_block([src '/Io3'],[m '/' sensor],'Position',[770 y+40 810 y+70]);
 wire(m,name,'RConn',1,sensor,'LConn',1);wire(m,sensor,'RConn',1,'Four DD track pads and DD receiver','LConn',k);wire(m,name,'RConn',2,'Four DD track pads and DD receiver','RConn',k);
 logSignal(m,[name '/1'],sprintf('lf%d_current',k),1950,y);logSignal(m,[sensor '/1'],sprintf('tx%d_current',k),2100,y);
end
capacitor(m,'Receiver Cs','Cs',[1220 1020 1270 1060]);resistor(m,'Cs ESR','ESRs',[1300 1020 1350 1060]);
add_block([src '/Io3'],[m '/Receiver AC current'],'Position',[1390 1020 1430 1050]);
add_block([src '/Synchronous Rectifier'],[m '/Four MOSFET synchronous rectifier'],'Position',[1510 970 1730 1150]);
wire(m,'Four DD track pads and DD receiver','LConn',5,'Receiver Cs','LConn',1);wire(m,'Receiver Cs','RConn',1,'Cs ESR','LConn',1);wire(m,'Cs ESR','RConn',1,'Receiver AC current','LConn',1);wire(m,'Receiver AC current','RConn',1,'Four MOSFET synchronous rectifier','LConn',1);wire(m,'Four DD track pads and DD receiver','RConn',5,'Four MOSFET synchronous rectifier','LConn',2);
capacitor(m,'Output capacitor','Cout',[1840 1060 1890 1100]);set_param([m '/Output capacitor'],'vc','initialOutputVoltage');
resistor(m,'3 ohm load','RL',[1940 1060 1990 1100]);
add_block([src '/Io3'],[m '/Rectifier DC current'],'Position',[1780 970 1820 1000]);
wire(m,'Four MOSFET synchronous rectifier','RConn',1,'Rectifier DC current','LConn',1);wire(m,'Rectifier DC current','RConn',1,'Output capacitor','LConn',1);wire(m,'Output capacitor','LConn',1,'3 ohm load','LConn',1);
wire(m,'Four MOSFET synchronous rectifier','RConn',2,'Output capacitor','RConn',1);wire(m,'Output capacitor','RConn',1,'3 ohm load','RConn',1);
add_block([src '/Receiver reference'],[m '/RX reference'],'Position',[1770 1200 1800 1230]);wire(m,'Output capacitor','RConn',1,'RX reference','LConn',1);
add_block([src '/Uo2'],[m '/Output voltage'],'Position',[2040 1060 2080 1100]);wire(m,'Output capacitor','LConn',1,'Output voltage','LConn',1);wire(m,'Output capacitor','RConn',1,'Output voltage','LConn',2);
chart([m '/Four bridge controller'],fileread(fullfile(root,'design_dd_track','pwm_track.m')),{'f','Ts','Vtarget','softStart','deadTime','Kp','Ki','u_nom'},[370 1320 640 1430]);
add_block('simulink/Sources/Digital Clock',[m '/Clock'],'SampleTime','Ts','Position',[40 1330 100 1360]);
add_block('simulink/Discrete/Unit Delay',[m '/Voltage sample'],'SampleTime','Ts','InitialCondition','0','Position',[200 1400 240 1430]);
add_line(m,'Clock/1','Four bridge controller/1','autorouting','on');add_line(m,'Output voltage/1','Voltage sample/1','autorouting','on');add_line(m,'Voltage sample/1','Four bridge controller/2','autorouting','on');
add_block('simulink/Signal Routing/Demux',[m '/Four gate buses'],'Outputs','[4 4 4 4]','Position',[700 1310 710 1450]);add_line(m,'Four bridge controller/1','Four gate buses/1');
for k=1:4,add_line(m,sprintf('Four gate buses/%d',k),sprintf('Section %d bridge and LCC/1',k),'autorouting','on');end
chart([m '/SR controller'],fileread(fullfile(root,'design1200w','sr_control.m')),{'Ts','srDeadTime','srThreshold','srEnabled'},[1370 1330 1590 1420]);
add_block('simulink/Discrete/Unit Delay',[m '/Current sample'],'SampleTime','Ts','InitialCondition','0','Position',[1230 1340 1280 1370]);
add_line(m,'Receiver AC current/1','Current sample/1','autorouting','on');add_line(m,'Current sample/1','SR controller/1');add_line(m,'SR controller/1','Four MOSFET synchronous rectifier/1','autorouting','on');add_line(m,'SR controller/2','Four MOSFET synchronous rectifier/2','autorouting','on');
logs={'Bus current/1','bus_current';'Output voltage/1','output_voltage';'Receiver AC current/1','rx_current';'Rectifier DC current/1','rect_dc_current';'Four bridge controller/1','tx_gates';'Four bridge controller/2','modulation';'Four bridge controller/3','reference';'SR controller/1','sr_positive';'SR controller/2','sr_negative'};
for k=1:size(logs,1),logSignal(m,logs{k,1},logs{k,2},2300,70*k);end
% Voltage probes across reactive elements, used for stress validation.
probe(m,src,'Cs voltage','Receiver Cs','LConn',1,'Receiver Cs','RConn',1,1480);
for k=1:4
 name=sprintf('Section %d bridge and LCC',k); b=[m '/' name];
 probe(b,src,'Cf voltage','Cf','LConn',1,'Cf','RConn',1,550);
 probe(b,src,'Cp voltage','Cp','LConn',1,'Cp','RConn',1,620);
end
add_block('simulink/Sinks/Scope',[m '/Output scope'],'Position',[2240 1090 2310 1140]);add_line(m,'Output voltage/1','Output scope/1','autorouting','on');
n=Simulink.Annotation(m,sprintf('FOUR-SECTION DD-to-DD LCC-S | 100 V max | 250 kHz | target 60 V, 20 A\nEach pad: 914.4 x 609.6 mm envelope | 100 mm clear gap | 3 turns per D lobe\nStatic-position switched circuit; default receiver at first seam. TX GaN channel proxy; RX silicon MOSFETs. See loss audit.'));n.Position=[250 10];n.FontSize=13;
set_param(m,'SimulationCommand','update');save_system(m,fullfile(root,[m '.slx']));fprintf('Built %s\n',m);
end
function port(p,n,i,side,pos),add_block('built-in/PMIOPort',[p '/' n],'Port',num2str(i),'Side',side,'Position',pos);end
function wire(p,a,sa,ia,b,sb,ib),pa=get_param([p '/' a],'PortHandles');pb=get_param([p '/' b],'PortHandles');add_line(p,pa.(sa)(ia),pb.(sb)(ib),'autorouting','on');end
function resistor(p,n,r,pos),add_block('fl_lib/Electrical/Electrical Elements/Resistor',[p '/' n],'R',r,'Position',pos);end
function capacitor(p,n,c,pos),add_block('fl_lib/Electrical/Electrical Elements/Capacitor',[p '/' n],'c',c,'vc_specify','on','vc_priority','High','vc','0','Position',pos);end
function chart(path,code,pars,pos)
add_block('simulink/User-Defined Functions/MATLAB Function',path,'Position',pos);r=sfroot;c=r.find('-isa','Stateflow.EMChart','Path',path);c.Script=code;
for k=1:numel(pars),d=Stateflow.Data(c);d.Name=pars{k};d.Scope='Parameter';end
end
function logSignal(m,s,n,x,y)
add_block('simulink/Sinks/To Workspace',[m '/' n],'VariableName',strrep(strrep(n,' ','_'),'-','_'),'SaveFormat','Timeseries','MaxDataPoints','inf','Decimation','max(1,round(20e-9/Ts))','Position',[x y x+120 y+30]);if strcmp(n,'bus_current'),set_param([m '/' n],'Decimation','1');end
add_line(m,s,[n '/1'],'autorouting','on');
end
function probe(m,src,n,a,sa,ia,b,sb,ib,y)
add_block([src '/Uo2'],[m '/' n],'Position',[950 y 990 y+40]);wire(m,a,sa,ia,n,'LConn',1);wire(m,b,sb,ib,n,'LConn',2);
[~,parent]=fileparts(m);var=matlab.lang.makeValidName([parent '_' n]);logSignal(m,[n '/1'],var,1100,y);
end
