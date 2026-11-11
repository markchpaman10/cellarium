local G=require('genome');local K={}
K.types={'Stem','Muscle','Nerve','Epithelial','Blood','Structural','Adipose'}
K.functions={'Differentiation and regeneration','Contraction and force','Signaling and coordination','Protection; digestive specialization','Transport of gases and nutrients','Support and leverage','Energy storage and insulation'}
K.rates={1.15,.75,.55,1.1,.9,.8,.85}
K.replicationLimits={20,10,5,16,12,10,12}
function K.cell(id,typ,genome,source,generation,strain)
 return {id=id,type=typ,genome=G.copy(genome),strain=strain or id,name='Strain '..(strain or id),generation=generation or 0,parent=source or 'Wild sample',parents={source or 'Wild sample'},health=1,viability=1,energy=1,replicationCapacity=K.replicationLimits[typ],age=0,tolerance=G.express(genome)[10],differentiation=typ==1 and 'pluripotent' or 'specialized',preservation='living',mutationHistory=G.copy(genome.mutations),mutated=#genome.mutations>0}
end
function K.dish(c,medium)
 return {cell=c,medium=medium,progress=0,nutrients=1,energy=1,temperature=37,waste=0,population=1,contamination=0,sterility=1,health=c.health,viable=0,elapsed=0}
end
function K.update(d,dt)
 if d.failed then return end
 d.elapsed=d.elapsed+dt
 local e=G.express(d.cell.genome);local suitability=math.max(0,1-math.abs(d.temperature-37)/(14+e[10]*10));local density=math.max(.15,1-d.population/8)
 local growth=K.rates[d.cell.type]*(.65+e[6]*.3+e[1]*.05)*suitability*d.nutrients*d.energy*(1-d.contamination)*d.health*density/(d.medium==2 and 9 or 15)
 d.progress=math.min(1,d.progress+dt*growth);d.population=1+d.progress*4;d.viable=math.floor(d.progress*4+.00001)
 if d.progress>=1 then d.viable=math.min(4,math.floor(4*d.health+.1)) end
 d.nutrients=math.max(0,d.nutrients-dt*growth*.25);d.energy=math.max(0,d.energy-dt*growth*.17);d.waste=math.min(1,d.waste+dt*growth*.22)
 d.contamination=math.min(1,d.contamination+dt*(1-d.sterility)*.003*(1+d.waste))
 local stress=(1-suitability)*.014+d.contamination*.018+math.max(0,d.waste-.6)*.02
 d.health=math.max(0,math.min(1,d.health-dt*stress));d.cell.age=d.cell.age+dt;d.cell.health=d.health;d.cell.energy=d.energy;d.cell.viability=d.health*(.75+.25*d.energy)
 if d.health<=.05 then d.failed='Culture died: temperature stress, contamination or waste.' end
end
function K.mutationRate(d) local stability=G.express(d.cell.genome).stability;return (d.medium==3 and .035 or .003)*(1.4-stability)+d.contamination*.02+math.abs(d.temperature-37)*.0004 end
return K
