"""Build authored watch content and selected licensed runtime assets. No gameplay screenshot is generated.

Usage: python tools/build_content.py --assets-root <supplied Kenney asset folder>
The source project contains copies and notices, so normal build/play needs no pack path.
"""
import argparse, hashlib, json, math, re, shutil, struct, wave
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
COASTS = [
 ('Lantern Bay','A warm first light','Hold the beam on a boat until its ring fills.',0,0,[]),
 ('Tideglass Reach','The water leans east','A cross-current carries unescorted boats toward the shoals.',9,0,[[420,445,42]]),
 ('Rainneedle Rocks','Every gap matters','Use the horn when traffic reaches the marked shoals.',-8,.15,[[150,450,38],[387,555,42]]),
 ('Gale Sound','Listen for the weather','A storm surge arrives near the end of each fifteen-second cycle.',13,.65,[[390,420,35],[150,580,35]]),
 ('Mistward Shelf','Find the signal','Emergency boats need a steady beam before the others.',-13,.35,[[130,400,37],[405,480,40],[250,590,32]]),
 ('Northlight Cape','Bring everyone home','Mixed fleets, quick cutters and heavy barges share the final approach.',17,.8,[[120,455,34],[405,525,37],[215,625,27]]),
]
NAMES = [
 ['Your first light','Two on the tide','White sail welcome','A little convoy','Bay keeper'],
 ['Eastbound morning','Crossing glints','A loaded sail','Urgent passage','The glass run'],
 ['Needle channel','Three white wakes','Rock garden','Cargo at dusk','Rainproof watch'],
 ['First squall','Shelter call','Barge and breeze','The long gust','Sound of safety'],
 ['Soft horizon','Signal through mist','Priority passage','A narrow ribbon','Keeper in the fog'],
 ['Northern arrivals','Cutter chorus','Heavy seas','All hands home','The last warm light'],
]
# Six further Canadian Atlantic packs, each with authored traffic names/weather.
COASTS += [
 ('Fundy Narrows','Turn with the tide','Split your attention across the tidal crossing.',-22,.25,[[126,430,35],[410,565,42]]),
 ('Lunenburg Roads','A working waterfront','Heavy cargo needs a longer steady light.',8,.35,[[360,440,45],[175,570,35]]),
 ('Grand Manan','Islands in the rain','Catch the emergency launches between the islands.',-18,.55,[[110,370,32],[420,490,32],[245,605,26]]),
 ('Cabot Cliffs','The headland wind','Fast cutters cross a gusting approach.',24,.75,[[390,380,35],[145,520,38],[385,635,27]]),
 ('Northumberland','Blue-water lanterns','Dense fog rewards a wider lens and deliberate sweeps.',-16,.4,[[105,480,38],[432,535,38],[250,630,25]]),
 ('Signal Hill','The Atlantic relay','Read every vessel, keep reserves, and bring the relay home.',22,1.0,[[120,390,32],[425,455,37],[175,590,31],[370,630,25]])]
NAMES += [
 ['Fundy arrival','Two-way tide','The narrows convoy','Launch in the current','High-water keeper'],
 ['Wharf opening','Salt-box sails','Freight to the harbor','The working fleet','Last cargo bell'],
 ['Island welcome','Three misty wakes','Shelter between rocks','Manan lifeboats','Island night watch'],
 ['Cliffside signal','Cutters in the gale','Cargo under Cabot','Windward emergency','Cape relay'],
 ['Blue morning','Lantern through fog','Northumberland freight','A hidden sail','The clear-water line'],
 ['Signal arrival','The ocean chorus','Big ships home','All stations calling','The Atlantic light']]
# Explicit five traffic phrases, composed with authored coast/weather/goal changes.
PATTERNS = [
 [('skiff',260),('skiff',130),('sailor',405),('skiff',280)],
 [('skiff',100),('sailor',430),('skiff',275),('sailor',145),('skiff',370),('skiff',250)],
 [('sailor',95),('cargo',390),('skiff',260),('cutter',150),('sailor',430),('cargo',215),('skiff',350),('skiff',110)],
 [('rescue',270),('skiff',100),('sailor',420),('rescue',150),('cargo',340),('skiff',240),('cutter',450),('sailor',120),('skiff',330)],
 [('cargo',110),('sailor',420),('cutter',260),('skiff',360),('rescue',145),('barge',300),('skiff',440),('sailor',90),('rescue',385),('cargo',240)],
]
ACHIEVEMENTS = [
 ('first_rescue','One warm light','Guide your first boat home.','rescued',1),
 ('rescue25','Harbor friend','Bring twenty-five boats home.','rescued',25),
 ('rescue100','A hundred safe wakes','Bring one hundred boats home.','rescued',100),
 ('rescue500','Coastal legend','Bring five hundred boats home.','rescued',500),
 ('watch1','On watch','Finish your first natural watch.','watches',1),
 ('watch10','The steady keeper','Finish ten natural watches.','watches',10),
 ('perfect1','No one left behind','Finish a watch without losing a boat.','perfect_watches',1),
 ('perfect10','Ten clear horizons','Finish ten perfect watches.','perfect_watches',10),
 *[(f'coast{i}',name+' keeper','Clear all five watches on this coast.','coasts',i) for i,(name,*_) in enumerate(COASTS,1)],
 ('keeper3','Apprentice of the lens','Reach keeper level three.','keeper_level',3),
 ('keeper6','A practiced hand','Reach keeper level six.','keeper_level',6),
 ('keeper12','Master of the light','Reach keeper level twelve.','keeper_level',12),
 ('upgrade1','A brighter beginning','Buy your first equipment upgrade.','upgrades',1),
 ('upgrade8','Built for the coast','Buy eight equipment upgrades in total.','upgrades',8),
 ('daily3','Three different dawns','Complete daily watches on three different days.','daily_watches',3),
]
BOARDS = [('best_endless','Longest shining watch','best_endless'),('total_rescued','Boats brought home','rescued'),
          ('keeper_level','Keeper level','keeper_level'),('perfect_watches','Perfect watches','perfect_watches')]

def write_json(path,data):
 path.parent.mkdir(parents=True,exist_ok=True)
 path.write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8',newline='\n')

def content():
 missions=[]
 for coast,(name,tag,brief,tide,storm,reefs) in enumerate(COASTS):
  for phrase,pattern in enumerate(PATTERNS):
   fleet=list(pattern)
   if coast>0:
    fleet += [('skiff' if coast<3 else 'cutter',170),('sailor' if coast<4 else 'rescue',390)] * (1+coast//3)
   gap=4.0 if coast==0 and phrase<2 else max(3.45,3.8-coast*.06)
   spawns=[{'time':round(.7+i*gap,2),'kind':kind,'x':x,'drift':[-4,3,0,6,-2][i%5]}
           for i,(kind,x) in enumerate(fleet)]
   special='rescue' if phrase==3 and coast>0 else 'cargo' if phrase in (2,4) else ''
   missions.append({'id':len(missions),'name':NAMES[coast][phrase],'coast':coast,'coast_name':name,
    'tagline':tag,'briefing':brief,'tutorial':len(missions)<2,'target':len(fleet)-(0 if len(missions)<2 else 1),
    'required_kind':special,'required_count':1 if special else 0,'tide':tide,'storm':storm,
    'fog':[0,0,.1,0,.6,.25,.15,.1,.35,.2,.7,.4][coast],
    'reefs':reefs,'lives':3,'duration':round(spawns[-1]['time']+70,2),'spawns':spawns})
 write_json(ROOT/'game/missions.json',{'schema':1,'coasts':[{'name':c[0],'tagline':c[1]} for c in COASTS],'missions':missions})
 write_json(ROOT/'game/catalog.json',{'schema':1,'achievements':[{'key':k,'title':title,'description':desc,
  'metric':metric,'target':target,'icon':'marketing/achievements/'+k+'.png'} for k,title,desc,metric,target in ACHIEVEMENTS],
  'leaderboards':[{'key':k,'title':title,'metric':metric,'icon':'marketing/leaderboards/'+k+'.png'} for k,title,metric in BOARDS]})
 config=json.loads((ROOT/'platform/config.json').read_text(encoding='utf-8-sig'))
 pgs=config.setdefault('play_games',{'enabled':False,'game_id':''})
 pgs.setdefault('achievements',{})
 pgs.setdefault('leaderboards',{})
 for item in ACHIEVEMENTS: pgs['achievements'].setdefault(item[0],'')
 for item in BOARDS: pgs['leaderboards'].setdefault(item[0],'')
 write_json(ROOT/'platform/config.json',config)

def copied_assets(packroot):
 mappings={'skiff':'dinghySmall1.png','sailor':'ship (1).png','cargo':'ship (13).png',
           'rescue':'ship (9).png','cutter':'dinghyLarge2.png','barge':'ship (19).png'}
 manifest=[]
 def copy(source,target):
  dest=ROOT/target;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(source,dest)
  manifest.append({'source':source.relative_to(packroot).as_posix(),'destination':target,
                   'sha256':hashlib.sha256(dest.read_bytes()).hexdigest(),'license':'CC0-1.0'})
 for key,name in mappings.items():copy(packroot/'kenney_pirate-pack/PNG/Retina/Ships'/name,'assets/ships/'+key+'.png')
 for key,name in [('click','click2.ogg'),('rescue','rollover1.ogg'),('warning','mouseclick1.ogg'),('finish','click5.ogg')]:
  copy(packroot/'kenney_ui-audio/Audio'/name,'assets/audio/'+key+'.ogg')
 for folder in ['kenney_pirate-pack','kenney_ui-audio']:
  copy(packroot/folder/'License.txt','assets/licenses/'+folder+'-CC0.txt')
 write_json(ROOT/'assets/ASSET-MANIFEST.json',{'schema':1,'copied_assets':manifest,'originals':'Apache-2.0 original code/content, composed thirteen 16-bar musical scores and generated harbor/lighthouse/shoal/app/feature illustrations; separate provenance files retain source images and hashes. Earlier badge art remains pending replacement.'})
 (ROOT/'assets/ASSET-NOTICES.txt').write_text('Kenney Pirate Pack and UI SFX Set by Kenney (www.kenney.nl), CC0-1.0.\nExact supplied notices are in assets/licenses. No Creature Mixer content is used.\nOriginal code-drawn lighthouse/coast/UI/marketing art and synthesized ambient audio: Apache-2.0.\n',encoding='utf-8')
 assets_license=ROOT/'LICENSES/Assets'
 assets_license.mkdir(parents=True,exist_ok=True)
 for source in (ROOT/'assets/licenses').glob('*.txt'):shutil.copyfile(source,assets_license/source.name)
 shutil.copyfile(ROOT/'assets/ASSET-NOTICES.txt',assets_license/'ASSET-NOTICES.txt')
 # A gentle original three-note tide loop; exact PCM source, no sampled recording.
 with wave.open(str(ROOT/'assets/audio/tide.wav'),'wb') as out:
  out.setnchannels(1);out.setsampwidth(2);out.setframerate(22050)
  samples=[]
  for i in range(22050*8):
   t=i/22050;envelope=math.sin(math.pi*t/8)**2
   value=sum(math.sin(2*math.pi*f*t) for f in [130.8128,196,261.6256])/3
   samples.append(struct.pack('<h',int(value*envelope*2800)))
  out.writeframes(b''.join(samples))


def round_two_assets(packroot):
 manifest=json.loads((ROOT/'assets/ASSET-MANIFEST.json').read_text())
 additions=[]
 def copy(source,target,pack):
  dest=ROOT/target;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(source,dest)
  additions.append({'source':source.relative_to(packroot).as_posix(),'destination':target,'sha256':hashlib.sha256(dest.read_bytes()).hexdigest(),'license':'CC0-1.0','pack':pack})
 for source,target in [('Yellow/Default/star.png','star-filled.png'),('Grey/Default/star_outline.png','star-empty.png')]:
  copy(packroot/'kenney_ui-pack/PNG'/source,'assets/ui/'+target,'Kenney UI Pack2.0')
 # Kenney's raster named outline has a filled center. Retain its vector and
 # derive the existing outer silhouette as a genuine hollow empty-state asset.
 vector=packroot/'kenney_ui-pack/Vector/Grey/star_outline.svg'
 source=vector.read_text(encoding='utf-8')
 original=ROOT/'assets/ui/kenney-star-outline-source.svg'
 original.write_text(source,encoding='utf-8',newline='\n')
 silhouette=re.findall(r'<path[^>]* d="([^"]+)"',source)[0].split(' M')[0]
 (ROOT/'assets/ui/star-empty.svg').write_text('<svg width="64" height="60" viewBox="-3 -3 70 66" xmlns="http://www.w3.org/2000/svg"><path d="'+silhouette+' Z" fill="none" stroke="#A9C8CB" stroke-width="4" stroke-linejoin="round"/></svg>\n',encoding='utf-8',newline='\n')
 additions.append({'source':vector.relative_to(packroot).as_posix(),'destination':original.relative_to(ROOT).as_posix(),'sha256':hashlib.sha256(original.read_bytes()).hexdigest(),'source_sha256':hashlib.sha256(vector.read_bytes()).hexdigest(),'normalization':'UTF8 LF text; original geometry preserved','license':'CC0-1.0'})
 manifest['derived_assets']=[{'destination':'assets/ui/star-empty.svg','source':'assets/ui/kenney-star-outline-source.svg','change':'Existing rounded silhouette rendered as hollow stroke; earned Kenney texture unchanged.','license':'CC0-1.0'}]
 for key,name in [('guided','confirmation_002.ogg'),('arrival','drop_001.ogg'),('horn','bong_001.ogg'),('upgrade','confirmation_004.ogg'),('continue','confirmation_001.ogg'),('flare','confirmation_003.ogg'),('loss','error_002.ogg')]:
  copy(packroot/'kenney_interface-sounds/Audio'/name,'assets/audio/'+key+'.ogg','Kenney Interface Sounds')
 for pack in ['kenney_ui-pack','kenney_interface-sounds']:
  copy(packroot/pack/'License.txt','assets/licenses/'+pack+'-CC0.txt',pack)
  (ROOT/'LICENSES/Assets').mkdir(exist_ok=True)
  shutil.copyfile(packroot/pack/'License.txt',ROOT/'LICENSES/Assets'/(pack+'-CC0.txt'))
 old=[r for r in manifest.get('copied_assets',[]) if r['destination'] not in {a['destination'] for a in additions}]
 manifest['copied_assets']=old+additions
 manifest['round_two']='Kenney filled/empty stars and Interface Sounds selected after actual asset review. Marketing illustration has a separate art workflow; this script never generates promotional images.'
 write_json(ROOT/'assets/ASSET-MANIFEST.json',manifest)
 notes=ROOT/'assets/ASSET-NOTICES.txt'
 text=notes.read_text()
 if 'UI Pack2.0' not in text: notes.write_text(text+'Round Two: Kenney UI Pack2.0 stars and Interface Sounds, CC0-1.0; original notice texts preserved in assets/licenses and LICENSES/Assets.\n',encoding='utf-8')
 shutil.copyfile(notes,ROOT/'LICENSES/Assets/ASSET-NOTICES.txt')

def music():
 # Original composed 16-bar scores. No downloaded/sampled recording is used.
 import numpy as np
 sample_rate=22050
 definitions=[('menu',60,88),*[(f'coast-{i:02d}',[60,62,57,65,59,67,55,64,58,69,61,66][i],84+i*2) for i in range(12)]]
 records=[]
 for index,(name,root,bpm) in enumerate(definitions):
  beat=60.0/bpm;duration=64*beat;n=int(round(duration*sample_rate));waveform=np.zeros(n,dtype=np.float64)
  progression=[[0,5,7,0],[0,3,5,7],[0,7,5,3],[0,5,3,7]][index%4]
  scale=[0,2,3 if index%3==0 else 4,5,7,9,10 if index%3==0 else 11,12]
  melody=[0,2,4,2,1,3,4,6,4,3,2,0,1,4,3,2]
  def note(midi,start,length,amplitude,bright=False):
   a=int(start*sample_rate);count=min(int(length*sample_rate),n-a)
   if count<=0:return
   t=np.arange(count)/sample_rate;phase=2*np.pi*(440*2**((midi-69)/12))*t
   envelope=np.minimum(1,t/.025)*np.minimum(1,(count/sample_rate-t)/.10)
   tone=np.sin(phase)+(.25*np.sin(phase*2)+.10*np.sin(phase*3) if bright else .12*np.sin(phase*2))
   waveform[a:a+count]+=amplitude*envelope*tone*np.exp(-t/(length*(.5 if bright else 2.2)))
  for bar in range(16):
   chord=root+progression[(bar+index//4+bar//8)%4]
   for semitone in [0,3 if index%3==0 else 4,7]:note(chord+semitone,bar*4*beat,3.95*beat,.075)
   for pulse in range(4):note(chord-12+(7 if pulse%2 else 0),(bar*4+pulse)*beat,.8*beat,.08)
   for pulse in range(4):
    degree=melody[(bar*4+pulse+index*3+(2 if bar>=8 else 0))%len(melody)]
    note(root+12+scale[degree],(bar*4+pulse)*beat,beat*.78,.09,True)
  fade=int(sample_rate*.02);waveform[:fade]*=np.linspace(0,1,fade);waveform[-fade:]*=np.linspace(1,0,fade)
  waveform=np.clip(waveform*.65,-.95,.95);data=(waveform*32767).astype('<i2').tobytes()
  path=ROOT/'assets/audio'/('music-'+name+'.wav')
  with wave.open(str(path),'wb') as out:out.setnchannels(1);out.setsampwidth(2);out.setframerate(sample_rate);out.writeframes(data)
  records.append({'file':path.relative_to(ROOT).as_posix(),'bars':16,'bpm':bpm,'seconds':round(n/sample_rate,4),'sha256':hashlib.sha256(path.read_bytes()).hexdigest()})
 write_json(ROOT/'assets/audio/MUSIC-MANIFEST.json',{'license':'Apache-2.0 original composition','sample_rate':sample_rate,'tracks':records,'loop':'Runtime sets AudioStreamWAV whole-buffer loop; unique score per level pack and a separate menu arrangement.','audible_verification':'Not established by generation, waveform checks or headless tests.'})
 (ROOT/'assets/audio/MUSIC-CREDITS.txt').write_text('Beacon Breakwater Round Two: thirteen original 16-bar coastal scores, composed/synthesized by tools/build_content.py. Apache-2.0 original project work; no external sampled recording.\n',encoding='utf-8')

if __name__=='__main__':
 parser=argparse.ArgumentParser(description=__doc__)
 parser.add_argument('--assets-root',type=Path)
 parser.add_argument('--music',action='store_true')
 args=parser.parse_args()
 content()
 if args.assets_root: round_two_assets(args.assets_root)
 if args.music: music()
 print(json.dumps({'missions':60,'coasts':12,'achievements':len(ACHIEVEMENTS),'leaderboards':len(BOARDS),'marketing_art_generated':False}))
