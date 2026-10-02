"""Reduced moving test: quasi-steady fundamental AC network plus Cout and PI.
Includes motional Ldot in AC impedance; omits resonant-envelope transients,
switching, sensing delay and position-estimation error. Speeds are examples.
"""
from size_circuit import *
from scipy.integrate import solve_ivp
from scipy.io import savemat
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
d=json.loads((ROOT/'final_design.json').read_text());p=d['parameters'];xs=np.array(d['x_m']);Ls=np.array(d['matrices_H']);us=np.array([q['u_rms'] for q in d['cases']]);Cout=.0022;c=2*np.sqrt(2)/np.pi

def run(speed):
 end=3*PITCH/speed
 def electrical(t,v,integ):
  x=PITCH/2+speed*t;j=min(len(xs)-2,max(0,np.searchsorted(xs,x)-1));a=(x-xs[j])/(xs[j+1]-xs[j]);L=Ls[j]*(1-a)+Ls[j+1]*a;Ld=(Ls[j+1]-Ls[j])*speed/(xs[j+1]-xs[j]);u=us[j]*(1-a)+us[j+1]*a
  gain=np.clip(1+.012*(60-v)+integ,0,90.0316316/max(u));u=u*gain
  zcf=.003+1/(1j*W*p['Cf']);zcp=.005+1/(1j*W*p['Cp']);zcs=.005+1/(1j*W*p['Cs'])
  A=np.zeros((9,9),complex)
  for k in range(4):
   A[k,k]=.006+2*.005*1.6+1j*W*p['Lf']+zcf;A[k,4+k]=-zcf;A[4+k,k]=-zcf;A[4+k,4+k]=zcf+zcp+p['Rcoil']
  A[4:,4:]+=1j*W*L+Ld;A[8,8]+=p['Rcoil']+zcs+.0064
  T=np.linalg.solve(A[:8,:8],np.c_[np.r_[u,np.zeros(4)],A[:8,8]])
  E=-A[8,:8]@T[:,0];Z=A[8,8]-A[8,:8]@T[:,1]
  # E = (Z*Irms + c*Vdc)*exp(j angle(I)); solve magnitude without fixing I phase.
  aa=abs(Z)**2;bb=2*Z.real*c*v;cc=(c*v)**2-abs(E)**2
  ir=max(0,(-bb+np.sqrt(max(0,bb*bb-4*aa*cc)))/(2*aa))
  return c*ir,gain*max(u)/max(gain,1e-12)/90.0316316
 def rhs(t,y):
  current,mod=electrical(t,y[0],y[1]);return [(current-y[0]/3)/Cout,15*(60-y[0])]
 sol=solve_ivp(rhs,(0,end),[60.,0.],method='Radau',rtol=1e-6,atol=1e-8,max_step=end/1500,t_eval=np.linspace(0,end,2501))
 assert sol.success,sol.message
 v=sol.y[0];result=dict(speed_m_s=speed,duration_s=end,Vmin=float(min(v)),Vmax=float(max(v)),max_error_percent=float(max(abs(v-60))/60*100),nfev=sol.nfev,model='Quasi-steady fundamental network plus output capacitor and PI; not switching or full resonant transient')
 print(result,flush=True);return sol,result
runs=[];fig,ax=plt.subplots(2,1,figsize=(11,6),layout='constrained')
for speed in [1.,10.]:
 sol,r=run(speed);runs.append(r);x=PITCH/2+speed*sol.t;ax[0].plot(x,sol.y[0],label=f'{speed:g} m/s (illustrative)');ax[1].plot(x,sol.y[0]/3,label=f'{speed:g} m/s')
 savemat(ROOT/f'moving_{speed:g}mps.mat',{'time':sol.t,'position':x,'voltage':sol.y[0],'current':sol.y[0]/3})
for a in ax:
 for pos in [PITCH,2*PITCH,3*PITCH]:a.axvline(pos,color='gray',ls='--',lw=.8)
 a.grid();a.legend();a.set_xlabel('Receiver center position [m]')
ax[0].set(ylabel='DC output [V]',title='Reduced moving test: quasi-steady AC network + output capacitor + voltage PI')
ax[1].set_ylabel('Load current [A]');fig.savefig(ROOT/'moving_handover.png',dpi=160)
(ROOT/'moving_metrics.json').write_text(json.dumps(runs,indent=2))
