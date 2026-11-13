# Desktop depth and growth-lab delivery

Desktop baseline 3686da42161cb38583bf52f22ffc319c9e32ae5a; imported organism-growth-lab 88c062bebf1ae6e54b714d8fab461b22ff547824. Updated target: desktop-laboratory-dev. The previous Windows workshop archive is retained.

Implemented: relative depth controls for all native items; workstation/docked-container depth groups; native ordering repair after resize/show; frontmost dropper and workshop targets; imported genetic reconstruction, staged growth, early embryo state, tissue/support/organ shapes, physical metrics and diagnostic animations; anatomy-derived legged/limbless locomotion; actual-distance gait phase; energy/oxygen/fatigue costs; functional-juvenile release gate; side/top and named-action preview controls.

## Executed checks

- 28 physical workshop groups passed.
- 53 headless desktop regression groups passed; interactive native run additionally exercises actual second-monitor movement, Windows event dragging, physical docking, transfer, hide/restore and real overlapping HWND depth.
- 30 anatomical reconstruction regression groups passed, including inheritance, current tissue identity, mass budgets, growth partitioning, save resumption and 1,000-genome diversity.
- Upstream smoke and integrity checks passed: 105 specimens across five stages, deterministic growth and early cleavage. The mechanical audit reports 692 attachment warnings; these are not hard integrity failures.
- Growth integration checks and native results are included as separate text files. The final runs passed 13 growth integration groups and 66 desktop/native groups (67 result lines including the physical second-monitor note). Together with workshop and anatomy suites, 137 groups passed.

## Actual generation results

1,000 genomes; seeds (20261112 + i*104729) mod 2147483647, i=1..1000. No rerolls or viability filtering. Conditions: full nutrition/oxygen, 98.6 F.

- Viable: 79; biological failures: 921; technical generation errors: 0.
- All generated bodies: 637 immobile, 248 legged, 115 undulating.
- Viable bodies only: 49 immobile, 18 legged, 12 undulating.
- Appendages: 0=118, 1=21, 2=180, 3=43, 4=245, 5=42, 6=223, 7=25, 8=85, 10=18.
- Symmetry: bilateral 751, asymmetric 186, radial 63. Support: endoskeleton 624, hydrostatic 239, exoskeleton 137.
- Major biological failure categories are insufficient nutrient acquisition, overlapping cavity contents, insufficient transport/exchange and structural support. Failure reasons may overlap within a specimen.

## Practical limits

The low viability rate is measured and retained. This import does not complete cellular morphogenesis: later structures still follow the source branch's adult-target schedules. Movement uses constrained kinematics and a static support estimate, with recorded slip for unreachable foot targets; falling, contact forces, dynamic balance and friction are not fully simulated. Flight retains compatibility approximations. Existing saved body graphs are preserved rather than regenerated without permission. No claim is made that every generated organism is healthy, mobile or bug-free.

See docs/GROWTH_LAB_INTEGRATION.md for source provenance, workflow and architecture. Older anatomy/workshop reports are historical and do not supersede this one.
