function show_dd_track()
% Open the finished circuit and the saved, tested waveform summary.
r=fileparts(mfilename('fullpath'));m='DWPT_DD_4section_100V';open_system(fullfile(r,[m '.slx']));set_param(m,'ZoomFactor','FitSystem');
f=figure('Name','DD-to-DD four-section design and validation','NumberTitle','off','Position',[40 50 1350 850]);
ax=axes(f,'Position',[.03 .13 .94 .83]);image(ax,imread(fullfile(r,'design_dd_track','switched_results.png')));axis(ax,'image');axis(ax,'off');
uicontrol(f,'Style','pushbutton','String','Circuit overview','Units','normalized','Position',[.03 .02 .15 .06],'Callback',@(~,~)open_system(m));
uicontrol(f,'Style','pushbutton','String','TX bridge and LCC','Units','normalized','Position',[.19 .02 .15 .06],'Callback',@(~,~)open_system([m '/Section 1 bridge and LCC']));
uicontrol(f,'Style','pushbutton','String','Pod MOSFET rectifier','Units','normalized','Position',[.35 .02 .17 .06],'Callback',@(~,~)open_system([m '/Four MOSFET synchronous rectifier']));
uicontrol(f,'Style','pushbutton','String','DD geometry','Units','normalized','Position',[.53 .02 .14 .06],'Callback',@(~,~)showimage(fullfile(r,'design_dd_track','dd_geometry.png')));
uicontrol(f,'Style','pushbutton','String','Read design report','Units','normalized','Position',[.68 .02 .15 .06],'Callback',@(~,~)edit(fullfile(r,'DD_TRACK_DESIGN.md')));
uicontrol(f,'Style','pushbutton','String','Run seam test','Units','normalized','Position',[.84 .02 .13 .06],'Callback',@(~,~)run_dd_track(.9144,.05,struct(),'seam'));
end
function showimage(p),figure('Name','DD geometry');image(imread(p));axis image off;end
