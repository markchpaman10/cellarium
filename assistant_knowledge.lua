-- Verified rules and read-only live-state explanations. The model cannot write this table.
local M=require('desktop_model');local V=require('vessels');local K={}
local answers={
 hello='Hello. I am Jenny, your laboratory assistant. Ask me about Cellarium, or select a specimen and ask what is happening to it.',
 capabilities='I can explain Cellarium procedures and inspect your current cultures, workstation, embryos and organisms. I do not perform experiments or alter samples when answering. If the evidence is missing, I will say so.',
 create='Buy a blank developmental cell from the Cellarium tray menu; it arrives in a vial for 1 credit. Put that vial at the workstation INPUT, an empty container at OUTPUT, and your DNA vial in the purple DNA dock. Install the DNA. Open the output container and begin development to incubate its installed cell. Development can fail; a generated body is not guaranteed to be viable.',
 buy='Right-click the Cellarium tray icon and choose Buy supplies. Each ordinary cell or blank developmental cell costs 1 credit and includes its own vial. Separately purchased containers arrive empty.',
 blank='A blank developmental cell is the purchased recipient for a genome. It costs 1 credit with its vial. Install DNA into it at the workstation; an ordinary cell cannot substitute for a blank in that operation.',
 workstation='The workstation extracts DNA, installs DNA in blank cells, and prepares egg or sperm precursors. It does not store or cultivate cells. Attach the source cell container at INPUT and a separate empty container at OUTPUT. DNA vials use the purple DNA dock.',
 install='Drag a DNA vial onto the workstation; it snaps into the purple DNA dock. Put a purchased blank-cell vial at INPUT and a separate empty container at OUTPUT. Open and thaw the cell containers, then click Install selected DNA. One blank is consumed; the exact attached genome goes into one living output cell. The archived DNA remains available.',
 extract='Attach a container holding an ordinary cell at the workstation INPUT and click Extract DNA to genome archive. The source cell stays alive in its container. Extraction does not need a physical output container; blanks and haploid precursors cannot be used as ordinary DNA sources.',
 edit='Open a DNA record in the Genome Forge, edit its allele values or other gene controls, then preview and archive the genome. Editing a draft does not rewrite an existing living organism. Install the archived genome into a blank developmental cell and incubate it to grow a new organism.',
 dosage='In the Forge, duplicate increases gene copy count, delete sets that locus to zero copies, restore returns its normal copy state, and regulate changes expression control. Splice copies the selected locus from the chosen donor. These are changes to the draft genome; archive and install the result to develop it.',
 incubate='After installing DNA, open the actual output container and choose its begin-development action. It consumes one installed developmental cell and adds its embryo to incubation. An ordinary uninstalled cell or a blank without DNA cannot start that process.',
 growth='Embryos advance in real time under their stored developmental conditions. The early cell state gives way to tissue populations and staged anatomy. Otherwise viable embryos remain incubating until their organs can function; some genomes fail development. Later growth in this version still follows adult-target schedules.',
 movement='Movement depends on generated anatomy, available muscle force, motor nerves, joint mobility, support, balance, energy, oxygen and fatigue. Legged bodies need ground contacts; suitable limbless bodies can undulate. A viable organism can still be immobile. Select a particular organism or give its ID for its current readings.',
 death='Select the deceased organism in Records or name its organism ID. I will use its recorded death cause. I cannot reliably diagnose a death from a screenshot or guess which specimen you mean.',
 stats='Select an organism or give its ID so I can report the current health, energy, oxygen, fatigue and anatomical movement readings for that specimen.',
 cultivate='Transfer ordinary living cells into a Petri dish, culture flask or culture plate. They multiply over real time while the culture is viable, fed, at a suitable temperature and below capacity. Storage vials do not cultivate. Blank developmental cells and gamete precursors do not multiply as ordinary colonies.',
 culture_problem='Select a culture container or include its ID. I can read its actual growth status, food, capacity and next-cell estimate. Empty, frozen, full, starving, unsuitable or nonviable cultures will not grow normally.',
 feed='Open the culture container and use its Feed action. Growth can resume if it has viable ordinary cells, suitable conditions and room. A storage vial still does not cultivate just because it has food.',
 transfer='Left-drag the dropper to move it. Right-click the source container and choose Take sample from this container. Move the loaded dropper tip over the open destination and release it to dispense. Right-click always opens menus. Rejected transfers keep the held sample.',
 transfer_problem='A source must contain a sample and be open and thawed. The destination must be open, thawed, compatible with the held sample and have room. The loaded tip must be over that destination to dispense. A failed transfer does not discard the held sample.',
 freeze='Load the dropper, then right-click it and choose Freeze contents into storage. This stores the contents, not the whole dropper, so the dropper remains usable. Freezing suspends the stored sample.',
 thaw='Use Retrieve frozen cells in the Cellarium tray or dropper context menu. Choose the stored sample and then an open, thawed, compatible container with enough space. An incompatible destination cannot consume the stored sample.',
 label='Right-click a vial, flask, dish or plate and choose Label container, or use its Label button. Enter saves the name; Escape cancels. The label belongs to that persistent container, not its current contents.',
 rack='Drop a vial onto the sample rack. It uses the nearest free one of eight separate slots, with spacing that accommodates vial scale. A full rack rejects a ninth vial. Drag a vial out to detach it; opening its controls also detaches it from the rack.',
 empty='The container count is the authority. An empty flask now renders clear glass; a positive cell count draws its suspension. Select a container or include its ID to check its actual contents.',
 depth='Right-click any desktop item for Bring to front, Raise one layer, Lower one layer or Send to back. A workstation or rack changes depth with its attached containers, which stay above it.',
 drag='Left-click and drag the visible body of the equipment. If it is locked, right-click and choose Unlock position. Dropping on another monitor preserves its persistent identity. Dragging an attached vial away detaches it from the machine or rack.',
 hide='Right-click the Cellarium tray icon to toggle Show Laboratory, Show Habitats or Show Desktop Organisms. They retain their contents and placement while hidden. Ctrl+Shift+L hides equipment and opens recovery controls.',
 save='Use Save Laboratory + Layout in the Cellarium tray menu to save explicitly. This desktop edition also saves on exit and restores on launch. Closing the records window hides it; use Exit Cellarium in the tray to exit the game.',
 time='Life uses elapsed PC time. There are no live pause or speed controls. Hiding the laboratory does not stop life, and elapsed offline time is processed on return. Anatomy Generator playback controls affect only its diagnostic preview, not living organisms.',
 units='Cellarium displays U.S. customary units, including Fahrenheit, inches and ounces. Some internal biological calculations use different units, which are converted for display.',
 combat='Combat and attack AI are deferred in this version. A diagnostic biting or scratching preview is not a combat system.',
 breed='Breeding requires two distinct living mature organisms, adequate energy and sufficient fertility. The compatibility check requires at least 45% energy in both parents. A child inherits from both parents; it is not guaranteed to be viable.',
 gametes='Attach a living stem-cell container at INPUT and an empty container at OUTPUT. Prepare egg or sperm uses one stem cell and produces its precursor in the output. Viability must exceed 50%. Maturation takes eight real minutes; freezing suspends it.',
 fertilize='Choose one mature egg and one mature sperm in the assembly controls. They must be distinct, unfrozen and compatible. Fertilization consumes their physical gamete records and starts a new embryo with genetic material from both.',
 habitat='An organism needs environmental exchange that can meet its oxygen demand. Freshwater, saltwater and terrestrial habitats have different chemistry and exposure. Its generated respiration and tolerance determine suitability; there is no universal best habitat.',
 personality='My facts come first. My dry remarks come from predefined dialogue rules. Use my desktop context menu to change Sarcasm between Off, Dry and Sharp; repeated questions can get a slightly more impatient introduction.',
 smart='You built the laboratory. I came with the instructions. We appear to be specializing.',
 offline='Questions are embedded locally by a CPU-only quantized MiniLM model. It identifies a likely topic; it does not generate replies. My answers use reviewed Cellarium procedures and current game data. No internet connection or API key is used during gameplay. Inference uses the CPU, not a GPU. The bundled Windows x64 runtime has a baseline SSE2 path with optional AVX acceleration; a physical non-AVX machine has not been tested in this development pass.',
 disable='Right-click the Cellarium tray icon and turn off Enable Assistant, or choose Disable assistant in my desktop context menu. This hides me without stopping laboratory life.'
}
answers.preservation=answers.freeze..'\n\nTo retrieve it: '..answers.thaw
answers.genome_analysis='Select a genome-bearing specimen so I can run its expression and anatomical generation checks.'
local function result(text,intent,scope,subject) return {text=text,intent=intent,scope=scope or 'Verified Cellarium procedure',subject=subject} end
local function explicitID(text) return tonumber(text:match('#%s*(%d+)') or text:lower():match('organism%s+(%d+)') or text:lower():match('vial%s+(%d+)') or text:lower():match('container%s+(%d+)')) end
local function find(list,id) for _,x in ipairs(list or {}) do if x.id==id then return x end end end
function K.context(s)
 local d=s.desktop or {};local object=M.find(s,d.selectedObject);return {object=object and object.id,organism=d.selectedOrganism}
end
local function organism(s,text,context)
 local id=explicitID(text);if id then return find(s.organisms,id),true end
 local object=context and M.find(s,context.object);if object and object.kind=='organism' then return find(s.organisms,object.entityId) end
 if context and context.organism then return find(s.organisms,context.organism) end
 if #(s.organisms or {})==1 then return s.organisms[1] end
end
local function vessel(s,text,context)
 local id=explicitID(text);if id then return find(s.vessels,id),true end
 local object=context and M.find(s,context.object);if object then return find(s.vessels,object.entityId) end
end
local function station(s,text,context)
 local object=context and M.find(s,context.object);if object and object.kind=='workstation' then return object end
 local id=explicitID(text);local list={};for _,o in ipairs(s.desktop and s.desktop.objects or {}) do if o.kind=='workstation' then if id and tonumber(o.id:match('%d+'))==id then return o end;list[#list+1]=o end end;if not id and #list==1 then return list[1] end
end
function K.answer(s,intent,text,context)
 text=text or '';context=context or K.context(s)
 if not intent or intent=='unknown' then return result('I do not have a verified answer to that. Ask a specific Cellarium question, or choose a topic below. If you mean a particular specimen, select it or include its ID.','unknown','No supported conclusion') end
 if intent=='genome_analysis' then
  local id=explicitID(text);local g,conditions,label
  local obj=context.object and M.find(s,context.object)
  local o,material,v
  if id then o=find(s.organisms,id);material=find(s.materials,id);v=find(s.vessels,id)
  else o=organism(s,text,context);material=obj and obj.kind=='dna' and find(s.materials,obj.entityId);v=obj and find(s.vessels,obj.entityId) end
  if material then g=material.genome;label='Archived genome #'..material.id
  elseif o then g=o.genome;conditions=o.anatomy and o.anatomy.development;label=(o.name or 'Organism')..' (#'..o.id..')'
  elseif v and v.contents[1] then g=v.contents[1].cell.genome;label='Cell in container #'..v.id end
  if not g then return result('Select a DNA vial, cell container or organism, or include its #ID. I need an actual genome to run the generator.',intent,'Specimen clarification') end
  local report=require('simulation_diagnostics').genome(g,conditions);if not report.available then return result(report.reason,intent,'No supported conclusion') end
  local f=report.forecast;local answer=string.format('%s: %d chromosome pairs, %d loci, %d altered-copy loci, %d deleted loci and %d regulation rules.\nCurrent-generator forecast: %d heads, %d appendages, %s symmetry, %s, %s locomotion, %.3f oz.',label,report.chromosomePairs,report.loci,report.alteredDosage,report.deleted,report.regulationRules,f.heads,f.appendages,tostring(f.symmetry),tostring(f.support),tostring(f.locomotion),f.massOunces)
  answer=answer..(f.viable and '\nThe generated anatomy passes the current viability checks.' or '\nThe generated anatomy fails: '..table.concat(f.failures,'; ')..'.')
  local e=report.expression;answer=answer..string.format('\nExpression inputs: D6 Branch initiation %.3f; D10 Joint differentiation %.3f; L16 Muscle growth %.3f; L22 Neural wiring %.3f.',e.development[6],e.development[10],e[16],e[22])
  answer=answer..'\nThis is a fresh generator forecast, not a rewrite of a living specimen. Conditions: '..string.format('nutrition %.0f%%, oxygen %.0f%%, %.1f F.',(report.conditions.nutrition or 1)*100,(report.conditions.oxygen or 1)*100,(report.conditions.temperature or 37)*9/5+32)
  return result(answer,intent,'Actual genotype expression and generator forecast',id)
 end
 if intent=='credits' then return result('You currently have '..tostring(s.credits or 0)..' credits. An ordinary cell or a blank developmental cell costs 1 credit, including its vial. Other container prices are listed in Buy supplies.',intent,'Current laboratory credits') end
 if intent=='status' then local live,dead=0,0;for _,o in ipairs(s.organisms or {}) do if o.alive then live=live+1 else dead=dead+1 end end;return result(string.format('Your laboratory has %d containers, %d living organisms, %d deceased records, %d embryos, %d archived genomes and %d frozen samples. Credits: %s.',#(s.vessels or {}),live,dead,#(s.eggs or {}),#(s.materials or {}),#(s.frozen or {}),tostring(s.credits or 0)),intent,'Current laboratory snapshot') end
 if intent=='install' then local w=station(s,text,context);if w then local plan,why=require('cell_workshop').inspectInstall(s,w.id);local observed=plan and ('Workstation '..w.id..' is ready: DNA #'..plan.dna.id..', blank-cell input #'..plan.input.id..' and output #'..plan.output.id..'.') or ('Workstation '..w.id..' currently reports: '..why);return result(observed..'\n\n'..answers.install,intent,'Current workstation and installation rules',w.id) end end
 if intent=='movement' or intent=='death' or intent=='stats' or intent=='habitat' then
  local o,explicit=organism(s,text,context)
  if explicit and not o then return result('There is no organism with that ID in this laboratory. I have not substituted a different specimen.',intent,'Missing specimen') end
  if not o then return result(answers[intent],intent) end
  local title=(o.name or 'Organism')..' (#'..o.id..')'
  if intent=='death' then return result(o.alive and (title..' is currently alive. There is no death to diagnose.') or (title..' has recorded cause of death: '..(o.deathCause or 'not recorded; I cannot determine a cause from this record alone')..'.'),intent,'Recorded organism state',o.id) end
  if intent=='habitat' then return result(title..' is currently in '..tostring(o.environment or o.worldId or 'an unrecorded environment')..'. Oxygen reserve: '..string.format('%.0f%%',(o.oxygen or 0)*100)..'.\n\n'..answers.habitat,intent,'Current organism and habitat rules',o.id) end
  local diagnostic=require('simulation_diagnostics').organism(s,o);local profile=diagnostic.available and diagnostic.profile or nil;local fatigue=o.motion and o.motion.fatigue or 1-(o.stamina or 100)/100
  if type(o.health)~='number' or type(o.energy)~='number' or type(o.oxygen)~='number' then return result(title..' has incomplete physiological readings. I cannot report health, energy or oxygen values that are absent from this record.',intent,'Incomplete organism readings',o.id) end
  local readings=string.format('%s: health %.0f%%, energy %.0f%%, oxygen %.0f%%, fatigue %.0f%%. Current behavior: %s.',title,o.health or 0,o.energy or 0,(o.oxygen or 0)*100,fatigue*100,tostring(o.behavior or 'not recorded'))
  if not o.alive then return result(readings..' It is deceased. Recorded cause: '..(o.deathCause or 'not recorded')..'.',intent,'Current organism record',o.id) end
  if diagnostic.available then
   readings=readings..string.format('\nFresh %s locomotion audit: %d ground contacts, balance %.2f, support %.2f, motor control %.2f. Current-condition speed estimate: %.3f in/sec.',diagnostic.medium,#profile.legs,profile.balance,profile.support,profile.control,diagnostic.speedInchesPerSecond)
   if #diagnostic.failures>0 then
    readings=readings..'\nFailed requirements:';for _,check in ipairs(diagnostic.failures) do readings=readings..string.format('\n- %s: %.4g; requires %s. %s',check.label,check.value,check.required,check.explanation) end
   else readings=readings..'\nThe tested biological movement requirements pass.' end
   if diagnostic.statedIdle then readings=readings..'\nThe recorded behavior is '..o.behavior..'; the live simulation intentionally holds position during that behavior.' end
   if diagnostic.navigation.tested then readings=readings..'\n'..diagnostic.navigation.reason else readings=readings..'\n'..diagnostic.navigation.reason end
   if #diagnostic.failures==0 and not diagnostic.statedIdle and not diagnostic.navigation.tested then readings=readings..' I cannot attribute the lack of movement to an unrecorded obstacle or target.' end
  else readings=readings..'\n'..diagnostic.reason end
  return result(readings,intent,'Fresh simulation diagnostics; current-condition estimates',o.id)
 end
 if intent=='culture_problem' or intent=='cultivate' or intent=='feed' or intent=='empty' or intent=='transfer_problem' or intent=='transfer' then
  local v,explicit=vessel(s,text,context)
  if explicit and not v then return result('There is no physical cell container with that ID in this laboratory.',intent,'Missing container') end
  if v then
   local info=V.growthInfo(v);local observed=string.format('%s (#%d) contains %d cell(s) out of %d. Status: %s. Food %.0f%%; temperature %.1f F; %s; %s.',v.label or V.types[v.kind].name,v.id,V.count(v),V.types[v.kind].capacity,info.status,(v.nutrients or 0)*100,(v.temperature or 37)*9/5+32,v.closed and 'closed' or 'open',v.frozen and 'frozen' or 'thawed')
   if info.nextCellSeconds then observed=observed..' Next-cell estimate: '..require('realtime').duration(info.nextCellSeconds)..' of real time.' end
   return result(observed..'\n\n'..answers[intent],intent,'Current container and culture rules',v.id)
  end
 end
 if intent=='growth' and #(s.eggs or {})>0 then
  local id=explicitID(text);local e;if id then e=find(s.eggs,id);if not e then return result('There is no embryo with that ID in this laboratory.',intent,'Missing specimen') end elseif #s.eggs==1 then e=s.eggs[1] end
  if e then return result(string.format('Embryo #%d: %s, incubation progress %.1f%%; anatomical development %.1f%%.\n\n',e.id,tostring(e.stage),100*(e.progress or 0),100*(e.anatomy and e.anatomy.growth or 0))..answers.growth,intent,'Current embryo and development rules',e.id) end
  return result('There are several embryos. Include the embryo ID so I can report the correct one.',intent,'Specimen clarification')
 end
 return result(answers[intent] or 'I do not have a reviewed explanation for that topic.',intent)
end
K.procedures=answers
return K
