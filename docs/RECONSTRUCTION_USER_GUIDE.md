# Reconstruction laboratory guide

Use the `desktop-laboratory-dev` reconstruction build. Extract the complete Windows ZIP and launch **Cellarium-Reconstruction-Dev.exe** with its DLLs beside it. Exit another Cellarium desktop build from its tray first. Main and the previous anatomy-dev version remain separate.

Open **Settings > Anatomy Generator / developer tool**. The normal desktop laboratory still opens first; the classic interface remains an explicit Settings option.

- **Generate Random Organism / Regenerate:** generate a real canonical genome and its actual anatomical tissue graph, retaining failed development.
- **Seed / Use seed:** reproduce a genome and its development under the standard displayed conditions. `20365841` is the first audited specimen.
- **Play / Pause / Step / Restart / Playback …x:** watch continuous biological development or step among 121 recorded trajectory samples. These controls affect this diagnostic playback only. Living organisms and cultures continue following PC time.
- **Timeline:** click the thin bar below the body viewport to inspect a developmental time. Statistics show the body at that time, not its adult potential.
- **Layers:** toggle External, Skeleton, Muscle, Fat, Organs and Nervous individually or together. Combined exposes multiple aligned internal layers. Solo external clears the other toggles.
- **Inspection:** click anatomy in the viewport, then use **< Structure / Structure >** to inspect individual components, including ribs and muscles occupying the same region. The panel shows component identity, density, mass, growth and capacity; the lower rows show the region's dimensions, genetic influences, tissue allocation and local protection.
- **Save Genome:** archive the exact canonical DNA. Use it in the existing Forge for editing, forecasting and installation into a developmental cell. The archive remains the normal laboratory archive.
- **Export:** write an anatomy-test-SEED.lua diagnostic into this executable's LÖVE save directory. The displayed path identifies the export. It contains the canonical genome, genetic target anatomy, current growth state, trajectory samples, statistics and errors. Re-exporting that seed replaces its diagnostic file.

Incubation now changes actual anatomy continuously, and released juveniles continue growing in habitats. Nutritional/oxygen/temperature stress slows development; limited capacity can cause biological failure. Feeding affects reserve storage and the body's tissue envelope. There are no live pause/speed controls. Dimensions use inches, mass ounces and temperature Fahrenheit.

Old organisms keep their existing bodies when explicitly imported. This build has its own save identity and does not automatically load main's or anatomy-dev's session. Closing records returns to the tray. The desktop edition still saves on exit and restores on launch. Ctrl+Q exits; Ctrl+Shift+L opens recovery.

## Tests and audit artifacts

```powershell
& 'C:\Program Files\LOVE\lovec.exe' . --reconstruction-test
& 'C:\Program Files\LOVE\lovec.exe' . --desktop-test
```

The first command executes assertions, unfiltered 100- and 1,000-genome audits, the first-20 contact sheet, the multi-stage growth sequence and actual draw/callback checks. Run it against an unpacked source directory or the fused executable with docs beside it. Results are reconstruction-test-results.txt and docs/RECONSTRUCTION_AUDIT_*.md. Full per-genome data are reconstruction-audit-*.lua. RECONSTRUCTION_GROWTH_RECORDS.lua contains the biological states behind the sequence image.

Read [RECONSTRUCTION_ARCHITECTURE.md](RECONSTRUCTION_ARCHITECTURE.md) for the framework, growth law, migration and verified limits. Native Windows interaction remains unverified for this revision because its test launch approval timed out; the report does not count earlier native tests as current passes.

Full growth-state records are available as RECONSTRUCTION_GROWTH_RECORDS.zip in the GitHub docs directory, and unpacked as RECONSTRUCTION_GROWTH_RECORDS.lua in the Windows/source packages.
