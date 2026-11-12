# CODEX IMPLEMENTATION PROMPT
# CELLARIUM: GENOME ENGINEERING, LIVING PHYSIOLOGY, BEHAVIOR & DESKTOP ORGANISM FOUNDATION

## PRIMARY OBJECTIVE

Overhaul Cellarium's genetic engineering and organism simulation to support the creation of entirely new life from engineered DNA.

The player does not select predefined animals or assemble creatures using character-creation menus.

Instead, the player builds genomes, engineers cells, grows embryos, and observes what develops.

Every organism must have its own anatomy, physiology, developmental history, behavioral nature, memories, and biological limitations.

The complete simulation should follow:

**DNA → Gene Expression → Development → Anatomy → Physiology → Cognition → Behavior**

An organism's experiences and environment must also influence its development, health, learning, and behavior.

The ultimate goal is to support organisms that can live inside laboratory habitats and eventually roam the user's Windows desktop, behaving according to their own biological capabilities.

Do not implement a full desktop companion or offline language model yet. Build the underlying systems and interfaces that will make those features possible later.

---

# PART 1: PRESERVE THE EXISTING SYSTEMS

Inspect the entire existing codebase before making changes.

Identify and reuse:

- The existing 24 chromosome-pair genome system.
- Alleles, inheritance, mutation, and reproduction.
- Procedural developmental grammar.
- Body regions and anatomical generation.
- Skeleton, muscle, nervous, organ, and skin systems.
- The seven existing cell types.
- Cell cultivation and experimental systems.
- Environmental adaptations and living habitats.
- Research and organism inspection interfaces.
- Cryobank and persistence systems.

Do not replace procedural organisms with predefined species.

Do not simplify anatomy into cosmetic body parts.

Do not discard existing working systems unnecessarily.

Maintain save compatibility through migrations wherever feasible.

# PART 2: DNA VIALS AND GENETIC MATERIAL

Replace the purchase of arbitrary wild cells with the purchase of DNA vials.

DNA vials contain generated genetic sequences, not predetermined species.

Each sequence must have a persistent identity and reproducible biological effects.

Sequences may influence:

- Developmental organization.
- Body axes and symmetry.
- Tissue differentiation.
- Skeletal development.
- Muscle development.
- Nervous system formation.
- Sensory structures.
- Circulation and respiration.
- Metabolism.
- Skin and protective tissues.
- Natural weapons.
- Growth and maturation.
- Aging and regeneration.
- Behavioral predispositions.
- Neural development and learning capacity.

Some sequences may be unidentified.

Players must be able to research them and gradually discover their functions.

Do not implement simple RPG modifiers such as Strength DNA +10.

Genetic sequences must influence biological processes, which subsequently determine physical and behavioral capabilities.

# PART 3: GENOME EDITOR

Preserve the 24 chromosome-pair architecture unless migration requirements justify an alternative.

Introduce a genome construction and manipulation interface.

Support:

1. Splicing genetic sequences.
2. Recombination between genomes.
3. Sequence duplication.
4. Sequence deletion.
5. Mutations.
6. Genome sequencing.
7. Genome comparison.
8. Genome archiving.
9. Named engineered strains.
10. Reusing previously successful genomes.

Allow genetic contributions from more than three DNA vials.

Do not impose an arbitrary limit of three genetic sources.

Genes must interact.

Regulatory genes can activate, suppress, or alter the expression of other genes.

Developmental timing and environmental conditions may influence expression.

The same sequence may have different effects in different genomic contexts.

The same genome grown under comparable conditions should produce broadly reproducible organisms.

# PART 4: BLANK CELLS AND CELL ENGINEERING

Introduce engineered blank developmental cells.

For Cellarium's fictional biotechnology, these cells have had their original nuclear genetic material removed and possess machinery capable of accepting a compatible synthetic genome.

Support two laboratory processes.

## Single-cell genome installation

Install a complete engineered genome into a blank developmental cell.

A successful installation can initiate embryonic development.

## Batch cell engineering

Produce cultures of engineered cells carrying the same genome.

Track:

- Cell population.
- Viability.
- Division rate.
- Nutrient consumption.
- Contamination.
- Mutation accumulation.
- Culture age.

Retain the seven existing specialized cell types.

They should represent differentiated biological cells and research materials rather than mandatory ingredients for constructing an organism.

An embryo must produce specialized cells through development.

# PART 5: EMBRYONIC DEVELOPMENT

Implement a meaningful developmental process.

Suggested stages:

1. Genome activation.
2. Initial cell division.
3. Early embryo.
4. Body-axis formation.
5. Tissue differentiation.
6. Organ development.
7. Juvenile.
8. Adult.
9. Elder.

The developing organism must grow through cellular division and differentiation.

Cell growth requires energy, nutrients, and viable biological conditions.

Use aggregate cell populations rather than simulating millions of individual cells.

Connect embryogenesis directly to the procedural developmental grammar.

Support coherent body regions, internal structures, sensory specialization, appendages, and continuous external tissues.

Do not force heads, limbs, bilateral symmetry, or familiar animal shapes.

Some genomes should fail development for identifiable biological reasons.

# PART 6: SIX DYNAMIC STATS

Implement six calculated organism stats.

**STR: Strength**
Derived from muscle mass, muscle quality, skeletal support, leverage, and tissue condition.

**DEF: Defense**
Derived from skin, scales, carapace, skeletal protection, material hardness, anatomical coverage, and structural condition.

**DEX: Dexterity**
Derived from nervous coordination, joint mobility, sensory feedback, muscle control, and functioning anatomy.

**INT: Intelligence**
Derived from neural organization, memory capacity, learning capability, information processing, and functioning neural tissue.

**VIT: Vitality**
Derived from organ function, physiological resilience, tissue repair, circulation, respiration, and resistance to biological stress.

**END: Endurance**
Derived from energy reserves, oxygen delivery, metabolic efficiency, fatigue resistance, and muscular efficiency.

These stats are summaries calculated from actual anatomy and physiology.

Do not assign them directly through genetic modifiers.

Do not use RPG-style stat points.

Stats must change with:

- Growth.
- Maturation.
- Injury.
- Disease.
- Fatigue.
- Healing.
- Environmental conditions.
- Aging.
- Anatomical development.

For example, an organism that develops a mineralized carapace gains protection because that tissue actually exists.

If its armor breaks, effective defense decreases.

Maintain underlying biological quantities rather than relying exclusively on normalized stat values.

# PART 7: PHYSIOLOGY AND VITAL SIGNS

Separate calculated stats from actual biological vital signs.

Track appropriate physiological processes, including:

- Oxygen supply.
- Tissue oxygenation.
- Nutrient transport.
- Hydration.
- Temperature.
- Energy reserves.
- Fatigue.
- Organ condition.
- Tissue damage.
- Healing.
- Circulation.
- Blood volume where appropriate.
- Blood pressure where appropriate.
- Cardiac function where appropriate.
- Respiratory performance.

Do not assume every organism has blood, lungs, or a heart.

Simple organisms may rely on diffusion.

Others may develop specialized transport and respiratory systems.

Organisms must survive or die according to their actual physiological condition.

Examples:

- Blood loss can reduce oxygen delivery.
- Damaged muscles reduce usable strength.
- Nervous damage impairs coordination.
- Organ failure can cause death.
- Starvation depletes energy reserves.
- Severe fatigue reduces performance.

Avoid generic hit points as the sole determinant of survival.

# PART 8: GROWTH, MATURATION, AND AGING

Organisms must change throughout their lives.

Their genome determines developmental potential and influences the timing of growth.

Possible changes include:

- Increased muscle mass.
- Skeletal growth.
- Developing claws.
- Developing teeth.
- Thickening skin.
- Mineralizing carapace.
- Growing scales or protective structures.
- Nervous system maturation.
- Reproductive maturity.
- Changes in metabolism.
- Age-related deterioration.

Do not use identical developmental milestones for every organism.

Allow environmental conditions to influence growth where biologically appropriate.

Distinguish:

**Development:** Genetically programmed maturation.

**Lifetime adaptation:** Changes such as conditioning, learning, tissue repair, and environmentally influenced gene expression.

**Evolution:** Heritable changes across generations.

An organism cannot spontaneously invent new organs simply because it needs them.

However, genetically supported developmental responses may be activated by environmental conditions.

# PART 9: NATURAL WEAPONS AND PROTECTIVE TISSUES

Expand the existing anatomical growth systems.

Support:

- Soft skin.
- Thick hide.
- Scales.
- Carapace.
- Protective plates.
- Claws.
- Teeth.
- Horns.
- Spines.
- Beaks.
- Other procedurally developed structures.

These structures must exist as anatomical components.

Their effectiveness depends on material properties, geometry, supporting anatomy, and current condition.

Protective structures should have tradeoffs involving weight, flexibility, growth, energy requirements, and movement.

Do not implement natural weapons as arbitrary equipment bonuses.

# PART 10: GENETICALLY INFLUENCED NATURE

Every organism must develop an individual behavioral nature.

Nature represents inherited behavioral predispositions, not a rigid personality class.

Do not use fixed categories such as Friendly, Aggressive, Cowardly, or Evil as the underlying simulation.

Instead, derive behavioral tendencies from the genome, neural development, physiology, and early experiences.

Suggested continuous behavioral dimensions:

**Sociability**
The tendency to approach, tolerate, or seek other organisms.

**Aggression**
The tendency to escalate conflicts or use force when challenged.

**Fearfulness**
Sensitivity to perceived threats and willingness to retreat.

**Curiosity**
Motivation to investigate unfamiliar objects, environments, and organisms.

**Territoriality**
Tendency to defend occupied space or important resources.

**Dominance tendency**
Propensity to compete for priority access or social position where relevant.

**Tolerance**
Willingness to remain near unfamiliar organisms without escalating.

**Attachment tendency**
Capacity to develop persistent social bonds.

**Exploration drive**
Motivation to travel beyond familiar areas.

**Behavioral flexibility**
Ability to change responses based on experience.

**Stress sensitivity**
How strongly adverse conditions affect behavior and physiological stress.

**Social learning tendency**
Propensity to observe and learn from other organisms.

These are proposed behavioral dimensions, not mandatory independent sliders.

Avoid duplicating traits that can be represented by shared underlying mechanisms.

Nature should emerge from interacting genetic and developmental influences.

The player must not directly select a personality template during genome creation.

An organism's observed nature should be discoverable through experimentation.

# PART 11: NATURE IS NOT DESTINY

Inherited temperament influences behavior but must not determine every action.

Actual behavior should depend on:

- Genetic predispositions.
- Current physiological condition.
- Hunger and thirst.
- Fatigue.
- Stress.
- Pain.
- Fear.
- Environmental conditions.
- Available sensory information.
- Memories.
- Familiarity with other organisms.
- Learned associations.
- Previous social experiences.

For example:

An organism with high aggression may retreat if badly injured.

A naturally fearful organism may approach a familiar companion.

A highly social organism may become temporarily defensive while protecting food.

An aggressive organism may learn to tolerate a particular neighbor after repeated peaceful encounters.

Do not randomly override established personality and memory without a simulated cause.

# PART 12: INDIVIDUAL MEMORY AND LEARNING

Create a persistent memory system for organisms with sufficient neural capabilities.

Memory complexity must depend on actual nervous-system development.

Do not give sophisticated memory to organisms lacking the necessary neural structures.

Support progressively more capable forms of memory:

- Stimulus habituation.
- Simple learned associations.
- Recognition of familiar environments.
- Recognition of individual organisms.
- Remembered food locations.
- Threat associations.
- Learned routines.
- Social relationships.
- Object associations.
- Learned behaviors and techniques.

Memories should contain appropriate information such as:

- Event type.
- Associated organism or object.
- Location or environmental context.
- Positive or negative outcome.
- Emotional or physiological significance.
- Memory strength.
- Time since occurrence.

Memory should be subject to forgetting, reinforcement, and interference.

An organism must not have knowledge of events it never perceived or learned about.

# PART 13: SOCIAL INTERACTION AND RELATIONSHIPS

Allow organisms to encounter and respond to one another.

Interactions should depend on both organisms' anatomy, senses, temperament, physiology, and history.

Possible behaviors include:

- Approaching.
- Observing.
- Ignoring.
- Avoiding.
- Retreating.
- Threat displays.
- Defensive posturing.
- Vocalizing.
- Investigating.
- Following.
- Sharing space.
- Competing for resources.
- Establishing familiarity.
- Forming social bonds.
- Protecting companions.
- Fighting when physically possible.

Do not assume every organism is social.

Do not assume every organism recognizes individuals.

Simple organisms may respond only to chemical or physical stimuli.

More sophisticated organisms may recognize particular individuals and remember previous interactions.

Maintain persistent relationship information where cognitive capacity supports it.

For example, Organism A may trust Organism B but fear Organism C.

These relationships should be learned rather than assigned by a generic faction system.

# PART 14: AUTONOMOUS DECISION-MAKING

Implement a reusable behavioral decision system.

The organism must choose actions based on its actual biological capabilities.

Suggested decision process:

1. Gather available sensory information.
2. Evaluate physiological needs.
3. Identify perceived opportunities and threats.
4. Consult relevant memories.
5. Evaluate behavioral predispositions.
6. Determine physically possible actions.
7. Select an action.
8. Execute the action using the organism's anatomy.
9. Record the result.
10. Update memories and learned responses.

Do not use an unrestricted action list that lets every organism perform the same behaviors.

Examples:

A limbless organism cannot walk.

An organism without functioning wings cannot fly.

An organism without manipulators cannot manufacture tools requiring precise handling.

An organism without sound-producing anatomy cannot produce ordinary vocal speech.

An organism without sufficient neural development cannot perform complex planning.

Use anatomy-driven capability checks throughout the behavior system.

The six summary stats may help present capabilities but must not replace direct anatomical and physiological checks.

# PART 15: INTELLIGENCE AND COGNITIVE DEVELOPMENT

Intelligence must emerge from neural anatomy and development.

Do not treat INT as a universal unlock level.

Represent relevant cognitive capabilities separately where possible:

- Sensory processing.
- Memory capacity.
- Learning rate.
- Pattern recognition.
- Behavioral flexibility.
- Planning.
- Problem-solving.
- Social recognition.
- Communication learning.
- Object manipulation knowledge.

Cognitive abilities should develop with neural maturation and experience.

An intelligent organism raised in isolation may have different learned skills from an equally intelligent organism raised socially.

Avoid automatically making every highly intelligent organism humanoid.

Intelligence and body shape must remain independent developmental outcomes.

# PART 16: COMMUNICATION AND SOUND FOUNDATION

Create a communication-capability system based on anatomy and cognition.

Potential communication mechanisms include:

- Chemical signaling.
- Body posture.
- Movement displays.
- Touch.
- Light or color changes.
- Simple sound production.
- Complex vocalizations.
- Learned symbolic communication.
- Language.

Actual communication capabilities must depend on sensory organs, signaling structures, neural development, and learning.

A simple organism may emit basic signals.

An animal-like organism may produce calls, growls, squeaks, or warning sounds.

An advanced organism may develop more complex learned communication.

Human-level cognition does not automatically grant human speech.

Provide structured communication events that future audio and AI systems can consume.

Example event fields:

- Organism ID.
- Communication mechanism.
- Intended recipient, if any.
- Biological intent.
- Emotional or physiological state.
- Vocal or signaling capability.
- Relevant memory context.

Do not integrate a full local language model yet.

# PART 17: FUTURE OFFLINE AI INTEGRATION

Design an optional AI communication interface for future integration with a local language model.

The AI must not replace the biological simulation.

The simulation determines:

- What the organism perceives.
- What it remembers.
- What it wants.
- What it understands.
- What it is capable of doing.
- Whether it can communicate.
- Which communication methods it possesses.

A future local AI model may help generate appropriate dialogue, communication, or high-level plans for sufficiently capable organisms.

However, the model must not invent biological abilities, memories, or knowledge.

The simulation must validate all proposed actions.

Do not make local AI a dependency for basic organism survival or behavior.

The simulation must function completely offline without any language model installed.

# PART 18: TOOL USE AND TECHNOLOGICAL BEHAVIOR

Lay the groundwork for advanced organisms to interact with objects.

Possible capabilities include:

- Recognizing objects.
- Remembering object locations.
- Carrying objects.
- Manipulating objects.
- Using simple objects as tools.
- Learning cause-and-effect relationships.
- Combining materials.
- Constructing simple objects.

These capabilities must depend on:

- Sensory perception.
- Neural processing.
- Memory.
- Planning ability.
- Suitable manipulators.
- Coordination.
- Physical strength.
- Experience.

Do not automatically unlock toolmaking at a particular INT value.

Do not implement an extensive crafting system yet.

Create a capability and interaction architecture that can support one later.

# PART 19: DESKTOP ORGANISM FOUNDATION

Prepare Cellarium for a future Windows desktop companion.

The player will eventually be able to select one or multiple living organisms and allow them to roam across Windows desktop monitors.

These must be the same organisms maintained in the laboratory, not separate cosmetic pets.

Their genetics, anatomy, physiology, nature, memories, injuries, and development must persist.

Design a reusable organism simulation interface that can operate independently of the main laboratory UI.

Separate:

- Biological simulation.
- Behavioral decision-making.
- Rendering.
- Environmental input.
- Audio and communication.
- Persistence.

Provide a clean interface for a future native Windows desktop host.

The future desktop system should support:

- Transparent organism rendering.
- Multiple monitors.
- Organism selection and recall.
- Persistent behavior.
- Interaction with cursor and desktop geometry.
- Resting, exploring, and moving.
- Multiple organisms interacting.
- Optional sound.
- Optional local AI communication.

Do not implement unrestricted control of Windows applications or user files.

Future interactions with real applications must be explicitly permission-controlled.

For this update, prioritize architectural separation and shared organism state rather than building the complete desktop companion.

# PART 20: RESEARCH AND LONG-TERM OBSERVATION

Expand the research interface to include behavioral observations.

Record:

- Developmental stages.
- Anatomical changes.
- Changes in six stats.
- Vital-sign history.
- Behavioral tendencies.
- Social interactions.
- Learned responses.
- Recognized individuals.
- Stress events.
- Aggressive encounters.
- Retreat behavior.
- Communication events.
- New learned capabilities.
- Aging and degeneration.

Players should be able to compare organisms with similar genomes but different experiences.

For example:

Two organisms may have nearly identical inherited sociability but develop different behavior after one experiences repeated attacks.

The research system should distinguish inherited predispositions from observed behavior.

Do not expose every behavioral gene's effect automatically.

Let players learn through observation and controlled experiments.

# PART 21: PERFORMANCE

The simulation must support multiple living organisms without requiring a language model for each.

Use lightweight biological and behavioral systems for ordinary activity.

Avoid expensive continuous full-brain simulations.

Use aggregate physiology and appropriately sized memory structures.

Allow behavior and physiology updates at different frequencies where sensible.

Design the desktop companion foundation so that organism state can be serialized and restored without losing memories or developmental progress.

# PART 22: TESTING AND VALIDATION

Implement deterministic tests for:

- DNA vial generation.
- Genome construction and editing.
- Gene interactions.
- Cell engineering.
- Embryonic development.
- Body-plan diversity.
- Tissue and organ growth.
- Dynamic STR, DEF, DEX, INT, VIT, END.
- Vital-sign changes.
- Injury and physiological failure.
- Aging and maturation.
- Behavioral trait inheritance.
- Temperament variation.
- Fear and aggression responses.
- Social tolerance.
- Individual recognition.
- Memory formation.
- Learning and forgetting.
- Capability restrictions.
- Communication restrictions.
- Persistent social relationships.
- Save/load compatibility.

Test contrasting organisms in the same environment.

For example:

- Highly social versus strongly solitary.
- Fearful versus bold.
- Aggressive versus tolerant.
- Curious versus cautious.
- Intelligent without manipulators.
- Low cognition with functional manipulators.
- Vocal anatomy without language capability.
- High cognition without vocal anatomy.

Verify that differences emerge from underlying systems rather than hardcoded personality classes.

Run a batch simulation with genetically diverse organisms and report:

- Embryonic viability.
- Body-plan diversity.
- Stat distributions.
- Temperament distributions.
- Social encounter outcomes.
- Memory persistence.
- Behavior variation.
- Physiological survival.
- Performance.

# PART 23: IMPLEMENTATION ORDER

1. Audit existing systems.
2. Introduce DNA vials.
3. Implement genome construction and editing.
4. Implement blank-cell genome installation.
5. Connect genomes to developmental grammar.
6. Implement embryogenesis and growth.
7. Implement six dynamic stats.
8. Integrate physiological vitals.
9. Implement maturation and aging.
10. Add genetically influenced behavioral nature.
11. Add physiological needs and sensory perception.
12. Implement autonomous behavior selection.
13. Add memory and learning.
14. Implement social recognition and relationships.
15. Add communication capabilities and events.
16. Create future offline-AI integration interfaces.
17. Separate organism simulation from rendering for desktop compatibility.
18. Expand research and observation tools.
19. Update persistence and migrations.
20. Run deterministic tests and performance audits.

If this scope is too large for one implementation pass, complete a working vertical slice first and preserve the remaining requirements as a clear implementation plan.

Do not replace functional systems with interface-only placeholders.

# FINAL DESIGN PRINCIPLES

**1. The player engineers life rather than selecting a species.**

**2. The genome determines developmental potential, not finished stats.**

**3. Anatomy determines physical capabilities.**

**4. Physiology determines whether those capabilities can currently function.**

**5. Neural development determines cognitive potential.**

**6. Nature influences decisions without completely controlling them.**

**7. Memory and experience change behavior over time.**

**8. Social relationships emerge from actual interactions.**

**9. Communication requires suitable biology and learned ability.**

**10. Desktop organisms must remain the same persistent biological entities as laboratory organisms.**

The ultimate objective is not merely to generate unusual-looking creatures.

It is to create synthetic life with individual bodies, biological needs, inherited dispositions, learned experiences, and genuinely different behaviors.

Every organism should be the result of its genome, its development, its environment, and its personal history.