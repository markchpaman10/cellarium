"""Build the native LÖVE 11.5 desktop package; Python standard library only."""
import argparse, hashlib, json, shutil, zipfile
from pathlib import Path

root = Path(__file__).resolve().parent
parser = argparse.ArgumentParser()
parser.add_argument('--out', type=Path, default=root / 'dist')
parser.add_argument('--love-dir', type=Path, default=Path('C:/Program Files/LOVE'))
args = parser.parse_args()
out = args.out.resolve(); out.mkdir(parents=True, exist_ok=True)
name = 'Cellarium-Growth-Integrated'
folder = out / name; folder.mkdir(exist_ok=True)
excluded = {'desktop-error.txt', 'growth_diagnostics.lua'}
def included(f):
    rel = f.relative_to(root)
    return f.is_file() and not any(x in {'.git', 'dist', 'builds', '__pycache__'} for x in rel.parts) and f.name not in excluded and out not in f.parents
files = sorted(f for f in root.rglob('*') if included(f))
lovefile = folder / (name + '.love')
with zipfile.ZipFile(lovefile, 'w', zipfile.ZIP_DEFLATED) as z:
    for f in files:
        if f.parent == root and f.suffix == '.lua': z.write(f, f.name)
exe = folder / (name + '.exe')
exe.write_bytes((args.love_dir / 'love.exe').read_bytes() + lovefile.read_bytes())
for f in args.love_dir.glob('*.dll'): shutil.copy2(f, folder / f.name)
for src, dest in [('license.txt', 'runtime-license.txt'), ('readme.txt', 'runtime-readme.txt')]:
    if (args.love_dir / src).exists(): shutil.copy2(args.love_dir / src, folder / dest)
for f in files:
    rel = f.relative_to(root)
    if f.suffix.lower() in {'.md', '.txt'} or rel.parts[0] == 'docs':
        dest = folder / rel; dest.parent.mkdir(parents=True, exist_ok=True); shutil.copy2(f, dest)
sourcezip = out / (name + '-Source.zip')
with zipfile.ZipFile(sourcezip, 'w', zipfile.ZIP_DEFLATED) as z:
    for f in files: z.write(f, str(Path(name + '-Source') / f.relative_to(root)))
windowszip = out / (name + '-Windows.zip')
with zipfile.ZipFile(windowszip, 'w', zipfile.ZIP_DEFLATED) as z:
    for f in sorted(folder.rglob('*')):
        if f.is_file(): z.write(f, str(Path(name) / f.relative_to(folder)))
checks = [windowszip, sourcezip, exe, lovefile]
(out / (name + '-SHA256.txt')).write_text(''.join(hashlib.sha256(f.read_bytes()).hexdigest() + '  ' + f.name + '\n' for f in checks), encoding='utf-8')
print(json.dumps([{'file': str(f), 'bytes': f.stat().st_size} for f in checks]))
