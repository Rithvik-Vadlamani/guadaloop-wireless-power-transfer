from design_dd import *
from scipy.optimize import brentq
# Five-turn circular compensation coil, same 9 mm litz bundle, fixed fill ratio.
def coil(outer,res=240):
 inner=.4*outer;rs=np.linspace(inner/2+.0045,outer/2-.0045,5)
 ps=[]
 for radius in rs:
  t=np.linspace(0,2*np.pi,res+1);ps.append(np.c_[radius*np.cos(t),radius*np.sin(t),t*0])
 return np.concatenate([(p[1:]+p[:-1])/2 for p in ps]),np.concatenate([np.diff(p,axis=0) for p in ps]),ps
want=1/((2*np.pi*250e3)**2*100e-9)
out=brentq(lambda d:mutual(coil(d),coil(d),self_term=True,radius=.0045)-want,.17,.3,xtol=1e-7)
c=coil(out);length=np.linalg.norm(c[1],axis=1).sum()+.4;area=6000*np.pi*(.0635e-3)**2/4
D=dict(turns=5,outer_envelope_m=out,inner_opening_m=.4*out,bundle_diameter_m=.009,center_pitch_m=(.3*out-.009)/4,wire_length_with_leads_m=length,L_H=mutual(c,c,self_term=True,radius=.0045),Rdc_80C_ohm=1.724e-8*length/area*(1+.00393*60),Rac_80C_estimate_ohm=1.724e-8*length/area*(1+.00393*60)*1.5,design_Rac_limit_ohm=.006)
(ROOT/'compensation_coil.json').write_text(json.dumps(D,indent=2));print(D)
