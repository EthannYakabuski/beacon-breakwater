"""Write source and accompanying-notice manifests; no builds, network or game run.

Preserves plugin native binaries/AARs. Excludes caches, exports and local runtime
test evidence. The source manifest intentionally excludes its own digest.
"""
import hashlib,json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
SKIP={'.git','.godot','.import','build','dist','exports','__pycache__','.gradle'}

def sha(path):
 with path.open('rb') as stream:return hashlib.file_digest(stream,'sha256').hexdigest()
def row(path):
 return {'path':path.relative_to(ROOT).as_posix(),'bytes':path.stat().st_size,'sha256':sha(path)}
def save(path,data):
 path.write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8')
def main():
 exact_sources={
  'Project/LICENSE':'LICENSE','Project/LICENSE.txt':'LICENSE',
  'Project/NOTICE':'NOTICE','Project/NOTICE.txt':'NOTICE',
  'Assets/ASSET-NOTICES.txt':'assets/ASSET-NOTICES.txt',
  'Assets/kenney_pirate-pack-CC0.txt':'assets/licenses/kenney_pirate-pack-CC0.txt',
  'Assets/kenney_ui-audio-CC0.txt':'assets/licenses/kenney_ui-audio-CC0.txt',
  'ThirdParty/PLAY-GAMES-MIT.txt':'addons/GodotPlayGameServices/LICENSE',
  'ThirdParty/POING-ADMOB-MIT.txt':'addons/admob/LICENSE',
 }
 notices=[]
 for path in sorted((ROOT/'LICENSES').rglob('*')):
  if not path.is_file() or path.name=='MANIFEST.json':continue
  relative=path.relative_to(ROOT/'LICENSES').as_posix()
  source=exact_sources.get(relative,'LICENSES/'+relative)
  source_path=ROOT/source
  if not source_path.is_file() or sha(source_path)!=sha(path):raise ValueError('Accompanying notice differs: '+relative)
  notices.append({**row(path),'source_relative':source,'source_sha256':sha(source_path),
   'scope':'Original project Apache-2.0' if relative.startswith('Project/') else 'Kenney selected assets CC0-1.0' if relative.startswith('Assets/') else 'Exact retained third-party notice; license text controls'})
 save(ROOT/'LICENSES/MANIFEST.json',{'schema':1,'game':'Beacon Breakwater','notice_files':notices,
  'scope':'Accompanying source/APK/Web notices. Does not relicense third-party content.',
  'engine_notice_provenance':'Exact retained Godot4.5.1 engine/component/font notice bundle from the reviewed shared platform distribution.'})
 files=[]
 for path in sorted(ROOT.rglob('*')):
  if not path.is_file():continue
  rel=path.relative_to(ROOT)
  if any(part in SKIP for part in rel.parts):continue
  if rel.as_posix().startswith('tests/evidence/') or rel.as_posix()=='docs/SOURCE-MANIFEST.json':continue
  if path.name.endswith(('.stdout.log','.stderr.log','.apk','.aab','.keystore','.jks','.log')):continue
  if path.name.startswith('.env') and path.name!='.env.example':continue
  if path.name in {'CHECKPOINT.txt','Thumbs.db','.DS_Store','local.properties'}:continue
  files.append(row(path))
 aar=[entry for entry in files if entry['path'].endswith('.aar')]
 if not any('/admob/' in entry['path'] for entry in aar) or not any('/GodotPlayGameServices/' in entry['path'] for entry in aar):
  raise ValueError('Required native plugin AAR distribution files missing')
 save(ROOT/'docs/SOURCE-MANIFEST.json',{'schema':1,'game':'Beacon Breakwater','files':files,
  'scope':'Intended portable source, assets, store art, tests and required native plugin distribution. Excludes only listed caches/export/runtime-evidence files and this manifest itself.',
  'excluded_directories':sorted(SKIP|{'tests/evidence'}),'required_native_aars':aar,
  'source_changed_by_manifest_generation':False})
 print(json.dumps({'source_files':len(files),'notice_files':len(notices),'native_aars':len(aar),
  'source_manifest_sha256':sha(ROOT/'docs/SOURCE-MANIFEST.json'),'license_manifest_sha256':sha(ROOT/'LICENSES/MANIFEST.json')}))
if __name__=='__main__':main()
