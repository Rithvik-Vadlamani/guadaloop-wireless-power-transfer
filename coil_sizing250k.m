function design = coil_sizing250k()
%COIL_SIZING250K Conditional air-core examples, not a fabrication release.
% Circular current-sheet self-L estimate and coaxial filament mutual-L sum.
% No ferrite, shields, lateral offset, inter-turn capacitance or proximity loss.
p=dwpt250k_parameters();mu0=4*pi*1e-7;rhoCopper=1.724e-8;
design.assumptions='Air core, identical coaxial transfer coils, 20 C copper, no nearby metal. Approximate geometry only.';
design.transfer=spiral(22,150e-3,50e-3,1.6e-3,250,0.0635e-3);
design.compensation=spiral(12,88e-3,33e-3,1.6e-3,250,0.0635e-3);
design.copper_skin_depth_m=sqrt(2*rhoCopper/(2*pi*p.f*mu0));
r=design.transfer.turn_center_radii_m;
Mtarget=p.k*sqrt(p.LP1*p.LS);
design.gap_for_nominal_mutual_m=fzero(@(z)mutual(r,z)-Mtarget,[.005 .15]);
gaps=[.010 .020 .030 .040 .050 .060];
for j=1:numel(gaps)
    value=mutual(r,gaps(j));
    design.gap_sweep(j)=struct('gap_m',gaps(j),'mutual_H',value, ...
        'k_using_estimated_self_L',value/design.transfer.inductance_H);
end
design.note='Gap estimates assume perfect coaxial alignment. Measure installed L, M, AC resistance and self-resonance before selecting final compensation components.';
disp(design);
root=fileparts(mfilename('fullpath'));
fid=fopen(fullfile(root,'design250k','coil_estimates.json'),'w');
fprintf(fid,'%s',jsonencode(design,PrettyPrint=true));fclose(fid);
end
function c=spiral(N,outer,inner,bundle,strands,strandDiameter)
mu0=4*pi*1e-7;davg=(outer+inner)/2;fill=(outer-inner)/(outer+inner);
c.turns=N;c.outer_diameter_m=outer;c.inner_diameter_m=inner;
c.bundle_outer_diameter_m=bundle;c.strands=strands;c.strand_diameter_m=strandDiameter;
c.inductance_H=mu0*N^2*davg/2*(log(2.46/fill)+0.2*fill^2);
c.turn_center_radii_m=linspace(inner/2+bundle/2,outer/2-bundle/2,N);
c.pitch_m=diff(c.turn_center_radii_m(1:2));
c.inter_turn_clearance_m=c.pitch_m-bundle;
assert(c.inter_turn_clearance_m>0,'Winding does not fit.');
c.wire_length_m=sum(2*pi*c.turn_center_radii_m);
c.copper_area_m2=strands*pi*(strandDiameter/2)^2;
c.dc_resistance_20C_ohm=1.724e-8*c.wire_length_m/c.copper_area_m2;
% Independent Wheeler flat-spiral estimate (radius and radial width in inches).
r=davg/2/0.0254;width=(outer-inner)/2/0.0254;
c.wheeler_inductance_H=1e-6*r^2*N^2/(8*r+11*width);
end
function M=mutual(r,gap)
mu0=4*pi*1e-7;a=r(:);b=r(:)';
m=4*(a*b)./((a+b).^2+gap^2);
[K,E]=ellipke(m);
M=sum(mu0*sqrt(a*b).*((2-m).*K-2*E)./sqrt(m),'all');
end
