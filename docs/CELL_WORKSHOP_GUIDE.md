# Cell workshop and physical cell stock

This desktop revision implements the workshop design agreed in chat. Purchases live in the Cellarium notification-area/taskbar icon's right-click menu. The workshop processes attached samples; cultivation stays in containers and transfers use the dropper.

## Starting and buying

A new experiment has **no cells, no blank cells and no gametes**. Existing empty starting equipment is retained. Right-click the Cellarium tray/taskbar icon and choose **Buy supplies…**.

- Each ordinary cell costs **1 credit**, including a physical vial containing exactly one cell.
- Each blank developmental cell also costs **1 credit**, including its own vial.
- Separately purchased Petri dishes, flasks, plates, storage vials and cryovials arrive empty. Their existing container prices are shown in the menu.
- Purchased ordinary cells are unmodified starter stock. The free Collect wild cells action has been removed.

The supplied one-credit vial cannot immediately be resold for a higher price. Physical-stock withdrawal no longer creates new loose cells and free packaging; use the dropper.

If this build restores an existing experiment, your previous specimens are preserved. Existing loose cells, explicit blank-cell stock and stored gamete records are housed in physical vials. Migration runs without replacing DNA or duplicating quantities. To test the new empty starting state, open **Settings > Start a new experiment…**. Starting a new experiment replaces the current desktop session under the existing desktop save policy.

## Attach containers to the workshop

1. Click the physical **Cell Workstation** to open its direct desktop controls. No context menu is needed.
2. Drag a container containing a cell onto the visible **INPUT / CELL SOURCE** dock on the left.
3. For physical output, drag an **empty** container onto **OUTPUT / EMPTY CONTAINER** on the right. A dish, tube/vial, flask or plate can be attached.
4. Open/thaw the attached containers before processing. An unsuitable or occupied output is rejected before anything is consumed.

The docks reference those same physical containers. The workshop holds no cells of its own and has no global container or cell selector. Moving the workshop moves its docked containers together. Dragging a docked container away, or pressing its Detach button, releases the attachment without changing its contents. Each container can occupy only one slot on one workshop.

## The processing controls

| Operation | Input | Result | Cost in cells |
|---|---|---|---|
| Extract DNA to genome archive | Ordinary living cell in INPUT | Exact genome archive record; confirmation on the terminal | Source cell retained; no output container required |
| Install selected DNA | Blank developmental cell in INPUT and a selected archived genome | Installed developmental cell in empty OUTPUT | One blank cell |
| Prepare egg | Viable stem cell in INPUT | Egg precursor in empty OUTPUT | One stem cell |
| Prepare sperm | Viable stem cell in INPUT | Sperm precursor in empty OUTPUT | One stem cell |

Use **Choose an archived genome…** to select DNA for installation. DNA extraction follows the existing archive system so the genome remains available to the Forge. The terminal reports the selected genome, completed operations and failures. The workshop contains no feeding, cultivation, harvesting, transfer or shopping controls.

Egg/sperm preparation uses the existing haploid inheritance machinery. Precursors mature over **eight real minutes**. Blanks and haploid precursors do not multiply as ordinary Petri cultures. Their physical specimens remain linked to the existing gamete records used by Incubation; fertilization consumes the corresponding physical specimens.

The Forge's **Use in workshop** action archives its edited copy and selects that DNA on the workshop. Attach a purchased blank-cell vial and an empty output to install it. On the resulting cell's own container, choose **Begin development** to consume that installed cell and enter existing incubation. There is no hidden blank-cell inventory to restock in the machine.

## Dropper and frozen storage

Normal transfers remain on the dropper. Right-click always opens a menu; left-drag moves the dropper. Sample from an open source, then dispense into a compatible destination.

To preserve a sample:

1. Load cells into the dropper.
2. Right-click the dropper and choose **Freeze contents into storage**.
3. The counted contents move to frozen storage. The dropper stays on the desktop, empty and usable; it is not put into storage.

To retrieve them:

1. Choose **Retrieve frozen cells…** from the dropper or Cellarium tray/taskbar menu. Cryobank records also provide **Retrieve into a container…**.
2. Choose the stored sample, then an open, unfrozen compatible container with space.
3. The stored sample is removed only after delivery succeeds. A rejected delivery leaves it frozen and intact.

Frozen gamete precursors stop maturing and resume after retrieval. Sample genome, quantity, viability and contamination metadata survive storage and save/load. A used empty dropper can be sterilized from its menu before another strain is sampled.

## Saving and time

The established desktop identity, exit-save/launch-restore and PC-linked biological timing remain. There are no live speed controls. American units and Fahrenheit are retained. Dock IDs, terminal history, physical stock and frozen packets persist. This change does not migrate or replace existing organism anatomy.

## Executed checks

26 workshop groups, 65 desktop groups (53 headless/model plus 12 native Windows groups), and 30 reconstruction regression groups passed. Native checks include an actual window-event container drag into the workshop dock, direct workshop operations, a Petri move to the connected second monitor, hide/restore and context menus. These are scripted checks rather than a complete manual usability review.

Source commands:

```powershell
& 'C:\Program Files\LOVE\lovec.exe' . --workshop-test
& 'C:\Program Files\LOVE\lovec.exe' . --desktop-test
& 'C:\Program Files\LOVE\lovec.exe' . --reconstruction-test
```

Run `--desktop-native-test` in an interactive Windows session for tray/HWND tests. They create and clean up their own test windows. Results are included in workshop-test-results.txt, desktop-test-results.txt and reconstruction-test-results.txt.
