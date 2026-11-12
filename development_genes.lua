-- Secondary loci extend the original 24 pairs; primary alleles are never replaced.
local D={names={'Axis elongation','Axis breadth','Axis curvature','Symmetry program','Segmentation drive','Branch initiation','Branch placement','Extension length','Extension girth','Joint differentiation','Support rigidity','Tissue allocation','Organ positioning','Sensory proliferation','Covering texture','Metabolic efficiency','Branch recursion','Radial distribution','Axis orientation','External support','Muscle distribution','Organ multiplicity','Sensory placement','Growth termination'}}
function D.expression(g)
 local d={};for i,name in ipairs(D.names) do local l=g.chromosomes[i].loci[2];local v=l and (l.a+l.b)/6 or .5;d[i]=v;d[name]=v end
 d.symmetry=d[4]<=1/3+.0001 and 'bilateral' or d[4]<=2/3+.0001 and 'radial' or 'asymmetric'
 d.rigidity=d[11];d.segments=1+math.floor(d[5]*10+.01)
 d.branchRoots=d[6]<=1/3+.0001 and 0 or 1+math.floor((d[6]-1/3)*5)
 d.branchDepth=d[17]>.67 and 2 or 1
 d.joints=math.floor(d[10]*3+.01);d.budget=math.floor(18+d[24]*32)
 return d
end
return D
