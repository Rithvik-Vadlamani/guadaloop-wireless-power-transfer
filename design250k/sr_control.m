function [positive,negative] = sr_control(current)
%#codegen
% Parameters: Ts, srDeadTime, srThreshold, srEnabled.
% Input is delayed one sample to avoid a physical-network algebraic loop.
% Turn off near zero current; require a stable polarity before turning on.
persistent previous stable
if isempty(previous)
    previous=0; stable=0;
end
polarity=0;
if current>srThreshold
    polarity=1;
elseif current<-srThreshold
    polarity=-1;
end
if polarity~=previous || polarity==0
    stable=0;
else
    stable=min(stable+1,ceil(srDeadTime/Ts)+1);
end
previous=polarity;
ready=stable>=ceil(srDeadTime/Ts) && srEnabled>0;
positive=double(ready && polarity==1);
negative=double(ready && polarity==-1);
end
