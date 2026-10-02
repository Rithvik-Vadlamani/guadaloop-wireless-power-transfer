from pathlib import Path
import json,numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle,FancyArrowPatch
r=Path(__file__).resolve().parent;d=json.loads((r/'final_design.json').read_text());p=d['parameters']
fig,ax=plt.subplots(figsize=(15,9));ax.set(xlim=(0,15),ylim=(0,9));ax.axis('off')
blue='#006699';green='#13856b'
def line(x,y,c='black',ls='-'):ax.plot(x,y,c=c,lw=1.4,ls=ls)
def box(x,y,w,h,text,c=blue):
 ax.add_patch(Rectangle((x,y),w,h,fill=False,ec=c,lw=1.7));ax.text(x+w/2,y+h/2,text,ha='center',va='center',fontsize=9,color=c)
def cap(x,y,label,vertical=False):
 if vertical:
  line([x,x],[y+.38,y+.08]);line([x-.17,x+.17],[y+.08,y+.08]);line([x-.17,x+.17],[y-.08,y-.08]);line([x,x],[y-.08,y-.38]);ax.text(x+.25,y,label,va='center',fontsize=9)
 else:
  line([x-.38,x-.08],[y,y]);line([x-.08,x-.08],[y-.17,y+.17]);line([x+.08,x+.08],[y-.17,y+.17]);line([x+.08,x+.38],[y,y]);ax.text(x,y+.27,label,ha='center',fontsize=9)
def coil(x,y,label):
 t=np.linspace(0,np.pi*6,100);ax.plot(x-.35+.7*t/(6*np.pi),y+.12*np.sin(t),color='black');ax.text(x,y+.23,label,ha='center',fontsize=9)
ax.text(.3,8.65,'Four-section DD-to-DD wireless power circuit',fontsize=20,weight='bold')
ax.text(.3,8.27,'100 V maximum DC input • 250 kHz • 100 mm clear winding gap • 60 V / 20 A target',fontsize=12)
box(.2,4.2,1.45,1.05,'100 V DC\ncommon bus\n≥ 1.277 kW')
line([1.65,2],[4.7,4.7]);line([2,2],[2,7.3])
for j in range(4):
 y=7.1-j*1.55
 line([2,2.3],[y,y]);box(2.3,y-.38,1.55,.8,f'TX{j+1} full bridge\n4 × 200 V GaN')
 line([3.85,4.2],[y,y]);coil(4.55,y,f'Lf {p["Lf"]*1e6:.2f} µH');line([4.9,5.25],[y,y]);cap(5.63,y,f'Cp {p["Cp"]*1e9:.2f} nF');line([6.01,6.5],[y,y]);box(6.5,y-.32,1.15,.65,f'DD TX{j+1}\n{p["L"]*1e6:.2f} µH')
 line([7.65,7.85,7.85,3.85],[y,y,y-.68,y-.68]);line([3.85,3.85],[y-.68,y-.2]);line([5.03,5.03],[y,y-.08]);cap(5.03,y-.34,'Cf\n100.00 nF',True)
 ax.text(7.98,y,f'M{j+1}(x)',fontsize=9,color=green);line([8.55,9],[y,y],green,'--')
box(9,3.35,1.2,1.25,'DD pod RX\n21.96 µH\n3 turns / D',green)
line([9,9],[3.35,7.1],green,'--')
line([10.2,10.45],[4.2,4.2]);cap(10.83,4.2,'Cs 18.46 nF');line([11.21,11.6],[4.2,4.2]);box(11.6,3.6,1.4,1.25,'Synchronous\nrectifier\n4 × 100 V\nMOSFET',green)
line([10.2,11.6],[3.6,3.6]);line([13,14.35],[4.2,4.2]);line([13,14.35],[3.6,3.6]);cap(13.45,3.9,'',True);ax.text(13.45,3.28,'2200 µF\nlow-ESR bank',ha='center',fontsize=9)
box(14.05,3.64,.65,.52,'3 Ω',green);line([14.35,14.35],[3.6,3.64]);line([14.35,14.35],[4.16,4.2]);ax.text(14.2,4.6,'60 V\n20 A\n1.2 kW',ha='center',fontsize=12,color=green)
box(9,1.4,5.7,1.15,'Common-phase 250 kHz PWM + voltage PI\nPosition-based sharing between adjacent sections\nDead time: 20 ns TX / 40 ns SR; SR follows RX current\nInactive TX: low-side clamp; LCC stays connected')
ax.text(.3,.65,'Compensation: Cf = 1/(ω²Lf), Cp = 1/[ω²(LTX − Lf)], Cs = 1/(ω²LRX).  Four identical LCC branches; series-compensated receiver.',fontsize=10)
ax.text(.3,.28,'Circuit values are simulation targets. 94% requires the stated hot-resistance and switching-loss budgets; component/thermal validation remains necessary.',fontsize=9,color='#993300')
fig.savefig(r/'final_circuit.png',dpi=180,bbox_inches='tight');fig.savefig(r/'final_circuit.svg',bbox_inches='tight');plt.close(fig)
