# Playable adaptive Math Castle integration

This pass connects the native mechanics and hidden placement foundation to the existing iPad adventure. It does not claim completion of Milestone A.

## Implemented

- `MathAdventure` is a plain-Swift, Codable execution state shared by the game and persistence. It selects again after each completed response, carries actual session-lane counts, honors elapsed-time/count-based exploration boundaries and preserves unfinished/finished work until an explicit Next action.
- Hidden placement uses only probes supported by the current runtime: quantity, quick-look subitizing, comparison, addition, number bonds and missing addends. Future subtraction, place-value and error-analysis probes are excluded from this playable sequence. Placement recommendations remain separate from mastery and do not bypass practice prerequisites.
- Math Castle presents one physical machine at a time, with Valkyrie approach/engagement, Pip reactions, a lever, exploration gear and five unscored workshop stations. Crystal/bond/light objects support tap and drag; scale pans/equal gear and bridge number controls route through the same learning runtime.
- Quick-look reference timing begins at engagement, not room entry. Help can replay it with recorded assistance. Returning after the preview has expired does not silently restart an independent probe.
- Correct/incorrect attempts and support flow through the existing MasteryEngine. Workshop activities remain unscored and cannot replace unfinished scored work.
- Profile, active runtime, placement session, interaction status, exploration boundary and session-lane history save together in the existing SwiftData V1 store. `cartData` now carries a versioned JSON envelope. Legacy cart JSON is read compatibly, preserving quantities, attempts, support and completion. Unknown envelopes fail without reset.
- Returning home or relaunching preserves a solved object until Next, preventing repeated evidence or silent advancement. World/settings restoration remains intact. Character positions reset to the room entrance on scene recreation.

## Validation

- Local Swift 6.0.3 core suite: 53 tests, zero failures.
- Static native project generation/reference checks and `git diff --check`: passed.
- Native hosted tests added for five runtime saves, legacy upgrade, placement completion/idempotence, unsupported versions, live-scene approach/tap routing, and hidden-reference input gating.
- Xcode/iPad Simulator CI verification is pending at initial publication. The PR records the verified head and result once complete.

## Mac and device verification

```sh
python3 scripts/validate_native.py
swift test
xcodebuild test -project ValkyrieLearn.xcodeproj -scheme ValkyrieLearn \
  -destination 'platform=iOS Simulator,name=iPad Pro 11-inch (M4)' \
  CODE_SIGNING_ALLOWED=NO
```

Choose an installed iPad Simulator if that device name is unavailable. For a physical iPad, configure a signing team, select the iPad destination and run the shared ValkyrieLearn scheme.

On device, verify movement, drag/tap alternatives, each workshop, quick-look timing, settings/background transitions, force-quit restoration, audio and touch readability. Physical iPad usability, disk persistence across process termination, performance and final production art have not been accepted by this pass.

## Next milestone

Strengthen scaffolding/alternate representations and delayed review, then add the optional prerequisite-safe Challenge Gate. Do not expand worlds or claim a complete curriculum or completed Milestone A yet.
