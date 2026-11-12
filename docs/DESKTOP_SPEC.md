# CODEX IMPLEMENTATION PROMPT
# CELLARIUM: COMPLETE WINDOWS DESKTOP LABORATORY & USER INTERFACE OVERHAUL

## IMPLEMENTATION DIRECTIVE

Implement a complete redesign of Cellarium's desktop interface.

This is a functional architecture and user-interface overhaul, not a mockup, prototype, or visual-only redesign.

The goal is to transform Cellarium from a conventional LÖVE2D game running inside a window into a persistent, interactive laboratory that operates directly on the Windows desktop.

The player must be able to position laboratory equipment, Petri dishes, DNA vials, cell cultures, habitats, and aquariums anywhere on their desktop, including across multiple monitors.

Laboratory objects must remain interactive while allowing normal Windows desktop interaction outside their visible boundaries.

The laboratory must be controllable from the Windows system tray.

Existing genetic engineering, organism development, physiology, cultivation, cryobank, research, and simulation functionality must remain operational.

Do not discard working systems or replace them with nonfunctional interface elements.

**IMPORTANT: Before modifying anything, audit the existing codebase thoroughly. This prompt describes desired behavior, not assumptions about the current source structure. Adapt the implementation to the actual project.**

---

# 1. DESIGN PHILOSOPHY

Cellarium is not intended to resemble a conventional game.

The player's Windows desktop becomes their laboratory workspace.

Physical laboratory objects appear directly on the desktop and can be manipulated individually.

Examples:

- Petri dishes can be dragged across the screen.
- DNA vials can be selected and moved.
- Droppers can collect and dispense biological samples.
- Cell workstations can be opened and used.
- The Forge provides genome engineering.
- Terrariums display living terrestrial organisms.
- Aquariums display freshwater and saltwater organisms.
- Research and cryobank information appears in a browser-style application window.

The player should be able to minimize ordinary applications, move laboratory objects around their desktop, and continue using Windows normally.

Do not implement the laboratory as a single conventional fullscreen game window.

Do not require the player to keep a large application window open to interact with their equipment.

Do not place all laboratory functionality inside a static background illustration.

The equipment itself must be interactive.

# 2. VISUAL REFERENCE MATERIAL

Use the following supplied references to understand the intended appearance, proportions, and function of the laboratory objects.

These links are visual references, not requirements to purchase or integrate products.

## PETRI DISH REFERENCE

NEST Scientific, 100 × 15 mm semi-stackable polystyrene Petri dish:

https://www.nestscientificusa.com/petri-dish-100-x-15-mm-semi-stackable-polystyrene-sterile-20-pk-500-cs.html

Reference requirements:

- Shallow circular laboratory dish.
- Transparent or translucent plastic.
- Raised rim.
- Visible interior.
- Optional removable lid.
- Suitable for displaying culture medium and growing cells.
- Recognizable as a Petri dish rather than a generic circular UI button.

## VIAL / CULTURE TUBE REFERENCE

Fisherbrand plastic culture tubes:

https://www.fishersci.com/shop/products/fisherbrand-nonsterile-plastic-culture-tubes-22/1496113

Reference requirements:

- Narrow cylindrical laboratory tubes.
- Transparent material.
- Visible contents.
- Appropriate caps or closures.
- Suitable for DNA samples, biological suspensions, and laboratory reagents.
- Can be stored in racks.

Use distinct visual treatments for DNA vials, cell suspensions, and reagent containers where useful.

## TERRESTRIAL HABITAT REFERENCE

User-supplied Google Shopping advertising reference:

[Advertising tracking redirect omitted from the development copy; use a provisional enclosed terrarium.]

This is an advertising redirect and may not resolve reliably.

If unavailable, do not invent details about the specific product.

Use a clear, enclosed terrestrial specimen habitat or terrarium as the provisional visual reference.

The habitat should appear as a real container sitting on the desktop, with the organism's simulated environment visible from above.

## AQUARIUM REFERENCE

Use realistic small desktop glass aquariums as the visual direction.

Provide distinct freshwater and saltwater configurations.

Do not use an arbitrary blue rectangle to represent an aquarium.

## ASSET RULES

Do not hotlink retailer product photographs into the game.

Create or use properly licensed local artwork inspired by the physical appearance of the equipment.

Respect the project's existing visual style unless a replacement is necessary.

Use transparent backgrounds and suitable scaling.

The result must look like recognizable laboratory equipment rather than standard game HUD widgets.

# 3. WINDOWS DESKTOP INTEGRATION

Target Windows desktop functionality first.

Preserve the existing LÖVE2D simulation where practical.

Implement a Windows-specific integration layer if necessary.

Possible technical approaches include:

- Native Windows API integration.
- A small companion executable.
- A native window-management wrapper around LÖVE2D.
- Another suitable Windows-native solution justified by the codebase.

Choose the architecture based on reliability, not convenience.

The application must support:

1. Transparent desktop objects.
2. Multiple independently positioned objects.
3. Mouse interaction only within intended interactive regions.
4. Normal interaction with underlying Windows applications.
5. Multi-monitor positioning.
6. System-tray integration.
7. Persistent object state.
8. Proper application shutdown and restoration.

A conventional fullscreen transparent window that captures all mouse input is unacceptable.

Use shaped input regions, per-object windows, or reliable hit-testing with mouse pass-through.

The user must still be able to click desktop icons, taskbar buttons, application windows, and empty desktop areas normally.

## TRANSPARENCY

Each laboratory object must have a transparent background.

Do not display opaque rectangular borders around circular Petri dishes or irregularly shaped equipment unless they are part of the actual object artwork.

Transparent visual pixels should not unnecessarily intercept mouse input.

## WINDOW LAYERING

Provide sensible layering rules.

Laboratory objects should be visible on the desktop without permanently obscuring important applications.

Support configurable always-on-top behavior where appropriate.

Do not force every laboratory object above every Windows application at all times.

Provide an option to temporarily suppress or hide overlays.

# 4. MULTI-MONITOR SUPPORT

The user's desktop may contain multiple monitors with different resolutions.

Support:

- Monitors positioned left, right, above, or below one another.
- Different monitor resolutions.
- Negative virtual desktop coordinates.
- Different display scaling settings.
- Objects moving between monitors.
- Saving object positions.
- Restoring positions on application restart.
- Display disconnection.
- Display reconnection.
- Resolution changes.

Each desktop object must have a persistent identity and position.

Store enough monitor information to restore the intended location.

If a previously used monitor is disconnected, temporarily move affected objects into a visible area on an available monitor.

Do not permanently overwrite the original preferred monitor placement solely because that monitor is temporarily unavailable.

Avoid restoring objects completely off-screen.

# 5. DESKTOP OBJECT MANAGEMENT

Implement a reusable desktop-object system.

All physical laboratory objects should use a common object-management interface.

Required properties:

- Unique persistent object ID.
- Object type.
- Position.
- Dimensions.
- Scale.
- Monitor association.
- Visibility.
- Layer order.
- Drag state.
- Interaction state.
- Associated simulation entity.
- Saved configuration.
- Optional lock state.

Supported actions:

- Select.
- Drag.
- Reposition.
- Open.
- Inspect.
- Hide.
- Restore.
- Lock position.
- Reset position.
- Resize where appropriate.
- Bring forward.
- Send backward.
- Return to laboratory storage.

Do not duplicate all window-management logic separately for each object type.

## DRAGGING

Users must be able to click and drag Petri dishes, vials, workstations, habitats, and aquariums.

Dragging should be smooth.

The object should remain attached to the cursor during movement.

Dragging must not interfere with the underlying biological simulation.

Provide a clear distinction between dragging an object and interacting with its contents.

For example:

- Drag a Petri dish by its rim.
- Interact with its contents by clicking inside the dish.
- Drag a habitat by its frame.
- Interact with organisms through the habitat interior.

Prevent accidental movement while performing delicate laboratory operations.

Support optional position locking.

# 6. PETRI DISHES

Petri dishes are persistent, movable cultivation containers.

Each dish represents a real culture within the simulation.

A dish must contain:

- Unique ID.
- Culture ID.
- Medium type.
- Cell population.
- Nutrient availability.
- Temperature.
- Contamination state.
- Culture age.
- Viability.
- Growth conditions.
- Optional lid state.
- Visual appearance.
- Desktop position.

The actual biological values must connect to the existing cultivation simulation.

Do not maintain a separate fake visual culture disconnected from the real data.

## PETRI DISH VISUALIZATION

Render the dish from a top-down perspective.

Show:

- Transparent circular rim.
- Culture medium.
- Visible colonies or cell clusters where appropriate.
- Changes in population or density.
- Changes in culture appearance.
- Contamination indicators where biologically relevant.

Avoid implying that individual microscopic cells are visible to the naked eye at ordinary scale.

At normal desktop scale, show macroscopic culture patterns or use a clearly identified magnified visualization.

Provide a microscope or magnification mode for detailed cell inspection.

## PETRI DISH INTERACTIONS

The user must be able to:

- Move the dish.
- Select it.
- Inspect its contents.
- Add medium.
- Add nutrients.
- Introduce cells.
- Remove samples.
- Transfer material.
- Label the dish.
- Open detailed culture information.
- Dispose of or archive a culture through appropriate actions.

Do not let visual dragging accidentally delete or replace culture contents.

# 7. DROPPERS AND PIPETTES

Implement an interactive dropper or pipette system.

The user must be able to manipulate a dropper directly on the desktop.

Required workflow:

1. Select an available dropper.
2. Select a vial, culture tube, or suitable source container.
3. Collect a valid quantity of material.
4. Move the loaded dropper over a Petri dish.
5. Dispense material into the dish.
6. Update both source and destination quantities.
7. Trigger the appropriate biological simulation response.

The dropper must carry an actual sample record.

Sample data should include:

- Source container ID.
- Sample type.
- Genetic identity where applicable.
- Cell identity where applicable.
- Volume or quantity.
- Viability where applicable.
- Contamination state.
- Relevant environmental conditions.

Do not allow a dropper to create unlimited cells or DNA from nothing.

Do not permit incompatible materials to transfer silently.

## DROP ANIMATION

Display a visible droplet when dispensing.

The droplet should travel from the dropper to the target dish.

On successful contact, the dish's actual contents must update.

Provide clear feedback if the transfer is invalid.

Examples:

- Empty dropper.
- Incompatible target.
- Insufficient sample.
- Closed container.
- No remaining capacity.
- Invalid culture conditions.

## CROSS-CONTAMINATION

Preserve or implement contamination rules where appropriate.

Reusing an unclean dropper may transfer unwanted material.

Provide cleaning, sterilization, or disposable pipette options as supported by existing game mechanics.

Do not make the process unnecessarily tedious, but maintain meaningful laboratory consequences.

# 8. DNA VIALS AND CULTURE TUBES

Implement movable vial objects and storage racks.

Vials can contain:

- DNA fragments.
- Engineered sequences.
- Prepared genetic material.
- Cell suspensions.
- Reagents.
- Other compatible laboratory samples.

Each vial must have a persistent contents record.

Display visible fill levels where appropriate.

Allow:

- Selecting a vial.
- Inspecting contents.
- Moving the vial.
- Placing it in a rack.
- Removing it from a rack.
- Transferring compatible contents.
- Labeling.
- Sending material to the Forge.
- Sending cells to a cultivation workstation.

Differentiate DNA samples from living cells in the data model.

A DNA vial is not automatically a living culture.

Use the existing genome and cell systems rather than creating unrelated inventory items.

# 9. CELL WORKSTATIONS

Cell workstations are physical laboratory objects placed on the desktop.

They belong to the laboratory visibility group.

They must provide access to existing cell-engineering and cultivation functionality.

Depending on available systems, workstations may support:

- Preparing blank developmental cells.
- Installing engineered genomes.
- Preparing cell suspensions.
- Cultivating engineered cells.
- Transferring cultures.
- Inspecting cell viability.
- Preparing embryo initiation.
- Handling laboratory reagents.

Clicking a workstation should open an appropriate detailed interface.

Do not force complex operations into tiny floating controls.

The workstation's visible desktop object is the entry point.

Its detailed interface may be a normal application panel or window.

Preserve all functional operations from the previous UI.

# 10. THE FORGE

The Forge is the genome-engineering workstation.

It must exist as a movable desktop object.

The Forge belongs to the laboratory visibility group.

Clicking or activating it opens the existing or revised genome editor.

Preserve support for:

- DNA vial selection.
- Genome assembly.
- Sequence splicing.
- Recombination.
- Mutation.
- Duplication.
- Deletion.
- Chromosome inspection.
- Gene regulation.
- Genome comparison.
- Genome archiving.
- Engineered genome export.
- Installing completed genomes into compatible cells.

Do not replace the Forge with a decorative machine that opens an empty panel.

The Forge must remain connected to the actual genome simulation.

## FORGE WORKFLOW

A valid workflow should be possible:

1. Acquire or prepare DNA vials.
2. Inspect genetic material.
3. Move or assign DNA samples to the Forge.
4. Open the genome editor.
5. Assemble or modify a genome.
6. Validate the genome.
7. Save the engineered genome.
8. Install it into a compatible developmental cell.
9. Initiate cultivation or embryonic development.

Preserve any existing restrictions and biological consequences.

# 11. LABORATORY VISIBILITY GROUP

Define a laboratory object group.

At minimum, it includes:

- Petri dishes.
- Droppers and pipettes.
- DNA vials.
- Vial racks.
- Cell workstations.
- The Forge.
- Associated laboratory equipment.

The player must be able to hide or show the entire laboratory from the system tray.

When hidden:

- All laboratory objects disappear.
- Their positions are saved.
- Their contents are preserved.
- Their simulation state remains valid.
- Their object identities remain unchanged.
- The underlying Windows desktop is unobstructed.

When restored:

- Every object returns to its previous location.
- The same cultures and samples remain present.
- Previously locked objects remain locked.
- Previously selected scaling is preserved.
- Monitor placement is restored.
- No duplicate objects are created.

Hiding the laboratory must not mean deleting it.

Do not automatically reset the layout.

Do not stop biological time simply because the user hides the equipment.

# 12. TERRESTRIAL LIVING HABITATS

Implement movable desktop habitat containers for land-based organisms.

The intended visual design is a transparent enclosed specimen habitat or terrarium.

The habitat is a physical desktop object.

Its interior must display a top-down simulation.

The container should visibly contain a living environment rather than acting as a static organism preview.

## HABITAT ENVIRONMENT

Support suitable environmental properties such as:

- Temperature.
- Humidity.
- Terrain.
- Substrate.
- Food availability.
- Water availability.
- Shelter.
- Environmental hazards.
- Habitat dimensions.
- Population capacity.
- Waste accumulation.
- Environmental quality.

Connect these values to the existing organism physiology and survival systems.

## ORGANISM BEHAVIOR

Organisms inside the habitat must:

- Move according to their anatomy.
- Perceive their environment according to their senses.
- Seek food or nutrients.
- Respond to threats.
- Rest when necessary.
- Interact with other organisms.
- Express genetically influenced nature.
- Learn from experience where cognitively capable.
- Maintain physiological needs.
- Age and develop.

Do not use generic wandering as the only behavior.

Do not allow organisms to perform movements unsupported by their anatomy.

## TOP-DOWN RENDERING

The habitat view must be top-down.

Use a coherent rendering representation that reflects each organism's generated body plan.

Avoid replacing all organisms with identical circular markers.

Preserve meaningful anatomical differences.

## HABITAT INTERACTION

The user must be able to:

- Move the habitat around the desktop.
- Resize it within sensible limits.
- Inspect its environment.
- Add or remove organisms.
- Add food and water.
- Change environmental settings.
- Observe behavior.
- Select an organism.
- Open detailed organism records.
- Inspect social interactions.

Moving or resizing the container must not reset the ecosystem.

# 13. AQUATIC HABITATS

Implement desktop aquariums for water-based organisms.

Support freshwater and saltwater environments.

Aquariums must be movable desktop objects.

They belong to the habitat visibility group, not the laboratory equipment group.

## WATER PARAMETERS

Track appropriate environmental conditions:

- Water type.
- Salinity.
- Temperature.
- Dissolved oxygen.
- Water quality.
- Nutrient availability.
- Waste.
- Food availability.
- Population.
- Environmental volume.

Use existing environmental simulation systems where possible.

Do not reduce aquatic compatibility to a simple yes/no flag if the existing physiology supports more detailed checks.

An organism's survival must depend on its actual biological compatibility.

For example:

An organism that relies on freshwater conditions may experience osmotic stress in saltwater.

An organism without suitable aquatic respiration may fail to obtain sufficient oxygen underwater.

## AQUARIUM VISUALS

Display a recognizable glass aquarium with visible water and interior contents.

Show organisms moving within the environment.

The container must be visually distinct from a terrestrial habitat.

Use a top-down simulation view for the organism environment.

A decorative side/front glass appearance may frame the aquarium, but must not contradict the simulated movement coordinates.

## AQUARIUM INTERACTIONS

Allow:

- Moving the aquarium.
- Inspecting organisms.
- Adding organisms.
- Removing organisms.
- Feeding.
- Adjusting environmental conditions.
- Monitoring water quality.
- Viewing organism health.
- Opening detailed records.

Preserve each aquarium's state and position.

# 14. HABITAT VISIBILITY GROUP

Habitats must be independently controllable from the laboratory.

The user may want to hide all laboratory equipment while leaving their terrarium or aquarium visible.

Implement separate visibility settings:

- Show Laboratory.
- Show Habitats.
- Show Desktop Organisms.

These settings must be independent.

For example:

Laboratory OFF, Habitats ON, Desktop Organisms ON.

This should hide the Forge, Petri dishes, and droppers while leaving habitats and released organisms visible.

Each visibility group must preserve its layout and simulation state.

# 15. DESKTOP ORGANISMS

Prepare the desktop system for organisms that can roam outside containers.

These must be the same persistent organisms maintained in Cellarium.

Do not create a separate cosmetic pet species system.

A released organism retains:

- Genome.
- Anatomy.
- Physiology.
- Age.
- Developmental state.
- Dynamic stats.
- Behavioral nature.
- Memories.
- Learned behavior.
- Injuries.
- Individual identity.

The desktop renderer must use the organism's actual anatomy and movement capabilities.

A limbless organism should not suddenly walk.

An organism without wings should not fly.

A water-dependent organism should not survive indefinitely on a dry desktop unless its biology genuinely supports it.

Provide organism release and recall interfaces.

If full desktop organism roaming is not already implemented, establish the necessary integration without introducing fake behavior or replacing existing organism systems.

# 16. WINDOWS SYSTEM TRAY

Implement a real Windows system-tray icon.

Do not simulate the system tray inside a LÖVE2D window.

The tray icon must remain available while Cellarium is running.

Right-clicking the icon opens a native or properly integrated context menu.

Suggested menu:

CELLARIUM

[✓] Show Laboratory
[✓] Show Habitats
[✓] Show Desktop Organisms

Research & Cryobank
Genome Database
Organism Records

Save Layout
Restore Layout
Reset Layout

Settings
About Cellarium

Exit Cellarium

## TRAY FUNCTIONALITY

Each menu action must work.

Show Laboratory:
Toggle visibility of laboratory equipment.

Show Habitats:
Toggle terrestrial and aquatic habitat visibility.

Show Desktop Organisms:
Toggle freely roaming organism rendering.

Research & Cryobank:
Open the research interface.

Save Layout:
Persist the current object positions and settings.

Restore Layout:
Restore the most recently saved arrangement.

Reset Layout:
Move objects into a safe default layout after confirmation.

Exit Cellarium:
Perform a safe shutdown.

## EXIT BEHAVIOR

On exit:

- Save object positions.
- Save culture state.
- Save habitat state.
- Save organism state.
- Save settings.
- Release native resources.
- Remove overlays.
- Remove the tray icon.
- Shut down cleanly.

Do not leave invisible windows intercepting mouse input after shutdown.

# 17. RESEARCH AND CRYOBANK INTERFACE

Research, genome records, cryobank records, and organism records must be accessible through a browser-style application interface.

This should look like an internal laboratory information system.

It may use:

- An embedded web-based UI.
- A local browser frontend.
- A native window styled as a browser.
- Another suitable local interface.

Do not require a public internet connection.

The application must work offline.

Do not create a real public website unless the existing architecture specifically requires one.

## REQUIRED SECTIONS

### Research

- Experiments.
- Discoveries.
- Gene observations.
- Developmental observations.
- Biological measurements.
- Behavioral studies.
- Research history.

### Cryobank

- Stored genomes.
- Preserved cells.
- Archived samples.
- Organism records where applicable.
- Storage conditions.
- Sample identity.
- Retrieval actions.

### Genome Database

- Chromosome information.
- Genetic sequences.
- Genome comparisons.
- Mutation history.
- Engineered genome records.

### Organism Records

- Organism identity.
- Genome.
- Anatomy.
- Age.
- Developmental stage.
- STR, DEF, DEX, INT, VIT, END.
- Vital signs.
- Behavioral nature.
- Memories.
- Social relationships.
- Growth history.
- Health history.

The interface must read and write the same underlying data as the laboratory simulation.

Do not create a disconnected duplicate database.

## INTERFACE BEHAVIOR

Support:

- Search.
- Filtering.
- Sorting.
- Record inspection.
- Navigating between related records.
- Opening records from desktop objects.
- Returning to the relevant organism or culture.

The user should be able to click a Petri dish and open its record directly.

Similarly, selecting an organism in a habitat should allow access to its research history.

# 18. PERSISTENCE AND SAVE SYSTEM

Implement reliable persistence for the entire desktop environment.

Save:

- Laboratory object IDs.
- Object positions.
- Monitor associations.
- Scale and dimensions.
- Visibility groups.
- Lock states.
- Layer ordering.
- Petri dish contents.
- Vial contents.
- Culture progress.
- Workstation state.
- Genome editor state where appropriate.
- Habitat environments.
- Organism identities.
- Organism conditions.
- Research records.
- Cryobank records.
- User settings.

Use a versioned save schema.

Provide migrations for older saves.

Do not silently discard incompatible records.

Use safe or atomic save operations where practical to reduce corruption risk.

Avoid unnecessary full-state writes on every rendered frame.

## CONTINUED SIMULATION

Simulation time must be independent of whether an object is visible.

When a laboratory object is hidden, its culture continues to exist.

When the application is minimized or its UI is closed, simulation should continue if the process remains running.

When Cellarium is fully exited, persist a timestamp and apply an appropriate bounded elapsed-time simulation when it starts again.

Do not assume unlimited background execution.

Use the existing simulation rules for elapsed-time advancement.

Avoid unrealistic instant death or unlimited growth caused by very large offline time jumps.

# 19. SIMULATION AND PRESENTATION SEPARATION

Separate biological simulation from desktop rendering.

The same organism or culture should not require its visual object to exist in order to maintain state.

Suggested responsibilities:

## Core Simulation

- Genetics.
- Cells.
- Cultivation.
- Development.
- Anatomy.
- Physiology.
- Behavior.
- Memory.
- Habitats.
- Research data.

## Desktop Host

- Windows integration.
- Tray icon.
- Desktop object management.
- Overlay rendering.
- Mouse input.
- Monitor management.
- Visibility.

## Laboratory Interface

- Petri dishes.
- Droppers.
- Vials.
- Forge.
- Workstations.

## Habitat Interface

- Terrariums.
- Aquariums.
- Organism inspection.

## Research Interface

- Cryobank.
- Genome database.
- Experiment records.
- Organism records.

These modules must share persistent entities rather than maintaining separate conflicting copies.

# 20. INPUT AND INTERACTION RULES

Implement a clear input model.

Mouse interactions must distinguish:

- Selecting.
- Dragging.
- Opening.
- Dispensing.
- Inspecting.
- Resizing.
- Interacting with organisms.
- Interacting with underlying Windows applications.

Examples:

Click Petri dish rim:
Select or drag the dish.

Click Petri dish interior:
Inspect or interact with culture.

Use loaded dropper over dish:
Dispense the selected sample.

Click habitat frame:
Move the habitat.

Click habitat interior:
Interact with the habitat or select an organism.

Click empty desktop space:
Pass input to Windows.

Right-click tray icon:
Open Cellarium controls.

Avoid ambiguous interactions.

Provide visible feedback for selected tools and current actions.

A loaded dropper should visibly indicate that it contains material.

# 21. PERFORMANCE REQUIREMENTS

The desktop host must remain lightweight.

Do not run the complete laboratory simulation at the rendering frame rate.

Use appropriate update frequencies.

Examples:

- Desktop animation: responsive visual updates.
- Cell growth: slower simulation updates.
- Physiological state: appropriate biological simulation ticks.
- Long-term research: event-driven or periodic updates.
- Hidden objects: no unnecessary rendering.
- Distant or inactive habitats: reduced visual processing where appropriate.

Maintain biological consistency.

Avoid high CPU usage while the user is doing ordinary Windows tasks.

Do not require an internet connection or cloud service.

Do not require an offline language model to run the laboratory.

# 22. WINDOWS COMPATIBILITY

Target Windows 10 and newer.

Do not assume modern CPU instruction support without checking.

Avoid dependencies that require AVX or AVX2 unless an alternative compatible build is available.

Support multiple monitors and mixed resolutions.

Package any necessary native components with the application.

Provide clear build and launch instructions.

Do not require users to manually launch multiple command-line programs for normal operation.

If multiple internal processes are necessary, the main launcher should manage them.

# 23. SECURITY AND SYSTEM INTEGRATION

The desktop overlay must not interfere with Windows security features.

Do not request administrator privileges unless genuinely required and justified.

Do not install system-wide hooks unnecessarily.

Do not manipulate unrelated application windows.

Do not access private files or control external applications without explicit user authorization.

The user must always be able to hide the laboratory or exit Cellarium.

Provide a recovery mechanism if the overlay becomes unresponsive.

# 24. VISUAL QUALITY

Use a coherent scientific laboratory style.

The physical desktop objects should have recognizable shapes, proportions, materials, and shadows.

Petri dishes should look shallow and transparent.

Vials should look like laboratory tubes.

Droppers should have identifiable tips and liquid contents.

Habitats should look like enclosed containers.

Aquariums should look like glass tanks.

The Forge and workstations should look like specialized scientific equipment.

Do not implement the finished UI as a set of plain colored rectangles with text labels.

Do not rely on temporary placeholder artwork for the delivered implementation.

Use available project assets where suitable and create consistent new assets where necessary.

Keep text and controls readable at different desktop scales.

# 25. COMPLETE USER WORKFLOW

The following end-to-end workflow must function.

1. Launch Cellarium.
2. The Windows system-tray icon appears.
3. Laboratory objects restore to saved positions.
4. The user drags a Petri dish to another monitor.
5. The user selects a vial containing cells.
6. The user collects a sample with a dropper.
7. The user moves the dropper over the dish.
8. The user dispenses the sample.
9. The actual Petri dish culture updates.
10. The user opens the dish's detailed record.
11. The user opens the Forge.
12. The user edits or inspects an engineered genome.
13. The user opens a cell workstation.
14. The user performs an existing cell-engineering operation.
15. The user places a viable organism into a terrestrial habitat.
16. The organism moves and behaves according to its anatomy and physiology.
17. The user opens an aquarium and inspects aquatic conditions.
18. The user opens the Research & Cryobank interface.
19. The user inspects the same organism and genome records.
20. The user turns off Show Laboratory from the system tray.
21. All laboratory equipment disappears.
22. Habitats remain visible.
23. The user continues interacting with Windows normally.
24. The user turns Show Laboratory back on.
25. Every laboratory object returns to its saved position with its contents intact.
26. The user exits Cellarium.
27. The user restarts Cellarium.
28. All objects, cultures, habitats, organisms, and records restore correctly.

This workflow is a mandatory acceptance test.

# 26. AUTOMATED TESTING

Add tests for:

- Desktop object creation.
- Object identity persistence.
- Dragging.
- Coordinate conversion.
- Multi-monitor placement.
- Negative desktop coordinates.
- Display scaling.
- Monitor disconnection.
- Layout restoration.
- Visibility toggles.
- System-tray actions.
- Petri dish state.
- Vial contents.
- Sample collection.
- Sample dispensing.
- Invalid transfers.
- Contamination behavior.
- Culture progression.
- Forge integration.
- Workstation integration.
- Habitat state.
- Aquarium state.
- Organism persistence.
- Research database consistency.
- Save migration.
- Clean shutdown.

Where Windows integration cannot be tested in a headless environment, isolate native functionality behind testable interfaces and provide a Windows-specific manual verification checklist.

# 27. MANUAL WINDOWS ACCEPTANCE TESTS

Verify on an actual Windows desktop:

- Objects are visible without a conventional fullscreen game window.
- Transparent regions do not block mouse input.
- Desktop icons remain clickable.
- The taskbar remains usable.
- Other applications can be opened normally.
- Objects can move between monitors.
- Objects restore after restart.
- Petri dishes can receive samples from droppers.
- Source quantities decrease correctly.
- Culture quantities increase correctly.
- Invalid transfers are rejected.
- The Forge opens and functions.
- Cell workstations remain functional.
- Terrestrial habitats display moving organisms.
- Aquariums preserve water conditions.
- The research interface displays actual records.
- Laboratory visibility can be toggled independently.
- Habitat visibility can be toggled independently.
- The tray menu functions correctly.
- The application exits without leaving input-blocking windows.

# 28. PRESERVE EXISTING GAME FUNCTIONALITY

Before removing or replacing an existing interface, inventory its functions.

Map each existing function to its new location.

Examples:

Old cultivation menu → Petri dish and cell workstation.

Old genome editor → Forge.

Old organism viewer → Habitat and organism inspection.

Old research menu → Research browser interface.

Old cryobank menu → Cryobank browser interface.

Do not remove functionality merely because it does not fit neatly into the new visual design.

If a feature requires a detailed panel, retain a detailed panel.

The desktop objects provide access to the systems; they do not replace the underlying systems.

# 29. IMPLEMENTATION STRATEGY

This is intended as one coordinated development pass.

Do not stop after creating a UI mockup.

Do not implement only the tray icon and claim the desktop overhaul is complete.

Do not create a second unrelated application that cannot access existing Cellarium data.

Proceed in this order:

1. Audit the current codebase and existing UI functions.
2. Identify existing simulation and rendering dependencies.
3. Establish a shared persistent simulation interface.
4. Implement the Windows desktop host.
5. Implement native tray integration.
6. Implement transparent interactive desktop objects.
7. Implement multi-monitor layout management.
8. Implement laboratory visibility groups.
9. Implement Petri dishes.
10. Implement vials and racks.
11. Implement functional droppers and sample transfers.
12. Integrate cell workstations.
13. Integrate the Forge.
14. Implement terrestrial habitat desktop containers.
15. Implement aquatic habitat desktop containers.
16. Connect habitat rendering to existing organism simulation.
17. Implement the browser-style research and cryobank interface.
18. Integrate persistence and save migration.
19. Optimize performance.
20. Run automated and Windows-specific acceptance tests.
21. Fix failures before reporting completion.

If a technical limitation requires a different architecture, explain the reason in the implementation report and use the most reliable solution.

Do not silently omit requested functionality.

# 30. REQUIRED FINAL REPORT

When finished, provide:

1. Summary of the architecture.
2. Files created and modified.
3. Windows-native dependencies added.
4. How the desktop overlay works.
5. How mouse pass-through works.
6. How multi-monitor placement works.
7. How the system-tray controls work.
8. How Petri dishes and droppers interact with real simulation data.
9. How the Forge and cell workstations connect to existing systems.
10. How terrestrial and aquatic habitats work.
11. How research and cryobank records are accessed.
12. How save migration works.
13. Automated test results.
14. Manual Windows testing performed.
15. Known limitations or unfinished items.
16. Exact build and launch instructions.

Clearly distinguish implemented functionality from functionality that has only been prepared architecturally.

Do not claim manual Windows testing was completed unless it was actually performed.

Do not claim the overhaul is finished if mandatory workflows remain broken.

---

# FINAL ACCEPTANCE CRITERIA

The revision is successful when Cellarium behaves like a persistent scientific laboratory living on the Windows desktop.

The player must be able to move Petri dishes, use droppers to transfer actual biological samples, operate the Forge and cell workstations, maintain terrestrial and aquatic habitats, and access research and cryobank records.

The laboratory can be hidden from the system tray without losing its layout or biological state.

Habitats remain independently visible.

Normal Windows interaction remains available.

Existing genetics, development, cultivation, physiology, and organism simulation systems continue working.

**Build a functional desktop laboratory, not a decorative desktop overlay.**