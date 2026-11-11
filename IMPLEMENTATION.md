# Specification inventory and implementation boundary



Before revision: collection, three petri dishes, cultivation, cryostorage, three-cell fusion, incubation, habitat movement/feeding, aging/death, budding, a journal, seeded RNG and local saves worked.



Incomplete: cultivation had no resource model; cells had almost no biological state; lineage was only text; reproduction mixed visible stat values; the journal was not structured experiment data.



Conflicts: seven haploid stat values instead of 24 chromosome pairs; digestive cells were a primary category and adipose cells were absent; freehand radial creatures had decorative anatomy; variable-step simulation; unversioned saves.



Preserved: the four-workspace laboratory loop, dish/library interactions, cryobank, speed controls, input handling, habitat, save identity and dark laboratory UI. V1 source is backed up separately in the working directory.



Restructured: canonical genetics, cell state, cultivation, development, procedural anatomy, physiology, reproduction, rendering, persistence. The old seven-value genome is explicitly migrated; it is not retained as a second simulation engine.



This revision targets the first four roadmap phases with an initial, constrained implementation, plus foundational lineage/selection. Desktop pets, desktop integration, online/server competition, full predation and large ecosystems remain later phases. Offline combat is also deferred rather than pretending an untested battle system is complete. Advanced allele editing, multiple modeled loci per chromosome, somatic mutations and detailed organ pathology remain extension points. The supported initial anatomy is a bilateral terrestrial lung-breathing organism assembled from 16x16 components.





# Procedural body-plan overhaul (v3)



Preserved the working genome primary loci, laboratory, cultivation, cryostorage, haploid reproduction, physiology, lineage and save identity. Added one secondary developmental locus per chromosome through an explicit version-3 migration. Existing primary alleles and living anatomical component records are preserved.



The old anatomy/rendering implementations remain in anatomy_legacy.lua and rendering_legacy.lua. The new generator is separated into developmental expression, bounded growth operations, functional viability and continuous-envelope rendering. A generated certificate gates default selection after the measured 1,000-fusion audit; unexpected technical errors use the preserved fallback, while biological failures remain genuine failures. Save migration never remakes a living version-2 body.



New construction operates on spatial regions and attachments, not 16×16 biological tiles. Rasterization is downstream of development. The component atlas remains useful for inspection. Added Development research and a second genome page; the rest of the working laboratory UI is preserved.



See diversity-audit.md and the 1,000-row CSV for actual frequencies, viability, offspring inheritance, topology diversity, short-term survival and explicit release gates. Representative examples originate from those same wild-fusion samples. Multi-legged/four-legged counts require actual primary jointed locomotor branches; all-appendage counts include recursive growth. These are overlapping measurements, not fixed creature classes.



# Ecology and laboratory update (v4)

Preserved the developmental grammar and legacy fallback. Added a third heritable locus per chromosome without replacing existing alleles. New development adds regional coverings, airways/gills, fins/membranes, supported feeding/defensive projections, and functional trade-offs. Environmental physiology uses a single seeded map. Old saved component geometry remains intact.

Cultivation and forge share a sorted/filterable collection with favorites. Forge exposes controlled seeded recombination/mutation and developmental conditions, a real anatomical forecast and release environment. No species presets were added. Temperatures use Fahrenheit. Startup stays fresh, New is available, Load and Save are explicit, and autosave is disabled.

Combat scope is limited to anatomy and a regional damage API. There is no attack AI, predator/prey fight loop, arena or network combat. Measured ecological frequencies and a 900-hour population run accompany the release, including deaths and finite-run limits.
