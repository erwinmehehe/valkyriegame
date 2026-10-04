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
manifest = json.loads((ROOT/'ValkyrieLearn/Resources/V331_ART_MANIFEST.json').read_text())
for name, metadata in manifest['outputs'].items():
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
print('PASS approved art hashes, dimensions and required atlas poses.')
