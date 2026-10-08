# Science Lab artwork review — PR #119

**Decision:** The candidate Greenhouse and Creature Grove PDFs are valid, independent 4:3 vector assets, but the October 8 iPad Simulator comparison showed they are visually **flatter and less detailed** than the currently approved painterly worlds. That is not a production-art improvement.

## Safe implementation

- The approved painterly Science Lab backdrop stays **on by default** in both Greenhouse and Creature Grove.
- The candidate PDF vector art remains packaged but is **review-only**. Set `scene.useCandidateVectorArtwork = true` before the scene is presented to preview the proposal (only in internal tooling/tests).
- CI verifies the shipped default and the explicit candidate render independently. It is a failure if a candidate is silently promoted or fails to decode.
- The same creature/learner actors, science props, touch targets, voice/text instructions, and progression logic remain unchanged.
- `scripts/validate_native.py` checks the manifest's review-only status and both scenes' default-off switches.

## Before-and-after iPad screenshots

The native art test captures **four actual SpriteKit frames on a 1024×768 simulator view**, producing files with these names in the `native-scene-preview` artifact:

- `Science-Art-Review-Approved-Greenhouse-4x3`
- `Science-Art-Review-Candidate-Greenhouse-4x3`
- `Science-Art-Review-Approved-CreatureGrove-4x3`
- `Science-Art-Review-Candidate-CreatureGrove-4x3`

The captures are built from real scene objects, not composed marketing mockups. Download the latest **Native foundation → native-scene-preview** artifact from [GitHub Actions](https://github.com/erwinmehehe/valkyriegame/actions/workflows/native.yml) and compare those four images.

The prior rendered **16:9** before/after comparisons were reviewed from simulator artifacts for PR #115 and PR #119; these show a substantial loss of lighting, blossoms, depth, waterfalls and environmental identity in the candidate vectors.

## Art acceptance criteria before changing the default

1. Commission or produce **two original, dedicated painterly artworks** for Greenhouse and Creature Grove at 4:3 Retina target (at least 2560×1920). Do not upscale or crop an unrelated atlas and claim it is original high-definition art.
2. Preserve the approved colorful fairy-tale visual language: detailed foliage, dimensional environment, coherent light, playable lower-center lane and recognizable individual room silhouettes.
3. Compare the proposed art directly against the approved scene at 16:9 **and** 4:3, not against a blank scene.
4. Confirm Valkyrie, Milo, interactive stations, hit testing, on-screen instructional text, Reduce Motion and offline support stay unchanged.
5. Obtain explicit owner visual sign-off and physical-iPad acceptance before changing `useCandidateVectorArtwork` from false or removing the review flag.

**Do not use passing compiler, geometry or bitmap-resolution tests as a substitute for visual art review.** The current vector candidates remain a review resource only.
