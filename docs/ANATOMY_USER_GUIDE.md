# Anatomy Generator guide

Use the separate anatomy-dev build. Exit another Cellarium desktop build through its tray icon before launching `Cellarium-Anatomy-Dev.exe`; keep its DLLs beside it. The normal native desktop laboratory still opens first.

1. Open **Settings** from the Cellarium tray or records sidebar.
2. Click **Anatomy Generator / developer tool**.
3. Choose **Generate Random Organism** or **Regenerate**. Every result uses a real canonical genome and the same generator used by Forge forecasts and incubation. Failed development remains visible.
4. Click the **Seed** field, type a number, then press Enter or **Use seed** to reproduce a result. Example: `20365841` is the first audited specimen.
5. Toggle External, Skeleton, Muscle, Fat, Organs and Nervous individually or together. **Solo external** clears the other views; **Combined** enables internal views together. Bilateral limbs can overlap in side view.
6. **Restart**, **Step**, **Play playback**, **Pause playback** and **Playback …x** inspect recorded construction states. These controls never pause or accelerate the living laboratory.
7. Click a body region to inspect its parent, dimensions, genetic influences, tissue allocations, attachment, regional defense, mass and raw muscle force. The panel shows the completed body's physiology while the viewport can show an earlier construction stage.
8. **Save Genome** adds an exact copy to the existing genome archive. Load that DNA from the Forge, edit any alleles or regulation, forecast it, and install it into a blank developmental cell. Incubation takes actual elapsed PC time. Genetic viability and habitat compatibility still apply.
9. **Export** writes `anatomy-test-SEED.lua` into this build's LÖVE save directory and displays the full path. It includes the canonical genome, hash, structures, recorded construction, physical stats and development failures. Re-exporting the same seed replaces that seed's diagnostic export.

The anatomy build uses a separate experiment/save identity. It does not load main's desktop session automatically. To explicitly import an older experiment, drop its experiment file onto the records window; existing organisms retain their original bodies. New embryos use the new anatomy generator. Exit saves and launch restoration follow the desktop edition policy.

## Reproduce the audits

From the source directory with LÖVE 11.5 installed:

```powershell
& 'C:\Program Files\LOVE\lovec.exe' . --anatomy-test
& 'C:\Program Files\LOVE\lovec.exe' . --desktop-test
```

The anatomy command executes assertions, both unfiltered audits, the first-20 contact sheet, layer/playback rendering and developer callback checks. Results go to `anatomy-test-results.txt`, `anatomy-audit-100.lua`, `anatomy-audit-1000.lua` and `docs/ANATOMY_AUDIT_*.md`. The previous generator's repeatable baseline is available through `--anatomy-baseline`. Keep failures in the denominator.

For the native equipment tests use `--desktop-native-test` from an ordinary interactive Windows session; those tests create and clean up their own test windows. Run only one test instance at a time. A restricted shell may block tray initialization.

Architecture, gene mapping, compatibility and current limitations are documented in [ANATOMY_ARCHITECTURE.md](ANATOMY_ARCHITECTURE.md). The older laboratory instructions remain in [USER_GUIDE.md](USER_GUIDE.md).
