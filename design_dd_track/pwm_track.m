function [g, modulation, reference] = pwm_track(t,v)
%#codegen
% Common fundamental phase across all four phase-shifted full bridges.
% Each bridge's complementary pair has enforced break-before-make.
persistent integral lastcycle command previous offcount
if isempty(integral)
 integral=0;lastcycle=-1;command=0;previous=zeros(16,1);offcount=ones(16,1)*1e6;
end
N=round(1/(f*Ts));tick=round(t/Ts);cycle=floor(tick/N);phase=mod(tick,N);
reference=Vtarget*min(t/softStart,1);
if cycle~=lastcycle
 error=reference-v;raw=reference/Vtarget+Kp*error+integral;
 if (raw<1/max(u_nom) && raw>0) || (raw>=1/max(u_nom) && error<0) || (raw<=0 && error>0)
  integral=integral+Ki*error/f;
 end
 command=max(0,min(1/max(u_nom),reference/Vtarget+Kp*error+integral));lastcycle=cycle;
end
modulation=min(1,max(0,u_nom(:)*command));desired=zeros(16,1);
dead=ceil(deadTime/Ts);
for k=1:4
 idx=4*(k-1);m=modulation(k);
 if m<.003
  desired(idx+2)=1;desired(idx+4)=1; % zero-vector clamp; tanks remain connected
 else
  halfwidth=round(N*asin(m)/(2*pi));
  a=mod(phase-(N/4-halfwidth),N);b=mod(phase-(N/4+halfwidth),N);
  desired(idx+1)=double(a>=dead && a<N/2);desired(idx+2)=double(a>=N/2+dead);
  desired(idx+3)=double(b>=dead && b<N/2);desired(idx+4)=double(b>=N/2+dead);
 end
end
g=zeros(16,1);
for j=1:16
 partner=j+1;if mod(j,2)==0,partner=j-1;end
 if previous(j)==0,offcount(j)=min(offcount(j)+1,1e6);else,offcount(j)=0;end
 if desired(j)>0 && desired(partner)==0 && previous(partner)==0 && offcount(partner)>=dead
  g(j)=1;
 end
end
previous=g;
end
