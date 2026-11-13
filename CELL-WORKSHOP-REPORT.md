# Container labeling update

Added right-click Label container and direct Label controls for all physical cell containers and DNA vials. A focused label screen provides Save, Clear and Cancel plus Enter/Escape/Ctrl+A. Custom names persist on canonical container IDs, appear on desktop tags and workshop docks, and do not alter cell contents or genome archives. Long tags fit safely with an ellipsis; text entry supports spaces and Unicode.

Executed for this revision: 28 workshop groups and all 53 headless desktop regression groups passed. The packaged executable also passes the workshop suite. Native physical keyboard interaction with the label screen was not separately manually certified; callback, rendering and save/load behavior are tested. The preceding revision's native results are retained below as historical verification.

# Cell workshop delivery report

Target branch: desktop-laboratory-dev, based on d9c2839242740cfd085011c8034ec274bd183a16. Changes concern desktop cell handling and the workshop; existing anatomical generator/growth modules are retained.

Implemented: cell-free new experiments; tray/taskbar Buy supplies menu; ordinary/blank single cells at one credit including a supplied vial; separately bought empty containers; removal of free wild collection; physical vial migration of prior loose/blank/gamete stock; visible drag-to-attach input/output docks; shared docked movement and detach; per-machine terminal; exact DNA archival retaining source; installation consuming one physical blank; egg/sperm preparation consuming one stem; actual empty-output validation and haploid records; dropper-content frozen storage; menu retrieval into compatible containers; frozen precursor suspension; physical gamete consumption at fertilization; installed-cell incubation from its own container; persistent IDs and counted stock.

The workstation has no cultivation, inventory, shop or transfer controls. Cells remain in their actual containers. Genome selection uses the existing archive. Forge editing is retained; installation is routed through the workshop. One-credit supplied vials cannot immediately be sold at the old higher resale price, and physical-stock withdrawal cannot mint free packaging.

Executed: 26 workshop groups passed; 65 desktop groups passed (53 headless/model and 12 actual native Windows groups); 30 reconstruction regression groups passed. Total 121 distinct groups. Native tests ran in an interactive Windows process and verified actual native down/move/up docking into the visible slot, direct workshop/Forge/culture controls, the connected second-monitor Petri move, counted transfer, hide/restore, right-click menus, save/load and native cleanup. The packaged executable also runs the workshop suite successfully. These checks are scripted, not a claim of exhaustive manual playtesting. Full actual result files are included.

The known historical monolithic tests.lua line-26 assertion from earlier deliveries remains documented and is not counted among passing groups. Current targeted suites pass. No new claim is made about future organism redesign work.

Migration preserves existing genomes, IDs and counts. Existing saves can contain previously acquired stock; only a new experiment starts cell-free. Desktop save identity and exit-save/restore behavior remain unchanged. American units, Fahrenheit, PC-linked time and context-menu input remain. The old loose-cell arrays remain compatibility internals and are emptied into physical vials; they are not a workshop inventory.

Launch: extract the entire Windows ZIP and open Cellarium-Cell-Workshop.exe with DLLs beside it. Exit an older Cellarium tray process first. Read docs/CELL_WORKSHOP_GUIDE.md. Cell purchase pricing is explicitly temporary as agreed. Development is still early; menus for shop and frozen retrieval can be redesigned later.
