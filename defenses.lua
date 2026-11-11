local D={}
-- Future injury interface only. There is deliberately no battle loop or attack AI.
function D.response(cover,mechanism,load)
 local armor=cover.armor or 0;local flex=cover.flexibility or .5
 local capacity=mechanism=='pierce' and armor*(.5+(cover.hardness or 0))*8 or mechanism=='tear' and ((cover.thickness or .2)*(cover.keratinization or .2)+flex*.2)*8 or (armor*.3+flex*(cover.thickness or .2))*8
 local transmitted=math.max(0,load-capacity*(cover.condition or 1));return {capacity=capacity,transmitted=transmitted,absorbed=load-transmitted}
end
function D.impact(a,id,mechanism,load)
 local part=a.components[id];if not part then return nil end;local response=D.response(part,mechanism,load);part.condition=math.max(0,part.condition-response.transmitted/(5+(part.strength or 1)))
 if part.parent and response.transmitted>(part.attachmentStrength or 1000) then local host=a.components[part.parent];host.condition=math.max(0,host.condition-response.transmitted*.01) end
 return response
end
return D
