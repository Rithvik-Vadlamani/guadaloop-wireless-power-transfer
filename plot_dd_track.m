function plot_dd_track()
% Scientific plots from actual native Simscape output, not reconstructed sine waves.
r=fileparts(mfilename('fullpath'));d=fullfile(r,'design_dd_track');
a=load(fullfile(d,'center_waveforms.mat'));b=load(fullfile(d,'seam_waveforms.mat'));
f=figure('Visible','off','Position',[30 30 1150 900]);if isprop(f,'Theme'),f.Theme='light';end;colororder(f,[0 .447 .741;.85 .325 .098;.466 .674 .188;.494 .184 .556]);tiledlayout(3,2,'TileSpacing','compact');
nexttile;plot(a.compact.output_voltage.Time*1e3,a.compact.output_voltage.Data);hold on;plot(b.compact.output_voltage.Time*1e3,b.compact.output_voltage.Data);yline(60,'--');ylabel('DC output [V]');xlabel('Time [ms]');legend('Pad center','Section seam','Target','Location','southeast');grid on;title('Zero-energy startup, native switched circuit');ylim([0 63]);
nexttile;plot(a.compact.output_voltage.Time*1e3,a.compact.output_voltage.Data/3);hold on;plot(b.compact.output_voltage.Time*1e3,b.compact.output_voltage.Data/3);ylabel('Load [A]');xlabel('Time [ms]');grid on;title('3 ohm load: 60 V / 20 A');ylim([0 22]);
nexttile;tailplot(a.compact.output_voltage,40);hold on;tailplot(b.compact.output_voltage,40);ylabel('DC output [V]');xlabel('Time before end [us]');grid on;title('Final 10 switching cycles');
nexttile;tailplot(b.compact.rx_current,40);hold on;tailplot(b.compact.tx1_current,40);tailplot(b.compact.tx2_current,40);ylabel('Coil currents [A]');xlabel('Time before end [us]');legend('DD receiver','DD TX1','DD TX2');grid on;
nexttile;tailplot(b.compact.DWPT_DD_4section_100V_CsVoltage,40);ylabel('Receiver Cs voltage [V]');xlabel('Time before end [us]');grid on;title('Resonant voltage greatly exceeds DC output');
nexttile;s=b.compact.tx_gates;t=s.Time;q=t>=t(end)-8e-6;hold on;for k=1:4,stairs((t(q)-t(end))*1e6,s.Data(q,k)+1.3*(4-k));end;yticks([0 1.3 2.6 3.9]);yticklabels({'Q4','Q3','Q2','Q1'});ylim([-.1 5.1]);xlabel('Time before end [us]');grid on;title('TX1 gate commands; 20 ns interlock');
sgtitle('100 V / 250 kHz / 100 mm gap — DD track and DD pod');exportgraphics(f,fullfile(d,'switched_results.png'),'Resolution',170);close(f);
end
function tailplot(s,width)
t=s.Time;q=t>=t(end)-width*1e-6;plot((t(q)-t(end))*1e6,s.Data(q,:));
end
