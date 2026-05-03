# Third-Party Notices

## Status

This file records the third-party notice review for the current VoiceBar Swift Package Manager dependency set in `Package.resolved`.

This is not legal advice. It is a maintainer release-preparation record. Re-run this review before publication if dependencies, bundled runtime files, bundled model files, or the public-release tree change.

Public release still requires operator approval and a scan of the exact public-facing repository or clean public fork. The private working repository must not be made public directly.

## Project License

VoiceBar is prepared for release under Apache License 2.0.

Project attribution:

- VoiceBar
- Built by Live
- Copyright 2026 Live Livingstone Rowe

## Dependency Review Method

The dependency inventory was checked against the exact local Swift Package Manager checkouts for the revisions pinned in `Package.resolved`.

Verified checkout paths:

- `.build/checkouts/argmax-oss-swift`
- `.build/checkouts/swift-argument-parser`
- `.build/checkouts/swift-asn1`
- `.build/checkouts/swift-collections`
- `.build/checkouts/swift-crypto`
- `.build/checkouts/swift-jinja`
- `.build/checkouts/swift-transformers`
- `.build/checkouts/yyjson`

## Dependency Inventory

| Package | Version | Revision | Source | Detected License | Upstream Notice File | Preservation Requirement | Public-Release Posture |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `argmax-oss-swift` | `0.18.0` | `e2adabbe7d98dc4d0ab9a5b75424ecc42a9cdbef` | <https://github.com/argmaxinc/argmax-oss-swift/tree/e2adabbe7d98dc4d0ab9a5b75424ecc42a9cdbef> | Massachusetts Institute of Technology (MIT) License | None found in resolved checkout. | Preserve the Massachusetts Institute of Technology (MIT) License copyright and permission notice. | Acceptable for public release if the notice text below stays included. |
| `swift-argument-parser` | `1.7.1` | `626b5b7b2f45e1b0b1c6f4a309296d1d21d7311b` | <https://github.com/apple/swift-argument-parser/tree/626b5b7b2f45e1b0b1c6f4a309296d1d21d7311b> | Apache License 2.0 with Swift Runtime Library Exception | None found in resolved checkout. | Preserve Apache License 2.0 terms and Swift Runtime Library Exception. | Acceptable for public release if license attribution is preserved. |
| `swift-asn1` | `1.7.0` | `eb50cbd14606a9161cbc5d452f18797c90ef0bab` | <https://github.com/apple/swift-asn1/tree/eb50cbd14606a9161cbc5d452f18797c90ef0bab> | Apache License 2.0 | `NOTICE.txt` found in resolved checkout. | Preserve Apache License 2.0 terms and upstream notice text. | Acceptable for public release if the notice text below stays included. |
| `swift-collections` | `1.4.1` | `6675bc0ff86e61436e615df6fc5174e043e57924` | <https://github.com/apple/swift-collections/tree/6675bc0ff86e61436e615df6fc5174e043e57924> | Apache License 2.0 with Swift Runtime Library Exception | None found in resolved checkout. | Preserve Apache License 2.0 terms and Swift Runtime Library Exception. | Acceptable for public release if license attribution is preserved. |
| `swift-crypto` | `4.4.0` | `476538ccb827f2dd18efc5de754cc87d77127a47` | <https://github.com/apple/swift-crypto/tree/476538ccb827f2dd18efc5de754cc87d77127a47> | Apache License 2.0 | `NOTICE.txt` found in resolved checkout. | Preserve Apache License 2.0 terms and upstream notice text. | Acceptable for public release if the notice text below stays included. |
| `swift-jinja` | `2.3.5` | `0aeefadec459ce8e11a333769950fb86183aca43` | <https://github.com/huggingface/swift-jinja/tree/0aeefadec459ce8e11a333769950fb86183aca43> | Apache License 2.0 | None found in resolved checkout. | Preserve Apache License 2.0 terms and dependency-specific copyright notice. | Acceptable for public release if license attribution is preserved. |
| `swift-transformers` | `1.1.9` | `150169bfba0889c229a2ce7494cf8949f18e6906` | <https://github.com/huggingface/swift-transformers/tree/150169bfba0889c229a2ce7494cf8949f18e6906> | Apache License 2.0 | None found in resolved checkout. | Preserve Apache License 2.0 terms and dependency-specific copyright notice. | Acceptable for public release if license attribution is preserved. |
| `yyjson` | `0.12.0` | `8b4a38dc994a110abaec8a400615567bd996105f` | <https://github.com/ibireme/yyjson/tree/8b4a38dc994a110abaec8a400615567bd996105f> | Massachusetts Institute of Technology (MIT) License | None found in resolved checkout. | Preserve the Massachusetts Institute of Technology (MIT) License copyright and permission notice. | Acceptable for public release if the notice text below stays included. |

## Preserved Massachusetts Institute of Technology (MIT) License Notices

### argmax-oss-swift

Massachusetts Institute of Technology (MIT) License

Copyright (c) 2024 argmax, inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

### yyjson

Massachusetts Institute of Technology (MIT) License

Copyright (c) 2020 YaoYuan <ibireme@gmail.com>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

## Apache License 2.0 Dependencies

The Apache License 2.0 text is included in this repository's `LICENSE` file. The following dependencies are licensed under Apache License 2.0 or Apache License 2.0 with the Swift Runtime Library Exception:

- `swift-argument-parser`
- `swift-asn1`
- `swift-collections`
- `swift-crypto`
- `swift-jinja`
- `swift-transformers`

For `swift-argument-parser` and `swift-collections`, the resolved license file includes the Swift Runtime Library Exception:

> As an exception, if you use this Software to compile your source code and portions of this Software are embedded into the binary product as a result, you may redistribute such product without providing attribution as would otherwise be required by Sections 4(a), 4(b) and 4(d) of the License.

The resolved license files for `swift-jinja` and `swift-transformers` include this dependency-specific notice:

> Copyright 2022 Hugging Face SAS.

## Preserved Apache Notice Text

### swift-asn1

The resolved checkout includes `NOTICE.txt`.

Notice text to preserve:

```text
                            The SwiftASN1 Project
                            =====================

Please visit the SwiftASN1 web site for more information:

  * https://github.com/apple/swift-asn1

Copyright 2022 The SwiftASN1 Project

The SwiftASN1 Project licenses this file to you under the Apache License,
version 2.0 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at:

  https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
License for the specific language governing permissions and limitations
under the License.

Also, please refer to each LICENSE.txt file, which is located in
the 'license' directory of the distribution file, for the license terms of the
components that this product depends on.

---

This product contains derivations of various scripts from SwiftNIO.

  * LICENSE (Apache License 2.0):
    * https://www.apache.org/licenses/LICENSE-2.0
  * HOMEPAGE:
    * https://github.com/apple/swift-nio

---

This product contains derivations of various scripts from Swift OpenAPI Generator.

  * LICENSE (Apache License 2.0):
    * https://www.apache.org/licenses/LICENSE-2.0
  * HOMEPAGE:
    * https://github.com/apple/swift-openapi-generator
```

### swift-crypto

The resolved checkout includes `NOTICE.txt`.

Notice text to preserve:

```text
                            The SwiftCrypto Project
                            =======================

Please visit the SwiftCrypto web site for more information:

  * https://github.com/apple/swift-crypto

Copyright 2019 The SwiftCrypto Project

The SwiftCrypto Project licenses this file to you under the Apache License,
version 2.0 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at:

  https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
License for the specific language governing permissions and limitations
under the License.

Also, please refer to each LICENSE.<component>.txt file, which is located in
the 'license' directory of the distribution file, for the license terms of the
components that this product depends on.

-------------------------------------------------------------------------------

This product contains test vectors from Google's wycheproof project.

  * LICENSE (Apache License 2.0):
    * https://github.com/C2SP/wycheproof/blob/31387e2cd596587c859c611027b6a44d2e2b65ff/LICENSE
  * HOMEPAGE:
    * https://github.com/google/wycheproof

---

This product contains a derivation of various files from SwiftNIO.

  * LICENSE (Apache License 2.0):
    * https://www.apache.org/licenses/LICENSE-2.0
  * HOMEPAGE:
    * https://github.com/apple/swift-nio
```

## External Runtime And Model Caveats

VoiceBar may rely on local runtimes or models that are installed outside this repository. This file does not grant redistribution rights for those external artifacts.

Release caveats:

- `whisper.cpp` runtime: review the exact upstream license and notice files before bundling or redistributing the runtime.
- Downloaded `whisper.cpp` speech-to-text models: review each model's license and hosting terms before bundling or redistributing model files.
- Ollama: review the exact Ollama license and distribution terms before bundling or redistributing Ollama itself.
- Downloaded Ollama formatter models: review each model's license, model card, and hosting terms before bundling, mirroring, or redistributing model files.
- Kokoro-backed text-to-speech runtime or model files: review the exact runtime package and model license before bundling or redistributing them.
- Qwen or TTSKit model files: review the exact model and package licenses before bundling or redistributing model artifacts.
- Future speech-to-text or text-to-speech model integrations: treat every runtime, model, tokenizer, and weight file as separately licensed until verified.

VoiceBar documentation may explain how an operator installs local runtimes, but a public release must not imply that this repository redistributes external model weights or grants rights to redistribute them unless that is directly verified.

## Required Follow-Up

- Re-run this review after any dependency version or revision changes.
- Re-run public-safety scans against the exact public-facing repository or clean public fork before publication.
- Keep `LICENSE`, `NOTICE`, and this file together in the public release tree.
- Obtain operator approval before creating or publishing a public repository.
