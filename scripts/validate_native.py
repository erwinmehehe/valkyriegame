#!/usr/bin/env python3
"""Static project integrity checks. These do not replace Xcode or touch testing."""
from pathlib import Path
import hashlib, json, plistlib, re, struct, subprocess, xml.etree.ElementTree as ET
ROOT = Path(__file__).resolve().parents[1]
project = ROOT/'ValkyrieLearn.xcodeproj/project.pbxproj'
old = project.read_bytes()
subprocess.run(['python3',str(ROOT/'scripts/generate_xcode_project.py')],check=True,cwd=ROOT)
assert old == project.read_bytes(), 'Regenerate and commit the Xcode project after changing source membership.'
text = project.read_text()
assert '(,)' not in text, 'Malformed empty OpenStep array'
ids = set(re.findall(r'^([A-F0-9]{24}) = ',text,re.M))
for reference in re.findall(r'"([A-F0-9]{24})"',text): assert reference in ids, reference
for path in re.findall(r'path = "(ValkyrieLearn/[^"\n]+)"',text): assert (ROOT/path).exists(), path
plist = plistlib.loads((ROOT/'ValkyrieLearn/Resources/Info.plist').read_bytes())
assert plist['UIRequiresFullScreen']
assert set(plist['UISupportedInterfaceOrientations~ipad']) == {'UIInterfaceOrientationLandscapeLeft','UIInterfaceOrientationLandscapeRight'}
assert 'TARGETED_DEVICE_FAMILY = "2"' in text
assert 'IPHONEOS_DEPLOYMENT_TARGET = "17.0"' in text
assert 'relativePath = "."' in text
scheme = ET.parse(ROOT/'ValkyrieLearn.xcodeproj/xcshareddata/xcschemes/ValkyrieLearn.xcscheme')
assert {n.attrib['BlueprintName'] for n in scheme.findall('.//TestableReference/BuildableReference')} == {'LearningCoreTests','PersistenceTests'}
for p in (ROOT/'ValkyrieLearn/Learning').rglob('*.swift'):
 assert not re.search(r'import\s+(SpriteKit|SwiftUI|SwiftData|UIKit|AVFoundation)',p.read_text()), p
for p in (ROOT/'ValkyrieLearn').rglob('*.swift'):
 assert not re.search(r'(WKWebView|import WebKit|import JavaScriptCore)',p.read_text()), p
# Pinned prototype digest works in shallow CI clones too.
assert hashlib.sha256((ROOT/'index.html').read_bytes()).hexdigest() == '3ac15b0237acfd5a4e0bc55abe57ba84c46c2e24a66284088f84c0561e9f82fe'
print('PASS project references, deterministic generation, landscape/iPad configuration, framework separation and unchanged prototype.')

# Validate all imported image bytes and crop dimensions using only the standard library.
def git_blob_sha(data):
    return hashlib.sha1(b'blob ' + str(len(data)).encode() + b'\0' + data).hexdigest()

def image_dimensions(data, path):
    if path.endswith('.png'):
        assert data[:8] == b'\x89PNG\r\n\x1a\n', path
        return list(struct.unpack('>II', data[16:24]))
    if path.endswith('.webp'):
        assert data[:4] == b'RIFF' and data[8:12] == b'WEBP', path
        chunk = data[12:16]
        if chunk == b'VP8X':
            width = 1 + int.from_bytes(data[24:27], 'little')
            height = 1 + int.from_bytes(data[27:30], 'little')
            return [width, height]
        if chunk == b'VP8 ':
            marker = data.find(b'\x9d\x01\x2a', 20, 1024)
            assert marker >= 0, path
            width = int.from_bytes(data[marker+3:marker+5], 'little') & 0x3fff
            height = int.from_bytes(data[marker+5:marker+7], 'little') & 0x3fff
            return [width, height]
        if chunk == b'VP8L':
            b0,b1,b2,b3,b4 = data[20:25]
            assert b0 == 0x2f, path
            width = 1 + (((b2 & 0x3f) << 8) | b1)
            height = 1 + (((b4 & 0x0f) << 10) | (b3 << 2) | ((b2 & 0xc0) >> 6))
            return [width, height]
        raise AssertionError(path)
    raise AssertionError(path)

companion_hd = json.loads((ROOT/'ValkyrieLearn/Resources/COMPANION_HD_ART_MANIFEST.json').read_text())
legacy_superseded_companion_paths = {
    'ValkyrieLearn/Resources/Milo.webp',
    'ValkyrieLearn/Resources/Tiko.webp',
    'ValkyrieLearn/Resources/Lumi.webp',
}
superseded_companion_paths = set(companion_hd['assets']) | legacy_superseded_companion_paths
for path, metadata in companion_hd['assets'].items():
    data = (ROOT/path).read_bytes()
    assert git_blob_sha(data) == metadata['blobSHA'], path
    assert image_dimensions(data, path) == metadata['size'], path
# Original vector paintings are scene-only PDF assets. They render at Retina
# resolution on device; unlike raster resampling they retain source geometry.
science_art = json.loads((ROOT/'ValkyrieLearn/Resources/SCIENCE_VECTOR_ART_MANIFEST.json').read_text())
assert science_art['sourceCanvas'] == [1280, 960]
assert science_art['retinaTarget'] == [2560, 1920]
assert len(science_art['assets']) == 2
for path, metadata in science_art['assets'].items():
    raw = (ROOT/path).read_bytes()
    assert raw.startswith(b'%PDF-1.4'), path
    assert b'/MediaBox [0 0 1280 960]' in raw, path
    assert b'/Type /Page' in raw, path
    assert raw.rstrip().endswith(b'%%EOF'), path
    assert git_blob_sha(raw) == metadata['blobSHA'], path
    contents = json.loads((ROOT/path).with_name('Contents.json').read_text())
    assert contents['properties']['preserves-vector-representation'] is True, path
    assert contents['images'][0]['filename'] == 'art.pdf', path
print('PASS dedicated Science world vector PDF art hashes, canvas and asset-catalog packaging.')

print('PASS HD companion art hashes and dimensions.')

manifest = json.loads((ROOT/'ValkyrieLearn/Resources/V331_ART_MANIFEST.json').read_text())
for name, metadata in manifest['outputs'].items():
    if ('ValkyrieLearn/Resources/' + name) in superseded_companion_paths:
        continue
    data = (ROOT/'ValkyrieLearn/Resources'/name).read_bytes()
    assert hashlib.sha256(data).hexdigest() == metadata['sha256'], name
    if name.endswith('.png'):
        assert data[:8] == b'\x89PNG\r\n\x1a\n', name
        dimensions = list(struct.unpack('>II', data[16:24]))
    else:
        assert data[:2] == b'\xff\xd8', name
        offset = 2; dimensions = None
        while offset < len(data):
            assert data[offset] == 255, name
            marker = data[offset+1]; length = struct.unpack('>H', data[offset+2:offset+4])[0]
            if marker in (0xC0,0xC1,0xC2):
                height,width = struct.unpack('>HH', data[offset+5:offset+9]); dimensions = [width,height]; break
            offset += 2 + length
    assert dimensions == metadata['size'], name
for character in ['Valkyrie', 'Pip']:
    atlas = ROOT/'ValkyrieLearn/Resources'/(character+'.atlas')
    for pose in ['idle','walk','interact','celebrate','react']:
        assert list(atlas.glob(pose+'_*.png')), (character, pose)
# Identity lock: environmental art changes must never silently restyle Valkyrie.
# The signed-off original sprite pixels are pinned in the v3.31 manifest.
valkyrie_sprite_paths = {
    name for name in manifest['outputs']
    if name.startswith('Valkyrie.atlas/') and name.endswith('.png')
}
assert valkyrie_sprite_paths == {
    'Valkyrie.atlas/idle_01.png',
    'Valkyrie.atlas/walk_01.png',
    'Valkyrie.atlas/walk_02.png',
    'Valkyrie.atlas/interact_01.png',
    'Valkyrie.atlas/celebrate_01.png',
    'Valkyrie.atlas/react_01.png',
}
assert {
    path.name for path in (ROOT/'ValkyrieLearn/Resources/Valkyrie.atlas').glob('*.png')
} == {Path(name).name for name in valkyrie_sprite_paths}
for name in sorted(valkyrie_sprite_paths):
    actual = hashlib.sha256((ROOT/'ValkyrieLearn/Resources'/name).read_bytes()).hexdigest()
    assert actual == manifest['outputs'][name]['sha256'], (
        f'VALKYRIE IDENTITY LOCK: original sprite changed: {name}'
    )
print('PASS Valkyrie original sprite identities locked to approved hashes.')

print('PASS approved art hashes, dimensions and required atlas poses.')

# Generated bridge props remain separate from the approved v3.31 import.
bridge_art = json.loads((ROOT/'ValkyrieLearn/Resources/BRIDGE_ART_MANIFEST.json').read_text())
for name, metadata in bridge_art['outputs'].items():
    data = (ROOT/'ValkyrieLearn/Resources'/name).read_bytes()
    assert hashlib.sha256(data).hexdigest() == metadata['sha256'], name
    assert data[:8] == b'\x89PNG\r\n\x1a\n', name
    assert list(struct.unpack('>II', data[16:24])) == metadata['size'], name
print('PASS illustrated bridge prop hashes and crop dimensions.')

# Word Garden reference assets are preserved exact v3.31 embedded-source blobs.
word_garden_art = json.loads((ROOT/'ValkyrieLearn/Resources/WORD_GARDEN_ART_MANIFEST.json').read_text())
assert git_blob_sha((ROOT/'index.html').read_bytes()) == word_garden_art['sourceBlobSHA']
for path, metadata in word_garden_art['assets'].items():
    if path in superseded_companion_paths:
        continue
    data = (ROOT/path).read_bytes()
    assert git_blob_sha(data) == metadata['blobSHA'], path
print('PASS Word Garden v3.31 source-blob provenance.')

# Puzzle Palace reuses the preserved world atlas and imports Tiko from the same v3.31 blob.
puzzle_art = json.loads((ROOT/'ValkyrieLearn/Resources/PUZZLE_PALACE_ART_MANIFEST.json').read_text())
assert git_blob_sha((ROOT/'index.html').read_bytes()) == puzzle_art['sourceBlobSHA']
for path, metadata in puzzle_art['assets'].items():
    if path in superseded_companion_paths:
        continue
    data = (ROOT/path).read_bytes()
    assert git_blob_sha(data) == metadata['blobSHA'], path
print('PASS Puzzle Palace v3.31 source-blob provenance.')
garden_source = ROOT/'ValkyrieLearn/Resources/AdventureArt.xcassets/WordGardenSourceAtlas.imageset/art.png'
assert hashlib.sha256(garden_source.read_bytes()).hexdigest() == manifest['sources']['adventure-art/worlds.png']
print('PASS full-resolution Word Garden source matches approved original artwork.')

# Finished illustrations are versioned separately; never replace pinned reference art.
illustrated = json.loads((ROOT/'ValkyrieLearn/Resources/ILLUSTRATED_WORLD_ART_MANIFEST.json').read_text())
assert len(illustrated['assets']) == 13
for path, metadata in illustrated['assets'].items():
    data = (ROOT/path).read_bytes()
    assert hashlib.sha256(data).hexdigest() == metadata['sha256'], path
    assert data[:2] == b'\xff\xd8', path
    offset = 2; dimensions = None
    while offset < len(data):
        marker = data[offset+1]; length = struct.unpack('>H', data[offset+2:offset+4])[0]
        if marker in (0xC0, 0xC1, 0xC2):
            height, width = struct.unpack('>HH', data[offset+5:offset+9])
            dimensions = [width, height]; break
        offset += 2 + length
    assert dimensions == metadata['size'], path
    assert dimensions[0] > 1280 and dimensions[1] > 720, path
    contents = json.loads((ROOT/path).with_name('Contents.json').read_text())
    assert contents['images'][0]['filename'] == 'art.jpg', path
print('PASS 13 versioned illustrations, original source dimensions and hashes; no source enlargement.')
