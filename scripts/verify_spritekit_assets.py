#!/usr/bin/env python3
"""Fail fast when a literal native SpriteKit image reference has no bundled asset.

This intentionally covers *static* texture names, not dynamically assembled
names or images that are downloaded. The production app stays fully offline.
"""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
# Keep this narrower than a general Swift string scanner: unqualified Image()
# can represent SF symbols or other intentional non-catalog sources.
STATIC_IMAGES = re.compile(
    r'\b(?:ArtSystem\.)?(?:texture|sprite|retinaEnhancedTexture)\(\s*"([^"]+)"'
    r'|\bUIImage\(\s*named:\s*"([^"]+)"'
    r'|\bSKTexture\(\s*imageNamed:\s*"([^"]+)"'
)


def bundled_image_names(root: Path) -> set[str]:
    resources = root / "ValkyrieLearn" / "Resources"
    catalog = resources / "AdventureArt.xcassets"
    images = {
        path.name.removesuffix(".imageset")
        for path in catalog.rglob("*.imageset")
        if (path / "Contents.json").is_file()
    }
    # These loose resources are explicitly copied by the Xcode project.
    for extension in ("png", "jpg", "jpeg", "webp"):
        images.update(path.stem for path in resources.glob(f"*.{extension}"))
    return images


def direct_references(swift: str):
    for match in STATIC_IMAGES.finditer(swift):
        yield (next(value for value in match.groups() if value is not None),
               swift.count("\n", 0, match.start()) + 1)


def audit(root: Path) -> tuple[int, list[str]]:
    known_images = bundled_image_names(root)
    assert known_images, "No bundled image assets found; cannot verify image lookups."
    game = root / "ValkyrieLearn" / "Game"
    hits = 0
    missing = []
    for source in sorted(game.rglob("*.swift")):
        for name, line in direct_references(source.read_text(encoding="utf-8")):
            hits += 1
            if name not in known_images:
                missing.append(
                    f"{source.relative_to(root)}:{line}: missing bundled image {name!r}"
                )
    assert hits > 0, "Found no native static image calls; inspect the scanner."
    return hits, missing


if __name__ == "__main__":
    count, problems = audit(ROOT)
    if problems:
        print("\n".join(problems))
        raise SystemExit(f"FAIL: {len(problems)} missing static image references.")
    print(f"PASS: {count} static SpriteKit image references resolve to bundled assets.")
