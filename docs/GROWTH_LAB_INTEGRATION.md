# Growth lab integration and desktop depth

Source: organism-growth-lab commit `88c062bebf1ae6e54b714d8fab461b22ff547824`. Desktop baseline: `3686da42161cb38583bf52f22ffc319c9e32ae5a`. Only desktop-laboratory-dev is updated. Main, anatomy-dev and the standalone growth branch remain separate.

## Imported system

The live default path is genome -> anatomy.blocks -> imported reconstruction -> imported anatomical development -> growth capabilities / lifecycle -> imported reconstruction renderer. Imported support geometry, organs, tissue paths, tissue envelope, cleavage and tissue-population modules are used by game rendering, incubation and developer previews. Source physiological metrics supply the live physical stat display. The old environmental exchange, habitat, cognition and reproduction APIs are compatibility bridges around this subsystem.

Exact upstream files, including its separate main.lua/conf.lua and validation scripts, are retained under vendor/organism-growth-lab for review. Those entry points do not run inside the desktop game. Runtime adapters add lifecycle wrappers to physiology.lua, anatomy-controlled locomotion to motion.lua, persistent embryology state to anatomical_development.lua, posed component aliases to anatomical_rendering.lua, and current motion state to the reconstruction renderer. The source branch's other diagnostic actions remain available: biting, scratching, eating, laying, dead, breathing and looking around. These are previews; no combat or attack AI was added.

## How movement works

Locomotion reads each actual appendage root, joint range/condition, muscle mass/force/leverage, motor-nerve reachability, skeletal support, body mass and center of mass. Only feet close enough to the support plane contribute to land contact; the support footprint determines static balance. Stride depends on actual limb length and mobility. There is no positive minimum speed. Disconnected nerves, failed muscles, immobile joints or an unsupported body can prevent movement.

Leg phases follow the generated contact arrangement, with stance and swing intervals and a load-dependent duty cycle. Inverse kinematics targets the actual foot contact points, refines against the renderer's hierarchical transforms, and clamps every joint to its limits. Unreachable targets are recorded as contact error/slip, never resolved by stretching a joint. Limbless bodies require a flexible supported axial chain and working muscles/nerves; their joints produce undulation. Swimming requires generated propulsive anatomy. Actual accepted habitat displacement advances the gait phase; resting or blocked organisms do not walk in place. Energy and oxygen limit movement, and the imported physiological activity model consumes fuel/oxygen and accumulates recoverable fatigue.

This is constrained kinematic locomotion with a static support/balance estimate, not a force-integrated rigid-body solver. It does not yet solve falling, substrate friction, dynamic tipping, or enforce zero slip at unreachable foot targets. Flight/environment exchange retain compatibility approximations; this pass does not certify flight biomechanics. The original validation reports 692 warnings about muscles not crossing a direct joint across its 105 specimens; those are retained as mechanical audit warnings, not hidden or declared fixed.

## Development and persistence

Early embryos expose deterministic individual cleavage cells and later tissue populations as saved biological state, visible through both projections. Later regional growth still follows the upstream adult-target activation schedule; this is not complete cellular morphogenesis. The original desktop release threshold could reject otherwise viable embryos before digestion/coordination matured. They now remain supported in incubation until validation succeeds, or fail when fully developed. Biological failures are never silently rerolled.

The current generator is the default for all new development. Existing saved organisms keep their physical tissue graphs, identity, genome, memories and world location while using the updated compatible runtime. Explicit legacy/procedural generation and older save readers are retained. Saves are not deleted or reset. Use Settings > Start a new experiment only if you want an empty laboratory.

## Depth and controls

Every object menu has Bring to front, Raise one layer, Lower one layer and Send to back. An attached vial changes depth with its workstation group; within that group, both vials are above the machine. Detach before independently positioning a docked vial. Native HWND ordering is reapplied after show, resize or order changes and preserved between changes, without activating the equipment. Dropper target selection and overlapping workstation docking use the same front-to-back order. The laboratory's ordinary/always-on-top setting remains separate from relative equipment depth.

For an isolated screenshot, press Win+Shift+S and drag a rectangle around the equipment.

## Developer checks

Run from a source folder with LÖVE 11.5:

- `love . --growth-integration-test`: 1,000 unfiltered genomes, movement failures, live displacement/exhaustion, development release, layers/actions, diagnostic controls, depth and transfer targeting.
- `love . --growth-source-test`: original smoke and anatomical integrity checks, 105 seeds x 5 stages plus deterministic growth/cleavage checks.
- `love . --reconstruction-test`: anatomy regression and unfiltered 100/1,000-genome audits.
- `love . --workshop-test`: physical containers, DNA, gametes, stock, freezing, labels and docking.
- `love . --desktop-native-test`: desktop UI/model plus real Windows tray/HWND drag, docking, depth, show/hide/resize and transfer checks. Requires an interactive Windows desktop.

Seed 22250963 is a viable moving fixture. Seed 20680028 demonstrates the limbless controller but fails nutrient viability; the 1,000-genome report also includes 12 viable undulating organisms. The complete audit retains failures and every denominator.
