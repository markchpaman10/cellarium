## Vessel workstations update (experimental)

The first tab is now **Cell Workstations** with six reusable starting containers: Petri dishes, a culture flask, a culture plate, a storage vial and a cryovial. Select a loose cell in the left library, select a vessel and choose **Add selected cell**. Cultivation works in dishes, flasks and plates with vessel-specific capacity and growth. Withdraw cells back into the library, buy empty vessels, clean/reuse them, sell individual cells or entire cultures, and freeze/thaw whole filled cryovials. Cultures with different genomes are kept separate instead of being silently merged. Containers and their cell populations persist in saves.

The second tab now supports **2 to 12 distinct genome donors**; this is multi-source synthetic recombination, not biological sexual reproduction. Research > Genome > Edit genome copy additionally offers **Incubate exact edited genome** to avoid recombination. Existing older three-donor UI smoke tests need updating. This pass has not been verified in a running LÖVE2D instance. The real-world clock/offline catch-up overhaul remains separate work.

## browser-gippity experimental pass (unverified)

This branch adds a **Research > Genome > Edit genome copy** action. Select a cell, creature, DNA template, or frozen specimen; edit either allele (0-3) at any of 72 loci; Undo or Reset; Preview a regenerated body; then **Save DNA copy**. Saved engineered DNA appears in Research > DNA. Select that template under Research > Engineering to recover a stem cell for the existing three-donor forge. The editor never changes a living organism in place.

The branch also adjusts axial and appendage tapering to encourage more differentiated silhouettes, and derives dietary compatibility from functional stomach, mouth, teeth/crushing parts, digestion and absorption. The existing foraging system uses these derived efficiencies. **Active hunting, plant growth/consumption ecosystems, and a full browser runtime are not yet implemented.** This code has not been executed in a LÖVE2D runtime by the assistant; test before merging.

# Cellarium v2 — Genetic Life Simulator

A native LÖVE2D game revised around the new Genetic Life Simulator specification. Start with a simple laboratory loop, then inspect the chromosomes, connected anatomy and physiology behind your organisms. All art is generated in Lua. Creature silhouettes are pixel-rasterized continuous envelopes of actual grown anatomy, with regional coverings, exchange tissues, membranes and attached projections. Cells retain procedural microscope graphics.

## Run

Windows: extract Cellarium-Windows.zip completely and open Cellarium.exe. The LÖVE runtime and licenses are included, so no installation is needed. Keep the DLL files beside the executable.

Other platforms with LÖVE 11.5: open Cellarium.love, or run `love path/to/Cellarium` from source.

## First organism

1. In Cultivation, select a cell in the left library and click Seed selected cell on a dish. Balanced conditions work automatically. Rich medium grows faster. Harvest once ready to obtain the original specimen and viable daughter cells.
2. In Genome forge, select a cell and add it to a donor slot. Repeat with three distinct specimens, then Combine genomes. No genetics knowledge is required.
3. The zygote develops through cell division, differentiation, body-plan formation, organ development and a viability check. A viable juvenile enters Living habitat after approximately 24–36 simulation hours, depending on developed tissue costs. One simulation hour takes one real second at 1×.
4. Click a creature to see its condition. Feed the habitat if needed. The freshwater pool supplies drinking water automatically. Creatures forage, drink, rest, grow, avoid aggressive neighbors, seek mates, age and die.
5. Freeze useful specimens and thaw them from Cryobank. Sample a living organism to return its inherited genome to the laboratory as seven tissue categories.

Startup always starts a fresh experiment. Click New to restart the current session; click Load only when you want to restore a manual save. New does not overwrite your saved experiment.

Space pauses; 1–5 select workspaces; S saves. The speed button cycles 1×, 3× and 8×. There is no autosave, including on exit. Only the Save button or S writes an experiment save. Smoke tests and UI tests never save their temporary experiments.

## Organized cells and the expanded forge

Cultivation and Genome Forge share a collection grouped by cell category and genetic strain. Cycle the cell-type filter, sort by type/strain, viability, mutations or generation, and mark favorite specimens with the star. Fav filters the collection to favorites. Filters and sorts never change the specimens or genomes. Each row shows strain name, generation and viability.

After choosing three distinct donors in Genome Forge, a development forecast shows the actual inherited body, viability, mass/upkeep, mutation history and environmental scores. Normal majority fusion remains the default. Mosaic recombination uses alternating source contributions. Mutation exposure changes alleles through seeded, recorded events; it can be harmful. Nutrition influences tissue development, minerals influence cover hardness and mass, oxygen affects respiratory development, and incubation warmth affects developmental quality. Temperatures are displayed in Fahrenheit. Release chooses an environment in the habitat, not an organism type. Auto places new juveniles in a suitable available region. Release into an incompatible environment remains risky.

New lab options apply to the resulting embryo and are stored in its experiment record. Nutritional/mineral/temperature changes alter development without rewriting the inherited genome; mutation exposure explicitly changes heritable genetic material. For repeatability, use the same donors and the same conditions.

## Research tools

Research has eight contextual views; they all use the same underlying simulation.

- Genome: inspect all 24 chromosome pairs, all 144 allele values across primary, developmental and ecology pages, locus expression and parental contributions. Pin one genome, then select another to compare changed alleles and similarity. The eight-base / 16-bit marker encodes alleles at the first four loci, not the whole genome.
- Anatomy: choose a creature and switch External, Skin, Muscle, Fat, Skeleton, Organs or Nervous layers. Click a structure or use the structure arrows to inspect its attachment, mass, condition and functional properties. The renderer reads the actual anatomy used in simulation.
- Development: inspect the expressed developmental instructions, region budget, actual GROW/DIVIDE/BRANCH/MIRROR/DIFFERENTIATE/CONNECT/TERMINATE history, support arrangement and functional limitations.
- Environment: inspect land, freshwater, saltwater and flight scores, respiratory supply/demand, buoyancy, moisture retention, lift/control/propulsion and dietary compatibility.
- Physiology: inspect health, energy, hunger, thirst, stamina, immunity, sickness, fat reserves, muscle mass, maturity, lifespan, metabolism, sensory performance and inherited mutation records.
- Engineering: extract DNA into a separate archive; recover a stem-cell template from archived DNA; name a genetic strain; specialize epithelial cells into digestive tissue; form egg or sperm precursors from stem cells. Precursors mature in eight hours. Select a mature egg and sperm and fertilize them. Select two mature, living creatures as parents A and B to breed deliberately.
- Experiments: browse structured cultivation, fusion and fertilization records, including inputs, conditions, genomes and development outcomes. Restore three fusion templates to repeat their genetic combination. The original genome-derived tie-break seed reproduces the same alleles; match development conditions to reproduce the anatomy.
- Cultures: inspect and adjust temperature, replenish sterile medium, unseal dishes to investigate contamination, and discard failed cultures. Growth depends on cell category, genetic efficiency, nutrients, energy, density, health, temperature, waste and contamination.

During early incubation, temperature can also be adjusted before the anatomical program is established. Default conditions are safe. Organ deficits and developmental failure report their reasons.

Strain names apply to living, cultured and frozen specimens in that line. Creature names are individual. Use Enter to accept a name and Escape to cancel.

## Canonical biology

The seven categories are Stem, Muscle, Nerve, Epithelial, Blood, Structural and Adipose. Digestive tissue is an epithelial subtype. Categories have distinct replication rates and replicative limits; stem cells support the reproductive-material pathway. Specimens carry unique IDs, strain/source lineage, generation, genomes, mutation history, viability, health, energy, age, environmental tolerance, differentiation and preservation state.

The canonical genome has 24 chromosome pairs, with the original primary and developmental loci plus an ecological locus on each chromosome (72 loci, 144 alleles). No primary allele has been discarded. Alleles range from 0–3. Additive/incomplete, dominant, recessive and blended pigment expression are defined explicitly. The ten primary traits are Power, Strength, Dexterity, Intelligence, Health, Vitality, Endurance, Nature, Speed and Attunement. Perception is derived from neural and sensory characteristics. Other loci control body dimensions, limbs, tissues, organs, pigmentation and fertility.

Three-cell laboratory fusion votes separately at each allele position and uses a genome-derived seed to resolve ties. Ordinary reproduction uses two haploid parental contributions from meiosis. All three loci segregate during meiosis, with modeled intrachromosomal recombination between them. Developmental mutations are usually single-allele steps; topology-changing symmetry, branch-initiation and recursion loci mutate less frequently. Nearby, healthy, mature, fertile pairs reproduce autonomously. Solitary organisms no longer bud. Lineage, offspring, common ancestry and homozygosity are inspectable. Recessive load affects fertility; there is no fixed I10 sterility rule.

Developmental expression controls axis length/breadth/orientation/curvature, segmentation, bilateral/radial/asymmetric symmetry, branching and recursion, appendage positions and joints, flexible/rigid/external support, tissue allocation, organ positioning and multiplicity, sensory structures, covering texture and metabolism. A shared growth grammar constructs connected regions. No named animal templates are selected. Primary morphology and physiology loci continue to influence the phenotype.

Organisms can have no appendages, one extension, paired structures, radial arrangements or recursive branches. Flexible support can replace bone. Muscles attach to real supporting regions. Organ counts, sizes and protected positions vary, and networks connect actual neural and circulatory components. Thin, flexible coverings can provide cutaneous exchange instead of lungs. Viability checks tissue support, connectivity, energy and resource supply, exchange, waste handling, organ cavities and coordination. Biological failure is recorded rather than silently replaced by a successful old-style creature.

Movement capabilities are calculated from the generated anatomy. Available mechanisms include jointed propulsion, contractions, undulation and radial propulsion. The strongest available mechanism is used, with existing energy, stamina, injury and physiology limits. Stationary organisms are supported if no effective propulsion remains. The renderer animates the corresponding grown graph and rasterizes its connected tissue envelope; it does not stamp rectangular skin tiles into the silhouette.

Simulation advances in fixed 0.05-hour steps independently of rendering. Seeded RNG controls explicitly variable events. Development itself is deterministic for a genome and controlled conditions.

## Save compatibility

Version 4 saves preserve cells, strains, cryostorage, genomes, DNA templates, gametes, experiments, embryos, organisms, anatomy/condition, physiology, lineage, food and habitat state. The application retains the existing save identity. The previous save is backed up before a successful write.

Original seven-value Cellarium saves are explicitly migrated to canonical chromosome genomes. Existing digestive cells become specialized epithelial cells; existing cell categories are remapped consistently. Original organisms retain identity, position, age, energy and health while anatomy is reconstructed from their translated genome. The migration is an approximation, not a claim that v1 stored 48 alleles. A separate explicit legacy 16-character numeric genome translator exists in genome.lua; there was no historical nine-stat save file to import.

Version 2 genomes gain deterministic developmental loci derived from their existing genetic content; every primary allele, marker, lineage and biological record is preserved. Existing living anatomy is retained exactly as legacy anatomy, rather than remaking saved creatures. Frozen cells, extracted DNA, embryos, gametes and historical experiment genomes are migrated too. New offspring use the developmental loci. Original seven-value saves also retain their explicit migration path.

## Measured diversity and fallback

Run the unpacked source with `lovec path/to/Cellarium --audit`. This generates diversity-audit.md, diversity-audit.csv (all 1,000 individual results), diversity-audit-data.lua, representative audit genotypes, and the release certificate. Seed 20261111 is recorded so the assay is reproducible. It uses 1,000 unfiltered three-wild-genome fusions, 200 actual chromosome-inheritance crosses of viable parents, 100 deterministic regeneration checks, three-generation fixed-line checks and 100 short habitat-survival runs. Failed embryos remain in the denominator. The report distinguishes developmental symmetry programs, visibly multi-region radial bodies, all appendages, and primary jointed locomotor branches.

The new generator is enabled by the measured certificate only after the release gates pass. anatomy_legacy.lua and rendering_legacy.lua remain intact as fallback implementations. Old saved anatomy continues to use them. Controlled development may explicitly request `{generator='legacy'}` for comparisons. An unexpected technical exception in the new generator invokes the legacy generator and records technicalFallback; ordinary biological failure never triggers that rescue. If the certificate is not approved, the legacy generator stays the default. Audit runs call the new generator directly and never count fallback output.

`Cellarium-Body-Plans.png` shows six actual viable audit outputs; their source genotypes and sample numbers are retained. The examples are acceptance categories selected from measured output, never predefined construction templates. They are fitted individually for legibility, not drawn to a common physical scale.

## Ecological habitat, coverings and anatomical defenses

One seeded map contains land, shorelines, shallow/deep freshwater and saltwater, plants, shelter, obstacles and elevation, with airspace above it. Organisms physically move across region boundaries. Air/water respiration uses actual exchange tissue, efficiency, oxygen availability and ventilation relative to metabolic demand. Oxygen deficiency reduces condition and can cause tissue injury or death. Hydration, thermal and salinity exposure use inherited tolerances. The climate control cycles 72°F, 54°F and 95°F. All user-facing temperature displays use Fahrenheit; internal simulation temperatures use the existing scientific scale.

Land, freshwater, saltwater and flight percentages are derived compatibility summaries, never fixed species classes or guaranteed survival probabilities. Jointed motion, contractions and undulation are retained. Fins and buoyancy influence swimming. Actual membrane area, mass, force, support and control determine whether gliding or powered flight is available. Flying organisms climb, expend energy, and descend to feed or rest. Shadows identify altitude. These are normalized game-scale aerodynamics, not a literal fluid-dynamics simulation.

Regional skin records carry keratinization, mineralization, flexibility, segmentation, thickness, repair, hardness, rigidity and armor. Joint and exposed-region expression varies. Covering descriptions emerge from those properties. Protection brings mass, growth, upkeep, flexibility, sensing/exchange and movement trade-offs. Attached projections emerge from tissue growth and supporting anatomy, with roles such as teeth, claws, horns/spines and crushing mouthparts. Their functional effectiveness includes attachment condition and actual muscular force. Select Skin or Defenses in Anatomy to inspect the real components.

Dissolved nutrients, plants, debris and animal tissue have different digestive compatibility. Tissue resources can come from corpses; having teeth never activates predatory AI. No battles, attack AI, arenas, multiplayer or competitive combat are included. defenses.lua provides only a tested regional injury interface for future work, with different penetration/tearing/blunt tissue responses. Armor is never treated as a universal percent damage reduction.

The ecological gene extension preserves every previous primary/developmental allele. Old saved anatomy is retained with a compatible legacy respiratory interpretation; new offspring express the new ecological genes. Habitat and all new component records are versioned and manually saved. Startup and New always start fresh; only Load restores a manual save. There is no autosave.

## Ecological audit

Run `lovec path/to/Cellarium --ecology-audit` from the unpacked source to reproduce the seed-7132026 audit of 1,000 independent wild-genome fusions. ecology-audit.md reports overlapping capability/covering/projection frequencies and nonviable causes without category quotas. ecology-audit.csv contains every individual result. The same run conducts a seeded 900-hour habitat simulation with diverse mature founders and records population, births, deaths/causes, generations, genetic diversity, adaptation and covering variation in ecology-population.csv. Resource renewal is explicitly recorded at 3x baseline for that finite study. It is a regression experiment, not a promise of indefinite ecological balance. All requested categories appeared in the audited seed.

The original body-plan audit and preserved fallback remain available separately. Ecology checks add suitable/mismatched respiration, boundary crossing, flight requirements, regional protection costs, valid attachments, mechanism-dependent injury, feeding compatibility, all-three-locus inheritance, forge condition effects, seeded maps, save/load, filters/favorites and Fahrenheit conversion. Development test fixtures never write player saves.

## Current implementation boundary

This revision implements a playable first version of roadmap phases 1–4, with foundational inheritance, selection and lineage. It does not claim to complete the whole long-term specification.

Deferred: desktop-pet windows and desktop integration, offline and online combat, authoritative servers, full predation/food webs, species taxonomy, large populations, advanced allele editing, somatic mutation, rich learning/memory, detailed organ pathology. Automatic breeding is limited to 30 concurrent living/developing organisms. Historical corpses remain inspectable. This remains an abstract developmental and physiological game simulation, not a molecular or clinical biology model. Airways, lung-like exchange, gill-like exchange and permeable skin are modeled with normalized capacities. Broader organ families and more detailed aerodynamics remain future work.

## Modules and validation

- genome.lua: chromosome representation, expression, markers, inheritance, mutation, legacy translation
- cultivation.lua: specimen records, cell functions and resource-driven cultures
- development.lua: differentiation, anatomy construction and viability
- development_genes.lua / growth.lua: expression of developmental loci and bounded growth operations
- anatomy.lua: functional capacities, viability, regional damage and certified fallback selection
- anatomy_legacy.lua: preserved previous anatomy implementation
- silhouette.lua: continuous graph-envelope rasterization
- physiology.lua: needs, autonomous behavior, growth, metabolism, illness, recovery and death
- reproduction.lua: compatibility, two-parent inheritance and ancestry
- biology.lua: simulation orchestration, lab actions and fixed steps
- persistence.lua: versioned data, migration, validation and anatomy reference reconstruction
- rendering.lua / rendering_legacy.lua: continuous pixel silhouettes, locomotion poses, anatomy layers and legacy rendering
- research.lua / main.lua: inspection tools, laboratory UI and input

`lovec path/to/Cellarium --test` runs simulation tests on Windows; `love` works elsewhere. Results appear in test-results.txt when run from an unpacked source folder. Thirty-three test groups cover canonical genetics, deterministic development, inheritance, functional anatomy, developmental failure, bounded mutation, repeated selective inheritance, the full beginner loop, controlled fusion replay, gametes, fixed-step consistency, lineage, cultivation stress and persistence/migration, developmental-locus inheritance, phenotype stability, fallback preservation and connected tissue envelopes in all locomotion poses.

`--ui-test` exercises actual mouse/key callbacks for the full lab loop, inspection, naming, extraction, gametes, fertilization and breeding. `--smoke`, `--habitat-smoke`, `--genome-smoke`, `--anatomy-smoke`, `--engineering-smoke`, `--physiology-smoke`, `--culture-smoke` and `--incubation-smoke`, `--development-smoke`, `--development-genome-smoke` and `--diversity-smoke` render test fixtures and exit. Unpacked-source smoke tests write preview.png. See IMPLEMENTATION.md for the original system inventory and restructuring decisions.

The 1,000-case audit takes additional time and writes its results into the unpacked source folder. It is separate from the quicker regression and UI checks.

Additional modules: environment_genes.lua (ecological loci), adaptation.lua (regional development/capabilities), habitat.lua (shared seeded map), habitat_view.lua (map rendering), defenses.lua (future injury interface), cell_library.lua (organized collection), forge_ui.lua (forecast/experimental controls), units.lua (Fahrenheit conversion), ecology_audit.lua and ecology_tests.lua (measured validation).

Navigation follows passable grid routes around obstacles and unsuitable regions. Low sensory acuity can still allow environmental mistakes. Natural offspring develop near their parents; laboratory release uses the chosen environment. Habitat Renewal cycles resource renewal from 1x to 4x. The current strict 900-hour study can become extinct; long-term balance remains an explicit development limitation, with measured causes retained in the report.
