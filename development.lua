local A=require('anatomy');local G=require('genome');local D={}
D.stages={'Zygote','Cleavage','Proliferation','Differentiation','Body plan','Organogenesis','Viability check','Juvenile release'}
function D.new(id,g,parents,generation,conditions) local embryo={id=id,genome=G.copy(g),parents=parents,generation=generation or 0,conditions=G.copy(conditions or {nutrition=1,temperature=37}),progress=0,stage='Zygote',tissues={}};local a=A.generate(g,embryo.conditions);if a.anatomicalVersion==2 then embryo.anatomy=a;embryo.potentialViable=a.viable;require('anatomical_development').setProgress(a,0,{fatFraction=.7});a.growthModel.elapsed=0 else embryo.pendingAnatomy=a end;return embryo end
function D.update(e,dt)
 if not e.anatomy then local body=e.pendingAnatomy or A.generate(e.genome,e.conditions);if body.anatomicalVersion==2 then e.anatomy=body;e.potentialViable=body.viable;require('anatomical_development').setProgress(body,(e.progress or 0)*body.growthModel.embryonicFraction,{fatFraction=.7}) else e.pendingAnatomy=body end end
 if e.anatomy and e.anatomy.anatomicalVersion==2 then local a=e.anatomy;require('anatomical_development').advance(a,dt,e.conditions);e.progress=math.min(1,a.growthModel.progress/a.growthModel.embryonicFraction);e.stage=D.stages[math.min(8,1+math.floor(e.progress*8))];e.constructionFrame=nil;e.tissues={};for _,c in ipairs(a.components) do e.tissues[c.type]=(e.tissues[c.type] or 0)+c.volume end;a.caps=A.capabilities(a,e.genome);if e.progress>=1 then a.viable,a.failures=A.validate(a);if not a.viable and e.potentialViable and a.growthModel.progress<1 then e.stage='Incubating / organ maturation';return nil end;return a.viable,a.failures end;return nil end
 e.progress=math.min(1,e.progress+dt/(24*(e.anatomy and 1/(e.anatomy.growthFactor or 1) or 1)));e.stage=D.stages[math.min(8,1+math.floor(e.progress*8))]
 if e.progress>.35 and not e.anatomy then e.anatomy=e.pendingAnatomy or A.generate(e.genome,e.conditions);e.pendingAnatomy=nil end
 if e.anatomy and e.anatomy.anatomicalVersion then e.constructionFrame=math.max(1,math.min(#e.anatomy.snapshots,math.floor((e.progress-.35)/.65*#e.anatomy.snapshots)+1)) end
 if e.anatomy then local fraction=math.min(1,(e.progress-.35)/.5);for k,v in pairs(e.anatomy.tissues) do e.tissues[k]=v*fraction end end
 if e.progress>=1 then return e.anatomy.viable,e.anatomy.failures end;return nil
end
return D
