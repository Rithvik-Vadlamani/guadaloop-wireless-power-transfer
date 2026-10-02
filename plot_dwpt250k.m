function plot_dwpt250k()
%PLOT_DWPT250K Export the verified startup and steady-state waveforms.
root=fileparts(mfilename('fullpath'));folder=fullfile(root,'design250k');
s=load(fullfile(folder,'nominal.mat'),'out','metrics');o=s.out;
f=figure('Visible','off','Position',[100 100 1100 850]);
tiledlayout(3,1);
nexttile;plot(o.load_voltage.Time*1e3,o.load_voltage.Data,'LineWidth',1.5);hold on;
plot(o.voltage_reference.Time*1e3,o.voltage_reference.Data,'--');
ylabel('Rectified output [V]');legend('Output','Reference','Location','southeast');grid on;
title('Single transmitter: 250 kHz LCC-S, 50 V input, 30 ohm load');
nexttile;plot(o.load_current.Time*1e3,o.load_current.Data,'LineWidth',1.5);
ylabel('DC load current [A]');grid on;
nexttile;plot(o.modulation.Time*1e3,o.modulation.Data);grid on;
ylabel('Modulation');xlabel('Time [ms]');
lightStyle(f);exportgraphics(f,fullfile(folder,'startup.png'),'Resolution',160);close(f);
f=figure('Visible','off','Position',[100 100 1100 850]);tiledlayout(3,1);
finish=o.load_voltage.Time(end);start=finish-4/250e3;
nexttile;plot((o.rect_ac_current.Time-start)*1e6,o.rect_ac_current.Data);grid on;
xlim([0 finish-start]*1e6);ylabel('RX current [A]');title('Last four switching cycles');
nexttile;stairs((o.sr_positive.Time-start)*1e6,o.sr_positive.Data);hold on;
stairs((o.sr_negative.Time-start)*1e6,o.sr_negative.Data);grid on;
xlim([0 finish-start]*1e6);ylim([-.1 1.2]);ylabel('SR gate');legend('Q1/Q4','Q2/Q3');
nexttile;plot((o.load_voltage.Time-start)*1e6,o.load_voltage.Data);grid on;
xlim([0 finish-start]*1e6);ylabel('Output [V]');xlabel('Time within final window [microseconds]');
lightStyle(f);exportgraphics(f,fullfile(folder,'steady_state.png'),'Resolution',160);close(f);
% Store a compact visual record: startup at 1 us, final 100 cycles at full rate.
% Numerical validation metrics were computed from the full-rate simulation.
if isa(o,'Simulink.SimulationOutput')
    out=struct();names=o.who;
    for j=1:numel(names)
        x=o.(names{j});
        if isa(x,'timeseries')
            count=numel(x.Time);stride=max(1,round(1e-6/median(diff(x.Time))));
            keep=unique([1:stride:count,find(x.Time>=finish-100/250e3)',count]);
            out.(names{j})=timeseries(x.Data(keep),x.Time(keep));
        end
    end
    metrics=s.metrics;
    save(fullfile(folder,'nominal.mat'),'out','metrics','-v7.3');
end
end

function lightStyle(f)
set(f,'Color','w');
set(findall(f,'Type','axes'),'Color','w','XColor','k','YColor','k','GridColor',[.5 .5 .5]);
set(findall(f,'Type','text'),'Color','k');
set(findall(f,'Type','legend'),'Color','w','TextColor','k','EdgeColor',[.5 .5 .5]);
end
