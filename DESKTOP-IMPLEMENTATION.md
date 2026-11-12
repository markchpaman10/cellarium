# Desktop laboratory implementation and verification

## Input repair and direct desktop controls — revision 3

Right-click now always opens the object's context menu, including the dropper and containers. The persisted dropper-tool flag is cleared and no longer intercepts other object clicks. Collection requires an explicit menu or desktop button action. Left-drag any visible object body; a five-pixel threshold distinguishes moving from clicking. Embedded buttons consume their own clicks without dragging. Native mouse events retain their event-time screen coordinates. A pointer poll runs only during a gesture begun on this application's equipment, allowing dragging to continue if SDL or a nonactivating window loses capture. No global input hook is installed. Reset Layout now respects its new positions instead of immediately restoring old preferred coordinates.

Forge, workstation and culture-container clicks expand working controls within the same native desktop HWND. They do not open a menu or a separate records application. The Forge exposes actual allele editing across all loci, dosage/regulation/splicing, undo/reset, two-source assembly, forecast, archiving, finite developmental-cell installation, incubation and export. The workstation exposes actual specimen/container selection, seeding, cultivation, extraction, blank-cell preparation, preservation and gamete precursors. Culture controls change their authoritative vessel record. Collapse restores the physical object footprint. The separate new records application remains optional through the tray.

Earlier native checks validated explicit window placement and down/up messages; they did not prove a complete mouse-movement drag. The revised regression run moves Petri dishes, ordinary/cryogenic vials, dropper, workstation and Forge via native down/move/up sequences and checks both model coordinates and actual Win32 window bounds. It also checks context-menu routing on every object after a stale saved dropper selection, and operates desktop workstation/Forge/culture buttons through native messages without opening the records window. 44 groups pass. Physical-mouse testing across all user configurations remains a manual check.

The descriptions below document the original desktop revision; where they describe rim-only dragging, immediate right-click aspiration or automatic opening of the detail application from a Forge/workstation, this revision supersedes them as described above.

## Result and scope

This is a separate Windows desktop development revision of the engineering/Gippity merge. It implements native equipment windows, a real tray, shared biological records, counted pipette transfers, independent visibility groups, multiple habitat contexts and a new detailed records application. The classic five-workspace interface is optional in Settings. It is not the launch or equipment-opening interface.

The implementation was audited before changes; see `docs/DESKTOP_AUDIT.md`. Previous versions and their save identities remain separate. The new prompt explicitly supersedes the earlier no-autosave preference for this edition's exit persistence and launch restoration.

## Architecture and native dependencies

One LÖVE 11.5 / LuaJIT process owns the biological state, detail window and desktop host. There is no independent database, web server, cloud service, injected application hook, startup task or companion process. LÖVE's existing SDL2 and LuaJIT FFI are reused. Windows provides user32, gdi32, shell32, kernel32 and optional shcore DPI queries. These are system DLLs, not additional downloads. The x64 LÖVE runtime and its licenses are packaged.

Each equipment item has its own `WS_EX_LAYERED | WS_EX_TOOLWINDOW | WS_EX_NOACTIVATE` Win32 popup window. A separate invisible control HWND owns the Shell_NotifyIcon tray icon and recovery hotkey. The normal SDL/LÖVE window opens only for details. Native window procedures enqueue events; the main thread applies actions to persistent records. No full-screen transparent input window exists.

Original procedural LÖVE artwork is rendered into per-object transparent RGBA canvases, converted to premultiplied BGRA and presented using UpdateLayeredWindow. Zero-alpha areas use Windows layered-window hit testing and pass through. Visible rims/frames and interiors have different actions. Objects do not become permanently topmost unless that setting is enabled. Hiding windows removes their input surfaces. The classic renderer remains available after an explicit Settings choice.

References: [Microsoft layered windows](https://learn.microsoft.com/en-us/windows/win32/winmsg/window-features), [UpdateLayeredWindow](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-updatelayeredwindow), and the supplied [Fisherbrand culture tube page](https://www.fishersci.com/shop/products/fisherbrand-nonsterile-plastic-culture-tubes-22/1496113). The NEST page returned 403. The supplied Petri requirements were used directly. The terrarium is a provisional enclosed specimen habitat; no specific product details were invented from the advertising redirect. No retailer photographs are included.

## Shared object management and monitors

`desktop_model.lua` owns persistent IDs, type, entity ID, signed screen position, logical dimensions, scale, visibility group, lock, layer, storage state and configuration. Handles/canvases are transient host resources. Dragging changes layout only. Petri rims and habitat frames drag; interiors inspect. The entire dropper body is a left-button drag handle. Right-click aspirates at its tip. Releasing a loaded tip over a valid target starts dispensing.

Native desktop positions use signed physical virtual-desktop coordinates. Dimensions are logical pixels multiplied by object scale and monitor DPI. Monitors are enumerated by Win32 device name, work area and DPI. Preferred placement stores the monitor and offsets in logical pixels. Disconnection clamps an object to an available work area without replacing its preferred placement; reconnection can restore it. Display notifications and a three-second inventory check reconcile changes. Layout save/restore preserves identities, layers, dimensions, locks and storage flags. Ordinary drag across displays is supported; wheel/context actions resize within bounds.

## Real samples, vessels and cultivation

The original `s.vessels` records remain authoritative. Their buckets contain canonical cells/genomes and counted populations. A dropper sample holds source container ID, kind, cell/genome identity, quantity, representative volume in fluid ounces, viability, contamination, temperature and medium. Collect decrements the source immediately. Dispense validates destination access, capacity, cell category, genome identity and growth conditions before mutation. Contact after the visible droplet animation commits the transfer. If interrupted by exit, the saved pipette still contains its counted sample; no second copy is created.

An unclean pipette retains residue; changing genomes can raise contamination. Sterilization clears residue only when no sample is loaded. Closed, frozen, empty, full and incompatible cases return feedback and preserve rejected samples. DNA archives are sequence records, not living cell suspensions; they go to the Forge rather than being silently treated as cells. Installing DNA consumes a finite blank developmental cell.

Vessel growth now reads temperature, nutrients, contamination, health and remaining replication capacity, and records culture age/waste. Containers continue updating while hidden. Frozen containers suspend growth. The former unrestricted multi-cell transfer from a single loose cell was removed. Legacy batch cultivation continues through the original K.update / B.harvest path and can be harvested in the new Cultures interface.

## Forge and new detailed UI

`desktop_app.lua` is the default offline records application, with independent navigation, layout and controls. It does not call the old research or Forge draw functions. It provides Cultures, Genome Forge, multi-source Assembly, Incubation, Habitats, Records, Research observations/history, Cryobank, behavioral/social records, magnification and Settings.

The Forge reads and writes canonical 24-pair / 72-locus genomes. All alleles remain editable in copies. It supports source selection, splicing, bounded dosage, deletion/restoration, a deterministic D12 regulatory link cycle, comparison, named archives, export, forecast, exact incubation and blank-cell installation. Undo now restores provenance as well as allele values. Dosage and regulatory metadata affect primary, developmental and ecological expression and survive the implemented inheritance paths. This is a simplified locus-level dosage model, not an arbitrary chromosome structural-variant editor. Two-parent dosage is a rounded parental mean; synthetic recombination uses a rounded donor mean. Conflicting regulatory targets deterministically retain the first source. These rules are explicit and testable.

The workstation opens the new Cultures application: collection, vessels, transfers, cell preparation, finite blank-cell restock, tissue specialization, extraction, preservation, sales and gamete precursors. Existing 2–12 donor fusion, fertility restrictions and embryonic viability remain. The optional Classic interface keeps the original specialized views and controls available. No classic screen appears automatically.

## Habitats, behavior and desktop organisms

`desktop_worlds.lua` partitions the same global organism/embryo records by world ID. It does not clone their biology. Each habitat has its own environment, food, RNG, clock accumulator and capacity; central IDs and lineage remain shared. Cultures/gametes advance once, not once per habitat. The terrestrial context retains the mixed mesocosm; separate freshwater and saltwater tanks have water volume, salinity, oxygen, waste and quality. These feed actual respiration, osmotic stress and survival. Temperature and humidity affect physiological stress/hydration. Feeding, drinking, rest, mate seeking, nature and anatomy-supported movement remain active.

Actual grown silhouettes render from above, oriented by heading. The organism is not replaced with a cosmetic marker. Release/recall moves the same ID, genome, anatomy, physiology, memories and relationships. The dry desktop is a bounded simulation context; dependent organisms can become stressed and die. Released movement is a projection of normalized biological coordinates onto the work area; it does not navigate around desktop icons or unrelated application windows.

The previous engineering cognition and dynamic-stat modules were restored and connected to physiology: neural-capacity-limited memory, perceived outcomes, social recognition/relationships, nonverbal signals, real STR/DEF/DEX/INT/VIT/END and cardiac transport where hearts exist. No combat, speech service or language model was introduced.

## Tray, persistence and shutdown

The native tray controls laboratory, habitats and desktop organisms independently; opens Research/Cryobank, genomes, organisms and Settings; saves/restores/resets layout; restores stored objects; and exits. Reset/disposal use confirmation dialogs. Classic UI is toggled only in Settings. Ctrl+Shift+L is a registered recovery hotkey, not a system-wide input hook. Ctrl+Q exits with the detail window focused. Closing the detail window hides it. A second desktop host is refused to avoid conflicting saves.

The new identity is `cellarium-desktop-laboratory-dev`. Desktop envelope schema 1 wraps the existing simulation schema, migrates old supported experiments, retains canonical genomes, stores editor drafts and new-UI draft name/source, and rebinds organism anatomy and the primary world. Save payloads are validated, staged and backed up; MoveFileEx with replace/write-through commits them. A corrupted primary save can recover its backup. Failed loads preserve the original and block automatic overwrite until an explicit new/imported session.

Exit saves once and releases equipment HWNDs, DIBs/DCs, tray icon, control window and recovery hotkey. A runtime error removes native surfaces and opens a diagnostic error window without replacing the previous save. Hidden/minimized objects keep simulating independently of rendering. Offline catch-up uses normal fixed biological steps, advances at 0.01 simulation hours per real second, and caps at five real minutes / three simulation hours. It can be disabled. Native artwork updates at 10 Hz; hidden equipment is not rendered. The background event loop sleeps instead of spinning at unrestricted frame rate.

## Files

New modules: desktop_model, desktop_samples, desktop_worlds, desktop_store, native_windows, desktop_art, desktop_host, desktop_app, desktop_panel (Classic compatibility inspector), desktop_tests and desktop_app_tests. Restored/adapted modules: cognition, living_stats and gene_expression.

Modified integration: main, conf, biology, physiology, vessels, genome, genome_editor, development_genes, environment_genes, rendering, habitat_view and research. Documentation/build: README, DESKTOP-IMPLEMENTATION, AGENTS, docs/DESKTOP_AUDIT, docs/DESKTOP_SPEC and build-desktop.ps1. The source distribution includes the original generator, fallback and audit tools.

## Verification performed

44 automated test groups passed in LÖVE 11.5, including eleven groups that create actual native Windows tray/windows in an interactive session. The three priority architecture checks passed:

1. A real Petri HWND was moved to the **second connected monitor** and its signed Win32 bounds were verified. Synthetic tests additionally cover negative coordinates, mixed DPI, changed resolution, disconnected-monitor fallback and restoration.
2. Counted cells passed from a real source vessel through a loaded pipette into the destination's persistent bucket. Source and target quantities, canonical genome and identities were checked. Native left-button/right-button events also exercised drag and aspiration. Empty/closed/frozen/full/incompatible cases and contamination were tested.
3. Native laboratory windows were hidden/restored while habitat windows stayed visible. The same HWNDs, object IDs, positions, locks, scale and contents remained. Hidden biological progression and an atomic disk save / decode round trip passed.

Native hit testing verified that a Petri's transparent corner is not its input window, while its visible culture center is. Cleanup verified tray and object-handle removal. New-interface callback tests exercised culture seeding, preview, archiving, finite cell installation and exact embryogenesis into a living organism. All new detail pages were rendered to canvases and inspected for runtime failures. The old Undo provenance discrepancy was reproduced and fixed. A normal packaged launch exposed and fixed a previously missing font-size initialization.

The native test must run at ordinary interactive Windows integrity. Shell_NotifyIcon returned E_FAIL from the restricted shell process; the same native tests passed when the fused runner was launched in the interactive session using the computer-use skill. A temporary fused-test report path also failed by treating an executable as a directory; it now writes beside the executable. These failed intermediate runs were not counted as passes.

Rendered equipment and the new Forge application preview were visually inspected. Windows Computer Use screenshot capture of the live OpenGL window timed out, so no manual visual desktop acceptance is claimed on that basis. The full 28-step human interaction workflow has **not** been certified. The 1,000-body generator audit was not rerun for this UI revision; the original audit tools, data, approved certificate and fallback remain. The representative audited genotype was used for deterministic development tests.

## Remaining manual checks and limits

- Drag with a physical mouse between differently scaled displays; physically disconnect/reconnect a monitor and change its resolution. Their coordinate logic has automated coverage, but those OS changes were not performed.
- Click desktop icons/taskbar/ordinary applications around equipment; exercise the tray popup commands with a mouse; verify Windows display/taskbar configuration variations.
- Perform the prompt's entire 28-step workflow through normal user input, including restart after personal experiments. Automated callbacks, native messages and disk round trips are not a claim that this manual workflow was completed.
- Monitor association uses Win32 device names and relative positions, not EDID hardware identifiers. If Windows renumbers display devices after hardware changes, Reset Layout may be needed.
- Desktop roaming does not include icon/application collision avoidance. This is the same organism simulation on a bounded desktop projection.
- Terrestrial product styling is provisional because the advertising redirect was not a usable direct reference. Artwork remains original programmer art, not product photographs.
- The classic-only historical cell favorites/filter UI remains available through Settings. The default new Records UI instead offers source filters, search and ID/name sorting. No old UI is shown unless explicitly enabled.

## Exact launch/build instructions

Exit an older running desktop build using **Exit Cellarium** in its tray menu. Extract the entire new Windows archive and double-click `Cellarium-Desktop-Laboratory.exe`. Equipment and a tray icon appear; no conventional game UI opens. Click equipment interiors or use tray Settings/records for the new detail app. Use Settings only if you explicitly want Classic. Keep the DLLs beside the executable.

For source: `love path/to/source` uses the installed LÖVE 11.5 runtime. Build with `build-desktop.ps1 -Runtime 'C:\Program Files\LOVE' -Destination 'C:\chosen\build-folder'`. Run `lovec path/to/source --desktop-test` for platform-independent tests or `--desktop-native-test` in an interactive Windows session for native acceptance groups. The packaged `.love` can be opened with LÖVE 11.5 on Windows; native desktop mode is Windows-specific.

This is a tested desktop development build, not a declaration that all manual Windows compatibility scenarios have passed.
