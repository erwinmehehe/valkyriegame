#!/usr/bin/env python3
"""Regression checks for the no-character-redesign rule."""
import unittest

from verify_valkyrie_identity import verify_atlas, verify_pr_changes


class ValkyrieIdentityGuardTests(unittest.TestCase):
    def test_original_sprite_files_are_unchanged(self):
        self.assertEqual(verify_atlas(), [])

    def test_scene_and_environment_changes_are_allowed(self):
        self.assertEqual(verify_pr_changes([
            "ValkyrieLearn/Game/Scenes/ScienceLabScene.swift",
            "ValkyrieLearn/Resources/AdventureArt.xcassets/ScienceGreenhousePaintedHD.imageset/art.pdf",
            "ValkyrieLearn/Resources/SCIENCE_VECTOR_ART_MANIFEST.json",
        ]), [])

    def test_character_frames_are_never_changed_by_world_art_prs(self):
        self.assertTrue(verify_pr_changes([
            "ValkyrieLearn/Resources/Valkyrie.atlas/idle_01.png",
        ]))

    def test_character_renderer_and_provenance_need_separate_approval(self):
        for path in [
            "ValkyrieLearn/Game/Actors/ValkyrieNode.swift",
            "ValkyrieLearn/Game/Systems/ArtSystem.swift",
            "ValkyrieLearn/Resources/V331_ART_MANIFEST.json",
            "ValkyrieLearn/Resources/AdventureArt.xcassets/NewValkyrie.imageset/art.png",
        ]:
            with self.subTest(path=path):
                self.assertTrue(verify_pr_changes([path]))

if __name__ == "__main__":
    unittest.main()
