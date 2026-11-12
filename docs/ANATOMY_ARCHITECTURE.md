# Anatomical development architecture

This is the experimental `anatomy-dev` branch, based on the PC-clock desktop version published to `main` at `631da87d49f0ade2804460290edc8e25aeca75cb`. The user's branch instruction supersedes the branch named in the supplied specification. Main retains the established generator.

## Shared biological representation

The canonical genome remains 24 chromosome pairs, 72 loci and 144 alleles. `genome.lua`, gene expression, dosage, regulatory links, meiosis, fertilization, fusion and mutation remain the existing implementations. There are no animal or species templates.

`body_parts.lua` defines parameterized lofts, capsules, tapered beams, jaws, pads, hooks and foils with anatomical roles. `anatomical_growth.lua` constructs regions, support, buds, articulated segments, distal adaptations, head-bearing structures, organs, muscle/connective/nerve networks, fat and coverings in dependency order. Each region has a unique ID, parent, socket, orientation, dimensions, cavity/tissue volume budget, condition, growth state and genetic references.

The result is the existing version-3 region/component graph, extended with `anatomicalVersion=1`. Rendering, physiology, archives, incubation, habitats, records and persistence consume this same graph. It is not a separate simulation. New saves use the independent LÖVE identity `cellarium-anatomy-dev`. Importing an older experiment preserves existing organisms' anatomy; it does not regenerate them. `persistence.rebind` reconnects canonical tissue lists and the `parts` alias after loading. Main's save identity is untouched.

`anatomy.generate` selects the block generator on this branch. `anatomy.procedural` remains the previous generator. Explicit `{generator='procedural'}` and `{generator='legacy'}` development conditions retain comparison/fallback access. A biological failure in the new generator retains its body and reasons. Technical exceptions propagate to caller/reporting; the new path does not silently substitute another organism.

## Genetic mapping

| Controls | Anatomical effects |
|---|---|
| L11–13, D1–3, D5, D24 | Body size, differentiated axial regions, proportions, curvature and tail |
| D4 alleles and expression | Bilateral, radial or asymmetric organization; categorical pairing avoids the old additive middle-bin radial bias |
| L14–16, D6–11, D18 | Appendage initiation/count, socket arrangement, segment lengths/girth, support and articulation |
| L4, L22, D13–14, D23 | Neck/cranium development, head count/placement, neural and sensory housing |
| L2–3, L15–18, D11/D20 | Muscle force/volume/density, connective leverage, structural density/thickness, fat and skin |
| L19–22, D22, E1–3 | Organ size/capacity, repeated supply organs, exchange tissues, brain and motor/sensory control |
| E9–10, E14–16, E18, E20–23 | Fins/membranes, terminal pads/claws/hooks/hooves, regional armor, horns/spikes and sensory extensions |

Genetic references are attached to each generated part and exposed in the inspector. The seed generates the canonical genome; fixed genome and development conditions give deterministic construction. Nutrition and temperature alter organ capacity and viability. Gene values do not independently add physical speed/strength/health bonuses after producing anatomy.

## Physiology and tradeoffs

Lengths are displayed in inches, tissue volume in cubic inches, and mass in ounces. The geometry calibration is 32 construction units per inch. Tissue density converts each allocated tissue volume to mass; per-region allocation cannot exceed its volume budget. Coefficients are exploratory game tuning, not measured animal physiology.

`anatomical_physiology.lua` derives force from actual muscle mass, fiber force, efficiency, leverage, neural control and structural load capacity. Stride comes from developed segment lengths. Joint range, body mass, armor rigidity, organ capacity, energy reserves and metabolic demand constrain locomotion/endurance. Existing ecological capabilities still derive environmental exchange, diets and habitat compatibility from these tissues. Genetic immunity, lifespan and behavioral traits retain their prior biological meanings.

`body_parts.defense(partId, surface)` returns local protection from living support, fat and the specified dorsal/ventral skin. Increasing chest dorsal armor does not protect abdominal ventral tissue. The summary DEF stat is an average for display; the regional query is the location-specific API for future damage work. Combat remains deferred.

Organs are packed in three dimensions into permitted host cavities, with containment and intersection checks. Each head has its own cranium, brain and sensory connections. The central neural graph connects head brains and reaches every supported functional region. Failure to place necessary tissues, insufficient transport/digestion, or disconnected nerves produces explicit developmental failure.

## Recorded construction and projections

Snapshots capture actual constructor states: initial cell, axes, support, appendage buds, elongated segments, joints/distal structures, heads/tails, organs, integration, coverings and mature body. Playback never scales the final organism as a substitute for construction. Incubation maps its construction interval onto these snapshots; release uses the same completed graph and viability result. Playback controls only advance the recorded viewer, independently of the laboratory's PC clock.

`anatomical_rendering.lua` projects connected loft/beam profiles and attachment bridges from these regions. Skin/fat/muscle allocation affects contours; internal layers use the same coordinates and IDs. Side and top views are projections of the same 3-D placement. Limited joint rotations propagate to descendant parts and tissue coordinates, keeping attachments connected. Head height offsets reveal multiple heads in side view. Bilateral limbs can overlap in side projection; the reported count is the actual graph count, not the number of visible silhouettes.

## Reproduction and audit

New bodies use the same genetic inheritance/mutation operations as the laboratory. Tests cover self-inherited homozygous anatomical traits, mutation effects, targeted appendage/head allele changes, archive installation and incubation release. The unfiltered 100- and 1,000-genome audits use fixed published seeds and include every failure. `ANATOMY_CONTACT_SHEET.png` is the first 20 genomes, with no attractiveness/viability selection.

## Limits and verification

This is an experimental synthetic anatomy model: support, metabolic and cavity coefficients still need balancing. The audited 1,000-genome viability rate is 59%; failures have not been hidden or retuned away. There is no collision-based gait solver or tissue deformation physics. The side-view renderer and recorded construction are procedural inspection graphics. Anatomy snapshots increase save size.

The new anatomy suite, desktop regressions and native message-based equipment tests have executed. Native tests cover an actual second-monitor Petri move, counted sample transfer, hide/restore, dragging, context menus and direct equipment controls. They are scripted HWND tests, not a complete manual usability certification. Physical mouse use of the new developer screen remains unverified; its actual draw and callback paths are tested.

The old monolithic `tests.lua` has a pre-existing failure at line 26, `Genetic tissue/supply incompatibility must fail naturally`, reproduced on unchanged main and on the preserved procedural comparison path. It is retained as `--historical-test` and is not reported as passing. `--test` / `--anatomy-test` run the branch's anatomy suite; `--desktop-test` runs the desktop regressions. Do not confuse the historical failure with biological failures in the random-generation audit.
