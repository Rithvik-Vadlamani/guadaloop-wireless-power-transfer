load_system('DWPT_250k_60V_1200W');
m='DWPT_250k_60V_1200W';
bs=find_system(m,'SearchDepth',1,'Type','Block');
for k=1:numel(bs)
 if contains(bs{k},{'Solver','DC','Ground','Electrical','Reference','Cd','RL'})
 disp(bs{k});disp(get_param(bs{k},'DialogParameters'));
 end
end
load_system('ddtrack_lib');disp(find_system('ddtrack_lib','SearchDepth',1,'Type','Block'));
b='ddtrack_lib/Five Windings'; if getSimulinkBlockHandle(b)==-1,b='ddtrack_lib/FiveWindings';end
disp(get_param(b,'PortHandles'));disp(get_param(b,'DialogParameters'));
