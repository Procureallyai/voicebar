# Dependency License Review

## Purpose

This note records a public-safe dependency license review for the software bill of materials packages previously flagged for manual license verification.

This is not legal advice. Treat the review as a maintainer preparation aid, and keep the final public release subject to operator approval and any required legal review.

## Summary

No copyleft license was detected in the reviewed dependency set. The detected licenses are Massachusetts Institute of Technology (MIT) License, Apache License 2.0, or Apache License 2.0 with Swift Runtime Library Exception.

Prompt 054 completed the upstream license and notice inspection for the exact revisions pinned in `Package.resolved`. `THIRD_PARTY_NOTICES.md` now records package names, versions, revisions, source links, detected licenses, upstream notice-file status, preservation requirements, and public-release posture.

Public release still requires operator approval and a scan of the exact public-facing repository or clean public fork. The private working repository should not be made public directly.

## Reviewed Packages

| Package | Version | Revision | Detected License | Source | Public Release Posture | Further Legal Review |
| --- | --- | --- | --- | --- | --- | --- |
| `argmax-oss-swift` | `0.18.0` | `e2adabbe7d98dc4d0ab9a5b75424ecc42a9cdbef` | Massachusetts Institute of Technology (MIT) License | <https://github.com/argmaxinc/argmax-oss-swift/tree/e2adabbe7d98dc4d0ab9a5b75424ecc42a9cdbef> | Acceptable as a permissive dependency if the notice text stays preserved in `THIRD_PARTY_NOTICES.md`. | Complete for current pinned revision. |
| `swift-argument-parser` | `1.7.1` | `626b5b7b2f45e1b0b1c6f4a309296d1d21d7311b` | Apache License 2.0 with Swift Runtime Library Exception | <https://github.com/apple/swift-argument-parser/tree/626b5b7b2f45e1b0b1c6f4a309296d1d21d7311b> | Acceptable as a permissive dependency if license attribution stays preserved in `THIRD_PARTY_NOTICES.md`. | Complete for current pinned revision. |
| `swift-asn1` | `1.7.0` | `eb50cbd14606a9161cbc5d452f18797c90ef0bab` | Apache License 2.0 with upstream `NOTICE.txt` | <https://github.com/apple/swift-asn1/tree/eb50cbd14606a9161cbc5d452f18797c90ef0bab> | Acceptable as a permissive dependency if license and notice text stay preserved in `THIRD_PARTY_NOTICES.md`. | Complete for current pinned revision. |
| `swift-collections` | `1.4.1` | `6675bc0ff86e61436e615df6fc5174e043e57924` | Apache License 2.0 with Swift Runtime Library Exception | <https://github.com/apple/swift-collections/tree/6675bc0ff86e61436e615df6fc5174e043e57924> | Acceptable as a permissive dependency if license attribution stays preserved in `THIRD_PARTY_NOTICES.md`. | Complete for current pinned revision. |
| `swift-crypto` | `4.4.0` | `476538ccb827f2dd18efc5de754cc87d77127a47` | Apache License 2.0 with upstream `NOTICE.txt` | <https://github.com/apple/swift-crypto/tree/476538ccb827f2dd18efc5de754cc87d77127a47> | Acceptable as a permissive dependency if license and notice text stay preserved in `THIRD_PARTY_NOTICES.md`. | Complete for current pinned revision. |
| `swift-jinja` | `2.3.5` | `0aeefadec459ce8e11a333769950fb86183aca43` | Apache License 2.0 | <https://github.com/huggingface/swift-jinja/tree/0aeefadec459ce8e11a333769950fb86183aca43> | Acceptable as a permissive dependency if license attribution stays preserved in `THIRD_PARTY_NOTICES.md`. | Complete for current pinned revision. |
| `swift-transformers` | `1.1.9` | `150169bfba0889c229a2ce7494cf8949f18e6906` | Apache License 2.0 | <https://github.com/huggingface/swift-transformers/tree/150169bfba0889c229a2ce7494cf8949f18e6906> | Acceptable as a permissive dependency if license attribution stays preserved in `THIRD_PARTY_NOTICES.md`. | Complete for current pinned revision. |
| `yyjson` | `0.12.0` | `8b4a38dc994a110abaec8a400615567bd996105f` | Massachusetts Institute of Technology (MIT) License | <https://github.com/ibireme/yyjson/tree/8b4a38dc994a110abaec8a400615567bd996105f> | Acceptable as a permissive dependency if the notice text stays preserved in `THIRD_PARTY_NOTICES.md`. | Complete for current pinned revision. |

## Prompt 053 Notice Preparation

Prompt 053 added a preliminary `THIRD_PARTY_NOTICES.md` inventory based on this review and `Package.resolved`.

The notice inventory is intentionally marked partial because this lane did not inspect every upstream license and notice file at the exact pinned revision. Do not treat the notices as final until that review is complete.

## Prompt 054 Notice Completion

Prompt 054 inspected the exact resolved checkouts under `.build/checkouts` and verified the pinned revisions matched `Package.resolved`.

Results:

- `argmax-oss-swift`, `swift-jinja`, `swift-transformers`, and `yyjson` include license files and no separate upstream notice file in the resolved checkout.
- `swift-argument-parser` and `swift-collections` include Apache License 2.0 license files with the Swift Runtime Library Exception and no separate upstream notice file in the resolved checkout.
- `swift-asn1` and `swift-crypto` include upstream `NOTICE.txt` files, and `THIRD_PARTY_NOTICES.md` now preserves their full upstream notice text.
- External local runtimes and model files remain separately licensed artifacts; this repository must not imply redistribution rights for them unless verified.

## Follow-Up Before Public Release

- Re-run `THIRD_PARTY_NOTICES.md` review before publication if dependencies change.
- Re-run dependency review after dependency bumps.
- Keep Apache License 2.0 as the current project license direction unless the maintainer explicitly changes it.
- Scan the exact public-facing repository or clean public fork before publication.
