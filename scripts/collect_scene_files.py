#!/usr/bin/env python3
"""Collect actual SpriteKit frames saved by simulator screenshot tests."""
from pathlib import Path
import shutil

destination = Path('native-scene-review') / 'rendered-scenes'
destination.mkdir(parents=True, exist_ok=True)
devices = Path.home() / 'Library/Developer/CoreSimulator/Devices'
for source in devices.glob('*/data/Containers/Data/Application/*/Documents/NativeSceneReview/*.png'):
    shutil.copy2(source, destination / source.name)
if not any(destination.glob('*.png')):
    raise SystemExit('No rendered scene files were collected from the simulator')
