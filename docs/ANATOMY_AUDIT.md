# Anatomy audit before implementation

Branch: anatomy-dev, created from main at 631da87d49f0ade2804460290edc8e25aeca75cb. The user's explicit new-branch instruction supersedes the pasted specification's desktop-laboratory-dev branch name. The tested PC-time desktop baseline remains on main.

## Existing representation and integration

The canonical genome is version 4: 24 chromosome pairs, three loci per pair, 144 bounded alleles. Primary, developmental and ecological expression already supports dosage and regulatory metadata; meiosis, fusion, mutation and archives use that same genome. It must not be replaced.

Anatomy version 3 is a region graph plus canonical tissue components and ID-based structural, neural and vascular edges. Physiology, locomotion, dynamic stats, damage, save rebinding, research layers and rendering all consume it. Older anatomical records and anatomy_legacy.lua must remain readable. New records can extend version 3 with an anatomical-block schema while retaining these canonical arrays and IDs, rather than introducing a second organism model.

## Why the current shapes cluster

1. growth.lua has only axis and appendage region kinds. It never constructs a torso/chest/pelvis, a head capsule, jaws, distal digits or anatomical attachment sockets. More regions cannot compensate for the missing distinctions.
2. Every region starts as an ellipse. silhouette.lua blends ellipses and sampled parent-to-child connectors. Long connected axes naturally become worms; radial copies become starbursts; compact budgets become blobs. The renderer accurately displays the limited graph it receives.
3. Symmetry uses additive D4 mean thresholds: <=1/3 bilateral, <=2/3 radial, otherwise asymmetric. For uniformly drawn allele pairs these bins contain 6/16, 7/16 and 3/16 combinations. Fusion further concentrates middle expressions. The middle band is therefore not an equally likely categorical choice.
4. D5 segmentation grows serial axes while D6 branch initiation has a broad off range. Those choices often allocate substantial budget to an unstructured trunk with no differentiated appendage sockets.
5. Branches use a repeated radius/taper formula and broad angular placements. Joint differentiation toggles some links, but no proximal/distal segment roles, limited articulation, functional terminal structures or support postures are built.
6. Tissue differentiation runs after the entire region graph is laid out. Muscles connect each support to its parent; their force uses primary Strength/Power multipliers. Organ placement searches ellipsoidal cavities. Sensors are distributed along axes rather than built into connected head-bearing systems.
7. Capability calculations already read tissue mass/condition, but speed, health and endurance also add direct genetic multipliers after genes produced those same tissues. This can double-count physical potential. Defense is averaged globally instead of exposing regional coverage and load paths.
8. Development records operations, but development.lua generates the complete anatomy at progress >0.35 and scales aggregate tissue quantities. Those operations are not chronological anatomical states, so scaling the finished body would not meet the requested playback requirement.
9. Existing rendering uses the same graph for external and internal layers, which should be preserved, but the internal views mostly stamp tissue icons. A block renderer should derive a continuous contour and aligned layers from the actual generated structures and their coordinates.

## Before-change measurement

ANATOMY_BASELINE.md and anatomy-baseline-data.lua are produced before generator changes from 100 unfiltered random canonical genomes with fixed seeds and standard conditions. Failures stay in the denominator. Explicit head count is zero because no head-bearing taxonomy exists, not because decorative sensors were reinterpreted as heads. No species templates or handpicked attractive results are used.

## Implementation constraints

Use a parameterized anatomical-part library and ordered construction with explicit sockets, support, joints, muscle origins/insertions, cavities, nerves, coverings and regional defense. Preserve the existing canonical genome and biological records. Keep actual developmental snapshots and dependency order for playback. Keep the old generator available as a named fallback/comparison path; ordinary biological failures must not be substituted with successful generic bodies. New parts, stats, UI, audit and contact sheet must all use the same generator as incubation and habitats.

The new developer playback is separate from the live PC clock. Its play/pause/speed controls must never pause or speed up the laboratory or organisms.
