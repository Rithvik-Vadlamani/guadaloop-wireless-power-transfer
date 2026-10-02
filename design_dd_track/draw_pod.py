from design_dd import *
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle
c=dd(3,60,diameter=.009,pitch=.014)
fig=plt.figure(figsize=(13,5.6),layout='constrained');ax=fig.add_subplot(121);b=fig.add_subplot(122,projection='3d')
for n,p in enumerate(c[2]):
 ax.plot(p[:,0]*1000,p[:,1]*1000,c='#0072B2' if n%2==0 else '#D55E00',lw=2)
 for z,color in [(0,'#0072B2'),(109,'#009E73')]:b.plot(p[:,0]*1000,p[:,1]*1000,np.full(len(p),z),color=color,lw=1)
ax.add_patch(Rectangle((-457.2,-304.8),914.4,609.6,fill=False,ls='--',ec='gray'))
for y in [6.5,-6.5]:ax.annotate('',xy=(180,y),xytext=(60,y),arrowprops=dict(arrowstyle='->',color='black',lw=1.6))
ax.text(0,160,'D lobe: 3 turns',ha='center',fontsize=12,color='#0072B2');ax.text(0,-160,'D lobe: 3 turns',ha='center',fontsize=12,color='#D55E00')
ax.set(xlim=(-490,490),ylim=(-330,330),xlabel='Travel direction [mm]',ylabel='Track width [mm]',title='Identical DD winding for each track pad and the pod');ax.set_aspect('equal');ax.grid(alpha=.2)
b.text(-430,-285,117,'Pod DD receiver',color='#009E73',fontsize=11);b.text(-430,-285,-20,'Track DD transmitter',color='#0072B2',fontsize=11)
b.set(xlabel='Length [mm]',ylabel='Width [mm]',zlabel='Height [mm]',zlim=(-30,160),title='100 mm clear gap; 109 mm center-plane spacing')
b.set_box_aspect((914.4,609.6,190));b.view_init(elev=26,azim=-65)
fig.savefig(ROOT/'dd_pod_geometry.png',dpi=180)
