from size_circuit import *
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from scipy.io import savemat
p,c=params(3)
high=dd(3,240,diameter=.009,pitch=.014)
p['L']=mutual(high,high,self_term=True,radius=.0045)
p['Lf']=1/(W*W*100e-9);p['Cf']=1/(W*W*p['Lf'])
p['Cp']=1/(W*W*(p['L']-p['Lf']));p['Cs']=1/(W*W*p['L'])
# Constant physical compensation at every position, all mutual terms retained.
xs=np.linspace(0,4*PITCH,129)
Ms=np.array([matrix(p,c,x) for x in xs])
cases=[operate(p,M) for M in Ms]
convergence=[]
for n in [30,60,120,240]:
 cc=dd(3,n,diameter=.009,pitch=.014)
 convergence.append(dict(resolution=n,L_H=mutual(cc,cc,self_term=True,radius=.0045),M_center_H=mutual(cc,cc,(0,0,.109)),M_seam_H=mutual(cc,cc,(PITCH/2,0,.109))))
comparison={}
for orientation in ['transverse','longitudinal']:
 cc=dd(3,60,orientation,diameter=.009,pitch=.014)
 comparison[orientation]=[mutual(cc,cc,(x,0,.109)) for x in np.linspace(0,PITCH,65)]
# Lateral sensitivity at mid-track seam; positive weights remain coherently driven.
lateral=[]
for y in [0,.025,.05,.1]:
 M=matrix(p,c,2*PITCH)
 for j in range(4):M[j,4]=M[4,j]=mutual(c,c,(2*PITCH-(j+.5)*PITCH,y,.109))
 r=operate(p,M);r['offset_m']=y;lateral.append(r)
result={'parameters':p,'x_m':xs.tolist(),'matrices_H':Ms.tolist(),'cases':cases,'convergence':convergence,'lateral_cases':lateral,'orientation_M_H':comparison,'assumptions':{'N_per_lobe':3,'finished_bundle_diameter_mm':9,'pitch_mm':14,'strands':6000,'strand_diameter_mm':.0635,'copper_area_mm2':p['area']*1e6,'temperature_C':80,'Rac_Rdc_at_temperature':1.5,'clear_gap_mm':100,'center_plane_gap_mm':109,'ferrite':False,'metal_shield':False,'edge_clearance_mm':25,'pad_envelope_mm':[914.4,609.6]}}
(ROOT/'final_design.json').write_text(json.dumps(result,indent=2))
savemat(ROOT/'dd_parameters.mat',{'Lcoil':p['L'],'Lf':p['Lf'],'Cf':p['Cf'],'Cp':p['Cp'],'Cs':p['Cs'],'Rcoil':p['Rcoil'],'x_grid':xs,'L_grid':np.moveaxis(Ms,0,2),'u_grid':np.array([r['u_rms'] for r in cases])/90.0316316})
fig,ax=plt.subplots(3,1,figsize=(11,9),layout='constrained')
for j in range(4):
 for q in c[2]:ax[0].plot((q[:,0]+(j+.5)*PITCH)*1000,q[:,1]*1000,lw=.8,color=['#0072B2','#009E73','#D55E00','#CC79A7'][j])
ax[0].set(xlabel='Along track [mm]',ylabel='Across track [mm]',title='Selected DD pads: 3 turns in each D lobe, opposite circulation');ax[0].set_aspect('equal');ax[0].grid()
for o,v in comparison.items():ax[1].plot(np.linspace(0,PITCH,65)*1000,np.array(v)*1e6,label=o)
ax[1].axvline(PITCH*500,color='gray',ls='--');ax[1].legend();ax[1].set(xlabel='Displacement from one TX center [mm]',ylabel='Mutual inductance [µH]');ax[1].grid()
ax[2].plot(xs,[r['max_modulation'] for r in cases],label='Required modulation at 60 V');ax[2].axhline(1,color='red',ls='--',label='100 V bus limit');ax[2].axvspan(0,PITCH/2,color='gray',alpha=.1);ax[2].axvspan(3.5*PITCH,4*PITCH,color='gray',alpha=.1);ax[2].set(xlabel='Receiver center along track [m]',ylabel='Modulation');ax[2].legend();ax[2].grid()
fig.savefig(ROOT/'dd_geometry.png',dpi=170)
print('Selected:',p)
valid=[r for x,r in zip(xs,cases) if PITCH/2<=x<=3.5*PITCH]
print('fully-on-track modulation max',max(r['max_modulation'] for r in valid),'eta min',min(r['eta'] for r in valid))
print('edge modulation',cases[0]['max_modulation']);print('convergence',convergence)
