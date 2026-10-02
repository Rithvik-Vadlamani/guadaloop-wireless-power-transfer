from design_dd import *
from scipy.optimize import minimize
W=2*np.pi*250e3

def params(turns=3):
    c=dd(turns,60,diameter=.009,pitch=.014)
    L=mutual(c,c,self_term=True,radius=.0045)
    length=np.linalg.norm(c[1],axis=1).sum()+.4
    area=6000*np.pi*(.0635e-3)**2/4
    R=1.724e-8*length/area*(1+.00393*60)*1.5
    ms=mutual(c,c,(PITCH/2,0,.109));mc=mutual(c,c,(0,0,.109))
    lf=2*ms*100/72
    return dict(turns=turns,L=L,Lf=lf,Cf=1/(W*W*lf),Cp=1/(W*W*(L-lf)),Cs=1/(W*W*L),Rcoil=R,wire_length=length,area=area,Mcenter=mc,Mseam=ms),c

def solve(p,M,u,Rscale=1,capscale=1):
    n=4;j=1j
    rtx=.005*1.6 # EPC2304 200V GaN hot-resistance assumption
    rrx=.002*1.6 # 100V silicon MOSFET candidate, see separate datasheet
    zf=.006*Rscale+2*rtx+j*W*p['Lf']; zcf=.003+1/(j*W*p['Cf']*capscale)
    zcp=.005+1/(j*W*p['Cp']*capscale); zcs=.005+1/(j*W*p['Cs']*capscale)
    A=np.zeros((9,9),complex)
    for a in range(4):
        A[a,a]=zf+zcf;A[a,4+a]=-zcf
        A[4+a,a]=-zcf;A[4+a,4+a]=zcf+zcp+p['Rcoil']*Rscale
    A[4:9,4:9]+=j*W*M
    A[8,8]+=p['Rcoil']*Rscale+zcs+8*3/np.pi**2+2*rrx
    I=np.linalg.solve(A,np.r_[u,np.zeros(5)])
    v=abs(I[8])*2*np.sqrt(2)/np.pi*3
    losses=dict(coils=float(np.sum(abs(I[4:])**2)*p['Rcoil']*Rscale),Lf=float(np.sum(abs(I[:4])**2)*.006*Rscale),TX_channel=float(np.sum(abs(I[:4])**2)*2*rtx),RX_channel=float(abs(I[8])**2*2*rrx),capacitors=float(np.sum(abs(I[:4]-I[4:8])**2)*.003+np.sum(abs(I[4:8])**2)*.005+abs(I[8])**2*.005))
    return v,I,losses

def matrix(p,c,x):
    M=np.eye(5)*p['L']
    for a in range(4):
        for b in range(a+1,4):M[a,b]=M[b,a]=mutual(c,c,((b-a)*PITCH,0,0))
        M[a,4]=M[4,a]=mutual(c,c,(x-(a+.5)*PITCH,0,.109))
    return M

def operate(p,M):
    # Use the two bracketing sections (positive coupling), common fundamental phase.
    ms=np.maximum(M[:4,4],0);ratio=ms/max(ms);blend=np.clip((ratio-.15)/.35,0,1);blend=blend*blend*(3-2*blend);ms=ms*blend
    u=ms/max(ms)*90.0316316
    v,I,loss=solve(p,M,u)
    u*=60/v
    v,I,loss=solve(p,M,u)
    # Declared preliminary budgets, NOT a device-model switching simulation.
    active=np.count_nonzero(u>.1)
    loss.update(TX_switching_allowance=active*15.,RX_switching_allowance=4.,gate_drive=(active*4*26e-9*5+4*152e-9*10)*250e3,auxiliary=3.,output_capacitor=1.)
    return dict(Vout=v,Iout=v/3,Pout=v*v/3,eta=1200/(1200+sum(loss.values())),losses=loss,max_modulation=float(max(u)/90.0316316),u_rms=u.tolist(),I_rms=abs(I).tolist(),Cf_Vrms=(abs(I[:4]-I[4:8])/(W*p['Cf'])).tolist(),Cp_Vrms=(abs(I[4:8])/(W*p['Cp'])).tolist(),Cs_Vrms=float(abs(I[8])/(W*p['Cs'])),min_eig_H=float(min(np.linalg.eigvalsh(M))))
if __name__=='__main__':
    for n in [2,3,4,5]:
        p,c=params(n)
        print('PARAM',p)
        for x in [.5*PITCH,PITCH]:
            M=matrix(p,c,x);print('CASE',x,operate(p,M))
