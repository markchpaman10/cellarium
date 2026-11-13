-- Authored personality, never model-generated. Fact text is immutable here.
local P={seen={},last={},cursor={}}
local lines={
 generic={'The clipboard remains optimistic.','One procedure at a time. Revolutionary, I know.','The lab is complicated. The instructions are at least consistent.','I have translated the paperwork into English.','Precision first. Dramatic announcements later.','We can save the theatrical reveal for after the measurements.','I prefer results that survive being written down.','The clipboard has room for both curiosity and a plan.','Let us give the measurements a speaking role.','A clear label can do remarkable things for a mystery.','I am being helpful. The commentary is complimentary.','A controlled experiment. What a concept.','The cells did not read our expectations.','Let us keep the procedure less exotic than the organism.','We have enough variables without adding improvisation.'},
 create={'Try not to invent a new species of paperwork.','An ambitious plan. Let us include the necessary cells this time.','The checklist is less exciting than a breakthrough, but considerably more useful.'},
 install={'The DNA gets its own dock. Apparently the machine appreciates personal space.','Three connections. A surprisingly persistent plot twist.','The blank cell is the recipient, not an optional decoration.'},
 culture_problem={'The culture has conditions. It is not negotiating them.','Cells are demanding tenants. Food and space are on the lease.','The container has supplied an actual status. How refreshingly specific.'},
 movement={'Viable and athletic are different qualifications.','Nature permits some rather unambitious transportation solutions.','Anatomy gets the final vote on locomotion.'},
 death={'The record is more useful than a dramatic theory.','I would prefer a living specimen. I will settle for an accurate record.','Let us keep the explanation better supported than the experiment.'},
 rack={'Eight slots. A finite number, despite our aspirations.','Personal space for vials. A breakthrough in laboratory etiquette.'},
 empty={'The count wins the argument with the glassware.','I consulted the contents rather than the atmosphere.'},
 transfer_problem={'The dropper retains the sample. At least someone here is holding things together.','Let us check the destination before blaming gravity.'}
}
local repeated={'Same procedure. Let us keep the steps in the same order.','We have met this question before. The answer has remained admirably consistent.','Again? Fine. Here are the actual steps.','I still have the instructions. Conveniently, so do you now.','The rules did not change during that question.','The clipboard and I have discussed this. We still agree.','A repeatable answer. The foundation of science.','I checked again. It remains the same procedure.','Consider this the increasingly familiar version.','My patience is finite. The instructions are reusable.','Same question, freshly checked facts.','We are becoming experts at this particular conversation.'}
function P.decorate(answer,level)
 level=math.max(0,math.min(2,tonumber(level) or 1));local key=tostring(answer.intent)..':'..tostring(answer.subject or '')
 P.seen[key]=(P.seen[key] or 0)+1
 if level==0 or answer.intent=='unknown' or answer.scope=='Missing specimen' or answer.scope=='Missing container' or answer.scope=='Specimen clarification' or answer.scope=='No supported conclusion' then return answer.text end
 if answer.intent=='smart' or answer.intent=='hello' or answer.intent=='offline' or answer.intent=='personality' then return answer.text end
 local repeatCount=P.seen[key];local eligible=level==2 or repeatCount%3==1
 if not eligible then return answer.text end
 local jokeIntent=answer.scope=='Current organism record' and 'death' or answer.intent;local useRepeated=repeatCount>1 and repeatCount%4==0;local useSpecific=lines[jokeIntent] and repeatCount%2==1;local pool=useRepeated and repeated or useSpecific and lines[jokeIntent] or lines.generic;local poolKey=useRepeated and 'repeated' or useSpecific and jokeIntent or 'generic';local i=(P.cursor[poolKey] or 0)%#pool+1
 if pool[i]==P.last[key] and #pool>1 then i=i%#pool+1 end;P.cursor[poolKey]=i;P.last[key]=pool[i]
 return answer.text..'\n\n'..pool[i]
end
return P
