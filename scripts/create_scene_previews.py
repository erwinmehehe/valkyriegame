#!/usr/bin/env python3
"""Create compact JPEG copies of simulator attachments for visual review on CI."""
from pathlib import Path
import shutil
import subprocess

source = Path('native-scene-review')
destination = Path('native-scene-preview')
if source.exists():
    destination.mkdir(exist_ok=True)
    for image in source.rglob('*.png'):
        output = destination / image.relative_to(source).with_suffix('.jpg')
        output.parent.mkdir(parents=True, exist_ok=True)
        subprocess.run([
            'sips', '-s', 'format', 'jpeg', '-s', 'formatOptions', '85',
            '-Z', '1280', str(image), '--out', str(output)
        ], check=True, stdout=subprocess.DEVNULL)
    for metadata in source.rglob('*.json'):
        output = destination / metadata.relative_to(source)
        output.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(metadata, output)
