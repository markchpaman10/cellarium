# Desktop revision: audit before implementation

Base: engineering merge fd52de1, identical to browser-gippity 1f4bd98. The local launch-only configuration uses a separate engineering identity.

The current main.lua owns the simulation and five detailed workspaces. Biology is in biology.lua; fixed steps are 0.05 simulation hours. No desktop host, native tray, independent windows, monitor layout or offline catch-up exists. persistence.lua supports manual version-4 experiments and older migrations. Rendering is LÖVE-specific; biological state is ordinary Lua tables.

Vessels are the authoritative reusable containers (vessels.lua); their contents contain real cell genomes and counts. They are distinct from older cultivation dishes, which must remain available. The existing transfer API accepts arbitrary quantities from a single loose cell and therefore cannot be used unchanged for a conserving pipette. It also omits several physical culture conditions. The new transfer layer must validate before mutation and retain samples when a target rejects them.

Genome editor supports 72 loci / 144 alleles, copy editing, preview, DNA archiving and exact incubation. Undo fails to restore sourceA/sourceB metadata. Multi-donor recombination supports 2–12 donors. Duplication, deletion, regulation and sequence export are absent in this base, despite being listed as desired Forge operations. They require real expression integration, not decorative buttons.

Physiology already uses real anatomy for movement, respiration, feeding, drinking, rest, mate seeking and survival. It uses one shared mixed terrestrial/aquatic habitat. Multiple persistent habitat contexts must partition the same organism records, not copy organisms. Memories, relationships and six dynamic stats from the former engineering version were overwritten by the Gippity merge; those are absent in this base.

UI inventory and destination:

| Existing capability | Desktop entry / detailed workspace |
|---|---|
| Cell collection, filters, favorites, cultivation, sales | Cell workstation / retained workspace 1 |
| Reusable vessel creation, growth, freeze/thaw | Physical vessel / vessel inspector and workspace 1 |
| 2–12 donor assembly, incubation settings | Forge / retained workspace 2 |
| Allele editing, preview, DNA archive, exact incubation | Forge / Research Genome Edit |
| Legacy dish maturation and harvest | Research Cultures / retained controls |
| Living ecosystem, resources, climate, tissue sampling | Habitat frame / retained workspace 3 plus object inspector |
| Freeze/thaw specimens and journal | Research / retained workspace 4 |
| Genome, anatomy layers, development, physiology, ecology | Research / retained workspace 5 |
| Extraction, gametes, fertilization, selective breeding | Cell workstation / Research Engineering |
| Manual Save / Load / New | Retained browser window; desktop envelope saves separately |

Architecture choice: one LÖVE/LuaJIT process, one Win32 per-pixel layered tool window per desktop object, one hidden tray-control window, and the retained LÖVE detailed application window. No desktop-sized input-capturing overlay and no external service. Window procedures queue actions; the main thread applies them to shared tables. Win32 is isolated behind a host interface; layout/transfers/worlds/persistence are testable without native windows.

The new prompt explicitly requires exit persistence and launch restoration. This desktop revision has a new save identity and implements that behavior; existing versions and their manual saves remain separate. It does not install startup tasks or system-wide mouse hooks.

References: Fisherbrand culture tubes confirmed as transparent round-bottom tubes; NEST page refused automated access (403). Petri art follows the supplied shallow-rim specification. Terrarium is a provisional enclosed generic specimen habitat; no claim is made about the advertising redirect's product. Artwork is local procedural LÖVE drawing, with no retailer photographs.
