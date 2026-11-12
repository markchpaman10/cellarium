local A=require('anatomy');local G=require('genome');local D={}
D.stages={'Genome activation','Initial cell division','Early embryo','Body-axis formation','Tissue differentiation','Organ development','Viability check','Juvenile release'}
function D.new(id,g,parents,generation,conditions) return {id=id,genome=G.copy(g),parents=parents,generation=generation or 0,conditions=G.copy(conditions or {nutrition=1,temperature=37}),progress=0,stage='Zygote',tissues={}} end
function D.update(e,dt)
 e.progress=math.min(1,e.progress+dt/(24*(e.anatomy and 1/(e.anatomy.growthFactor or 1) or 1)));e.stage=D.stages[math.min(8,1+math.floor(e.progress*8))]
 if e.progress>.35 and not e.anatomy then e.anatomy=A.generate(e.genome,e.conditions) end
 e.population=math.floor(2^(math.min(18,e.progress*18)));e.energyDemand=e.population*.00001;e.nutrientUse=(e.nutrientUse or 0)+dt*e.energyDemand;e.developmentalHistory=e.developmentalHistory or {};if not e.developmentalHistory[#e.developmentalHistory] or e.developmentalHistory[#e.developmentalHistory].stage~=e.stage then e.developmentalHistory[#e.developmentalHistory+1]={stage=e.stage,population=e.population,progress=e.progress} end
 if e.anatomy then local fraction=math.min(1,(e.progress-.35)/.5);for k,v in pairs(e.anatomy.tissues) do e.tissues[k]=v*fraction end end
 if e.progress>=1 then return e.anatomy.viable,e.anatomy.failures end;return nil
end
return D
