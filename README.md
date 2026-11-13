# Cellarium: Desktop Laboratory + Organism Growth Lab

[Download Windows build](builds/Cellarium-Growth-Integrated-Windows.zip). Extract the ZIP and run **Cellarium-Growth-Integrated.exe**, keeping the DLLs beside it. Exit the older Cellarium build through its tray icon first. The previous workshop build remains available in `builds/`.

## Sample racks and empty flasks

The rack holds eight individually spaced vials, with one vial per slot. Drop onto the rack to use the nearest available slot; a full rack rejects extra vials. Existing saved racks adjust automatically. Empty flasks now display clear glass. See [equipment update and checks](EQUIPMENT-UPDATE.md).

## Desktop depth

Right-click **any desktop item** for **Bring to front**, **Raise one layer**, **Lower one layer**, or **Send to back**. Higher items receive input first. The workstation and its attached containers move through depth together, and both docked containers always appear above their workstation. Saved layouts retain depth. Laboratory hiding/restoration retains the group.

## Organisms

The default generator, development, anatomical tissue renderers, early embryology, physiological metrics and named diagnostic animations now use [organism-growth-lab at 88c062b](https://github.com/markchpaman10/cellarium/tree/88c062bebf1ae6e54b714d8fab461b22ff547824). Its standalone main/conf were kept out of the desktop runtime. Exact upstream files are under [vendor/organism-growth-lab](vendor/organism-growth-lab); the source branch is unchanged.

Open **Settings > Anatomy Generator / developer tool**. Generate or enter a seed; inspect layers and side/top projections; use **Motion** to select available actions, pause/resume, or stop. Walking uses generated joints, supports, muscles, nerve connections, body mass and ground contacts. Limbless anatomy can undulate. Some viable organisms cannot move. Preview playback controls affect only this diagnostic view; living organisms still follow elapsed PC time. Seed **22250963** is a reproducible viable legged example.

The 1,000-genome audit found **79 viable, 921 biological failures, zero technical errors**. Among viable organisms, 49 were immobile, 18 legged and 12 undulating. Across all generated bodies, four-appendage plans were 245/1,000. [Read the integration guide and limitations](docs/GROWTH_LAB_INTEGRATION.md), [actual anatomy audit](docs/RECONSTRUCTION_AUDIT_1000.md), and [movement audit](docs/GROWTH_LAB_MOVEMENT_AUDIT.md).

## Cell workshop and containers

1. New experiments start with no cells. Right-click the Cellarium tray icon > **Buy supplies...**. An ordinary or blank cell costs **1 credit**, supplied in its own vial; separately purchased containers are empty.
2. Click the workstation, then drag a cell container onto **INPUT** and an empty container onto **OUTPUT**.
3. To install DNA, drag a DNA vial onto the workstation; it connects to the purple DNA dock. Keep a blank-cell vial at INPUT and an empty container at OUTPUT. Click **Install selected DNA**. The archived-genome selector remains available when no DNA vial is attached.
4. Extract DNA into the archive while retaining its source; install archived DNA using one blank cell; or prepare an egg/sperm precursor using one stem cell. Physical results go into the attached output, messages into the machine's terminal.
5. Cultivate inside containers. Transfer with the dropper. Its context menu freezes contents into storage and retrieves frozen samples into containers.
6. Right-click a container > **Label container...** or use **Label...**. Enter saves; Escape cancels. Labels follow persistent container IDs.

[Complete workshop guide](docs/CELL_WORKSHOP_GUIDE.md). Existing specimen identities, genomes, records, container contents and layouts are preserved; existing grown anatomical records remain compatible. Newly generated and incubated organisms use the imported generator. Legacy generator code remains available explicitly, not as an automatic replacement for biological failures. Desktop exit-save/launch-restore and PC-linked life timing remain. Classic UI requires an explicit Settings choice.

## Verification

See [current delivery report](GROWTH-INTEGRATION-REPORT.md) and included test results. Earlier anatomy/workshop reports describe their historical revisions. This is an experimental artificial-life model: later growth still uses genetically planned adult targets, and movement uses constrained kinematics rather than a full rigid-body physics solver.
