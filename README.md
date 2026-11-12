# Cellarium — Genome Engineering Development

This is **genome-engineering-dev**, a separate experimental version. The preserved ecology game is on [main](https://github.com/markchpaman10/cellarium/tree/main). This branch delivers a working vertical slice of the larger supplied specification.

## Run

Extract **builds/dev/Cellarium-Engineering-Dev-Windows.zip** and run **Cellarium-Engineering-Dev.exe**, or open **builds/dev/Cellarium-Engineering-Dev.love** with LÖVE 11.5. Source runs with `love path/to/checkout`.

The old artifacts at builds/Cellarium-Windows.zip and builds/Cellarium.love remain the ecology baseline. New artifacts live in builds/dev/. The development game uses its own `cellarium-genome-engineering-dev` save identity. Both versions start fresh and keep manual New/Save/Load. No autosave. Temperatures use Fahrenheit.

## Engineering loop

1. Open **Genome laboratory**. Three unidentified DNA vials and eight blank developmental cells are provided. Additional vials cost 10 lab credits from an initial prototype budget of 120.
2. Select one or more vials and **Assemble selected DNA**. Complete genomes retain 24 chromosome pairs and all three existing locus families. More than three sources are supported; tests and the audit include six-source assemblies. Vials contain modeled allele sequences and metadata, never animal templates.
3. Inspect primary, developmental or ecological loci. Select a locus and splice the chosen vial's corresponding sequence, duplicate its dosage, delete/suppress it, restore it, mutate an allele or cycle an activating/suppressing regulatory link. The actual developmental forecast updates. No finished stats or species are selected.
4. Name and archive successful genomes. Reuse an archive to obtain an independent editable copy. Sequencing a vial takes six simulation hours and reveals its organization/marker finding. Richer experimental gene discovery remains future work.
5. **Install genome / single embryo** consumes a blank cell and enters the existing division, differentiation, anatomy and viability pipeline. Failed development remains possible. **Batch engineer** creates six matched stem cells for the existing cultures. Specialized cells remain research materials, not mandatory organism ingredients.
6. Observe the organism in the habitat, then open **Life & observations** to inspect six dynamic summaries, vital signs, continuous predispositions, perceived memories, learned relationships and signaling history.

Procurement now acquires DNA instead of arbitrary wild cells. The seven starter tissue categories and working cultivation/cryobank/research systems remain. This slice does not implement a full laboratory economy.

## Living-state foundation

Dosage and explicit regulatory links feed the shared expression functions. Edited dosage/regulation is inherited through gametes and fertilization. Deletion retains the original alleles and explicitly suppresses expression. This is a game-level locus model, not a molecular DNA editor.

STR, DEF, DEX, INT, VIT and END are calculated from real anatomy, material condition, neural organization, oxygen, energy and fatigue. They are summaries, not editable RPG point allocations. Initial cardiac/transport vital records include normalized blood volume and pressure; transport failure can kill an organism while generic health remains positive.

Neural anatomy and maturation bound memory, recognition and learning. Organisms can reinforce and forget perceived feeding/stress associations, revisit remembered food locations, and develop directional familiarity/trust/fear through actual encounters. Continuous predispositions influence otherwise-idle behavior; physiological needs retain priority. Memories are individual experience and are not inherited as genes.

Communication produces structured posture/chemical events. Speech, language, a local AI model and a desktop overlay are not implemented. The adapter preserves the same organism state and validates a narrow biological intent vocabulary. It provides no operating-system or file-control capability.

## Validation

- `--test`: 46 deterministic test groups, including all 33 preserved ecology groups.
- `--ui-test`: actual callbacks for cultivation, cryostorage, DNA construction, installation, development, archives, batches, living/ecology inspection and New.
- `--engineering-audit`: 1,000 one-to-six-vial assemblies, anatomy/stat/temperament distributions and a 60-hour matched-pair cohort. See [the measured report](engineering-audit.md) and [all individual results](engineering-audit.csv).
- `--engineering-dev-smoke` and `--life-dev-smoke`: reproducible rendered fixtures. Tests and previews never create player saves.

See [the complete supplied prompt](docs/GENOME_ENGINEERING_SPEC.md), [the delivered slice and remaining milestones](docs/ENGINEERING_IMPLEMENTATION.md), and [the preserved baseline documentation](docs/ECOLOGY_BASELINE_README.md). Historical ecology audits describe the old model, not the new cognitive system. Long-term ecosystem balance remains unfinished.
