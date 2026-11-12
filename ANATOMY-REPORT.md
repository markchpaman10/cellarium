# Anatomy development delivery

Stable main: 631da87d49f0ade2804460290edc8e25aeca75cb. Experimental branch: anatomy-dev. Main is not changed by this anatomy commit.

Completed: parameterized anatomical parts, canonical genomic development, supported joints, muscles, connected nerves, cavity organs, regional defense, anatomy-derived physiology, side/top projections, recorded construction playback, development-only inspection screen, Forge/archive/incubation/habitat integration, compatibility and separate save identity. No species templates. The old generator remains callable.

Executed: 19 anatomy test groups passed; 64 desktop regression groups passed (53 headless plus 11 native). Native tests ran in an interactive Windows process, including an actual second-monitor Petri move, counted sample transfer and hide/restore. The anatomy screen's draw, controls and export serialization were tested through actual Lua callbacks; physical mouse usability of that new screen is not manually certified. An exported diagnostic was tested in the workspace rather than the sandbox-restricted AppData directory.

Unfiltered 100 genomes: 59 viable, 41 biological failures, zero technical errors, 80 configurations. Unfiltered 1,000 genomes: 590 viable, 410 biological failures, zero technical errors, 381 configurations. Appendages: 118 limbless, 21 one, 180 two, 43 three, 245 four, 42 five, 223 six, 25 seven, 85 eight, 18 ten. Heads: 181 zero, 487 one, 228 two, 104 three. Contact sheet: first 20 genomes of the audit, no filtering.

Known historical regression: tests.lua line 26 asserts a particular old genotype must have supply below 0.22. It fails on unchanged main and on the explicitly preserved old generator. It is not included among passing tests; --historical-test preserves access. The new default --test runs the anatomy suite. Full details, reproducible seeds, actual result files, architecture, mapping and limitations are in docs.

Experimental limits: 59% random-genome viability, exploratory metabolic coefficients, no collision-based gait solver or tissue deformation physics, larger saves due to recorded construction, and some bilateral structures overlap in side projection. Ordinary developmental failures are retained, never replaced with a fallback organism.

Launch: extract the complete Windows ZIP and open Cellarium-Anatomy-Dev.exe with DLLs beside it. Exit older Cellarium builds from the tray first. Open Settings > Anatomy Generator / developer tool. The live simulation follows PC elapsed time; replay controls affect only recorded construction. Main and anatomy save identities are separate.
