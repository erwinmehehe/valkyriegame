#!/usr/bin/env python3
"""Prepare approved v3.31 source art for native rendering; requires Pillow.

Usage: python3 scripts/import_v331_art.py --source-zip /path/to/Word-Garden-RC.zip
The reference archive stays external. No generated/replacement character art.
"""
import argparse, hashlib, io, json, zipfile
from collections import deque
from pathlib import Path
from PIL import Image, ImageFilter, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
RESOURCES = ROOT / 'ValkyrieLearn/Resources'
parser = argparse.ArgumentParser()
parser.add_argument('--source-zip', required=True, type=Path)
args = parser.parse_args()
archive = zipfile.ZipFile(args.source_zip)
prefix = next(n[:-len('preview/adventure-art/worlds.png')] for n in archive.namelist() if n.endswith('preview/adventure-art/worlds.png'))
manifest = {'reference': args.source_zip.name, 'archiveSHA256': hashlib.sha256(args.source_zip.read_bytes()).hexdigest(), 'sources': {}, 'outputs': {}}

def source(name):
    data = archive.read(prefix + 'preview/' + name)
    manifest['sources'][name] = hashlib.sha256(data).hexdigest()
    return Image.open(io.BytesIO(data)).convert('RGBA')

def output(image, name):
    path = RESOURCES / name
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(path.stem + ".tmp" + path.suffix)
    if path.suffix == ".jpg": image.convert("RGB").save(temporary, quality=92, subsampling=2, optimize=True)
    else: image.save(temporary, optimize=True)
    temporary.replace(path)
    manifest['outputs'][name] = {'sha256': hashlib.sha256(path.read_bytes()).hexdigest(), 'size': list(image.size)}

def asset(image, name, extension="png"):
    filename = "art." + extension
    output(image, 'AdventureArt.xcassets/' + name + '.imageset/' + filename)
    path = RESOURCES / 'AdventureArt.xcassets' / (name + '.imageset/Contents.json')
    path.write_text(json.dumps({'images': [{'filename': filename, 'idiom': 'universal'}], 'info': {'author': 'xcode', 'version': 1}}, indent=2) + '\n')

# Preserve the full overworld and isolate exactly the math quadrant (omit grid seams).
overworld = source('adventure-art/overworld.png')
asset(overworld.resize((1280, 720), Image.Resampling.LANCZOS), 'StarlightIsles', 'jpg')
worlds = source('adventure-art/worlds.png')
asset(worlds.crop((838, 0, 1672, 469)).resize((1280, 720), Image.Resampling.LANCZOS), 'MathCastle', 'jpg')
# Extend the painted foreground courtyard into a usable native stage, with a
# feathered upper edge. This replaces flat gray platforms over the chasm.
math = worlds.crop((838, 0, 1672, 469)).resize((1280,720), Image.Resampling.LANCZOS)
floor = math.crop((150,600,1130,720)).resize((1280,250), Image.Resampling.LANCZOS)
mask = Image.new('L',floor.size)
mask.putdata([round(255*min(1,y/70)) for y in range(250) for x in range(1280)])
floor.putalpha(mask)
asset(floor,'CastleCourtyard')


# Matched canvases and one shared scale retain silhouette size and foot position.
poses = source('adventure-art/valkyrie-poses.png')
garden = source('adventure-art/valkyrie-garden-actions.png')
def character_frame(image):
    bounds = image.getchannel('A').point(lambda a: 255 if a >= 32 else 0).getbbox()
    image = image.crop(bounds)
    image = image.resize((round(image.width * .55), round(image.height * .55)), Image.Resampling.LANCZOS)
    canvas = Image.new('RGBA', (370, 480))
    canvas.alpha_composite(image, ((370-image.width)//2, 480-image.height))
    return canvas
idle = character_frame(poses.crop((0, 0, 591, 887)))
walk1 = character_frame(garden.crop((0, 0, 591, 887)))
walk2 = character_frame(garden.crop((591, 0, 1182, 887)))
reach = character_frame(garden.crop((1182, 0, 1774, 887)))
for name, image in [('idle_01',idle), ('walk_01',walk1), ('walk_02',walk2), ('interact_01',reach), ('celebrate_01',idle), ('react_01',idle)]:
    output(image, 'Valkyrie.atlas/' + name + '.png')

# Pip is no longer generated from the v3.31 archive. Production companion art is
# managed independently by COMPANION_ART_MANIFEST.json so rerunning this importer
# cannot overwrite the approved HD mascot with the historical penguin artwork.

props = source('adventure-art/props.png')
for name, box in [('CrystalCart',(512,0,1024,512)), ('Crystal',(1024,512,1536,1024)), ('StoryBloom',(0,0,512,512))]:
    image = props.crop(box)
    bounds = image.getchannel('A').point(lambda a: 255 if a >= 32 else 0).getbbox()
    image = image.crop(bounds); image.thumbnail((512,512), Image.Resampling.LANCZOS)
    asset(image, name)

# Separate corner occluders preserve source pixels with a feathered alpha only.
for world, image in [('Isles',overworld.resize((1280,720),Image.Resampling.LANCZOS)), ('Castle',worlds.crop((838,0,1672,469)).resize((1280,720),Image.Resampling.LANCZOS))]:
    for side,box in [('Left',(0,560,150,720)), ('Right',(1130,560,1280,720))]:
        corner = image.crop(box); mask = Image.new('L',corner.size); values = []
        for y in range(corner.height):
            for x in range(corner.width):
                distance = x if side == 'Left' else corner.width-1-x
                values.append(round(255 * min(1,(corner.width-distance)/45) * min(1,y/35)))
        mask.putdata(values); corner.putalpha(mask)
        asset(corner, world + 'Foreground' + side)
(RESOURCES / 'AdventureArt.xcassets/Contents.json').write_text(json.dumps({'info':{'author':'xcode','version':1}},indent=2)+'\n')
(RESOURCES / 'V331_ART_MANIFEST.json').write_text(json.dumps(manifest, indent=2)+'\n')
print('Prepared', len(manifest['outputs']), 'native images from existing v3.31 sources.')
