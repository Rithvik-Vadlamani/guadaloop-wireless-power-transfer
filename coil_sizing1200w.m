function design=coil_sizing1200w()
%COIL_SIZING1200W Air-core candidate within a 3 ft x 2 ft envelope at 10 mm clear gap.
p=dwpt1200w_parameters();
design.envelope_m=[.9144 .6096];
design.clear_surface_gap_m=.010;
design.assumptions='Aligned circular air-core single-layer coils; no ferrite, chassis metal, lateral offset or parasitic capacitance. Bundle thickness estimated at 6 mm.';
design.transfer=spiral(5,.300,.200,.006,2500,.0635e-3);
design.winding_center_plane_spacing_m=design.clear_surface_gap_m+design.transfer.bundle_outer_diameter_m;
design.mutual_H=mutual(design.transfer.turn_center_radii_m,design.winding_center_plane_spacing_m);
design.k=design.mutual_H/design.transfer.inductance_H;
assert(abs(design.transfer.inductance_H/p.LP1-1)<1e-8);
assert(abs(design.k/p.k-1)<1e-7);
assert(design.transfer.outer_diameter_m<min(design.envelope_m));
% Scale a 5-turn, inner/outer ratio 0.4 circular winding to required Lf.
base=spiral(5,.200,.080,.006,2500,.0635e-3);
scale=p.LT1/base.inductance_H;
design.compensation=spiral(5,.200*scale,.080*scale,.006,2500,.0635e-3);
design.transfer_AC_resistance_assumption_ohm=2*design.transfer.dc_resistance_20C_ohm;
design.compensation_AC_resistance_assumption_ohm=p.RT1;
design.copper_skin_depth_m=sqrt(2*1.724e-8/(2*pi*p.f*4*pi*1e-7));
for j=1:5
    gaps=[.005 .010 .015 .020 .030];
    value=mutual(design.transfer.turn_center_radii_m,gaps(j)+.006);
    design.gap_sweep(j)=struct('clear_gap_m',gaps(j),'mutual_H',value,'k',value/design.transfer.inductance_H);
end
design.note='Winding and coupling estimates are design inputs, not measured or FEM-validated hardware. AC resistance factor 2 is an assumption. Measure installed inductance, coupling, AC loss, self-resonance and temperature.';
root=fileparts(mfilename('fullpath'));
fid=fopen(fullfile(root,'design1200w','coil_estimates.json'),'w');
fprintf(fid,'%s',jsonencode(design,PrettyPrint=true));fclose(fid);
disp(design);
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
