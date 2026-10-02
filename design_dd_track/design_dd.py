"""DD air-core filament geometry and multi-transmitter LCC-S circuit design.
SI units. No ferrite, shield, steel, leads or distributed capacitance in field model.
"""
from pathlib import Path
import numpy as np
from scipy.spatial.distance import cdist
import json
ROOT=Path(__file__).resolve().parent
MU=1e-7
PITCH=.9144

def dd(nturn=3, resolution=60, orientation='transverse', diameter=.009, pitch=.014):
    # 25 mm edge clearance, including wire radius. Opposite traversal of lobes.
    length=.9144-.050-diameter; width=.6096-.050-diameter
    if orientation=='longitudinal':length,width=width,length
    loops=[]
    for j in range(nturn):
        a=length/2-j*pitch; y0=diameter/2+.002+j*pitch
        b=width/2-y0-j*pitch
        theta=np.linspace(0,np.pi,resolution+1)
        arc=np.c_[a*np.cos(theta),y0+b*np.sin(theta),np.zeros_like(theta)]
        line=np.c_[np.linspace(-a,a,resolution+1)[1:],np.full(resolution,y0),np.zeros(resolution)]
        upper=np.vstack([arc,line])
        lower=upper*np.array([1,-1,1])
        loops.extend([upper,lower])
    if orientation=='longitudinal':loops=[p[:,[1,0,2]] for p in loops]
    dl=np.concatenate([np.diff(p,axis=0) for p in loops]); mid=np.concatenate([(p[1:]+p[:-1])/2 for p in loops])
    return mid,dl,loops

def mutual(c1,c2,offset=(0,0,0),self_term=False,radius=.0045):
    p,d,_=c1;q,e,_=c2
    dist=cdist(p,q+np.array(offset))
    if self_term:
        # Regularized filament kernel using round-conductor GMD at uniform current.
        # This approximates bundle self-inductance; convergence/uncertainty reported.
        a=radius*np.exp(-.25)
        dist=np.sqrt(dist**2+a*a)
    product=d@e.T
    v=product/dist
    if self_term:
        lengths=np.linalg.norm(d,axis=1)
        np.fill_diagonal(v,2*(lengths*np.arcsinh(lengths/a)-np.sqrt(lengths**2+a*a)+a))
    return MU*np.sum(v)
