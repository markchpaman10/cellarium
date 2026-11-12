local A=require('anatomy');local G=require('genome');local D={}
D.stages={'Zygote','Cleavage','Proliferation','Differentiation','Body plan','Organogenesis','Viability check','Juvenile release'}
function D.new(id,g,parents,generation,conditions) return {id=id,genome=G.copy(g),parents=parents,generation=generation or 0,conditions=G.copy(conditions or {nutrition=1,temperature=37}),progress=0,stage='Zygote',tissues={}} end
function D.update(e,dt)
 e.progress=math.min(1,e.progress+dt/(24*(e.anatomy and 1/(e.anatomy.growthFactor or 1) or 1)));e.stage=D.stages[math.min(8,1+math.floor(e.progress*8))]
 if e.progress>.35 and not e.anatomy then e.anatomy=A.generate(e.genome,e.conditions) end
 if e.anatomy and e.anatomy.anatomicalVersion then e.constructionFrame=math.max(1,math.min(#e.anatomy.snapshots,math.floor((e.progress-.35)/.65*#e.anatomy.snapshots)+1)) end
 if e.anatomy then local fraction=math.min(1,(e.progress-.35)/.5);for k,v in pairs(e.anatomy.tissues) do e.tissues[k]=v*fraction end end
 if e.progress>=1 then return e.anatomy.viable,e.anatomy.failures end;return nil
end
return D
