from size_circuit import *
d=json.loads((ROOT/'final_design.json').read_text());p=d['parameters'];xs=np.array(d['x_m']);mat=np.array(d['matrices_H'])
valid=(xs>=PITCH/2)&(xs<=3.5*PITCH)
items=[]
for name,rscale,cscale,mscale,vin in [('nominal',1,1,1,100),('90V_bus',1,1,1,90),('caps_minus_1pct',1,.99,1,100),('caps_plus_1pct',1,1.01,1,100),('Rac_plus_50pct',1.5,1,1,100),('coupling_minus_20pct',1,1,.8,100)]:
 rows=[]
 for x,M0,c in zip(xs[valid],mat[valid],np.array(d['cases'],dtype=object)[valid]):
  M=M0.copy();M[:4,4]*=mscale;M[4,:4]*=mscale
  u=np.array(c['u_rms']);v,I,loss=solve(p,M,u,rscale,cscale);u*=60/v;v,I,loss=solve(p,M,u,rscale,cscale)
  base={k:v for k,v in c['losses'].items() if k not in loss};loss.update(base)
  rows.append(dict(x_m=x,modulation=max(u)/(2*np.sqrt(2)/np.pi*vin),eta=1200/(1200+sum(loss.values())),loss_W=sum(loss.values())))
 items.append(dict(case=name,max_required_modulation=max(r['modulation'] for r in rows),min_budget_efficiency=min(r['eta'] for r in rows),voltage_feasible=all(r['modulation']<=1 for r in rows),efficiency_budget_pass=all(r['eta']>=.94 for r in rows)))
(ROOT/'tolerances.json').write_text(json.dumps(items,indent=2));print(json.dumps(items,indent=2))
# Export center and worst-position summaries for test choice.
validcases=[(x,c) for x,c in zip(xs,d['cases']) if PITCH/2<=x<=3.5*PITCH]
print('worst modulation',max(validcases,key=lambda xc:xc[1]['max_modulation'])[0]);print('worst efficiency',min(validcases,key=lambda xc:xc[1]['eta'])[0])
