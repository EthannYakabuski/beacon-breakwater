"""Build authored content and code-drawn store art. No gameplay screenshot is generated.

Usage: python tools/build_content.py --assets-root <supplied Kenney asset folder>
The source project contains copies and notices, so normal build/play needs no pack path.
"""
import argparse, hashlib, json, math, shutil, struct, wave
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

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
 path.write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8')

def content():
 missions=[]
 for coast,(name,tag,brief,tide,storm,reefs) in enumerate(COASTS):
  for phrase,pattern in enumerate(PATTERNS):
   fleet=list(pattern)
   if coast>0:
    fleet += [('skiff' if coast<3 else 'cutter',170),('sailor' if coast<4 else 'rescue',390)] * (1+coast//3)
   gap=4.0 if coast==0 and phrase<2 else 3.8-coast*.16
   spawns=[{'time':round(.7+i*gap,2),'kind':kind,'x':x,'drift':[-4,3,0,6,-2][i%5]}
           for i,(kind,x) in enumerate(fleet)]
   special='rescue' if phrase==3 and coast>0 else 'cargo' if phrase in (2,4) else ''
   missions.append({'id':len(missions),'name':NAMES[coast][phrase],'coast':coast,'coast_name':name,
    'tagline':tag,'briefing':brief,'tutorial':len(missions)<2,'target':len(fleet)-(0 if len(missions)<2 else 1),
    'required_kind':special,'required_count':1 if special else 0,'tide':tide,'storm':storm,
    'fog':[0,0,.1,0,.6,.25][coast],
    'reefs':reefs,'lives':3,'duration':round(spawns[-1]['time']+32,2),'spawns':spawns})
 write_json(ROOT/'game/missions.json',{'schema':1,'coasts':[{'name':c[0],'tagline':c[1]} for c in COASTS],'missions':missions})
 write_json(ROOT/'game/catalog.json',{'schema':1,'achievements':[{'key':k,'title':title,'description':desc,
  'metric':metric,'target':target,'icon':'marketing/achievements/'+k+'.png'} for k,title,desc,metric,target in ACHIEVEMENTS],
  'leaderboards':[{'key':k,'title':title,'metric':metric,'icon':'marketing/leaderboards/'+k+'.png'} for k,title,metric in BOARDS]})
 config=json.loads((ROOT/'platform/config.json').read_text(encoding='utf-8-sig'))
 config['play_games']={'enabled':False,'game_id':'','achievements':{a[0]:'' for a in ACHIEVEMENTS},'leaderboards':{b[0]:'' for b in BOARDS}}
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
 write_json(ROOT/'assets/ASSET-MANIFEST.json',{'schema':1,'copied_assets':manifest,'originals':'Lighthouse/coast/beam/weather/UI/store vector/code art; synthesized ambient audio; Apache-2.0 original project work.'})
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

def font(size,bold=True):
 options=[Path('C:/Windows/Fonts/seguisb.ttf' if bold else 'C:/Windows/Fonts/segoeui.ttf'),Path('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf')]
 for path in options:
  if path.is_file():return ImageFont.truetype(str(path),size)
 return ImageFont.load_default(size=size)

def emblem(size,index=0):
 im=Image.new('RGB',(size,size),'#0a2334');d=ImageDraw.Draw(im)
 for y in range(size):
  t=y/size;d.line((0,y,size,y),fill=(int(10+8*t),int(35+34*t),int(52+37*t)))
 s=size/512
 def pts(values):return [(int(x*s),int(y*s)) for x,y in values]
 d.polygon(pts([(259,126),(38,65),(34,289),(259,150),(490,263),(490,58)]),fill='#f3c66c')
 d.ellipse((180*s,358*s,350*s,455*s),fill='#386963')
 d.polygon(pts([(232,410),(284,410),(273,153),(245,153)]),fill='#f6edd2')
 d.polygon(pts([(232,338),(280,338),(278,299),(236,299)]),fill='#da7564')
 d.rectangle((232*s,121*s,284*s,165*s),fill='#f7d67d')
 d.polygon(pts([(222,122),(294,122),(258,96)]),fill='#ec8c6c')
 for y in [438,468,491]:d.arc((22*s,(y-35)*s,492*s,(y+28)*s),0,180,fill='#70c8c1',width=max(1,int(5*s)))
 if index:
  d.ellipse((356*s,344*s,485*s,473*s),fill='#f3c66c')
  text=str(index);f=font(int(61*s));box=d.textbbox((0,0),text,font=f)
  d.text(((420*s)-(box[2]-box[0])/2,361*s),text,font=f,fill='#112f3f')
 return im

def art():
 icon=emblem(512);(ROOT/'marketing').mkdir(exist_ok=True)
 icon.save(ROOT/'platform/app-icon-512.png');icon.save(ROOT/'marketing/app-icon-512.png')
 for size in [48,72,96,144,192]:
  emblem(size).save(ROOT/f'platform/launcher-{size}.png')
 for i,(key,*_) in enumerate(ACHIEVEMENTS,1):
  path=ROOT/'marketing/achievements'/f'{key}.png';path.parent.mkdir(parents=True,exist_ok=True);emblem(256,i).save(path)
 for i,(key,*_) in enumerate(BOARDS,1):
  path=ROOT/'marketing/leaderboards'/f'{key}.png';path.parent.mkdir(parents=True,exist_ok=True);emblem(256,20+i).save(path)
 feature=Image.new('RGB',(1024,500),'#0a2334');d=ImageDraw.Draw(feature)
 for y in range(500):d.line((0,y,1024,y),fill=(10,int(35+y*.06),int(52+y*.06)))
 feature.paste(emblem(460),(540,20))
 d.text((48,75),'BEACON',font=font(66),fill='#fff2d6')
 d.text((48,144),'BREAKWATER',font=font(48),fill='#f3c66c')
 d.text((51,232),'Sweep a light.',font=font(34),fill='#8fdad3')
 d.text((51,279),'Save a fleet.',font=font(34),fill='#8fdad3')
 d.text((52,403),'A small lighthouse. A coast worth keeping.',font=font(21,False),fill='#f4ecd5')
 feature.save(ROOT/'marketing/feature-1024x500.png')
 (ROOT/'marketing/ART-SCOPE.txt').write_text('App/feature/achievement/leaderboard graphics are original code-drawn promotional illustrations.\nThey are not gameplay screenshots or native-device evidence.\nActual screenshots require normal implemented play and coordinator capture approval.\n',encoding='utf-8')

def main():
 parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--assets-root',type=Path,required=True);args=parser.parse_args()
 content();copied_assets(args.assets_root);art()
 print(json.dumps({'missions':30,'coasts':6,'achievements':len(ACHIEVEMENTS),'leaderboards':len(BOARDS),'fake_gameplay_screenshots_created':False}))
if __name__=='__main__':main()
