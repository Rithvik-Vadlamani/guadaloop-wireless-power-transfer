root=fileparts(fileparts(mfilename('fullpath')));addpath(root);
[~,metrics]=run_dwpt1200w(.03,struct('k',0.1908378163367059),false);
fid=fopen(fullfile(root,'design1200w','gap100mm_metrics.json'),'w');fprintf(fid,'%s',jsonencode(metrics,PrettyPrint=true));fclose(fid);
