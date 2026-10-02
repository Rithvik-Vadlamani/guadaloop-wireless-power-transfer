function fig=show_dwpt1200w(out,metrics)
%SHOW_DWPT1200W Interactive tour of the model using a completed simulation.
% After [live_out,live_metrics]=run_dwpt1200w(), use:
% show_dwpt1200w(live_out,live_metrics)
m='DWPT_250k_60V_1200W';root=fileparts(mfilename('fullpath'));
fig=figure('Name','DWPT walkthrough - live 60 V / 20 A simulation', ...
    'NumberTitle','off','Color','w','WindowStyle','normal','Position',[80 80 1250 850]);
annotation(fig,'textbox',[.04 .92 .93 .065],'String',sprintf( ...
    'LIVE RUN: %.3f V | %.3f A | %.1f W output | 250 kHz', ...
    metrics.Vload_mean_V,metrics.Iload_mean_A,metrics.Pload_W), ...
    'FontSize',19,'FontWeight','bold','EdgeColor','none','Color','k');
annotation(fig,'textbox',[.04 .855 .93 .065],'String', ...
    '50 V DC  >  phase-shift bridge  >  LCC  >  10 mm gap  >  synchronous rectifier  >  3 ohm load', ...
    'FontSize',12,'EdgeColor','none','Color','k');
ax=axes(fig,'Position',[.07 .54 .39 .29]);
t=out.load_voltage.Time;take=1:100:numel(t);
plot(ax,t(take)*1e3,out.load_voltage.Data(take),'LineWidth',1.5);hold(ax,'on');
plot(ax,out.voltage_reference.Time(take)*1e3,out.voltage_reference.Data(take),'--','LineWidth',1);
xlabel(ax,'Time [ms]');ylabel(ax,'DC voltage [V]');title(ax,'1. Soft start and 60 V regulation');
legend(ax,{'Output','Reference'},'Location','southeast');grid(ax,'on');
ax=axes(fig,'Position',[.57 .54 .39 .29]);
plot(ax,t(take)*1e3,out.load_current.Data(take),'LineWidth',1.5);hold(ax,'on');
yline(ax,20,'--');xlabel(ax,'Time [ms]');ylabel(ax,'DC load current [A]');
title(ax,'2. Current reaches 20 A through 3 ohms');grid(ax,'on');
finish=t(end);start=finish-4/metrics.parameters.f;
ax=axes(fig,'Position',[.07 .17 .39 .28]);
x=out.rect_ac_current;keep=x.Time>=start;
plot(ax,(x.Time(keep)-start)*1e6,x.Data(keep),'LineWidth',1.2);
xlabel(ax,'Time in final four cycles [us]');ylabel(ax,'Receiver AC current [A]');
title(ax,'3. Resonant receiver current');grid(ax,'on');
ax=axes(fig,'Position',[.57 .17 .39 .28]);
x=out.sr_positive;keep=x.Time>=start;
stairs(ax,(x.Time(keep)-start)*1e6,x.Data(keep),'LineWidth',1.2);hold(ax,'on');
y=out.sr_negative;stairs(ax,(y.Time(keep)-start)*1e6,y.Data(keep),'LineWidth',1.2);
xlabel(ax,'Time in final four cycles [us]');ylabel(ax,'Gate command');ylim(ax,[-.1 1.2]);
title(ax,'4. Alternating MOSFET pairs, with blanking');
legend(ax,{'Q1 / Q4','Q2 / Q3'},'Location','southeast');grid(ax,'on');
labels={'Full circuit','Coupled coils','MOSFET rectifier','TX control code','RX control code','Parameters'};
paths={m,[m '/Coupled Coils'],[m '/Synchronous Rectifier'], ...
    [m '/Inverter control'],[m '/Synchronous rectifier control'],''};
for j=1:6
    uicontrol(fig,'Style','pushbutton','Units','normalized', ...
        'Position',[.025+(j-1)*.16 .045 .15 .047],'String',labels{j}, ...
        'FontSize',11,'Callback',@(~,~)navigate(paths{j},root));
end
set(findall(fig,'Type','axes'),'Color','w','XColor','k','YColor','k','GridColor',[.5 .5 .5]);
set(findall(fig,'Type','text'),'Color','k');
set(findall(fig,'Type','legend'),'Color','w','TextColor','k','EdgeColor',[.5 .5 .5]);
annotation(fig,'textbox',[.025 .003 .95 .03],'String', ...
    'Buttons open the actual model. Coil coupling and losses are estimates; this is not a hardware validation.', ...
    'FontSize',10,'EdgeColor','none','Color',[.25 .25 .25]);
drawnow;
exportgraphics(fig,fullfile(root,'design1200w','live_walkthrough.png'),'Resolution',140);
end
function navigate(path,root)
if isempty(path)
    edit(fullfile(root,'dwpt1200w_parameters.m'));
else
    open_system(path);
    if ~contains(path,'control'),set_param(path,'ZoomFactor','FitSystem');end
end
end
