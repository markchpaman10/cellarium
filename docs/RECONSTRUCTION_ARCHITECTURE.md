# Anatomical reconstruction and continuous development

This request targets `desktop-laboratory-dev`. It incorporates the anatomy-dev foundation at 7f4230a without changing main or that preserved anatomy branch. The pre-change comparison is in [RECONSTRUCTION_AUDIT.md](RECONSTRUCTION_AUDIT.md). The original instruction document is retained as RECONSTRUCTION_SPEC.md.

## Canonical system, richer framework

The genome remains 24 chromosome pairs, 72 loci and 144 alleles, with the existing expression, regulatory dosage, inheritance, mutation, Forge and archives. `reconstruction.lua` reuses the existing genetic regional plan, then builds its actual structural and tissue graph. It does not define complete animal templates.

New bodies extend the canonical region/component representation with `anatomicalVersion=2`. The same component IDs, positions, masses, conditions and network edges serve growth, physiology, research, rendering and saves. Regions retain persistent identity from latent precursor through bud, differentiation, embryo release, juvenile growth and maturity.

The structural foundation now includes connected vertebral or equivalent segments, cervical segments, protective rib arches, shoulder/pelvic girdles, paired long supports, cranial vaults, orbital rims, jaws, tooth attachment sites, distal bases, individual phalanges and supported keratin claws. Manipulation and load-bearing appendages share the same machinery. Each support has a parent, children, actual path length, width, thickness, density, volume, mass, joint references, muscle attachments, integrity and growth state. Hydrostatic support and segmented exoskeletons remain possible.

Organs are placed in oriented protected cavities with three-dimensional containment and intersection checks. Existing circulation, digestion, exchange and cognition types remain in use. Kidney and gonad components add waste-handling and reproductive tissue. Generic pump/ganglion roles do not require mammalian anatomy. Muscle bundles form flexor/extensor pairs with distinct origins and insertions, tendons and physical tissue volumes. Nerves branch through parent regions to sensory, skeletal, muscular and internal-organ targets. Vascular, gill, membrane, fin and tissue-condition visualization is retained.

## Genetic control and tradeoffs

Existing L11–18 and developmental D1–11 control size, axial proportions/curvature, support, appendage initiation, placement, segments and articulation. D13–14/D23 and L4/L22 control neck/cranium and nervous development; E22 modifies snout/jaw proportions. L3/D8/D10 control distal specialization, digit number and phalanges; E14/E15/E21 control terminal keratin. L15 controls support density; L16 controls muscle volume and density; L17 controls fat distribution/storage; L18 and ecological covering loci control dorsal/ventral skin. D19 controls body-axis orientation. D21 differentiates manipulation from support appendages. L6 controls developmental duration through existing expression. No hidden random species selector is used.

Capabilities derive from the current graph: actual muscle mass/quality/leverage, joint range and condition, neural connectivity, descendant load on neck/limb supports, organ capacity, fat reserves and tissue integrity. Longer segments and larger heads increase supported loads; dense supports add mass; reserve storage and new tissue consume energy. Protection is queried per region and surface. Dorsal armor does not shield a different region's ventral tissue. Nonphysical inherited traits retain their prior meanings.

For version 2, capacity checks compare current tissue demand rather than an adult-sized absolute digestion threshold. Existing version-1 bodies retain their original capability implementation in anatomical_physiology_v1.lua. Combat is not added.

## Persistent actual growth

`anatomical_development.lua` stores immutable genetic targets and a continuous growth model alongside mutable current regions/components. These targets describe potential, not current physical anatomy. Each structure has an activation time, current and target dimensions, growth progress, tissue maturity and functional maturity. A root precursor starts at cell size. Other structures begin with zero physical volume and emerge as small buds. Regional elongation, width growth, tissue recruitment, mineral density and function have overlapping schedules rather than one shared whole-body scale.

An elapsed biological minute remains one real PC minute. Nutrition, oxygen and temperature constrain developmental advancement. Genetics sets total developmental duration, and incubation releases a growing organism at the embryonic boundary; juvenile physiology continues changing its actual anatomy. The mutation of existing tables preserves IDs and attachments. Skin, muscles, nerves and organs follow the changing framework. No frame-count growth is used.

Fat has genetic capacity plus current reserve fraction. Physiology updates actual canonical adipose volume/mass, pays energy for stored reserve and new growth, and returns energy when reserve is used. This affects body mass, metabolic demand, protection and the visible envelope. It no longer relies on an unrelated display-only fat value.

The developer viewer records 121 biological trajectory samples, including actual dimensions and mass, using this same state evaluator. Playback evaluates the continuous biological trajectory between sample times; Step visits those recorded samples. It does not interpolate a completed adult sprite. The statistics and inspector read the current developing graph. The exported multi-stage sequence includes full recorded biological states in RECONSTRUCTION_GROWTH_RECORDS.lua.

## Continuous tissue envelope and layers

`tissue_surface.lua` computes a smooth implicit union of tapered cross sections and attachment bridges from the current region/tissue volumes. Its shader receives floating-point anatomical span data through a texture, avoiding the hardware uniform-register limit found during testing. Actual muscle/fat allocation changes radii; skin armor affects local surface appearance. It draws one continuous outer field instead of a collection of oval sprites.

`reconstruction_rendering.lua` uses the same graph for structural paths, muscle attachments, adipose bands, cavity organs, nerve branches, vessels, gills and external structures. Limited joint poses propagate to descendants and skeletal paths. Side and top projection share anatomy. Very early precursors are physically small; the viewer keeps a stable adult-sized framing so growth is visible in proportion. The contact sheet is the first 20 audit genomes, including failures.

## Save compatibility

This experimental executable uses `cellarium-desktop-reconstruction-dev`, separate from main and anatomy-dev. Desktop exit-save/launch-restore behavior remains unchanged. Import older experiment files explicitly. Old legacy, procedural and anatomical-version-1 organisms keep their bodies and original capability calculation. Version-2 growth models and current anatomy save together and resume at their recorded progress. Older unfinished embryos without an allocated body adopt version 2 at the equivalent existing progress; already allocated older embryos keep their existing anatomy.

## Actual verification and limits

The current executed reconstruction suite passes 30 groups, including deterministic generation, structural/tissue coverage, oriented organ placement, neural/muscle connections, physical stats, inheritance, conservation, bounded growth changes, persistent table identity, elapsed-time partition independence, saved-growth continuation, old records, incubation/juveniles, recorded playback, layer rendering and developer callbacks. All 53 headless desktop regression groups pass. The self-contained executable is also tested with this suite.

Native equipment tests could not be launched for this revision: the Computer Use tool returned **Computer Use app approval timed out** and no native result file was created. Prior revisions' native successes are not counted as this revision's passes. Physical dragging, multi-monitor behavior, tray persistence and mouse operation of the new screen remain unverified for this executable. The headless native-model and actual drawing/callback paths did execute.

The historical tests.lua line-26 failure documented in the prior delivery remains a known prior-generator test failure; it is not reported as passing. Use --reconstruction-test (or --test / --anatomy-test) for the new suite, --desktop-test for desktop regressions, and --historical-test for the retained old monolithic suite.

This is a scheduled synthetic tissue-development model, not a cellular embryology solver, finite-element tissue simulator or collision-based gait solver. Genetic schedule coefficients and organ allocation still need balancing. In the final 1,000-genome audit, 431 were viable and 569 failed biology, with no technical generation errors. The prior version had 590 viable; the decrease is explicitly retained. Exact signature counts include skeletal counts and orientation bins and must not be interpreted as that many visually unrelated body plans. The appendage/head distributions remain inherited from the existing regional planner. Further work on regional regulatory expression can broaden that planner without discarding the connected framework or growth system.

Full growth-state records are available as RECONSTRUCTION_GROWTH_RECORDS.zip in the GitHub docs directory, and unpacked as RECONSTRUCTION_GROWTH_RECORDS.lua in the Windows/source packages.
