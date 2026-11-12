# CODEX TASK: Cellarium Anatomical Body Generator Overhaul

**Repository:** `markchpaman10/cellarium`  
**Branch:** `desktop-laboratory-dev`

## Objective

Replace the current blob/worm/starfish-dominated organism generation with a genetically driven anatomical construction system.

The existing generator produces varied silhouettes, but it does not reliably produce recognizable, structurally coherent multicellular organisms.

We need a system that constructs organisms from **reusable anatomical part shapes**, then modifies, connects, grows, and renders those parts according to DNA.

**We are NOT creating predefined animals or species. We ARE creating predefined anatomical building blocks.**

The same building blocks must be capable of producing radically different organisms through genetic variation.

This is an experimental development pass. Prioritize correct anatomical generation, meaningful genetics, and visual inspection over polish.

---

## 1. Audit the Existing Systems First

Before implementing anything, inspect the existing:

- Genome and allele representation
- Developmental gene expression
- Body-plan generator
- Skeleton and structural tissue generation
- Muscle and connective tissue
- Nervous system
- Organs and physiology
- Skin, fat, armor, and other tissues
- Organism rendering and anatomical layers
- Growth and embryonic development
- Genome editing, inheritance, and mutation
- Existing anatomy audits and regression tests

**Reuse the existing biological systems wherever possible.**

Do not replace the established 24 chromosome pairs, 72 loci, or 144 alleles with an unrelated genetic model.

Do not create a second, disconnected anatomy simulation.

Identify why the current generator favors worms, radial shapes, and amorphous bodies. Document those causes before modifying it.

Preserve save compatibility where practical.

---

## 2. Introduce an Anatomical Building-Block Library

Create a reusable library of parameterized anatomical structures.

These are not complete animal parts or species templates. They are basic shapes with biological attachment rules.

### Body regions

Support:

- Torso and trunk
- Chest and abdomen
- Pelvic or posterior body regions
- Neck or connecting regions
- Head-bearing regions
- Tail-bearing regions

Regions must support variable length, width, thickness, curvature, taper, and internal volume.

They must connect to form a continuous organism.

A region may be absent, repeated, fused, or subdivided when genetically appropriate.

### Heads and sensory structures

Support parameterized:

- Cranium or head capsule
- Snout or forward extension
- Upper and lower jaws
- Mouth opening
- Eye sockets and sensory attachment points
- Antennae and other sensory projections

Allow zero, one, or multiple head-bearing structures.

Multiple heads must have their own anatomical connections and sensory/nervous structures.

Do not simply duplicate a decorative head sprite.

### Limbs

Create a generic articulated appendage system supporting:

- One or more structural segments
- Variable segment lengths and widths
- Joints with defined movement limits
- Muscle attachment points
- Distal digits or terminal structures
- Pads, claws, hooks, hooves, fins, or other terminal adaptations

The same underlying appendage system should produce short supporting legs, long running legs, grasping appendages, insect-like limbs, and flipper-like structures.

Do not hardcode animal-specific limbs.

### Other appendages

Support tails, fins, membranes, horns, spikes, antennae, and flexible extensions.

These must connect to valid body regions and use appropriate supporting tissues.

### Anatomical metadata

Each building block needs:

- Unique ID
- Parent structure
- Attachment position
- Local orientation
- Length, width, thickness, and curvature
- Structural support type
- Tissue composition
- Joint definitions where applicable
- Functional role or capability
- Growth state
- Damage and health state

Use one shared anatomical representation for rendering, physiology, development, and future combat.

---

## 3. Genetics Must Control Actual Anatomy

The genome must influence:

- Number and arrangement of body regions
- Body-axis organization
- Symmetry
- Head development and placement
- Appendage count and attachment locations
- Segment proportions
- Joint placement and flexibility
- Skeletal density and thickness
- Muscle volume and density
- Skin thickness and toughness
- Fat distribution
- Armor and defensive structures
- Organ development and placement
- Sensory and nervous-system development
- Growth rates and developmental timing

Use existing loci and gene-expression mechanisms where possible.

If additional developmental controls are needed, derive them through the existing regulatory/expression architecture rather than silently changing the genome format.

Every major visible anatomical variation must be traceable to a genome or developmental condition.

A fixed genome, seed, and developmental environment must reproduce the same anatomy.

Mutation and inheritance must meaningfully affect these anatomical characteristics.

---

## 4. Generate Anatomy in a Defined Developmental Order

Do not generate a random silhouette and fill it with tissue afterward.

Instead:

1. Establish the organism's primary body axis and symmetry.
2. Develop its initial body regions.
3. Establish structural support.
4. Form appendage buds at genetically selected attachment points.
5. Elongate and differentiate appendage segments.
6. Form joints and distal structures.
7. Develop head-bearing and sensory structures.
8. Place internal organs within suitable regions.
9. Connect muscle, nerve, and supporting tissues.
10. Develop fat, skin, protective tissue, and external coverings.
11. Continue growth toward the mature anatomical proportions.

The exact biological timing may overlap, but the dependency relationships must remain valid.

An appendage cannot have a functional joint without suitable supporting structures.

Muscles must connect to structures they can actually move.

Organs must occupy valid anatomical space.

Nerves must connect functional sensory and motor structures.

If a genetically generated organism is biologically impossible, allow developmental failure or reduced viability.

Do not silently replace a failed organism with a generic blob.

---

## 5. Make Physical Stats Emerge From Anatomy

This is a central requirement.

**DNA controls anatomical development. Developed anatomy determines physical capabilities.**

Do not independently generate a high Strength value and then create an unrelated weak-looking body.

Use the existing stat system, but make the anatomical and physiological calculations meaningful.

### Strength

Derive functional force production from:

- Muscle mass
- Muscle quality
- Muscle attachment leverage
- Joint configuration
- Structural support
- Energy availability

### Defense

Derive protection from:

- Bone thickness and density
- Skin thickness and toughness
- Fat distribution
- Protective plates or armor
- Anatomical location
- Tissue health

Defense must be region-specific.

A heavily armored back should not automatically protect an exposed abdomen.

### Dexterity

Consider:

- Joint articulation
- Nervous-system control
- Sensory feedback
- Fine muscle control
- Appendage specialization

### Speed

Consider:

- Limb proportions
- Locomotion method
- Muscle force
- Body mass
- Balance
- Joint range
- Energy consumption

### Vitality and Health

Consider:

- Organ capacity
- Circulatory efficiency
- Respiratory capacity
- Tissue health
- Body size and metabolic demand

### Endurance

Consider:

- Energy reserves
- Muscle efficiency
- Respiratory and circulatory support
- Metabolic demand
- Fatigue accumulation

Preserve the distinction between inherited genetic potential and current physiological condition.

Existing primary stats that are not purely physical, such as Intelligence, Nature, and Attunement, must retain their appropriate biological or behavioral meanings.

Avoid double-counting the same genetic influence through both a direct stat bonus and the anatomy it produced.

### Anatomical tradeoffs

Implement meaningful tradeoffs.

Examples:

- Heavy bone and muscle increase mass and energy requirements.
- Thick armor improves protection but may reduce mobility.
- Long limbs can improve stride but increase leverage and structural demands.
- Large bodies require greater circulatory and respiratory capacity.
- Multiple heads or appendages require additional energy, nerves, and support.

Anatomy should constrain capabilities rather than merely decorate them.

---

## 6. Create a Dedicated Anatomy Generator Test Screen

Add a new development-only screen accessible from the desktop laboratory's Settings or developer controls.

Name it **Anatomy Generator**.

It must be clearly separated from the normal laboratory workflow.

### Required controls

**Generate Random Organism**

Generate a random genome using the real Cellarium genome system.

Run it through the actual developmental and anatomical generator.

Display the resulting organism in a large side-view viewport.

**Regenerate**

Immediately generate another random organism.

**Seed**

Display and allow entry of the random seed.

Reusing the seed with identical conditions must reproduce the same result.

**Development playback**

Show the organism developing from its initial cell through anatomical formation.

Include:

- Play
- Pause
- Step
- Restart
- Playback speed

Playback must reflect actual recorded developmental states, not an animation that simply scales the final organism.

**Anatomy layers**

Provide the existing anatomical views:

- External/skin
- Skeleton
- Muscle
- Fat
- Organs
- Nervous system

Allow individual layers and combined views.

Each view must show the same generated organism, with the correct structures aligned.

**Inspection**

Click an anatomical structure to inspect:

- Structure type
- Parent and attachments
- Dimensions
- Tissue composition
- Genetic influences
- Function
- Calculated physical contribution

**Statistics panel**

Display:

- Primary genetic traits
- Expressed physical stats
- Body mass
- Muscle mass
- Bone mass
- Fat mass
- Protective tissue mass
- Organ capacity
- Locomotion capabilities
- Metabolic requirements
- Viability

Show enough detail to explain why the organism has its calculated stats.

**Save Genome**

Allow saving an interesting genome to the existing genome archive for later use in the laboratory.

**Export Test Results**

Export the seed, genome reference, anatomical structure summary, statistics, viability, and any development errors.

### Side-view rendering

Use a side-view presentation that clearly reveals:

- Head and torso proportions
- Limb placement
- Joint articulation
- Tail placement
- Skeletal connections
- Muscle distribution
- Body posture

The test screen must use the real generated anatomy.

Do not create hand-authored example animals or substitute static illustrations.

---

## 7. Improve Rendering Without Faking Anatomy

The external silhouette must be derived from the connected anatomical structures.

Avoid drawing each structure as an isolated oval or circle.

Blend adjoining body volumes into a continuous silhouette while preserving visible anatomical distinctions.

Examples:

- Limbs should visibly emerge from the torso.
- Heads should have recognizable separation from neck or trunk regions.
- Joints should articulate without disconnected tissue.
- Tails should taper naturally.
- Muscle and fat distribution should affect the outer contour.
- Armor should appear only where protective tissue exists.

Do not use random spikes, branches, or surface noise as a substitute for anatomical complexity.

Maintain procedural graphics. Do not require external animal sprite sheets.

---

## 8. Preserve Biological Freedom

Do not restrict organisms to conventional Earth animals.

Valid results may include:

- Two-legged organisms
- Four-legged organisms
- Six-legged organisms
- Multiple heads
- No distinct head
- Unusual body proportions
- Radial or asymmetric organisms
- Aquatic or terrestrial adaptations
- Limbless organisms

However, these forms must arise from anatomical development, not arbitrary silhouette distortion.

**Worms, starfish, and blobs remain valid possible outcomes. They must no longer dominate the generator merely because it cannot construct anything else.**

Do not force every genome into a quadruped.

---

## 9. Validation and Automated Testing

Add automated tests for:

1. Deterministic generation from genome, seed, and environment.
2. Anatomical parent-child connectivity.
3. Valid limb and joint attachments.
4. Muscle-to-structure connections.
5. Nervous-system connectivity.
6. Organ placement within suitable body regions.
7. Tissue mass conservation and nonnegative volumes.
8. Region-specific defense.
9. Stat changes when anatomical properties change.
10. Genetic inheritance of anatomical characteristics.
11. Developmental failure without generic fallback substitution.
12. Save/load preservation of anatomy and genomes.
13. Development playback consistency with the final organism.
14. Compatibility with existing organism records and laboratory systems.

Create a repeatable **100-organism generation audit**.

Report:

- Number of viable organisms
- Number of developmental failures
- Distribution of body configurations
- Appendage counts
- Head-bearing region counts
- Body mass ranges
- Muscle and skeletal mass ranges
- Common structural failures
- Distinct anatomical configurations

Generate a visual contact sheet showing at least 20 actual generated organisms in side view, each with its seed.

The contact sheet must come from the same anatomy generator used by the laboratory.

Do not artificially select only successful or attractive specimens without identifying the selection criteria.

---

## 10. Integration and Compatibility

Keep the work on `desktop-laboratory-dev`.

The new generator must integrate with:

- Existing genome archives
- The Genome Forge
- Incubation and embryonic development
- Organism research records
- Anatomical layer inspection
- Habitats and locomotion
- Physiology
- Save/load
- Inheritance and mutation

Preserve existing functionality unless a change is necessary and documented.

Do not replace the desktop laboratory interface with the anatomy test screen.

The test screen is a development tool, not a separate game or fake prototype.

If a change requires migrating old anatomical records, implement a documented migration strategy rather than silently discarding organisms.

---

## 11. Deliverables

When finished, provide:

1. The working anatomical building-block system.
2. The genetically driven development pipeline.
3. Anatomy-derived physical statistics and defensive properties.
4. The new interactive side-view Anatomy Generator screen.
5. Development playback and anatomical layer inspection.
6. A reproducible 100-organism audit.
7. A 20-organism visual contact sheet.
8. Automated tests and their actual results.
9. Documentation explaining the new architecture.
10. An updated user/developer guide explaining how to access and operate the generator.

Do not report tests as passed unless they were executed successfully.

If native Windows interaction cannot be tested, explicitly identify the unverified behavior.

## Acceptance Criteria

This development pass succeeds when:

- Random genomes can produce coherent, visibly distinct anatomical configurations.
- Body parts visibly develop instead of appearing as finished decorations.
- Skeleton, muscle, skin, fat, nerves, and organs correspond to the same structures.
- DNA meaningfully controls anatomical proportions and tissue development.
- Calculated physical stats agree with the organism's actual anatomy.
- Side-view organisms look like assembled, living multicellular bodies rather than disconnected geometric shapes.
- The player can inspect the entire process in the Anatomy Generator screen.
- The resulting organisms can enter the existing Cellarium laboratory and habitat systems.

**Most importantly: do not solve this by creating a collection of predefined animal templates. Build reusable anatomical structures whose genetic variation creates the organisms.**

We are building a synthetic-life simulator. The goal is believable emergent anatomy, not randomly assembled animal sprites.