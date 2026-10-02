function [g1,g2,g3,g4,modulation,reference] = pwm_control(t,vout)
%#codegen
% Parameters: f, Ts, Vtarget, Vavailable, softStart, deadTime, Kp, Ki, closedLoop.
% Update phase only at period boundaries to avoid mid-cycle gate glitches.
persistent integral command last1 last2 last3 last4 off1 off2 off3 off4
if isempty(integral)
    integral=0; command=0;
    last1=0;last2=0;last3=0;last4=0;
    off1=0;off2=0;off3=0;off4=0;
end
N=round(1/(f*Ts));
tick=mod(round(t/Ts),N);
reference=Vtarget*min(t/softStart,1);
if tick==0
    error=reference-vout;
    feedforward=reference/Vavailable;
    u=feedforward+closedLoop*(Kp*error+integral);
    command=min(max(u,0),1);
    if closedLoop>0 && ((u>0 && u<1) || (u>=1 && error<0) || (u<=0 && error>0))
        integral=min(max(integral+Ki*error/f,-1),1);
    end
end
shift=round(N*asin(command)/pi);
dead=round(deadTime/Ts);
phaseB=mod(tick-shift,N);
% Enforce interlock even when the phase command moves a carrier edge.
off1=min((off1+1)*(last1==0),dead+1);
off2=min((off2+1)*(last2==0),dead+1);
off3=min((off3+1)*(last3==0),dead+1);
off4=min((off4+1)*(last4==0),dead+1);
g1=double(tick>=dead && tick<N/2 && off2>=dead);
g2=double(tick>=N/2+dead && tick<N && off1>=dead);
g3=double(phaseB>=dead && phaseB<N/2 && off4>=dead);
g4=double(phaseB>=N/2+dead && phaseB<N && off3>=dead);
last1=g1;last2=g2;last3=g3;last4=g4;
modulation=command;
end
