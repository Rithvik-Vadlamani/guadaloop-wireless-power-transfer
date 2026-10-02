from design_dd import *
from scipy.special import ellipk,ellipe
c=dd();data=json.loads((ROOT/'final_design.json').read_text())
assert len(c[2])==6
for q in c[2]:
 assert np.allclose(q[0],q[-1])
 assert max(abs(q[:,0]))+.0045<=.9144/2-.025+1e-12
 assert max(abs(q[:,1]))+.0045<=.6096/2-.025+1e-12
m=mutual(c,c,(0,0,.109));assert abs(m/data['parameters']['Mcenter']-1)<1e-10
fwd=mutual(c,c,(.3,.04,.109));rev=mutual(c,c,(-.3,-.04,-.109));assert abs(fwd-rev)<1e-14
ls=np.array(data['matrices_H']);assert np.allclose(ls,np.swapaxes(ls,1,2));mineig=float(np.linalg.eigvalsh(ls).min());assert mineig>0
th=np.linspace(0,2*np.pi,481);points=np.c_[.2*np.cos(th),.2*np.sin(th),0*th];circle=((points[1:]+points[:-1])/2,np.diff(points,axis=0),[points]);z=.106;r=.2;k2=4*r*r/(4*r*r+z*z);k=np.sqrt(k2)
exact=4*np.pi*MU*r*((2/k-k)*ellipk(k2)-2/k*ellipe(k2));numeric=mutual(circle,circle,(0,0,z));error=abs(numeric/exact-1);assert error<5e-5
p=data['parameters'];w=2*np.pi*250000
assert abs(w*w*p['Lf']*p['Cf']-1)<1e-12
assert abs(w*w*(p['L']-p['Lf'])*p['Cp']-1)<1e-12
assert abs(w*w*p['L']*p['Cs']-1)<1e-12
result=dict(result='PASS',DD_loops_per_pad=len(c[2]),reciprocity_error_H=abs(fwd-rev),minimum_inductance_matrix_eigenvalue_H=mineig,circle_benchmark_relative_error=error,LCC_resonance_identities=True)
(ROOT/'geometry_checks.json').write_text(json.dumps(result,indent=2));print(json.dumps(result,indent=2))
