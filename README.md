# CELLARIUM: Organism Growth Lab

**Independent organism-generation and development test project.** Extracted from `markchpaman10/cellarium`, source branch `desktop-laboratory-dev` at commit `d9c2839242740cfd085011c8034ec274bd183a16`. The main game is **not modified**.

## Running on Windows

Install **LÖVE 11.5** (https://love2d.org/). Download this branch as a ZIP, extract, then drag this project folder onto `love.exe` or run `love .` from this folder. No desktop laboratory, Python server, or extra game files needed.

## Controls

- **Random organism**: make a new seeded genome and anatomical plan
- **Same seed**: regenerate exactly the same organism
- **Seed**: click and enter a specific numeric seed, press Enter
- **Play growth / Pause**: run a slow developmental playback
- **Step back / forward**, **Start: cell**, **Adult**, or drag the timeline
- **External / Skeleton / Muscle / Fat / Organs / Nervous**: isolate anatomy layers
- Click a region in the side/top view to inspect its ID/type/growth
- Keyboard: Space play/pause; N new; R regenerate; S seed; left/right step; Home/End start/adult; 1-6 layers

## What this extraction actually contains

The original canonical genome model (24 chromosome pairs, 72 loci), genetic body-plan generator, region/component graph, developmental progression model, and anatomical renderer. Source code is copied unchanged into this branch except for the new standalone entrypoint and tests. This makes it possible to compare future experiments against the original without touching the game.

## Known flaws to rebuild deliberately

**This is a baseline, not the completed biological rewrite.**

1. The current anatomy generator plans the adult body first. Its development system then grows parts according to activation schedules. It is **not yet a true cell-division / tissue-differentiation / morphogenesis simulation**.
2. Growth must begin with a genuine cell state, then construct a persistent axial scaffold. Heads, jaws, limbs, joints, and digits must form visibly through buds and differentiation, not scale up from adult sprites.
3. The existing renderer still leans on round/elliptical geometry. Skeletons need anatomical bone-specific geometry (vertebrae, rib arcs, girdles, skull vaults, jaws, long bones with shafts and epiphyses, joint surfaces) and proper connectivity.
4. Organs, nerves, muscle, fat and skin must follow the growing skeleton and remain inside anatomically appropriate volumes.
5. Show every intermediate state with the timeline, side/top views, and anatomy layers. Preserve seeded reproducibility.
6. We will rebuild and validate one developmental stage and anatomical subsystem at a time. **Do not introduce the laboratory UI here.**

## Source separation

This branch holds only the self-contained organism subsystem and its immediate dependencies. To integrate a successful version back into Cellarium later, port only the corrected biological modules; do not merge this standalone `main.lua` over the real game's UI.

## Validation

Run `lua smoke.lua` if Lua is installed. It generates seeded specimens, advances the organism from 0 to 100%, checks for non-finite dimensions and disconnected parent indices, and verifies deterministic regeneration.

**Note:** the full graphical LÖVE application has not yet been run in this environment.
