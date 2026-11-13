# Sample rack and empty-flask repair

The rack now has eight exclusive slots with 106 logical pixels between vial centers at default scale. Both artwork and snapping use the same slot geometry. Spacing expands for larger vials, includes display DPI in positioning, and migrates narrow saved racks and duplicate old slots without changing specimen identities or contents. Racked vials render above their rack. Dragging a vial out or opening its controls detaches it.

An empty flask previously rendered a green liquid polygon unconditionally. Liquid now appears only when its actual cell count is positive, and the empty tag explicitly reads Empty / 0 cells.

Executed checks: eight focused geometry, scaling/DPI, saved-layout migration, exclusive-slot, drag/detach, depth and rendering checks passed; all 53 headless desktop regression groups passed. The programmer-art preview uses the actual desktop renderer. Existing organism code, genomes and saves were not reset. Current running builds must be exited through the tray before opening the updated executable.

## Physical DNA attachment

Drag an archived DNA vial onto the workstation, including its collapsed body. It opens and snaps the vial into a dedicated purple DNA dock. Keep a purchased blank-cell vial at INPUT and an empty container at OUTPUT, then click Install selected DNA. The attached DNA takes priority over archive-menu selection. Installation consumes one blank cell and outputs one living cell carrying the exact attached genome; the DNA archive record stays available. The purple dock has a Detach button. Missing or occupied DNA docks reject changes without consuming cells.

Final validation: 8 equipment checks, 5 DNA-docking checks, 28 workshop checks and 53 desktop regression groups passed (94 groups/checks).
