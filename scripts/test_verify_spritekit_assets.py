#!/usr/bin/env python3
"""Regression tests for native image reference linting."""
from pathlib import Path
from tempfile import TemporaryDirectory
import unittest

from verify_spritekit_assets import audit, bundled_image_names, direct_references


class NativeAssetReferenceTests(unittest.TestCase):
    def test_current_spritekit_references_resolve(self):
        repo_root = Path(__file__).resolve().parents[1]
        count, missing = audit(repo_root)
        self.assertGreaterEqual(count, 40)
        self.assertEqual(missing, [])

    def test_detects_missing_literal_but_ignores_dynamic_texture_name(self):
        with TemporaryDirectory() as directory:
            root = Path(directory)
            resources = root / "ValkyrieLearn" / "Resources"
            catalog = resources / "AdventureArt.xcassets"
            valid = catalog / "ApprovedPainting.imageset"
            valid.mkdir(parents=True)
            (valid / "Contents.json").write_text('{"images":[],"info":{}}')
            loose = resources / "Lumi.png"
            loose.write_bytes(b"placeholder")
            game = root / "ValkyrieLearn" / "Game"
            game.mkdir()
            (game / "Scene.swift").write_text(
                'ArtSystem.texture("ApprovedPainting")\n'
                'ArtSystem.sprite("Lumi", size: size)\n'
                'ArtSystem.texture(variableName)\n'
                'ArtSystem.texture("TypoPainting")\n'
            )
            self.assertIn("ApprovedPainting", bundled_image_names(root))
            self.assertIn("Lumi", bundled_image_names(root))
            count, missing = audit(root)
            self.assertEqual(count, 3)
            self.assertEqual(len(missing), 1)
            self.assertIn("TypoPainting", missing[0])
            self.assertIn("Scene.swift:4:", missing[0])

    def test_recognizes_supported_literal_loaders(self):
        sample = (
            'UIImage(named: "Backdrop")\n'
            'SKTexture(imageNamed: "Sparkle")\n'
            'retinaEnhancedTexture("Castle", targetPoints: size)\n'
            'ArtSystem.texture(variableName)\n'
        )
        self.assertEqual(
            list(direct_references(sample)),
            [("Backdrop", 1), ("Sparkle", 2), ("Castle", 3)]
        )


if __name__ == "__main__":
    unittest.main()
