import Foundation
import VoiceBarCore

@main
struct VoiceBarSmokeTests {
    static func main() async {
        do {
            try await assertBootstrapProfilesIncludeCodexDefault()
            try await assertNormalizationOptionsDecoderPrefersHeadingsOnlyFlag()
            try await assertNormalizationOptionsTreatEquivalentHeadingsOnlyModesAsEqual()
            try await assertNormalizationSkipsFencedCodeBlocksByDefault()
            try await assertNormalizationCanReadEverythingWhenRequested()
            try await assertNormalizationCanReturnHeadingsOnly()
            try await assertNormalizationSupportsInlineCodeToggle()
            try await assertNormalizationImprovesURLsPathsAndIdentifiers()
            try await assertNormalizationDoesNotMangleTechnicalEdgeCases()
            try await assertPronunciationServiceSeedsAndAppliesOverrides()
            try await assertNormalizationAndPronunciationStayCompatible()
            try await assertPronunciationServiceIgnoresEmptyMatches()
            try await assertPronunciationServiceDoesNotCacheFailedUpdates()
            try await assertAppProfileStorePersistsAndMatchesProfiles()
            try await assertAppProfileStoreDoesNotCacheFailedUpdates()
            try await assertStorageLocationsMatchDocumentedPaths()
            try await assertProfileDefaultsDriveNormalizationBehavior()
            try await assertResolvedPreferredModePrefersAppProfiles()
            try await assertNormalizedParagraphsStillDriveChunkerPauses()
            try await assertLiveTextCaptureServiceRequiresAccessibilityBeforeSelection()
            try await assertLiveTextCaptureServiceReadsAccessibilitySelection()
            try await assertLiveTextCaptureServiceReadsClipboardText()
            try await assertLiveTextCaptureServiceUsesCopyFallbackAndRestoresClipboard()
            try await assertLiveTextCaptureServiceSkipsCopyFallbackWhenClipboardChangesAgain()
            try await assertLiveTextCaptureServiceReportsRestoreFailureDuringCopyFallbackError()
            try await assertLiveTextCaptureServiceRetriesSelectionAfterMenuDelay()
            try await assertJSONDictationStoresReloadExternalEdits()
            try await assertWisprFlowSnippetImporterPreviewsSafeSyntheticImports()
            try await assertWisprFlowSnippetImporterAppliesWithBackupAndMerge()
            try await assertWisprFlowSnippetImporterRejectsMultiSnippetTriggerConflicts()
            try await assertWisprFlowSnippetImporterRejectsPunctuationEquivalentTriggers()
            try await assertWisprFlowSnippetImporterDoesNotQuarantineHyphenatedWords()
            try await assertWisprFlowSnippetImporterAcceptsSingleEntryManifest()
            try await assertWisprFlowSnippetImporterAcceptsLabelLessSnippets()
            try await assertWisprFlowSnippetImporterDoesNotReserveQuarantinedTriggers()
            try await assertWisprFlowSnippetImporterKeepsEntryIdentifiersDistinct()
            try await assertUnconfiguredSpeechEngineSurfacesUnavailableState()
            try await assertTTSKitEnginesStartConfiguredForOnDemandLoad()
            try await assertSpeechChunkSupportsJSONRoundTrip()
            try await assertSpeechRequestSupportsVoiceSelectionRoundTrip()
            try await assertFormatterDefaultsPreferSmallLocalModel()
            try await assertFormatterQualityModesControlTimeouts()
            try await assertFormatterEnvironmentOverrideTakesPrecedence()
            try await assertFunctionKeyHoldToTalkSourceCoverage()
            try await assertOperatorCriticalAliasBackfillSourceCoverage()
            try await assertOllamaFormatterDecodeRoundTripsStructuredSchema()
            try await assertKokoroPlaybackPlannerChunksLongReadsForInteractiveStart()
            try await assertKokoroPlaybackPlannerKeepsFirstSegmentSmall()
            try await assertSnippetExpansionAndDeterministicActionRoutingStayAligned()
            try await assertGoogleCloudPlatformLoginSnippetAliasesExpandSameText()
            try await assertSyntheticLocalNotesSnippetAliasesExpandSameText()
            try await assertCommandTextSnippetExpandsWithoutActionExecution()
            try await assertSnippetLabelIsNotImplicitTrigger()
            try await assertAddLabelAsTriggerDeduplicatesNormalizedTriggers()
            try await assertAddLabelAsTriggerSupportsNonLatinLabels()
            try await assertMixedScriptTriggersDoNotCollapseToSharedDigitKey()
            try await assertSyntheticProductNameSpeechAliasesExpandSameText()
            try await assertSnippetExpansionTreatsWholeUtteranceTriggersWithTrailingPunctuationAsExactMatch()
            try await assertSnippetExpansionPreservesLiteralDollarAmounts()
            try await assertDeterministicFormatterHandlesStructuredDictationAcceptanceFixtures()
            try await assertDeterministicFormatterHandlesExplicitListAndSpokenPunctuation()
            try await assertDeterministicFormatterHandlesBareNumberedListCommand()
            try await assertDeterministicFormatterLeavesWhitespaceUntouchedWhenNoRulesApply()
            try await assertDeterministicFormatterRecognizesSpokenPunctuationWithTrailingSTTPunctuation()
            try await assertDeterministicFormatterHandlesExpandedSpokenPunctuation()
            try await assertDeterministicFormatterDoesNotRewriteNaturalProseLineMentions()
            try await assertDeterministicFormatterPreservesStandaloneLineBreakCommands()
            try await assertFallbackTextPolisherImprovesSentenceAndQuestionOutput()
            try await assertDictationPipelinePolishesModelPunctuationBeforeInsertion()
            try await assertDictationPipelineRecoversFromEmptyModelDictationOutput()
            try await assertDictationActionRouterSkipsMixedModeActionsUnlessAllowed()
            try await assertDictationActionRouterReportsMatchedTrigger()
            try await assertSnippetExpansionCannotTriggerActions()
            try await assertDeterministicFormattingCannotTriggerActions()
            try await assertFormatterCandidatesCannotTriggerActionsWithoutRawMatch()
            try await assertRawTriggerActionSuppressesFormatterInsertion()
            try await assertDictationPipelinePreservesExactActionTriggersAfterDeterministicRewrite()
            try await assertDictationPipelinePassesFormatterModelAndRollingContext()
            try await assertDictationPipelinePlainTextModeSkipsFormatter()
            try await assertDictationPipelineBypassesModelWhenDeterministicFormattingAlreadySolvedOutput()
            try await assertDictationPipelineFallsBackWhenFormatterStalls()
            try await assertDictationPipelineFallbackPreservesMultilineSnippetExpansion()
            try await assertDictationPipelineHandlesTimeoutWithClearDiagnostics()
            try await assertDiagnosticsCaptureUsesBoundedHistory()
            try await assertSpeechRequestChunkerSplitsParagraphsAndPauses()
            try await assertSpeechRequestChunkerGroupsStreamingSegmentsWithoutWholeParagraphBuffering()
            try await assertSpeechRequestChunkerSplitsLongSentencesIntoSmallerPhrases()
            try await assertDependencyContainerLiveWiresSpeechRuntime()
            try await assertQueuedPlaybackControllerQueuesAndReplaysRequests()
            try await assertQueuedPlaybackControllerForwardsPrebufferHints()
            try await assertAudioChunkPlayerPrebufferPolicyGrowsBufferBeforeFirstFlush()
            try await assertAudioChunkPlayerPrebufferPolicyIgnoresHintsAfterFirstFlush()
            try await assertQueuedPlaybackControllerPausesAndResumesPlayback()
            try await assertQueuedPlaybackControllerStopsAndClearsQueue()
            try await assertQueuedPlaybackControllerRetainsReplayAfterStop()
            try await assertQueuedPlaybackControllerReplayRestartsPausedPlayback()
            try await assertQueuedPlaybackControllerStopDoesNotDegradeAutoMode()
            try await assertQueuedPlaybackControllerStopDoesNotClobberNewPlayback()
            try await assertQueuedPlaybackControllerStopBeforeEnqueueSuppressesAudio()
            try await assertQueuedPlaybackControllerStopDoesNotRecordCompletedPlayback()
            try await assertQueuedPlaybackControllerStopDuringDrainSuppressesDrainDiagnostic()
            try await assertQueuedPlaybackControllerKeepsExplicitPremiumWhenCold()
            try await assertQueuedPlaybackControllerTemporarilyStartsQuickWhenAutoUsesColdPremium()
            try await assertQueuedPlaybackControllerFallsBackToQuickWhenPremiumFails()
            try await assertQueuedPlaybackControllerFallsBackWhenPremiumOnlyProducesParagraphPause()
            try await assertQueuedPlaybackControllerDegradesAutoAfterRepeatedPremiumFailures()
            print("VoiceBar smoke tests passed.")
        } catch {
            fputs("VoiceBar smoke tests failed: \(error.localizedDescription)\n", stderr)
            Foundation.exit(1)
        }
    }

    private static func assertFormatterDefaultsPreferSmallLocalModel() async throws {
        guard OllamaFormatterService.defaultModel == "llama3.2:3b" else {
            throw SmokeTestError("Expected low-latency formatter default model to be llama3.2:3b.")
        }

        guard OllamaFormatterService.requestTimeoutSeconds == 2 else {
            throw SmokeTestError("Expected legacy formatter timeout constant to stay aligned with Fast mode.")
        }
    }

    private static func assertFormatterQualityModesControlTimeouts() async throws {
        let key = OllamaFormatterService.timeoutOverrideEnvironmentKey
        let originalValue = ProcessInfo.processInfo.environment[key]

        defer {
            if let originalValue {
                setenv(key, originalValue, 1)
            } else {
                unsetenv(key)
            }
        }

        unsetenv(key)

        guard OllamaFormatterService.requestTimeoutSeconds(for: .fast) == 2 else {
            throw SmokeTestError("Expected Fast formatter quality to keep the 2-second timeout.")
        }

        guard OllamaFormatterService.requestTimeoutSeconds(for: .balanced) == 4 else {
            throw SmokeTestError("Expected Balanced formatter quality to allow a 4-second cleanup window.")
        }

        guard OllamaFormatterService.requestTimeoutSeconds(for: .quality) == 8 else {
            throw SmokeTestError("Expected Quality formatter quality to allow an 8-second cleanup window.")
        }
    }

    private static func assertFormatterEnvironmentOverrideTakesPrecedence() async throws {
        let key = OllamaFormatterService.modelOverrideEnvironmentKey
        let originalValue = ProcessInfo.processInfo.environment[key]

        defer {
            if let originalValue {
                setenv(key, originalValue, 1)
            } else {
                unsetenv(key)
            }
        }

        setenv(key, "env-override-model", 1)

        let service = OllamaFormatterService()
        let resolvedWithOverride = service.resolvedModelIdentifier(for: "preference-model")
        guard resolvedWithOverride == "env-override-model" else {
            throw SmokeTestError("Expected VOICEBAR_OLLAMA_FORMATTER_MODEL to override explicit formatter preferences when set.")
        }

        unsetenv(key)

        let resolvedWithoutOverride = service.resolvedModelIdentifier(for: "preference-model")
        guard resolvedWithoutOverride == "preference-model" else {
            throw SmokeTestError("Expected formatter preferences to apply normally when the environment override is not set.")
        }
    }

    private static func assertFunctionKeyHoldToTalkSourceCoverage() async throws {
        let preferencesSource = try String(
            contentsOfFile: "Sources/VoiceBarApp/App/VoiceBarPreferences.swift",
            encoding: .utf8
        )
        let hotkeySource = try String(
            contentsOfFile: "Sources/VoiceBarApp/App/HotkeyManager.swift",
            encoding: .utf8
        )

        guard preferencesSource.contains("enum HoldToTalkMode") else {
            throw SmokeTestError("Expected hold-to-talk mode preference to persist through VoiceBarPreferences.")
        }

        guard preferencesSource.contains("case functionKeyExperimental") else {
            throw SmokeTestError("Expected Function key (Fn) experimental mode to be a persisted preference case.")
        }

        guard preferencesSource.contains("case optionShortcut") else {
            throw SmokeTestError("Expected Option shortcut mode to remain a valid hold-to-talk preference.")
        }

        guard hotkeySource.contains(".maskSecondaryFn") else {
            throw SmokeTestError("Expected Function key (Fn) mode to use maskSecondaryFn instead of a normal keyCode.")
        }

        guard hotkeySource.contains("eventMask = (1 << CGEventType.flagsChanged.rawValue)") else {
            throw SmokeTestError("Expected Function key (Fn) mode to install only a flagsChanged event tap.")
        }

        guard hotkeySource.contains("guard type == .flagsChanged else") else {
            throw SmokeTestError("Expected Function key (Fn) filtering to ignore keyDown and keyUp events.")
        }

        guard hotkeySource.contains("functionKey.event.filtered") else {
            throw SmokeTestError("Expected Function key (Fn) filtering diagnostics to record event type, key code, maskSecondaryFn, and accept/ignore state.")
        }

        guard preferencesSource.contains("HotkeyCatalog.isAllowedHoldToTalkKey(shortcut.keyCode)") else {
            throw SmokeTestError("Expected existing hold-to-talk validation to keep rejecting unsafe Option-letter shortcuts.")
        }
    }

    private static func assertOperatorCriticalAliasBackfillSourceCoverage() async throws {
        let appStateSource = try String(
            contentsOfFile: "Sources/VoiceBarApp/App/VoiceBarAppState.swift",
            encoding: .utf8
        )

        guard appStateSource.contains("aliasConflicts(for:") else {
            throw SmokeTestError("Expected operator-critical alias backfill to detect cross-snippet trigger conflicts.")
        }

        guard appStateSource.contains("nonConflictingMissingAliases(") else {
            throw SmokeTestError("Expected operator-critical alias backfill to append only non-conflicting missing aliases.")
        }

        guard appStateSource.contains("Skipped conflicting aliases") else {
            throw SmokeTestError("Expected operator-critical alias backfill to report skipped conflict handling without exposing private expansions.")
        }
    }

    private static func assertBootstrapProfilesIncludeCodexDefault() async throws {
        let store = InMemoryAppProfileStore()
        let profile = await store.profile(for: "COM.OPENAI.CODEX")

        guard profile?.preferredMode == .quick else {
            throw SmokeTestError("Expected Codex default profile to prefer the Kokoro-backed Quick path on a configured machine.")
        }

        guard profile?.allowClipboardFallback == true else {
            throw SmokeTestError("Expected Codex default profile to allow clipboard fallback.")
        }
    }

    private static func assertNormalizationOptionsDecoderPrefersHeadingsOnlyFlag() async throws {
        let payload = Data(
            #"{"handlingMode":"proseFirst","headingsOnly":true,"skipCodeBlocks":false,"skipInlineCode":true}"#
                .utf8
        )
        let decoded = try JSONDecoder().decode(
            NormalizationOptions.self,
            from: payload
        )

        guard decoded.handlingMode == .headingsOnly else {
            throw SmokeTestError("Expected contradictory headings-only payloads to normalize to the headings-only handling mode.")
        }

        guard decoded.resolvedHandlingMode == .headingsOnly else {
            throw SmokeTestError("Expected resolvedHandlingMode to stay aligned with the normalized decoder output.")
        }
    }

    private static func assertNormalizationOptionsTreatEquivalentHeadingsOnlyModesAsEqual() async throws {
        let handlingModeOnly = NormalizationOptions(handlingMode: .headingsOnly)
        let legacyHeadingsOnly = NormalizationOptions(headingsOnly: true)

        guard handlingModeOnly == legacyHeadingsOnly else {
            throw SmokeTestError("Expected headings-only normalization options to compare equal regardless of whether they came from the legacy boolean or the enum mode.")
        }

        let encoded = try JSONEncoder().encode(handlingModeOnly)
        let decoded = try JSONDecoder().decode(NormalizationOptions.self, from: encoded)

        guard decoded == legacyHeadingsOnly else {
            throw SmokeTestError("Expected headings-only normalization options to persist in the canonical shape used by override comparisons.")
        }
    }

    private static func assertNormalizationSkipsFencedCodeBlocksByDefault() async throws {
        let service = DefaultTextNormalizationService()
        let capturedText = CapturedText(
            text: """
            Intro paragraph.

            ```swift
            apiURL
            ```

            Outro paragraph.
            """,
            source: .clipboard,
            frontmostBundleIdentifier: "com.example.voicebar.synthetic-host"
        )

        let output = await service.normalize(
            capturedText,
            options: NormalizationOptions(),
            profile: nil
        )

        guard output.contains("Intro paragraph.") else {
            throw SmokeTestError("Expected prose-first normalization to keep the leading paragraph.")
        }

        guard output.contains("Outro paragraph.") else {
            throw SmokeTestError("Expected prose-first normalization to keep the trailing paragraph.")
        }

        guard output.contains("U R L") == false else {
            throw SmokeTestError("Expected prose-first normalization to omit fenced code blocks by default.")
        }

        guard output.contains("\n\n") else {
            throw SmokeTestError("Expected prose-first normalization to preserve paragraph boundaries for the speech chunker.")
        }
    }

    private static func assertNormalizationCanReadEverythingWhenRequested() async throws {
        let service = DefaultTextNormalizationService()
        let capturedText = CapturedText(
            text: """
            Intro paragraph.
            # Overview
            1) topLevel()
            - literal bullet

            ```swift
            #include <stdio.h>
            1) foo()
            value = a*b
            value = a * b * c
            value = a|b
            cache~backup
            apiURL
            ```
            """,
            source: .clipboard
        )

        let output = await service.normalize(
            capturedText,
            options: NormalizationOptions(
                handlingMode: .readEverything,
                skipCodeBlocks: false
            ),
            profile: nil
        )

        guard output.contains("U R L") else {
            throw SmokeTestError("Expected read-everything mode to keep fenced code contents in a speakable form.")
        }

        guard output.contains("# Overview") else {
            throw SmokeTestError("Expected read-everything mode to keep unfenced markdown-shaped headings literal instead of relabeling them.")
        }

        guard output.contains("top Level()") || output.contains("topLevel()") else {
            throw SmokeTestError("Expected read-everything mode to keep unfenced numbered-looking technical lines literal instead of relabeling them as list items.")
        }

        guard output.contains("literal bullet") else {
            throw SmokeTestError("Expected read-everything mode to keep unfenced bullet-looking lines literal instead of relabeling them as bullet summaries.")
        }

        guard output.contains("Title:") == false else {
            throw SmokeTestError("Expected read-everything mode to keep technical lines literal instead of relabeling headings.")
        }

        guard output.contains("Item 1:") == false else {
            throw SmokeTestError("Expected read-everything mode to keep technical lines literal instead of relabeling numbered items.")
        }

        guard output.contains("Bullet:") == false else {
            throw SmokeTestError("Expected read-everything mode to keep technical lines literal instead of relabeling bullet items.")
        }

        guard output.contains("a*b") else {
            throw SmokeTestError("Expected literal asterisk characters inside fenced code to survive normalization.")
        }

        guard output.contains("a * b * c") else {
            throw SmokeTestError("Expected markdown cleanup to preserve literal infix asterisk operators inside technical text.")
        }

        guard output.contains("cache~backup") else {
            throw SmokeTestError("Expected literal tilde characters inside fenced code to survive normalization.")
        }

        guard output.contains("a|b") else {
            throw SmokeTestError("Expected literal pipe characters inside fenced code to survive normalization.")
        }

        guard output.contains("```") == false else {
            throw SmokeTestError("Expected read-everything mode to drop raw fence markers instead of speaking backticks.")
        }
    }

    private static func assertNormalizationCanReturnHeadingsOnly() async throws {
        let service = DefaultTextNormalizationService()
        let capturedText = CapturedText(
            text: """
            # Overview
            Body text that should be skipped.
            ## Details
            - Bullet text that should also be skipped.
            """,
            source: .service
        )

        let output = await service.normalize(
            capturedText,
            options: NormalizationOptions(handlingMode: .headingsOnly),
            profile: nil
        )

        guard output.contains("Title: Overview") else {
            throw SmokeTestError("Expected headings-only mode to keep the top-level heading.")
        }

        guard output.contains("Section: Details") else {
            throw SmokeTestError("Expected headings-only mode to keep lower-level headings.")
        }

        guard output.contains("Body text") == false && output.contains("Bullet") == false else {
            throw SmokeTestError("Expected headings-only mode to omit prose and list content.")
        }
    }

    private static func assertNormalizationSupportsInlineCodeToggle() async throws {
        let service = DefaultTextNormalizationService()
        let capturedText = CapturedText(
            text: "Use `apiURL` in prose.",
            source: .clipboard
        )

        let keptInlineCode = await service.normalize(
            capturedText,
            options: NormalizationOptions(skipInlineCode: false),
            profile: nil
        )
        let skippedInlineCode = await service.normalize(
            capturedText,
            options: NormalizationOptions(skipInlineCode: true),
            profile: nil
        )

        guard keptInlineCode.contains("U R L") else {
            throw SmokeTestError("Expected the default inline-code path to unwrap and normalize inline code.")
        }

        guard skippedInlineCode.contains("U R L") == false else {
            throw SmokeTestError("Expected skip-inline-code mode to remove inline code spans entirely.")
        }
    }

    private static func assertNormalizationImprovesURLsPathsAndIdentifiers() async throws {
        let service = DefaultTextNormalizationService()
        let capturedText = CapturedText(
            text: """
            Visit https://docs.github.com/en/actions?foo=bar and open Sources/VoiceBarCore/Models/AppProfile.swift with JSON API output.
            Visit https://mywww.example.com/docs for the edge-case host.
            Visit https://example.com/docs.
            Open /tmp folder for logs and restart.
            Use /tmp/Application Support/ExampleApp/config.json before overrides.
            Keep my_api_key in sync with renderQueue and kebab-case values.
            """,
            source: .clipboard
        )

        let output = await service.normalize(
            capturedText,
            options: NormalizationOptions(),
            profile: nil
        )
        let lowercasedOutput = output.lowercased()

        guard output.contains("docs dot github dot com") else {
            throw SmokeTestError("Expected URLs to be shortened to a speakable host form.")
        }

        guard output.contains("with query parameters") else {
            throw SmokeTestError("Expected long query strings to be summarized instead of read literally.")
        }

        guard output.contains("Sources slash Voice Bar Core slash Models slash App Profile dot swift") else {
            throw SmokeTestError("Expected file paths to be normalized into a speakable slash and dot form.")
        }

        guard output.contains("/tmp folder for logs and restart") == false else {
            throw SmokeTestError("Expected path handling to stop before trailing prose instead of rewriting the rest of the sentence as one path.")
        }

        guard output.contains("Use tmp slash Application Support slash Example App slash config dot j s o n before overrides.") else {
            throw SmokeTestError("Expected Application Support paths with internal spaces to normalize the full path before trailing prose.")
        }

        guard output.contains("ExampleApp slash config") == false else {
            throw SmokeTestError("Expected camel-case normalization to prove the path match consumed the full synthetic config path.")
        }

        guard output.contains("mywww dot example dot com") else {
            throw SmokeTestError("Expected only a leading www host label to be trimmed from spoken URLs.")
        }

        guard output.contains("example dot com slash docs.") else {
            throw SmokeTestError("Expected sentence-ending punctuation to stay outside the spoken URL host and path.")
        }

        guard output.contains("example dot com slash docs dot") == false else {
            throw SmokeTestError("Expected trailing periods after URLs to avoid being spoken as part of the domain or path.")
        }

        guard lowercasedOutput.contains("my a p i key") || lowercasedOutput.contains("my api key") else {
            throw SmokeTestError("Expected snake_case identifiers to keep their word boundaries after markdown cleanup.")
        }

        guard lowercasedOutput.contains("render queue") else {
            throw SmokeTestError("Expected camelCase identifiers to be split into a speakable form.")
        }

        guard lowercasedOutput.contains("kebab case") else {
            throw SmokeTestError("Expected kebab-case identifiers to be split into a speakable form.")
        }

        guard output.contains("J S O N") && output.contains("A P I") else {
            throw SmokeTestError("Expected short all-caps acronyms to be spelled out for TTS.")
        }
    }

    private static func assertNormalizationDoesNotMangleTechnicalEdgeCases() async throws {
        let service = DefaultTextNormalizationService()
        let capturedText = CapturedText(
            text: """
            1. Ship it
            2.5 million users
            .gitignore matters
            100.0% coverage
            #channel-name stays literal
            THE AND FOR ARE HAS NOT CAN MAY NEW OLD AID
            IT IS NO PROBLEM for API users.
            __init__ stays literal.
            MY__VAR should keep its internal boundary.
            """,
            source: .clipboard
        )

        let output = await service.normalize(
            capturedText,
            options: NormalizationOptions(),
            profile: nil
        )

        guard output.contains("Item 1: Ship it") else {
            throw SmokeTestError("Expected real numbered markdown items to stay labeled.")
        }

        guard output.contains("Item 2: 5 million users") == false else {
            throw SmokeTestError("Expected decimal numbers to avoid numbered-item relabeling.")
        }

        guard output.contains("Item : gitignore") == false else {
            throw SmokeTestError("Expected dotfiles to avoid numbered-item relabeling.")
        }

        guard output.contains("Item 100: 0% coverage") == false else {
            throw SmokeTestError("Expected floating-point percentages to avoid numbered-item relabeling.")
        }

        guard output.contains("Title: channel name") == false else {
            throw SmokeTestError("Expected hashtags to avoid heading relabeling.")
        }

        guard output.contains("IT IS NO PROBLEM") else {
            throw SmokeTestError("Expected short all-caps English words to remain words instead of being spelled letter-by-letter.")
        }

        guard output.contains("THE AND FOR ARE HAS NOT CAN MAY NEW OLD AID") else {
            throw SmokeTestError("Expected common three-to-five-letter all-caps English words to remain words instead of being spelled letter-by-letter.")
        }

        guard output.contains("A P I") else {
            throw SmokeTestError("Expected explicit acronyms to keep being spelled out after the heuristic refinement.")
        }

        guard output.contains("__init__") else {
            throw SmokeTestError("Expected adjacent underscore boundaries to survive on dunder-style identifiers.")
        }

        guard output.contains("M Y V A R") == false else {
            throw SmokeTestError("Expected adjacent underscores to preserve a word boundary instead of collapsing identifiers into one acronym block.")
        }

        guard output.contains("MY VAR") || output.contains("M Y VAR") || output.contains("MY V A R") else {
            throw SmokeTestError("Expected double-underscore identifiers to keep a visible boundary after normalization.")
        }
    }

    private static func assertPronunciationServiceSeedsAndAppliesOverrides() async throws {
        let temporaryDirectoryURL = try makeTemporaryDirectoryURL()
        defer {
            try? setPosixPermissions(temporaryDirectoryURL, to: 0o755)
            try? FileManager.default.removeItem(at: temporaryDirectoryURL)
        }

        let storageURL = temporaryDirectoryURL.appendingPathComponent("pronunciation-dictionary.json")
        let service = JSONPronunciationService(storageURL: storageURL)

        let seededOutput = await service.applyOverrides(
            to: "Codex and Qwen follow the EU AI Act.",
            profile: nil
        )

        guard seededOutput.contains("Code ex") else {
            throw SmokeTestError("Expected the seeded pronunciation dictionary to replace Codex.")
        }

        guard seededOutput.contains("Queen") else {
            throw SmokeTestError("Expected the seeded pronunciation dictionary to replace Qwen.")
        }

        guard seededOutput.contains("E U A I Act") else {
            throw SmokeTestError("Expected the seeded pronunciation dictionary to replace EU AI Act.")
        }

        var dictionary = try await service.loadDictionary()
        guard dictionary.entries.count >= 5 else {
            throw SmokeTestError("Expected the seeded pronunciation dictionary file to contain the required sample entries.")
        }

        guard FileManager.default.fileExists(atPath: storageURL.path) else {
            throw SmokeTestError("Expected the pronunciation dictionary to be persisted under the configured storage URL.")
        }

        let seededFileContents = try JSONDecoder().decode(
            PronunciationDictionary.self,
            from: Data(contentsOf: storageURL)
        )
        guard seededFileContents.entries.isEmpty else {
            throw SmokeTestError("Expected the on-disk pronunciation file to start with explicit overrides only so shipped defaults can evolve later.")
        }

        if let qwenIndex = dictionary.entries.firstIndex(where: { $0.id == "qwen" }) {
            dictionary.entries[qwenIndex].isEnabled = false
        } else {
            throw SmokeTestError("Expected the seeded dictionary to include the Qwen sample entry.")
        }

        try await service.updateDictionary(dictionary)

        let updatedOutput = await service.applyOverrides(
            to: "Qwen still appears here.",
            profile: nil
        )

        guard updatedOutput.contains("Queen") == false else {
            throw SmokeTestError("Expected disabled pronunciation entries to stop applying.")
        }

        let persistedOverrideDictionary = try JSONDecoder().decode(
            PronunciationDictionary.self,
            from: Data(contentsOf: storageURL)
        )
        guard persistedOverrideDictionary.entries.map(\.id) == ["qwen"] else {
            throw SmokeTestError("Expected the pronunciation file to persist only the changed seeded entry instead of freezing every default entry on disk.")
        }

        let reloadedService = JSONPronunciationService(storageURL: storageURL)
        let reloadedOutput = await reloadedService.applyOverrides(
            to: "Codex still appears here.",
            profile: nil
        )

        guard reloadedOutput.contains("Code ex") else {
            throw SmokeTestError("Expected shipped pronunciation defaults to keep applying even when the on-disk file stores only explicit overrides.")
        }
    }

    private static func assertNormalizationAndPronunciationStayCompatible() async throws {
        let temporaryDirectoryURL = try makeTemporaryDirectoryURL()
        defer {
            try? setPosixPermissions(temporaryDirectoryURL, to: 0o755)
            try? FileManager.default.removeItem(at: temporaryDirectoryURL)
        }

        let normalizationService = DefaultTextNormalizationService()
        let pronunciationService = JSONPronunciationService(
            storageURL: temporaryDirectoryURL.appendingPathComponent("pronunciation-dictionary.json")
        )
        let normalized = await normalizationService.normalize(
            CapturedText(
                text: "Codex and Qwen follow the EU AI Act.",
                source: .clipboard
            ),
            options: NormalizationOptions(),
            profile: nil
        )
        let spoken = await pronunciationService.applyOverrides(
            to: normalized,
            profile: nil
        )

        guard spoken.contains("Code ex") else {
            throw SmokeTestError("Expected the full normalization-plus-pronunciation pipeline to keep replacing Codex.")
        }

        guard spoken.contains("Queen") else {
            throw SmokeTestError("Expected the full normalization-plus-pronunciation pipeline to keep replacing Qwen.")
        }

        guard spoken.contains("E U A I Act") else {
            throw SmokeTestError("Expected the full normalization-plus-pronunciation pipeline to preserve the intended spoken EU AI Act output.")
        }
    }

    private static func assertPronunciationServiceIgnoresEmptyMatches() async throws {
        let temporaryDirectoryURL = try makeTemporaryDirectoryURL()
        defer {
            try? setPosixPermissions(temporaryDirectoryURL, to: 0o755)
            try? FileManager.default.removeItem(at: temporaryDirectoryURL)
        }

        let storageURL = temporaryDirectoryURL.appendingPathComponent("pronunciation-dictionary.json")
        let service = JSONPronunciationService(storageURL: storageURL)
        var dictionary = try await service.loadDictionary()
        dictionary.entries.append(
            PronunciationEntry(
                id: "empty-match",
                match: "",
                replacement: "boom"
            )
        )
        dictionary.entries.append(
            PronunciationEntry(
                id: "whitespace-match",
                match: "   ",
                replacement: "boom"
            )
        )

        try await service.updateDictionary(dictionary)

        let spoken = await service.applyOverrides(
            to: "Codex keeps reading normally.",
            profile: nil
        )

        guard spoken == "Code ex keeps reading normally." else {
            throw SmokeTestError("Expected malformed empty pronunciation matches to be ignored instead of expanding across the entire input.")
        }
    }

    private static func assertPronunciationServiceDoesNotCacheFailedUpdates() async throws {
        let temporaryDirectoryURL = try makeTemporaryDirectoryURL()
        defer {
            try? setPosixPermissions(temporaryDirectoryURL, to: 0o755)
            try? FileManager.default.removeItem(at: temporaryDirectoryURL)
        }

        let storageURL = temporaryDirectoryURL.appendingPathComponent("pronunciation-dictionary.json")
        let service = JSONPronunciationService(storageURL: storageURL)
        let originalDictionary = try await service.loadDictionary()
        var updatedDictionary = originalDictionary

        if let qwenIndex = updatedDictionary.entries.firstIndex(where: { $0.id == "qwen" }) {
            updatedDictionary.entries[qwenIndex].replacement = "Cue when"
        } else {
            throw SmokeTestError("Expected the seeded pronunciation dictionary to include the Qwen sample entry.")
        }

        try setPosixPermissions(temporaryDirectoryURL, to: 0o555)

        do {
            try await service.updateDictionary(updatedDictionary)
            throw SmokeTestError("Expected pronunciation updates to fail when the backing directory is not writable.")
        } catch {
            // The failure is the expected regression guard for the persist-before-cache path.
        }

        let cachedDictionaryAfterFailure = try await service.loadDictionary()
        guard cachedDictionaryAfterFailure == originalDictionary else {
            throw SmokeTestError("Expected a failed pronunciation write to leave the in-memory dictionary unchanged.")
        }

        try setPosixPermissions(temporaryDirectoryURL, to: 0o755)

        let reloadedService = JSONPronunciationService(storageURL: storageURL)
        let reloadedDictionary = try await reloadedService.loadDictionary()
        guard reloadedDictionary == originalDictionary else {
            throw SmokeTestError("Expected a failed pronunciation write to leave the on-disk dictionary unchanged.")
        }
    }

    private static func assertAppProfileStorePersistsAndMatchesProfiles() async throws {
        let temporaryDirectoryURL = try makeTemporaryDirectoryURL()
        defer {
            try? setPosixPermissions(temporaryDirectoryURL, to: 0o755)
            try? FileManager.default.removeItem(at: temporaryDirectoryURL)
        }

        let storageURL = temporaryDirectoryURL.appendingPathComponent("app-profiles.json")
        let store = JSONAppProfileStore(storageURL: storageURL)

        let notesProfile = await store.profile(for: "COM.APPLE.NOTES")
        guard notesProfile?.stylePreset == "Calm Narrator" else {
            throw SmokeTestError("Expected the JSON-backed store to seed the Notes profile and match bundle identifiers case-insensitively.")
        }

        let seededFileContents = try JSONDecoder().decode(
            [AppProfile].self,
            from: Data(contentsOf: storageURL)
        )
        guard seededFileContents.isEmpty else {
            throw SmokeTestError("Expected the on-disk app profile file to start with explicit overrides only so shipped defaults can evolve later.")
        }

        let notesDefaultWithLowercaseBundleID = AppProfile(
            bundleIdentifier: "com.apple.notes",
            preferredMode: .quick,
            stylePreset: "Calm Narrator",
            normalizationOptions: NormalizationOptions(
                handlingMode: .proseFirst,
                skipCodeBlocks: true
            ),
            pacingMultiplier: 0.97,
            allowClipboardFallback: false
        )
        try await store.upsert(notesDefaultWithLowercaseBundleID)

        let persistedProfilesAfterDefaultUpsert = try JSONDecoder().decode(
            [AppProfile].self,
            from: Data(contentsOf: storageURL)
        )
        guard persistedProfilesAfterDefaultUpsert.isEmpty else {
            throw SmokeTestError("Expected case-only bundle identifier differences on shipped defaults to avoid persisting redundant overrides.")
        }

        let customProfile = AppProfile(
            bundleIdentifier: "com.test.Editor",
            preferredMode: .quick,
            stylePreset: "Energetic Guide",
            normalizationOptions: NormalizationOptions(
                handlingMode: .readEverything,
                skipCodeBlocks: false
            ),
            pacingMultiplier: 1.08,
            allowClipboardFallback: true
        )
        try await store.upsert(customProfile)

        let reloadedStore = JSONAppProfileStore(storageURL: storageURL)
        let reloadedProfile = await reloadedStore.profile(for: "com.test.editor")

        guard reloadedProfile == customProfile else {
            throw SmokeTestError("Expected app profile overrides to persist across store instances.")
        }

        let loadedProfiles = try await reloadedStore.loadProfiles()
        guard loadedProfiles.contains(where: { $0.bundleIdentifier == "com.apple.Notes" }) else {
            throw SmokeTestError("Expected persisted profiles to retain seeded defaults alongside overrides.")
        }

        let persistedOverrideProfiles = try JSONDecoder().decode(
            [AppProfile].self,
            from: Data(contentsOf: storageURL)
        )
        guard persistedOverrideProfiles == [customProfile] else {
            throw SmokeTestError("Expected the app profile file to persist only explicit overrides instead of freezing shipped defaults on disk.")
        }
    }

    private static func assertAppProfileStoreDoesNotCacheFailedUpdates() async throws {
        let temporaryDirectoryURL = try makeTemporaryDirectoryURL()
        defer {
            try? setPosixPermissions(temporaryDirectoryURL, to: 0o755)
            try? FileManager.default.removeItem(at: temporaryDirectoryURL)
        }

        let storageURL = temporaryDirectoryURL.appendingPathComponent("app-profiles.json")
        let store = JSONAppProfileStore(storageURL: storageURL)
        guard let originalProfile = await store.profile(for: "com.apple.Notes") else {
            throw SmokeTestError("Expected the JSON-backed store to seed the Notes profile before failure-path testing.")
        }

        let updatedProfile = AppProfile(
            bundleIdentifier: "com.apple.Notes",
            preferredMode: .quick,
            stylePreset: "Energetic Guide",
            normalizationOptions: originalProfile.normalizationOptions,
            pacingMultiplier: 1.05,
            allowClipboardFallback: originalProfile.allowClipboardFallback
        )

        try setPosixPermissions(temporaryDirectoryURL, to: 0o555)

        do {
            try await store.upsert(updatedProfile)
            throw SmokeTestError("Expected app profile updates to fail when the backing directory is not writable.")
        } catch {
            // The failure is the expected regression guard for the persist-before-cache path.
        }

        let cachedProfileAfterFailure = await store.profile(for: "com.apple.Notes")
        guard cachedProfileAfterFailure == originalProfile else {
            throw SmokeTestError("Expected a failed app profile write to leave the in-memory profile cache unchanged.")
        }

        try setPosixPermissions(temporaryDirectoryURL, to: 0o755)

        let reloadedStore = JSONAppProfileStore(storageURL: storageURL)
        let reloadedProfile = await reloadedStore.profile(for: "com.apple.Notes")
        guard reloadedProfile == originalProfile else {
            throw SmokeTestError("Expected a failed app profile write to leave the on-disk profile unchanged.")
        }
    }

    private static func assertProfileDefaultsDriveNormalizationBehavior() async throws {
        let service = DefaultTextNormalizationService()
        let codexProfile = AppProfile.bootstrapDefaults.first { $0.bundleIdentifier == "com.openai.codex" }
        let textEditProfile = AppProfile.bootstrapDefaults.first { $0.bundleIdentifier == "com.apple.TextEdit" }

        guard let codexProfile, let textEditProfile else {
            throw SmokeTestError("Expected bootstrap defaults to include both Codex and TextEdit profiles.")
        }

        let capturedText = CapturedText(
            text: """
            Intro.

            ```swift
            apiURL
            ```
            """,
            source: .clipboard
        )

        let codexOutput = await service.normalize(
            capturedText,
            options: codexProfile.normalizationOptions,
            profile: codexProfile
        )
        let textEditOutput = await service.normalize(
            capturedText,
            options: textEditProfile.normalizationOptions,
            profile: textEditProfile
        )

        guard codexOutput.contains("U R L") == false else {
            throw SmokeTestError("Expected the Codex profile's prose-first defaults to skip fenced code.")
        }

        guard textEditOutput.contains("U R L") else {
            throw SmokeTestError("Expected the TextEdit profile's read-everything defaults to keep code content.")
        }
    }

    private static func assertResolvedPreferredModePrefersAppProfiles() async throws {
        let selectedMode: SpeechMode = .premium
        let safariProfile = AppProfile.bootstrapDefaults.first {
            $0.bundleIdentifier == "com.apple.Safari"
        }

        guard let safariProfile else {
            throw SmokeTestError("Expected the bootstrap defaults to include the Safari profile.")
        }

        guard resolvedPreferredMode(selectedMode: selectedMode, profile: safariProfile) == .quick else {
            throw SmokeTestError("Expected the shared preferred-mode helper used by VoiceBarAppState to prioritize the app profile over the global selection.")
        }

        guard resolvedPreferredMode(selectedMode: selectedMode, profile: nil) == .premium else {
            throw SmokeTestError("Expected the shared preferred-mode helper to fall back to the global selection when no app profile is present.")
        }
    }

    private static func assertNormalizedParagraphsStillDriveChunkerPauses() async throws {
        let service = DefaultTextNormalizationService()
        let chunker = SpeechRequestChunker(paragraphPauseMilliseconds: 400)
        let normalizedText = await service.normalize(
            CapturedText(
                text: """
                First paragraph sentence.

                ```swift
                apiURL
                ```

                Second paragraph sentence.
                """,
                source: .clipboard
            ),
            options: NormalizationOptions(),
            profile: nil
        )

        let segments = chunker.chunk(normalizedText)

        guard segments.count == 2 else {
            throw SmokeTestError("Expected normalized prose paragraphs to remain visible to the speech chunker.")
        }

        guard segments.first?.pauseAfterMilliseconds == 400 else {
            throw SmokeTestError("Expected the normalized first paragraph to keep its paragraph pause.")
        }
    }

    private static func assertLiveTextCaptureServiceRequiresAccessibilityBeforeSelection() async throws {
        let service = LiveTextCaptureService(
            accessibilityClient: AccessibilityCaptureClient(
                isTrusted: { false },
                promptForTrust: { false },
                selectedText: { "Hidden selection" },
                performCopyShortcut: {},
                frontmostBundleIdentifier: { "com.apple.Safari" }
            ),
            clipboardClient: makeClipboardClient()
        )

        try await assertThrowsTextCaptureError(
            .accessibilityPermissionRequired,
            "Expected captureSelection() to require Accessibility access first."
        ) {
            _ = try await service.captureSelection()
        }
    }

    private static func assertLiveTextCaptureServiceReadsAccessibilitySelection() async throws {
        let service = LiveTextCaptureService(
            accessibilityClient: AccessibilityCaptureClient(
                isTrusted: { true },
                promptForTrust: { true },
                selectedText: { "Hello from Accessibility" },
                performCopyShortcut: {},
                frontmostBundleIdentifier: { "com.apple.Safari" }
            ),
            clipboardClient: makeClipboardClient()
        )

        let capturedText = try await service.captureSelection()

        guard capturedText.text == "Hello from Accessibility" else {
            throw SmokeTestError("Expected accessibility capture to preserve the selected text.")
        }

        guard capturedText.source == .accessibility else {
            throw SmokeTestError("Expected accessibility capture to report the accessibility source.")
        }

        guard capturedText.frontmostBundleIdentifier == "com.apple.Safari" else {
            throw SmokeTestError("Expected accessibility capture to preserve the frontmost bundle identifier.")
        }
    }

    private static func assertLiveTextCaptureServiceReadsClipboardText() async throws {
        let service = LiveTextCaptureService(
            accessibilityClient: AccessibilityCaptureClient(
                isTrusted: { true },
                promptForTrust: { true },
                selectedText: { nil },
                performCopyShortcut: {},
                frontmostBundleIdentifier: { "com.apple.TextEdit" }
            ),
            clipboardClient: makeClipboardClient(string: "Clipboard text")
        )

        let capturedText = try await service.captureClipboard()

        guard capturedText.text == "Clipboard text" else {
            throw SmokeTestError("Expected clipboard capture to preserve the clipboard text.")
        }

        guard capturedText.source == .clipboard else {
            throw SmokeTestError("Expected clipboard capture to report the clipboard source.")
        }
    }

    private static func assertLiveTextCaptureServiceUsesCopyFallbackAndRestoresClipboard() async throws {
        let clipboardState = ClipboardState(
            currentString: "Before copy",
            changeCount: 3
        )

        let originalSnapshot = ClipboardSnapshot(
            items: [
                ClipboardItemSnapshot(
                    typeData: ["public.utf8-plain-text": Data("Before copy".utf8)]
                )
            ]
        )

        let service = LiveTextCaptureService(
            accessibilityClient: AccessibilityCaptureClient(
                isTrusted: { true },
                promptForTrust: { true },
                selectedText: { nil },
                performCopyShortcut: {
                    clipboardState.setCurrentString("Copied selection")
                    clipboardState.setChangeCount(clipboardState.changeCount() + 1)
                },
                frontmostBundleIdentifier: { "com.google.Chrome" }
            ),
            clipboardClient: ClipboardClient(
                string: {
                    clipboardState.currentString()
                },
                changeCount: {
                    clipboardState.changeCount()
                },
                snapshot: {
                    originalSnapshot
                },
                restore: { snapshot in
                    guard snapshot == originalSnapshot else {
                        throw SmokeTestError("Expected copy fallback to restore the original clipboard snapshot.")
                    }

                    clipboardState.setCurrentString("Before copy")
                },
                waitForChange: { initialChangeCount, _ in
                    clipboardState.changeCount() != initialChangeCount
                }
            )
        )

        let fallbackResult = try await service.captureSelectionUsingCopyFallback()

        guard fallbackResult.capturedText.text == "Copied selection" else {
            throw SmokeTestError("Expected copy fallback to capture the copied selection text.")
        }

        guard fallbackResult.capturedText.source == .copyFallback else {
            throw SmokeTestError("Expected copy fallback to report the copyFallback source.")
        }

        guard fallbackResult.didRestoreClipboard else {
            throw SmokeTestError("Expected copy fallback to report successful clipboard restoration in the smoke harness.")
        }

        guard clipboardState.currentString() == "Before copy" else {
            throw SmokeTestError("Expected copy fallback to restore the prior clipboard string in the smoke harness.")
        }
    }

    private static func assertLiveTextCaptureServiceSkipsCopyFallbackWhenClipboardChangesAgain() async throws {
        let clipboardState = ClipboardState(
            currentString: "Before copy",
            changeCount: 8
        )

        let service = LiveTextCaptureService(
            accessibilityClient: AccessibilityCaptureClient(
                isTrusted: { true },
                promptForTrust: { true },
                selectedText: { nil },
                performCopyShortcut: {
                    clipboardState.setCurrentString("Copied selection")
                    clipboardState.setChangeCount(clipboardState.changeCount() + 1)
                },
                frontmostBundleIdentifier: { "com.google.Chrome" }
            ),
            clipboardClient: ClipboardClient(
                string: {
                    let copiedValue = clipboardState.currentString()

                    // Simulate another app mutating the pasteboard after VoiceBar
                    // observed the copy but before it can trust the copied text.
                    clipboardState.setCurrentString("Clipboard manager override")
                    clipboardState.setChangeCount(clipboardState.changeCount() + 1)
                    return copiedValue
                },
                changeCount: {
                    clipboardState.changeCount()
                },
                snapshot: {
                    ClipboardSnapshot(items: [])
                },
                restore: { _ in
                    throw SmokeTestError("Copy fallback should skip restore when the clipboard changes again.")
                },
                waitForChange: { initialChangeCount, _ in
                    clipboardState.changeCount() != initialChangeCount
                }
            )
        )

        try await assertThrowsTextCaptureError(
            .copyFallbackUnavailable(
                "VoiceBar saw another clipboard change before it could trust the copied selection, so copy fallback was skipped."
            ),
            "Expected copy fallback to fail closed when the clipboard changes again before restore."
        ) {
            _ = try await service.captureSelectionUsingCopyFallback()
        }
    }

    private static func assertLiveTextCaptureServiceReportsRestoreFailureDuringCopyFallbackError() async throws {
        let clipboardState = ClipboardState(
            currentString: "Before copy",
            changeCount: 12
        )

        let service = LiveTextCaptureService(
            accessibilityClient: AccessibilityCaptureClient(
                isTrusted: { true },
                promptForTrust: { true },
                selectedText: { nil },
                performCopyShortcut: {
                    clipboardState.setCurrentString("")
                    clipboardState.setChangeCount(clipboardState.changeCount() + 1)
                },
                frontmostBundleIdentifier: { "com.apple.TextEdit" }
            ),
            clipboardClient: ClipboardClient(
                string: {
                    clipboardState.currentString()
                },
                changeCount: {
                    clipboardState.changeCount()
                },
                snapshot: {
                    ClipboardSnapshot(items: [])
                },
                restore: { _ in
                    throw TextCaptureError.copyFallbackUnavailable("Synthetic restore failure")
                },
                waitForChange: { initialChangeCount, _ in
                    clipboardState.changeCount() != initialChangeCount
                }
            )
        )

        do {
            _ = try await service.captureSelectionUsingCopyFallback()
            throw SmokeTestError("Expected copy fallback to surface the restore failure details.")
        } catch let error as TextCaptureError {
            guard case let .copyFallbackUnavailable(message) = error else {
                throw SmokeTestError("Expected a copyFallbackUnavailable error when restore fails.")
            }

            guard message.contains("could not restore the prior clipboard contents safely") else {
                throw SmokeTestError("Expected the restore failure details to be included in the copy fallback error.")
            }

            guard message.contains("Synthetic restore failure") else {
                throw SmokeTestError("Expected the specific restore failure to be surfaced in the error details.")
            }
        }
    }

    private static func assertLiveTextCaptureServiceRetriesSelectionAfterMenuDelay() async throws {
        final class AttemptCounterBox: @unchecked Sendable {
            private let lock = NSLock()
            private var attempts = 0

            func nextAttempt() -> Int {
                lock.lock()
                defer { lock.unlock() }
                attempts += 1
                return attempts
            }

            func currentValue() -> Int {
                lock.lock()
                defer { lock.unlock() }
                return attempts
            }
        }

        let counter = AttemptCounterBox()
        let service = LiveTextCaptureService(
            accessibilityClient: AccessibilityCaptureClient(
                isTrusted: { true },
                promptForTrust: { true },
                selectedText: {
                    let attempt = counter.nextAttempt()
                    return attempt < 3 ? nil : "Recovered selection"
                },
                performCopyShortcut: {},
                frontmostBundleIdentifier: { "com.apple.TextEdit" }
            ),
            clipboardClient: makeClipboardClient()
        )

        let capturedText = try await service.captureSelection(
            retryCount: 2,
            retryDelayNanoseconds: 0
        )

        guard capturedText.text == "Recovered selection" else {
            throw SmokeTestError("Expected the retrying selection helper to return the recovered Accessibility text.")
        }

        guard counter.currentValue() == 3 else {
            throw SmokeTestError("Expected retryCount to mean retries-after-the-first-attempt so the helper still reaches the third selection attempt here.")
        }
    }

    private static func assertJSONDictationStoresReloadExternalEdits() async throws {
        let temporaryDirectoryURL = try makeTemporaryDirectoryURL()
        defer { try? FileManager.default.removeItem(at: temporaryDirectoryURL) }

        let snippetsURL = temporaryDirectoryURL.appendingPathComponent("dictation-snippets.json")
        let actionsURL = temporaryDirectoryURL.appendingPathComponent("dictation-actions.json")

        let snippetStore = JSONDictationSnippetStore(storageURL: snippetsURL)
        let actionStore = JSONDictationActionRegistryStore(storageURL: actionsURL)

        let initialSnippets = try await snippetStore.loadSnippets()
        guard initialSnippets.isEmpty == false else {
            throw SmokeTestError("Expected the snippet store to seed an initial on-disk config.")
        }

        let initialActions = try await actionStore.loadActions()
        guard initialActions.isEmpty == false else {
            throw SmokeTestError("Expected the action store to seed an initial on-disk config.")
        }

        let updatedSnippets = [
            DictationSnippet(
                id: "custom-snippet",
                triggers: ["hello voicebar"],
                expansion: "Hello VoiceBar"
            )
        ]
        let updatedActions = [
            DictationActionDefinition(
                id: "custom-action",
                displayName: "Custom Action",
                triggers: ["run custom action"],
                scriptPath: "~/bin/custom-action.sh"
            )
        ]

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(updatedSnippets).write(to: snippetsURL, options: .atomic)
        try encoder.encode(updatedActions).write(to: actionsURL, options: .atomic)

        let reloadedSnippets = try await snippetStore.loadSnippets()
        guard reloadedSnippets == updatedSnippets else {
            throw SmokeTestError("Expected the snippet store to reflect external JSON edits without requiring an app restart.")
        }

        let reloadedActions = try await actionStore.loadActions()
        guard reloadedActions == updatedActions else {
            throw SmokeTestError("Expected the action store to reflect external JSON edits without requiring an app restart.")
        }
    }

    private static func assertWisprFlowSnippetImporterPreviewsSafeSyntheticImports() async throws {
        let importer = WisprFlowSnippetImporter(maximumExpansionCharacterCount: 80)
        let existingSnippets = [
            DictationSnippet(
                id: "existing-imported",
                label: "Existing Synthetic Snippet",
                triggers: ["existing trigger"],
                expansion: "Existing synthetic expansion",
                importMetadata: DictationSnippetImportMetadata(
                    sourceApplication: "Wispr Flow",
                    sourceIdentifier: "wispr-flow:existing"
                )
            )
        ]
        let oversizedExpansion = String(repeating: "a", count: 81)
        let payload = """
        {
          "entries": [
            {
              "id": "synthetic-new",
              "label": "Synthetic Multiline",
              "trigger": "synthetic shortcut",
              "expansion": "First synthetic line\\nSecond synthetic line",
              "source": { "name": "Wispr Flow", "id": "source-synthetic" },
              "createdAt": "2026-04-28T09:00:00Z",
              "updatedAt": "2026-04-28T09:30:00Z"
            },
            {
              "id": "existing",
              "label": "Existing Synthetic Snippet",
              "trigger": "updated trigger",
              "expansion": "Updated synthetic expansion"
            },
            {
              "id": "command",
              "label": "Synthetic Command Text",
              "trigger": "synthetic command text",
              "expansion": "Run the synthetic report",
              "type": "command-text"
            },
            {
              "id": "deleted",
              "label": "Deleted Synthetic",
              "trigger": "deleted synthetic",
              "expansion": "Deleted synthetic expansion",
              "deleted": true
            },
            {
              "id": "label-less",
              "trigger": "label less",
              "expansion": "Synthetic expansion"
            },
            {
              "id": "duplicate",
              "label": "Duplicate Synthetic",
              "trigger": "synthetic shortcut",
              "expansion": "Duplicate synthetic expansion"
            },
            {
              "id": "sensitive",
              "label": "Sensitive Synthetic",
              "trigger": "sensitive synthetic",
              "expansion": "Synthetic private placeholder"
            },
            {
              "id": "too-large",
              "label": "Too Large Synthetic",
              "trigger": "too large synthetic",
              "expansion": "\(oversizedExpansion)"
            }
          ]
        }
        """.data(using: .utf8)!
        let manifestPayload = """
        [
          {
            "id": "sensitive",
            "trigger": "sensitive synthetic",
            "expansion_category": "sensitive_secret",
            "expansionLength": 29
          },
          {
            "id": "synthetic-new",
            "trigger": "synthetic shortcut",
            "expansionCategory": "long-text",
            "expansionLength": 42
          }
        ]
        """.data(using: .utf8)!

        let preview = try importer.previewImport(
            from: payload,
            manifestData: manifestPayload,
            existingSnippets: existingSnippets
        )

        guard preview.entryCount == 8 else {
            throw SmokeTestError("Expected the synthetic Wispr Flow preview to account for every export entry.")
        }

        guard preview.importableEntryCount == 4,
              preview.newSnippetCount == 3,
              preview.updatedSnippetCount == 1 else {
            throw SmokeTestError("Expected preview counts to separate new, updated, and quarantined synthetic snippets.")
        }

        guard preview.ignoredDeletedCount == 1,
              preview.invalidEntryCount == 2,
              preview.duplicateTriggerCount == 1,
              preview.quarantinedSensitiveEntryCount == 1,
              preview.commandTextEntryCount == 1 else {
            throw SmokeTestError("Expected preview validation to ignore deleted entries, reject invalid entries, quarantine sensitive entries, and classify command text as snippet text.")
        }

        guard preview.invalidReasonCounts["duplicateTrigger"] == 1,
              preview.invalidReasonCounts["expansionTooLarge"] == 1 else {
            throw SmokeTestError("Expected preview validation reasons to stay count-based without exposing snippet expansions.")
        }

        guard preview.categoryCounts["sensitive-secret"] == 1,
              preview.categoryCounts["long-text"] == 1 else {
            throw SmokeTestError("Expected the redacted manifest to drive category counts and sensitive quarantine without inspecting raw private expansion text.")
        }
    }

    private static func assertWisprFlowSnippetImporterAppliesWithBackupAndMerge() async throws {
        let temporaryDirectoryURL = try makeTemporaryDirectoryURL()
        defer { try? FileManager.default.removeItem(at: temporaryDirectoryURL) }

        let snippetsURL = temporaryDirectoryURL.appendingPathComponent("dictation-snippets.json")
        let existingSnippets = [
            DictationSnippet(
                id: "source-merged",
                label: "Old Source Label",
                triggers: ["old source trigger"],
                expansion: "Old source expansion",
                importMetadata: DictationSnippetImportMetadata(
                    sourceApplication: "Wispr Flow",
                    sourceIdentifier: "wispr-flow:source-one"
                )
            ),
            DictationSnippet(
                id: "trigger-merged",
                label: "Old Trigger Label",
                triggers: ["shared trigger"],
                expansion: "Old trigger expansion"
            )
        ]

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try VoiceBarStorageLocation.ensureDirectoryExists(for: snippetsURL)
        try encoder.encode(existingSnippets).write(to: snippetsURL, options: .atomic)
        let backupDateFormatter = DateFormatter()
        backupDateFormatter.dateFormat = "yyyyMMddHHmmss"
        backupDateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        let staleBackupTimestamp = backupDateFormatter.string(from: Date(timeIntervalSinceNow: -86_400))
        for index in 0..<25 {
            let backupURL = temporaryDirectoryURL
                .appendingPathComponent("dictation-snippets.backup-\(staleBackupTimestamp)-\(String(format: "%02d", index)).json")
            try Data("[]".utf8).write(to: backupURL, options: .atomic)
        }

        let payload = Data(
            #"""
            {
              "snippets": [
                {
                  "id": "source-one",
                  "label": "Updated Source Label",
                  "trigger": "new source trigger",
                  "expansion": "Updated source expansion",
                  "updatedAt": "2026-04-28T10:00:00Z"
                },
                {
                  "id": "trigger-one",
                  "label": "Updated Trigger Label",
                  "trigger": "shared trigger",
                  "expansion": "First trigger line\nSecond trigger line",
                  "category": "Synthetic Category"
                },
                {
                  "id": "command-one",
                  "label": "Command Text Import",
                  "trigger": "command text trigger",
                  "expansion": "Run the synthetic command text",
                  "type": "command-text"
                },
                {
                  "id": "secret-one",
                  "label": "Synthetic Secret",
                  "trigger": "secret trigger",
                  "expansion": "secret: synthetic-placeholder"
                },
                {
                  "id": "deleted-one",
                  "label": "Deleted Entry",
                  "trigger": "deleted trigger",
                  "expansion": "Deleted expansion",
                  "deleted": 1
                }
              ]
            }
            """#.utf8
        )

        let importer = WisprFlowSnippetImporter(storageURL: snippetsURL)
        let summary = try await importer.applyImport(from: payload)

        guard let backupURL = summary.backupURL,
              FileManager.default.fileExists(atPath: backupURL.path) else {
            throw SmokeTestError("Expected Wispr Flow apply to create a rollback backup before writing snippets.")
        }

        let retainedBackupFileNames = try FileManager.default.contentsOfDirectory(atPath: temporaryDirectoryURL.path)
            .filter { fileName in
                fileName.hasPrefix("dictation-snippets.backup-") && fileName.hasSuffix(".json")
            }

        guard retainedBackupFileNames.count <= 20,
              retainedBackupFileNames.contains(backupURL.lastPathComponent) else {
            throw SmokeTestError("Expected Wispr Flow apply to retain the new backup while pruning stale backups.")
        }

        guard summary.preview.updatedSnippetCount == 2,
              summary.preview.newSnippetCount == 1,
              summary.preview.quarantinedSensitiveEntryCount == 1,
              summary.preview.ignoredDeletedCount == 1,
              summary.storedSnippetCount == 3 else {
            throw SmokeTestError("Expected Wispr Flow apply summary to describe merge results without exposing expansion values.")
        }

        let storedData = try Data(contentsOf: snippetsURL)
        let storedSnippets = try JSONDecoder().decode([DictationSnippet].self, from: storedData)

        guard let sourceMerged = storedSnippets.first(where: { $0.id == "source-merged" }),
              sourceMerged.label == "Updated Source Label",
              sourceMerged.triggers.contains("old source trigger"),
              sourceMerged.triggers.contains("new source trigger") else {
            throw SmokeTestError("Expected source-identifier matching to update the existing snippet while preserving operator-added triggers.")
        }

        guard let triggerMerged = storedSnippets.first(where: { $0.id == "trigger-merged" }),
              triggerMerged.expansion == "First trigger line\nSecond trigger line" else {
            throw SmokeTestError("Expected trigger matching to update the existing snippet and preserve multiline expansion text.")
        }

        guard storedSnippets.contains(where: {
            $0.label == "Command Text Import"
                && $0.importMetadata?.sourceKind == "command-text"
        }) else {
            throw SmokeTestError("Expected command-text entries to import as text snippets rather than executable actions.")
        }

        guard storedSnippets.contains(where: { $0.label == "Synthetic Secret" }) == false else {
            throw SmokeTestError("Expected sensitive-looking synthetic entries to stay out of the active snippet store by default.")
        }

        let repeatPreview = try importer.previewImport(
            from: payload,
            existingSnippets: storedSnippets
        )

        guard repeatPreview.updatedSnippetCount == 0,
              repeatPreview.unchangedSnippetCount == 3 else {
            throw SmokeTestError("Expected a repeated Wispr Flow preview to classify unchanged snippets as unchanged, not as timestamp-only updates.")
        }
    }

    private static func assertWisprFlowSnippetImporterRejectsMultiSnippetTriggerConflicts() async throws {
        let existingSnippets = [
            DictationSnippet(
                id: "first-existing",
                triggers: ["first shared"],
                expansion: "First synthetic expansion"
            ),
            DictationSnippet(
                id: "second-existing",
                triggers: ["second shared"],
                expansion: "Second synthetic expansion"
            )
        ]
        let payload = Data(
            #"""
            [
              {
                "id": "multi-conflict",
                "label": "Multi Trigger Conflict",
                "triggers": ["first shared", "second shared"],
                "expansion": "Synthetic merged expansion"
              }
            ]
            """#.utf8
        )

        let preview = try WisprFlowSnippetImporter().previewImport(
            from: payload,
            existingSnippets: existingSnippets
        )

        guard preview.importableEntryCount == 0,
              preview.invalidEntryCount == 1,
              preview.duplicateTriggerCount == 1,
              preview.invalidReasonCounts["duplicateExistingTrigger"] == 1 else {
            throw SmokeTestError("Expected an import candidate that touches two existing snippets to be rejected instead of duplicating an enabled trigger.")
        }
    }

    private static func assertWisprFlowSnippetImporterRejectsPunctuationEquivalentTriggers() async throws {
        let payload = Data(
            #"""
            [
              {
                "id": "plain-trigger",
                "label": "Plain Trigger",
                "trigger": "synthetic email",
                "expansion": "First synthetic expansion"
              },
              {
                "id": "punctuated-trigger",
                "label": "Punctuated Trigger",
                "trigger": "synthetic email.",
                "expansion": "Second synthetic expansion"
              }
            ]
            """#.utf8
        )

        let preview = try WisprFlowSnippetImporter().previewImport(from: payload)

        guard preview.importableEntryCount == 1,
              preview.invalidEntryCount == 1,
              preview.duplicateTriggerCount == 1,
              preview.invalidReasonCounts["duplicateTrigger"] == 1 else {
            throw SmokeTestError("Expected punctuation-equivalent triggers to be rejected before runtime matching could choose the wrong expansion.")
        }
    }

    private static func assertWisprFlowSnippetImporterDoesNotQuarantineHyphenatedWords() async throws {
        let payload = Data(
            #"""
            [
              {
                "id": "hyphen-safe",
                "label": "Hyphen Safe",
                "trigger": "hyphen safe",
                "expansion": "Use a risk-based task-list for this synthetic plan."
              }
            ]
            """#.utf8
        )

        let preview = try WisprFlowSnippetImporter().previewImport(from: payload)

        guard preview.importableEntryCount == 1,
              preview.quarantinedSensitiveEntryCount == 0 else {
            throw SmokeTestError("Expected ordinary hyphenated words containing sk- across word boundaries to import normally.")
        }
    }

    private static func assertWisprFlowSnippetImporterAcceptsSingleEntryManifest() async throws {
        let payload = Data(
            #"""
            [
              {
                "id": "single-manifest-entry",
                "label": "Single Manifest Entry",
                "trigger": "single manifest trigger",
                "expansion": "Synthetic command text"
              }
            ]
            """#.utf8
        )
        let manifest = Data(
            #"""
            {
              "id": "single-manifest-entry",
              "expansionCategory": "command-text"
            }
            """#.utf8
        )

        let preview = try WisprFlowSnippetImporter().previewImport(
            from: payload,
            manifestData: manifest
        )

        guard preview.importableEntryCount == 1,
              preview.commandTextEntryCount == 1,
              preview.categoryCounts["command-text"] == 1 else {
            throw SmokeTestError("Expected a single-object redacted manifest to classify its matching synthetic entry.")
        }
    }

    private static func assertWisprFlowSnippetImporterAcceptsLabelLessSnippets() async throws {
        let temporaryDirectoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("voicebar-label-less-import-\(UUID().uuidString)", isDirectory: true)
        let snippetsURL = temporaryDirectoryURL.appendingPathComponent("dictation-snippets.json")
        defer {
            try? FileManager.default.removeItem(at: temporaryDirectoryURL)
        }

        let payload = Data(
            #"""
            {
              "entries": [
                {
                  "id": "label-less",
                  "phrase": "label less synthetic",
                  "replacement": "Synthetic expansion without a source label"
                }
              ]
            }
            """#.utf8
        )

        let importer = WisprFlowSnippetImporter(storageURL: snippetsURL)
        _ = try await importer.applyImport(from: payload)
        let storedData = try Data(contentsOf: snippetsURL)
        let storedSnippets = try JSONDecoder().decode([DictationSnippet].self, from: storedData)
        let importedSnippet = storedSnippets.first { snippet in
            snippet.id == "wispr-flow-wispr-flow-label-less"
        }

        guard importedSnippet?.label == "label less synthetic",
              importedSnippet?.triggers == ["label less synthetic"],
              importedSnippet?.expansion == "Synthetic expansion without a source label" else {
            throw SmokeTestError("Expected label-less Wispr Flow entries to import using the trigger as the VoiceBar label.")
        }
    }

    private static func assertWisprFlowSnippetImporterDoesNotReserveQuarantinedTriggers() async throws {
        let payload = Data(
            #"""
            [
              {
                "id": "sensitive-first",
                "label": "Sensitive First",
                "trigger": "shared synthetic trigger",
                "expansion": "Synthetic sensitive placeholder",
                "category": "sensitive-secret"
              },
              {
                "id": "safe-second",
                "label": "Safe Second",
                "trigger": "shared synthetic trigger",
                "expansion": "Safe synthetic expansion"
              }
            ]
            """#.utf8
        )

        let preview = try WisprFlowSnippetImporter().previewImport(from: payload)

        guard preview.importableEntryCount == 1,
              preview.newSnippetCount == 1,
              preview.quarantinedSensitiveEntryCount == 1,
              preview.duplicateTriggerCount == 0,
              preview.invalidEntryCount == 0 else {
            throw SmokeTestError("Expected quarantined sensitive entries not to reserve duplicate triggers against later safe snippets.")
        }
    }

    private static func assertWisprFlowSnippetImporterKeepsEntryIdentifiersDistinct() async throws {
        let temporaryDirectoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("voicebar-distinct-source-import-\(UUID().uuidString)", isDirectory: true)
        let snippetsURL = temporaryDirectoryURL.appendingPathComponent("dictation-snippets.json")
        defer {
            try? FileManager.default.removeItem(at: temporaryDirectoryURL)
        }

        let payload = Data(
            #"""
            [
              {
                "id": "first-entry",
                "label": "First Entry",
                "trigger": "first entry",
                "expansion": "First synthetic expansion",
                "source": { "id": "shared-source" }
              },
              {
                "id": "second-entry",
                "label": "Second Entry",
                "trigger": "second entry",
                "expansion": "Second synthetic expansion",
                "source": { "id": "shared-source" }
              }
            ]
            """#.utf8
        )

        let importer = WisprFlowSnippetImporter(storageURL: snippetsURL)
        _ = try await importer.applyImport(from: payload)
        let storedData = try Data(contentsOf: snippetsURL)
        let storedSnippets = try JSONDecoder().decode([DictationSnippet].self, from: storedData)
        let sourceIdentifiers = Set(
            storedSnippets.compactMap(\.importMetadata?.sourceIdentifier)
                .filter { $0.hasPrefix("wispr-flow:") }
        )

        guard sourceIdentifiers == ["wispr-flow:first-entry", "wispr-flow:second-entry"] else {
            throw SmokeTestError("Expected per-entry Wispr Flow identifiers to keep snippets with shared source metadata distinct.")
        }
    }

    private static func assertUnconfiguredSpeechEngineSurfacesUnavailableState() async throws {
        let engine = UnconfiguredSpeechEngine(
            identifier: "test-engine",
            unavailableReason: "Not configured yet"
        )

        let availability = engine.availability
        guard availability.isAvailable == false else {
            throw SmokeTestError("Expected the unconfigured engine to report unavailable.")
        }

        guard availability.reason == "Not configured yet" else {
            throw SmokeTestError("Expected the unconfigured engine to preserve its unavailable reason.")
        }

        try await assertThrowsBootstrapError(
            "Expected prepare() to throw until the engine is configured."
        ) {
            try await engine.prepare()
        }

        let request = SpeechRequest(text: "Hello", preferredMode: .quick)
        var iterator = engine.synthesize(request).makeAsyncIterator()
        try await assertThrowsBootstrapError(
            "Expected synthesize() to fail for the unconfigured engine."
        ) {
            _ = try await iterator.next()
        }

        await engine.stop()
    }

    private static func assertSpeechChunkSupportsJSONRoundTrip() async throws {
        let chunk = SpeechChunk(textFragment: "Hello", sequenceNumber: 7)
        let encoded = try JSONEncoder().encode(chunk)
        let decoded = try JSONDecoder().decode(SpeechChunk.self, from: encoded)

        guard decoded == chunk else {
            throw SmokeTestError("Expected SpeechChunk to round-trip through JSON encoding.")
        }
    }

    private static func assertSpeechRequestSupportsVoiceSelectionRoundTrip() async throws {
        let request = SpeechRequest(
            text: "Hello world.",
            preferredMode: .premium,
            styleInstruction: SpeechStyleCatalog.instruction(
                for: SpeechStyleCatalog.defaultPresetName,
                customInstruction: ""
            ),
            voiceIdentifier: SpeechVoiceCatalog.defaultVoiceIdentifier,
            bundleIdentifier: "com.openai.codex"
        )
        let encoded = try JSONEncoder().encode(request)
        let decoded = try JSONDecoder().decode(SpeechRequest.self, from: encoded)

        guard decoded == request else {
            throw SmokeTestError("Expected SpeechRequest to preserve voice selection through JSON encoding.")
        }
    }

    private static func assertOllamaFormatterDecodeRoundTripsStructuredSchema() async throws {
        let payload = Data(
            """
            {
              "message": {
                "content": "{\\"cleanedText\\":\\"Hello world\\",\\"formattedText\\":\\"Hello, world!\\",\\"detectedMode\\":\\"dictation\\",\\"snippetApplications\\":[{\\"snippetID\\":\\"local-notes\\",\\"trigger\\":\\"local notes\\",\\"expansion\\":\\"Local Notes\\"}],\\"actionCandidates\\":[{\\"actionID\\":\\"example-local-notes\\",\\"triggerPhrase\\":\\"open example local notes\\",\\"confidence\\":0.92}],\\"shouldInsertText\\":true,\\"confidence\\":0.88}"
              }
            }
            """.utf8
        )

        let decoded = try OllamaFormatterService.decodeFormatterResponse(from: payload)

        guard decoded.cleanedText == "Hello world" else {
            throw SmokeTestError("Expected Ollama formatter decoding to preserve cleanedText.")
        }

        guard decoded.formattedText == "Hello, world!" else {
            throw SmokeTestError("Expected Ollama formatter decoding to preserve formattedText.")
        }

        guard decoded.actionCandidates.first?.actionID == "example-local-notes" else {
            throw SmokeTestError("Expected Ollama formatter decoding to preserve action candidates.")
        }
    }

    private static func assertKokoroPlaybackPlannerChunksLongReadsForInteractiveStart() async throws {
        let segments = KokoroPlaybackPlanner.plannedSegments(
            for: """
            This is a longer paragraph that should be split into smaller grouped segments for faster interactive playback on the Kokoro quick path, even before the full request has finished synthesizing.

            This is a second paragraph so the planner also keeps a paragraph pause instead of flattening everything into one long monologue.
            """
        )

        guard segments.count >= 2 else {
            throw SmokeTestError("Expected the Kokoro quick planner to split long reads into multiple grouped segments.")
        }

        guard segments.contains(where: { $0.pauseAfterMilliseconds > 0 }) else {
            throw SmokeTestError("Expected the Kokoro quick planner to preserve paragraph pauses between grouped segments.")
        }
    }

    private static func assertKokoroPlaybackPlannerKeepsFirstSegmentSmall() async throws {
        let repeatedWords = Array(repeating: "word", count: 72)
        try assertKokoroFirstSegmentIsSmall(
            text: repeatedWords.joined(separator: " "),
            context: "plain long text"
        )

        try assertKokoroFirstSegmentIsSmall(
            text: "One two three four five six seven eight nine ten eleven twelve thirteen fourteen, then the rest of this synthetic sentence continues.",
            context: "clause-heavy opening text"
        )
    }

    private static func assertKokoroFirstSegmentIsSmall(
        text: String,
        context: String
    ) throws {
        let segments = KokoroPlaybackPlanner.plannedSegments(for: text)
        guard let firstSegment = segments.first else {
            throw SmokeTestError("Expected Kokoro quick planning to produce at least one segment for \(context).")
        }

        let firstSegmentWordCount = firstSegment.text
            .split(whereSeparator: { $0.isWhitespace || $0.isNewline })
            .count

        guard firstSegmentWordCount <= 12 else {
            throw SmokeTestError("Expected Kokoro quick planning to cap the first segment at 12 words for \(context).")
        }
    }

    private static func assertSnippetExpansionAndDeterministicActionRoutingStayAligned() async throws {
        let snippetExpansion = DictationTextExpander.applySnippets(
            to: "please run example notes",
            snippets: [
                DictationSnippet(
                    id: "example-notes-command",
                    triggers: ["example notes"],
                    expansion: "open example local notes"
                )
            ]
        )

        guard snippetExpansion.text.contains("open example local notes") else {
            throw SmokeTestError("Expected snippet expansion to produce the configured text expansion.")
        }

        let formatterResponse = DictationFormatterResponse(
            cleanedText: "open example local notes",
            formattedText: "",
            detectedMode: .command,
            snippetApplications: snippetExpansion.applications,
            actionCandidates: [
                DictationActionCandidate(
                    actionID: "example-local-notes",
                    triggerPhrase: "open example local notes",
                    confidence: 0.91
                )
            ],
            shouldInsertText: false,
            confidence: 0.91
        )

        let resolvedAction = DictationActionRouter.resolveAction(
            transcript: "please run example notes",
            formatterResponse: formatterResponse,
            actions: [
                DictationActionDefinition(
                    id: "example-local-notes",
                    displayName: "Example Local Notes",
                    triggers: ["open example local notes"],
                    scriptPath: "/tmp/fake-example-local-notes.sh"
                )
            ]
        )

        guard resolvedAction == nil else {
            throw SmokeTestError("Expected snippet-expanded command text and formatter candidates to stay unable to trigger actions.")
        }
    }

    private static func assertSyntheticLocalNotesSnippetAliasesExpandSameText() async throws {
        let syntheticExpansion = "synthetic local-notes command text"
        let aliases = [
            "open example local notes",
            "open local notes",
            "example local notes"
        ]
        let snippets = [
            DictationSnippet(
                id: "synthetic-local-notes",
                label: "Synthetic Local Notes",
                triggers: aliases,
                expansion: syntheticExpansion
            )
        ]

        for alias in aliases {
            let expansion = DictationTextExpander.applySnippets(
                to: alias,
                snippets: snippets
            )

            guard expansion.text == syntheticExpansion else {
                throw SmokeTestError("Expected every explicit open example local notes alias to expand to the same stored text.")
            }

            guard expansion.applications.first?.trigger == alias else {
                throw SmokeTestError("Expected alias expansion metadata to preserve the exact matched trigger phrase.")
            }
        }
    }

    private static func assertGoogleCloudPlatformLoginSnippetAliasesExpandSameText() async throws {
        let syntheticExpansion = "synthetic command text only"
        let aliases = [
            "Google Cloud login",
            "Google Cloud log in",
            "Google Cloud Logging",
            "GCP login",
            "GCP log in"
        ]
        let snippets = [
            DictationSnippet(
                id: "synthetic-google-cloud-platform-login",
                label: "Google Cloud Platform login",
                triggers: aliases,
                expansion: syntheticExpansion
            )
        ]

        for alias in aliases {
            let expansion = DictationTextExpander.applySnippets(
                to: alias,
                snippets: snippets
            )

            guard expansion.text == syntheticExpansion else {
                throw SmokeTestError("Expected every explicit Google Cloud Platform login alias to expand to the same stored text.")
            }

            guard expansion.applications.first?.trigger == alias else {
                throw SmokeTestError("Expected Google Cloud Platform alias expansion metadata to preserve the exact matched trigger phrase.")
            }
        }
    }

    private static func assertCommandTextSnippetExpandsWithoutActionExecution() async throws {
        let commandText = "synthetic-cli --dry-run"
        let snippetExpansion = DictationTextExpander.applySnippets(
            to: "synthetic command trigger",
            snippets: [
                DictationSnippet(
                    id: "synthetic-command-text",
                    label: "Synthetic Command Text",
                    triggers: ["synthetic command trigger"],
                    expansion: commandText
                )
            ]
        )

        guard snippetExpansion.text == commandText else {
            throw SmokeTestError("Expected command-text snippets to expand as plain insertion text.")
        }

        let formatterResponse = DictationFormatterResponse(
            cleanedText: snippetExpansion.text,
            formattedText: snippetExpansion.text,
            detectedMode: .dictation,
            snippetApplications: snippetExpansion.applications,
            actionCandidates: [],
            shouldInsertText: true
        )
        let resolvedAction = DictationActionRouter.resolveAction(
            transcript: snippetExpansion.text,
            formatterResponse: formatterResponse,
            actions: [
                DictationActionDefinition(
                    id: "synthetic-command-text",
                    displayName: "Synthetic Command Text",
                    triggers: ["synthetic command trigger"],
                    scriptPath: "/tmp/synthetic-command-text.sh"
                )
            ]
        )

        guard resolvedAction == nil else {
            throw SmokeTestError("Expected command-text snippet expansion to avoid action execution unless a separate allowlisted action resolves.")
        }
    }

    private static func assertSnippetLabelIsNotImplicitTrigger() async throws {
        let snippet = DictationSnippet(
            id: "synthetic-label-only",
            label: "Synthetic Label",
            triggers: ["spoken synthetic trigger"],
            expansion: "synthetic expansion"
        )

        let labelExpansion = DictationTextExpander.applySnippets(
            to: "Synthetic Label",
            snippets: [snippet]
        )
        guard labelExpansion.text == "Synthetic Label", labelExpansion.applications.isEmpty else {
            throw SmokeTestError("Expected snippet labels to stay display-only unless added to the trigger list.")
        }

        let triggerExpansion = DictationTextExpander.applySnippets(
            to: "spoken synthetic trigger",
            snippets: [snippet]
        )
        guard triggerExpansion.text == "synthetic expansion" else {
            throw SmokeTestError("Expected explicit snippet triggers to keep expanding normally.")
        }
    }

    private static func assertAddLabelAsTriggerDeduplicatesNormalizedTriggers() async throws {
        let triggers = DictationSnippetTriggerUtilities.addingLabelAsTrigger(
            label: "Synthetic Label",
            to: ["existing trigger", "synthetic-label"]
        )

        guard triggers == ["existing trigger", "synthetic-label"] else {
            throw SmokeTestError("Expected Add Label as Trigger to avoid normalized duplicates in the same draft.")
        }

        let appendedTriggers = DictationSnippetTriggerUtilities.addingLabelAsTrigger(
            label: "New Synthetic Label",
            to: ["existing trigger"]
        )

        guard appendedTriggers == ["existing trigger", "New Synthetic Label"] else {
            throw SmokeTestError("Expected Add Label as Trigger to append a non-empty label when no normalized trigger exists.")
        }
    }

    private static func assertAddLabelAsTriggerSupportsNonLatinLabels() async throws {
        let appendedTriggers = DictationSnippetTriggerUtilities.addingLabelAsTrigger(
            label: "你好",
            to: ["existing trigger"]
        )

        guard appendedTriggers == ["existing trigger", "你好"] else {
            throw SmokeTestError("Expected Add Label as Trigger to support non-Latin labels when the label is non-empty.")
        }

        let deduplicatedTriggers = DictationSnippetTriggerUtilities.addingLabelAsTrigger(
            label: "你好",
            to: ["existing trigger", "你好"]
        )

        guard deduplicatedTriggers == ["existing trigger", "你好"] else {
            throw SmokeTestError("Expected Add Label as Trigger to avoid duplicate non-Latin trigger labels.")
        }

        let snippet = DictationSnippet(
            id: "synthetic-non-latin-label",
            label: "你好",
            triggers: appendedTriggers,
            expansion: "synthetic non-Latin expansion"
        )
        let expansion = DictationTextExpander.applySnippets(
            to: "你好",
            snippets: [snippet]
        )
        guard expansion.text == "synthetic non-Latin expansion" else {
            throw SmokeTestError("Expected a non-Latin label added as a trigger to expand as an exact trigger.")
        }
    }

    private static func assertMixedScriptTriggersDoNotCollapseToSharedDigitKey() async throws {
        let triggers = DictationSnippetTriggerUtilities.uniquedTriggers([
            "你好 1",
            "再见 1"
        ])

        guard triggers == ["你好 1", "再见 1"] else {
            throw SmokeTestError("Expected mixed-script triggers with the same digit to remain distinct.")
        }

        let appendedTriggers = DictationSnippetTriggerUtilities.addingLabelAsTrigger(
            label: "你好 1",
            to: ["再见 1"]
        )

        guard appendedTriggers == ["再见 1", "你好 1"] else {
            throw SmokeTestError("Expected Add Label as Trigger to preserve distinct mixed-script triggers.")
        }
    }

    private static func assertSyntheticProductNameSpeechAliasesExpandSameText() async throws {
        let aliases = DictationSnippetTriggerUtilities.conservativeSpeechAliases(for: "@ExampleAudit")
        guard aliases == ["ExampleAudit", "Example Audit"] else {
            throw SmokeTestError("Expected conservative speech aliases to strip a leading at sign and space camel-case synthetic product labels.")
        }

        let snippet = DictationSnippet(
            id: "synthetic-review-tool",
            label: "@ExampleAudit",
            triggers: aliases,
            expansion: "synthetic audit review request"
        )

        for alias in ["ExampleAudit", "Example Audit"] {
            let expansion = DictationTextExpander.applySnippets(
                to: alias,
                snippets: [snippet]
            )

            guard expansion.text == "synthetic audit review request" else {
                throw SmokeTestError("Expected synthetic product-name speech aliases to expand to the same text.")
            }
        }
    }

    private static func assertSnippetExpansionTreatsWholeUtteranceTriggersWithTrailingPunctuationAsExactMatch() async throws {
        let snippetExpansion = DictationTextExpander.applySnippets(
            to: "live email one.",
            snippets: [
                DictationSnippet(
                    id: "live-email-one",
                    triggers: ["live email one"],
                    expansion: "team@voicebar.local"
                )
            ]
        )

        guard snippetExpansion.text == "team@voicebar.local" else {
            throw SmokeTestError("Expected exact whole-utterance snippet triggers to ignore trailing punctuation from STT.")
        }

        guard snippetExpansion.applications.first?.trigger == "live email one" else {
            throw SmokeTestError("Expected snippet application metadata to preserve the exact matched trigger.")
        }
    }

    private static func assertSnippetExpansionPreservesLiteralDollarAmounts() async throws {
        let snippetExpansion = DictationTextExpander.applySnippets(
            to: "the annual plan price",
            snippets: [
                DictationSnippet(
                    id: "plan-price",
                    triggers: ["annual plan price"],
                    expansion: "costs $50 per month"
                )
            ]
        )

        guard snippetExpansion.text == "the costs $50 per month" else {
            throw SmokeTestError("Expected snippet expansion to preserve literal dollar amounts instead of treating them as regex capture references.")
        }

        guard snippetExpansion.applications.first?.expansion == "costs $50 per month" else {
            throw SmokeTestError("Expected snippet application metadata to preserve the original operator-authored expansion text.")
        }
    }

    private static func assertDeterministicFormatterHandlesStructuredDictationAcceptanceFixtures() async throws {
        let numberedList = DictationDeterministicFormatter.apply(
            to: "make this a numbered list one apples two oranges three pears"
        )
        guard numberedList.text == "1. apples\n2. oranges\n3. pears", numberedList.shouldBypassModel else {
            throw SmokeTestError("Expected explicit numbered-list dictation to produce a deterministic numbered list.")
        }

        let sortedNumberedList = DictationDeterministicFormatter.apply(
            to: "this should be a sorted numbered list one bananas two apples three carrots"
        )
        guard sortedNumberedList.text == "1. apples\n2. bananas\n3. carrots", sortedNumberedList.shouldBypassModel else {
            throw SmokeTestError("Expected sorted numbered-list dictation to sort items deterministically.")
        }

        let sortedList = DictationDeterministicFormatter.apply(
            to: "this should be a sorted list one bananas two apples three carrots"
        )
        guard sortedList.text == "1. apples\n2. bananas\n3. carrots", sortedList.shouldBypassModel else {
            throw SmokeTestError("Expected sorted-list dictation to sort items deterministically.")
        }

        let bulletList = DictationDeterministicFormatter.apply(
            to: "write this as a bullet list apples oranges pears"
        )
        guard bulletList.text == "- apples\n- oranges\n- pears", bulletList.shouldBypassModel else {
            throw SmokeTestError("Expected explicit bullet-list dictation to produce a deterministic bullet list.")
        }

        let email = DictationDeterministicFormatter.apply(
            to: "format this as an email to the team saying the report is ready"
        )
        guard email.text == "To: the team\n\nThe report is ready.", email.shouldBypassModel else {
            throw SmokeTestError("Expected explicit email dictation to produce a deterministic synthetic email fixture.")
        }

        let malformedEmail = DictationDeterministicFormatter.apply(
            to: "format this as an email the team saying the report is ready"
        )
        guard malformedEmail.text == "format this as an email the team saying the report is ready",
              malformedEmail.shouldBypassModel == false else {
            throw SmokeTestError("Expected email formatting without a recipient marker to remain unformatted.")
        }

        let naturalProse = "this is a new line of products"
        let proseResult = DictationDeterministicFormatter.apply(to: naturalProse)
        guard proseResult.text == naturalProse, proseResult.shouldBypassModel == false else {
            throw SmokeTestError("Expected natural prose containing 'new line' to remain normal prose.")
        }
    }

    private static func assertDeterministicFormatterHandlesExplicitListAndSpokenPunctuation() async throws {
        let result = DictationDeterministicFormatter.apply(
            to: "make this a numbered list one apples two oranges three pears period"
        )

        guard result.text.contains("1. apples") else {
            throw SmokeTestError("Expected deterministic formatter to render the first numbered list item.")
        }

        guard result.text.contains("2. oranges") else {
            throw SmokeTestError("Expected deterministic formatter to render the second numbered list item.")
        }

        guard result.text.contains("3. pears") else {
            throw SmokeTestError("Expected deterministic formatter to render the third numbered list item.")
        }

        guard result.shouldBypassModel else {
            throw SmokeTestError("Expected deterministic formatter list rules to bypass the model for obvious formatting commands.")
        }
    }

    private static func assertDeterministicFormatterHandlesBareNumberedListCommand() async throws {
        let result = DictationDeterministicFormatter.apply(
            to: "numbered list one apples two oranges three pears"
        )

        guard result.text.contains("1. apples") else {
            throw SmokeTestError("Expected bare 'numbered list' command to render the first numbered list item.")
        }

        guard result.text.contains("2. oranges") else {
            throw SmokeTestError("Expected bare 'numbered list' command to render the second numbered list item.")
        }

        guard result.text.contains("3. pears") else {
            throw SmokeTestError("Expected bare 'numbered list' command to render the third numbered list item.")
        }

        guard result.shouldBypassModel else {
            throw SmokeTestError("Expected bare 'numbered list' command to bypass formatter model requests.")
        }
    }

    private static func assertDeterministicFormatterLeavesWhitespaceUntouchedWhenNoRulesApply() async throws {
        let sourceText = "first line\n\nsecond line\twith    spacing"
        let result = DictationDeterministicFormatter.apply(to: sourceText)

        guard result.text == sourceText else {
            throw SmokeTestError("Expected deterministic formatter to preserve original whitespace when no deterministic rules are applied.")
        }

        guard result.didApplyFormatting == false, result.shouldBypassModel == false else {
            throw SmokeTestError("Expected deterministic formatter to avoid bypassing the model when no explicit formatting command was detected.")
        }
    }

    private static func assertDeterministicFormatterRecognizesSpokenPunctuationWithTrailingSTTPunctuation() async throws {
        let result = DictationDeterministicFormatter.apply(to: "hello world period.")

        guard result.didApplyFormatting, result.shouldBypassModel else {
            throw SmokeTestError("Expected deterministic formatter to recognize spoken punctuation even when STT appends trailing punctuation.")
        }

        guard result.text.lowercased().contains("period") == false else {
            throw SmokeTestError("Expected deterministic punctuation formatting to replace spoken punctuation tokens with symbols.")
        }
    }

    private static func assertDeterministicFormatterHandlesExpandedSpokenPunctuation() async throws {
        let result = DictationDeterministicFormatter.apply(
            to: "hello comma world exclamation point"
        )

        guard result.text == "Hello, world!" else {
            throw SmokeTestError("Expected expanded spoken punctuation aliases to render as symbols.")
        }

        let fullStop = DictationDeterministicFormatter.apply(to: "the build passed full stop")
        guard fullStop.text == "The build passed." else {
            throw SmokeTestError("Expected British spoken punctuation 'full stop' to render as a period.")
        }
    }

    private static func assertDeterministicFormatterDoesNotRewriteNaturalProseLineMentions() async throws {
        let prose = "we are launching a new line of products"
        let result = DictationDeterministicFormatter.apply(to: prose)

        guard result.text == prose else {
            throw SmokeTestError("Expected deterministic formatter to preserve natural-prose occurrences of 'new line' instead of forcing structural line breaks.")
        }

        guard result.didApplyFormatting == false, result.shouldBypassModel == false else {
            throw SmokeTestError("Expected deterministic formatter to keep model cleanup enabled for natural-prose 'new line' phrases.")
        }
    }

    private static func assertDeterministicFormatterPreservesStandaloneLineBreakCommands() async throws {
        let newLine = DictationDeterministicFormatter.apply(to: "new line")
        guard newLine.text == "\n", newLine.shouldBypassModel else {
            throw SmokeTestError("Expected standalone 'new line' to insert a line break instead of being trimmed to empty text.")
        }

        let newParagraph = DictationDeterministicFormatter.apply(to: "new paragraph")
        guard newParagraph.text == "\n\n", newParagraph.shouldBypassModel else {
            throw SmokeTestError("Expected standalone 'new paragraph' to insert paragraph spacing instead of being trimmed to empty text.")
        }
    }

    private static func assertFallbackTextPolisherImprovesSentenceAndQuestionOutput() async throws {
        let statement = DictationFallbackTextPolisher.apply(
            to: "hello world this is a test",
            qualityMode: .balanced
        )
        guard statement == "Hello world this is a test." else {
            throw SmokeTestError("Expected formatter fallback polish to capitalize and punctuate statements.")
        }

        let question = DictationFallbackTextPolisher.apply(
            to: "can you send me the latest build status",
            qualityMode: .balanced
        )
        guard question == "Can you send me the latest build status?" else {
            throw SmokeTestError("Expected formatter fallback polish to detect common question forms.")
        }

        let modelQuestion = DictationFallbackTextPolisher.apply(
            to: "Can you send me the latest build status.",
            sourceTranscript: "can you send me the latest build status",
            qualityMode: .balanced
        )
        guard modelQuestion == "Can you send me the latest build status?" else {
            throw SmokeTestError("Expected formatter fallback polish to correct model output that missed a question mark.")
        }

        let modelExclamation = DictationFallbackTextPolisher.apply(
            to: "Hello world!",
            sourceTranscript: "hello world",
            qualityMode: .balanced
        )
        guard modelExclamation == "Hello world." else {
            throw SmokeTestError("Expected formatter fallback polish to remove unsupported model exclamation marks.")
        }
    }

    private static func assertDictationPipelinePolishesModelPunctuationBeforeInsertion() async throws {
        let pipeline = DictationPipeline(
            formatterService: UnderPunctuatingDictationFormatter(),
            snippetStore: InMemoryDictationSnippetStore(snippets: []),
            actionStore: InMemoryDictationActionStore(actions: [])
        )

        let questionResult = try await pipeline.processTranscript(
            "can you send me the latest build status",
            formattingMode: .notes,
            qualityMode: .balanced,
            formatterModelIdentifier: "llama3.2:3b",
            frontmostBundleIdentifier: "com.example.voicebar.synthetic-host"
        )

        guard questionResult.insertionText == "Can you send me the latest build status?" else {
            throw SmokeTestError("Expected dictation pipeline to repair missing model question punctuation before insertion.")
        }

        let statementResult = try await pipeline.processTranscript(
            "hello world",
            formattingMode: .notes,
            qualityMode: .balanced,
            formatterModelIdentifier: "llama3.2:3b",
            frontmostBundleIdentifier: "com.example.voicebar.synthetic-host"
        )

        guard statementResult.insertionText == "Hello world." else {
            throw SmokeTestError("Expected dictation pipeline to remove unsupported model exclamation before insertion.")
        }
    }

    private static func assertDictationPipelineRecoversFromEmptyModelDictationOutput() async throws {
        let pipeline = DictationPipeline(
            formatterService: EmptyDictationFormatter(),
            snippetStore: InMemoryDictationSnippetStore(snippets: []),
            actionStore: InMemoryDictationActionStore(actions: [])
        )

        let result = try await pipeline.processTranscript(
            "can you send me the latest build status",
            formattingMode: .notes,
            qualityMode: .quality,
            formatterModelIdentifier: "llama3.2:3b",
            frontmostBundleIdentifier: "com.apple.TextEdit"
        )

        guard result.insertionText == "Can you send me the latest build status?" else {
            throw SmokeTestError("Expected dictation pipeline to recover from empty model output by polishing the source transcript.")
        }
    }

    private static func assertDictationActionRouterSkipsMixedModeActionsUnlessAllowed() async throws {
        let formatterResponse = DictationFormatterResponse(
            cleanedText: "open example local notes and send the note",
            formattedText: "Send the note.",
            detectedMode: .mixed,
            snippetApplications: [],
            actionCandidates: [
                DictationActionCandidate(
                    actionID: "example-local-notes",
                    triggerPhrase: "open example local notes",
                    confidence: 0.95
                )
            ],
            shouldInsertText: true,
            confidence: 0.84
        )

        let blockedAction = DictationActionRouter.resolveAction(
            transcript: "open example local notes and send the note",
            formatterResponse: formatterResponse,
            actions: [
                DictationActionDefinition(
                    id: "example-local-notes",
                    displayName: "Example Local Notes",
                    triggers: ["open example local notes"],
                    scriptPath: "/tmp/fake-example-local-notes.sh",
                    allowMixedMode: false
                )
            ]
        )

        guard blockedAction == nil else {
            throw SmokeTestError("Expected mixed-mode action routing to stay blocked unless the allowlist explicitly opts in.")
        }
    }

    private static func assertDictationActionRouterReportsMatchedTrigger() async throws {
        let formatterResponse = DictationFormatterResponse(
            cleanedText: "secondary notes trigger",
            formattedText: "secondary notes trigger",
            detectedMode: .command,
            snippetApplications: [],
            actionCandidates: [],
            shouldInsertText: false,
            confidence: 1.0
        )

        let resolvedAction = DictationActionRouter.resolveAction(
            transcript: "secondary notes trigger",
            formatterResponse: formatterResponse,
            actions: [
                DictationActionDefinition(
                    id: "example-local-notes",
                    displayName: "Example Local Notes",
                    triggers: ["primary notes trigger", "secondary notes trigger"],
                    scriptPath: "/tmp/fake-example-local-notes.sh"
                )
            ]
        )

        guard resolvedAction?.matchedTrigger == "secondary notes trigger" else {
            throw SmokeTestError("Expected action routing to report the exact configured trigger matched by the raw transcript.")
        }
    }

    private static func assertSnippetExpansionCannotTriggerActions() async throws {
        let pipeline = DictationPipeline(
            formatterService: DictationFormatterRecorder(),
            snippetStore: InMemoryDictationSnippetStore(
                snippets: [
                    DictationSnippet(
                        id: "local-notes-shortcut",
                        triggers: ["local notes"],
                        expansion: "open example local notes"
                    )
                ]
            ),
            actionStore: InMemoryDictationActionStore(
                actions: [
                    DictationActionDefinition(
                        id: "example-local-notes",
                        displayName: "Example Local Notes",
                        triggers: ["open example local notes"],
                        scriptPath: "/tmp/fake-example-local-notes.sh"
                    )
                ]
            )
        )

        let result = try await pipeline.processTranscript(
            "local notes",
            formattingMode: .notes,
            formatterModelIdentifier: "gpt-oss:20b",
            frontmostBundleIdentifier: "com.example.voicebar.test-host"
        )

        guard result.resolvedAction == nil else {
            throw SmokeTestError("Expected snippet expansion text to stay text-only and never trigger allowlisted actions.")
        }

        guard result.insertionText == "open example local notes" else {
            throw SmokeTestError("Expected the imported command-like snippet to remain insertion text.")
        }
    }

    private static func assertDeterministicFormattingCannotTriggerActions() async throws {
        let pipeline = DictationPipeline(
            formatterService: DictationFormatterRecorder(),
            snippetStore: InMemoryDictationSnippetStore(snippets: []),
            actionStore: InMemoryDictationActionStore(
                actions: [
                    DictationActionDefinition(
                        id: "hello-world",
                        displayName: "Hello World",
                        triggers: ["hello world"],
                        scriptPath: "/tmp/fake-hello-world.sh"
                    )
                ]
            )
        )

        let result = try await pipeline.processTranscript(
            "hello world period",
            formattingMode: .automatic,
            formatterModelIdentifier: "",
            frontmostBundleIdentifier: "com.example.voicebar.test-host"
        )

        guard result.formatterPath == .deterministicBypass else {
            throw SmokeTestError("Expected spoken punctuation to use deterministic formatting.")
        }

        guard result.insertionText.lowercased().contains("period") == false else {
            throw SmokeTestError("Expected spoken punctuation to format as insertion text.")
        }

        guard result.resolvedAction == nil else {
            throw SmokeTestError("Expected deterministic punctuation output to be unable to trigger actions.")
        }
    }

    private static func assertFormatterCandidatesCannotTriggerActionsWithoutRawMatch() async throws {
        let pipeline = DictationPipeline(
            formatterService: ActionCandidateDictationFormatter(),
            snippetStore: InMemoryDictationSnippetStore(snippets: []),
            actionStore: InMemoryDictationActionStore(
                actions: [
                    DictationActionDefinition(
                        id: "example-local-notes",
                        displayName: "Example Local Notes",
                        triggers: ["open example local notes"],
                        scriptPath: "/tmp/fake-example-local-notes.sh"
                    )
                ]
            )
        )

        let result = try await pipeline.processTranscript(
            "please tidy this note",
            formattingMode: .notes,
            formatterModelIdentifier: "gpt-oss:20b",
            frontmostBundleIdentifier: "com.example.voicebar.test-host"
        )

        guard result.resolvedAction == nil else {
            throw SmokeTestError("Expected model-supplied action candidates to be ignored unless the raw transcript matches the trigger.")
        }

        guard result.insertionText == "Please tidy this note." else {
            throw SmokeTestError("Expected formatter output to remain insertion text when no raw action trigger matched.")
        }
    }

    private static func assertRawTriggerActionSuppressesFormatterInsertion() async throws {
        let pipeline = DictationPipeline(
            formatterService: DictationFormatterRecorder(),
            snippetStore: InMemoryDictationSnippetStore(snippets: []),
            actionStore: InMemoryDictationActionStore(
                actions: [
                    DictationActionDefinition(
                        id: "example-local-notes",
                        displayName: "Example Local Notes",
                        triggers: ["open example local notes"],
                        scriptPath: "/tmp/fake-example-local-notes.sh"
                    )
                ]
            )
        )

        let result = try await pipeline.processTranscript(
            "open example local notes",
            formattingMode: .notes,
            formatterModelIdentifier: "gpt-oss:20b",
            frontmostBundleIdentifier: "com.example.voicebar.test-host"
        )

        guard result.resolvedAction?.definition.id == "example-local-notes" else {
            throw SmokeTestError("Expected raw transcript action trigger to resolve before insertion.")
        }

        guard result.insertionText.isEmpty else {
            throw SmokeTestError("Expected raw transcript action trigger to suppress formatter insertion text.")
        }
    }

    private static func assertDictationPipelinePreservesExactActionTriggersAfterDeterministicRewrite() async throws {
        let formatter = DictationFormatterRecorder()
        let pipeline = DictationPipeline(
            formatterService: formatter,
            snippetStore: InMemoryDictationSnippetStore(snippets: []),
            actionStore: InMemoryDictationActionStore(
                actions: [
                    DictationActionDefinition(
                        id: "line-break-action",
                        displayName: "Line Break Action",
                        triggers: ["new line"],
                        scriptPath: "/tmp/fake-line-break-action.sh"
                    )
                ]
            )
        )

        let result = try await pipeline.processTranscript(
            "new line",
            formattingMode: .automatic,
            formatterModelIdentifier: "",
            frontmostBundleIdentifier: "com.apple.TextEdit"
        )

        guard result.formatterPath == .deterministicBypass else {
            throw SmokeTestError("Expected deterministic bypass for explicit spoken formatting phrases.")
        }

        guard result.resolvedAction?.definition.id == "line-break-action" else {
            throw SmokeTestError("Expected action routing to still match exact allowlisted triggers using pre-deterministic transcript sources.")
        }

        guard result.insertionText.isEmpty else {
            throw SmokeTestError("Expected command-mode action trigger utterances to suppress insertion text.")
        }

        let recordedRequests = await formatter.recordedRequests()
        guard recordedRequests.isEmpty else {
            throw SmokeTestError("Expected deterministic bypass action routing to avoid formatter requests.")
        }
    }

    private static func assertDictationPipelinePassesFormatterModelAndRollingContext() async throws {
        let formatter = DictationFormatterRecorder()
        let pipeline = DictationPipeline(
            formatterService: formatter,
            snippetStore: InMemoryDictationSnippetStore(snippets: []),
            actionStore: InMemoryDictationActionStore(actions: [])
        )

        _ = try await pipeline.processTranscript(
            "first pass",
            formattingMode: .notes,
            formatterModelIdentifier: "gpt-oss:20b",
            frontmostBundleIdentifier: "com.apple.TextEdit"
        )

        let secondResult = try await pipeline.processTranscript(
            "second pass",
            formattingMode: .notes,
            formatterModelIdentifier: "gpt-oss:20b",
            frontmostBundleIdentifier: "com.apple.TextEdit"
        )

        let recordedRequests = await formatter.recordedRequests()
        guard recordedRequests.count == 2 else {
            throw SmokeTestError("Expected the dictation pipeline to forward both formatter requests.")
        }

        guard recordedRequests.first?.formatterModelIdentifier == "gpt-oss:20b" else {
            throw SmokeTestError("Expected the dictation pipeline to preserve the requested formatter model.")
        }

        guard recordedRequests.last?.rollingContext == ["First pass."] else {
            throw SmokeTestError("Expected the dictation pipeline to carry recent insertion context into the next formatter request.")
        }

        guard secondResult.insertionText == "Second pass." else {
            throw SmokeTestError("Expected the dictation pipeline to surface polished formatter insertion text.")
        }

        guard secondResult.formatterPath == .ollama else {
            throw SmokeTestError("Expected normal dictation prose to flow through the Ollama formatter path when deterministic bypass does not apply.")
        }

        guard secondResult.formatterModelIdentifier == "gpt-oss:20b" else {
            throw SmokeTestError("Expected dictation pipeline results to expose the resolved formatter model identifier.")
        }

        guard secondResult.latencyBreakdown != nil else {
            throw SmokeTestError("Expected dictation pipeline results to include a latency breakdown for stage instrumentation.")
        }
    }

    private static func assertDictationPipelinePlainTextModeSkipsFormatter() async throws {
        let formatter = DictationFormatterRecorder()
        let pipeline = DictationPipeline(
            formatterService: formatter,
            snippetStore: InMemoryDictationSnippetStore(snippets: []),
            actionStore: InMemoryDictationActionStore(actions: [])
        )

        let result = try await pipeline.processTranscript(
            "plain text should not wait on the formatter",
            formattingMode: .plainText,
            formatterModelIdentifier: "llama3.2:3b",
            frontmostBundleIdentifier: "com.apple.TextEdit"
        )

        let recordedRequests = await formatter.recordedRequests()
        guard recordedRequests.isEmpty else {
            throw SmokeTestError("Expected Plain Text mode to bypass formatter requests for low-latency dictation.")
        }

        guard result.formatterPath == .deterministicBypass, result.latencyBreakdown?.formatterMilliseconds == 0 else {
            throw SmokeTestError("Expected Plain Text mode to report a zero-millisecond formatter bypass.")
        }

        guard result.insertionText == "plain text should not wait on the formatter" else {
            throw SmokeTestError("Expected Plain Text mode to preserve insertion text without model cleanup.")
        }
    }

    private static func assertDictationPipelineBypassesModelWhenDeterministicFormattingAlreadySolvedOutput() async throws {
        let formatter = DictationFormatterRecorder()
        let pipeline = DictationPipeline(
            formatterService: formatter,
            snippetStore: InMemoryDictationSnippetStore(snippets: []),
            actionStore: InMemoryDictationActionStore(actions: [])
        )

        let result = try await pipeline.processTranscript(
            "make this a numbered list one apples two oranges three pears",
            formattingMode: .notes,
            formatterModelIdentifier: "",
            frontmostBundleIdentifier: "com.apple.TextEdit"
        )

        let recordedRequests = await formatter.recordedRequests()
        guard recordedRequests.isEmpty else {
            throw SmokeTestError("Expected deterministic formatting bypass to skip expensive formatter requests.")
        }

        guard result.formatterPath == .deterministicBypass else {
            throw SmokeTestError("Expected deterministic formatting to mark the deterministicBypass formatter path.")
        }

        guard result.insertionText.contains("1. apples") else {
            throw SmokeTestError("Expected deterministic bypass output to remain insertion-ready as a numbered list.")
        }

        guard result.snippetExpandedTranscript == "make this a numbered list one apples two oranges three pears" else {
            throw SmokeTestError("Expected snippetExpandedTranscript to preserve snippet-stage text rather than post-deterministic formatter output.")
        }
    }

    private static func assertDictationPipelineFallsBackWhenFormatterStalls() async throws {
        let pipeline = DictationPipeline(
            formatterService: FailingDictationFormatter(),
            snippetStore: InMemoryDictationSnippetStore(
                snippets: [
                    DictationSnippet(
                        id: "local-notes",
                        triggers: ["local notes"],
                        expansion: "Local Notes"
                    )
                ]
            ),
            actionStore: InMemoryDictationActionStore(
                actions: [
                    DictationActionDefinition(
                        id: "example-local-notes",
                        displayName: "Example Local Notes",
                        triggers: ["open example local notes"],
                        scriptPath: "/tmp/fake-example-local-notes.sh"
                    )
                ]
            )
        )

        let proseResult = try await pipeline.processTranscript(
            "hello local notes team",
            formattingMode: .notes,
            formatterModelIdentifier: "gpt-oss:20b",
            frontmostBundleIdentifier: "com.apple.TextEdit"
        )

        guard proseResult.insertionText == "Hello Local Notes team." else {
            throw SmokeTestError("Expected formatter fallback to insert lightly polished snippet-expanded text when structured cleanup stalls.")
        }

        guard proseResult.formatterStatusNote?.contains("Formatter fallback:") == true else {
            throw SmokeTestError("Expected formatter fallback to surface an explicit operator-facing note.")
        }

        let actionResult = try await pipeline.processTranscript(
            "open example local notes",
            formattingMode: .notes,
            formatterModelIdentifier: "gpt-oss:20b",
            frontmostBundleIdentifier: "com.apple.TextEdit"
        )

        guard actionResult.insertionText.isEmpty else {
            throw SmokeTestError("Expected exact allowlisted commands to stay command-only during formatter fallback.")
        }

        guard actionResult.resolvedAction?.definition.id == "example-local-notes" else {
            throw SmokeTestError("Expected deterministic allowlisted action matching to survive formatter fallback.")
        }
    }

    private static func assertDictationPipelineFallbackPreservesMultilineSnippetExpansion() async throws {
        let pipeline = DictationPipeline(
            formatterService: FailingDictationFormatter(),
            snippetStore: InMemoryDictationSnippetStore(
                snippets: [
                    DictationSnippet(
                        id: "multiline-note",
                        triggers: ["meeting notes"],
                        expansion: "Agenda:\n- Budget review\n- Hiring plan"
                    )
                ]
            ),
            actionStore: InMemoryDictationActionStore(actions: [])
        )

        let result = try await pipeline.processTranscript(
            "meeting notes",
            formattingMode: .notes,
            formatterModelIdentifier: "gpt-oss:20b",
            frontmostBundleIdentifier: "com.apple.TextEdit"
        )

        guard result.insertionText == "Agenda:\n- Budget review\n- Hiring plan" else {
            throw SmokeTestError("Expected formatter fallback to preserve multiline snippet formatting instead of flattening it.")
        }

        guard result.snippetExpandedTranscript == "Agenda:\n- Budget review\n- Hiring plan" else {
            throw SmokeTestError("Expected snippet-expanded transcript to match the original multiline snippet text when deterministic formatting does not apply.")
        }
    }

    private static func assertDictationPipelineHandlesTimeoutWithClearDiagnostics() async throws {
        // Test that timeout diagnostics are clear and actionable
        let pipeline = DictationPipeline(
            formatterService: TimeoutDictationFormatter(),
            snippetStore: InMemoryDictationSnippetStore(
                snippets: [
                    DictationSnippet(
                        id: "procure-ally",
                        triggers: ["procure ally"],
                        expansion: "Procure Ally"
                    )
                ]
            ),
            actionStore: InMemoryDictationActionStore(actions: [])
        )

        let result = try await pipeline.processTranscript(
            "hello procure ally team",
            formattingMode: .notes,
            formatterModelIdentifier: "gpt-oss:20b",
            frontmostBundleIdentifier: "com.apple.TextEdit"
        )

        // Verify fallback behavior works with timeout-specific diagnostics
        guard result.insertionText == "Hello Procure Ally team." else {
            throw SmokeTestError("Expected timeout fallback to insert lightly polished snippet-expanded text.")
        }

        guard let statusNote = result.formatterStatusNote else {
            throw SmokeTestError("Expected timeout to produce explicit status note.")
        }

        // Verify the fallback message is clear and actionable
        guard statusNote.contains("Formatter fallback:") else {
            throw SmokeTestError("Expected formatter fallback to produce explicit status note.")
        }

        guard statusNote.contains("structured cleanup failed") else {
            throw SmokeTestError("Expected fallback message to explain the failure.")
        }

        guard statusNote.contains("snippet-expanded transcript") else {
            throw SmokeTestError("Expected fallback message to explain the fallback behavior.")
        }
    }

    private static func assertDiagnosticsCaptureUsesBoundedHistory() async throws {
        let diagnostics = InMemoryDiagnosticsCapture()

        for index in 1...1005 {
            await diagnostics.record(
                DiagnosticEvent(
                    name: "event-\(index)",
                    detail: "detail-\(index)"
                )
            )
        }

        let events = await diagnostics.recentEvents(limit: 2000)
        guard events.count == 1000 else {
            throw SmokeTestError("Expected diagnostics history to retain only the latest 1000 events.")
        }

        guard events.first?.name == "event-6" else {
            throw SmokeTestError("Expected diagnostics history to evict the oldest overflow entries.")
        }
    }

    private static func assertStorageLocationsMatchDocumentedPaths() async throws {
        let baseDirectory = VoiceBarStorageLocation.baseDirectoryURL.path
        let modelCacheBaseDirectory = VoiceBarStorageLocation.ttsModelDownloadBaseURL.path
        let modelRepoCachePath = VoiceBarStorageLocation.ttsModelRepoCacheURL.path
        let tokenizerRepoCachePath = VoiceBarStorageLocation.ttsTokenizerRepoCacheURL.path
        let pronunciationPath = VoiceBarStorageLocation.fileURL(
            named: "pronunciation-dictionary.json"
        ).path
        let appProfilesPath = VoiceBarStorageLocation.fileURL(
            named: "app-profiles.json"
        ).path

        guard baseDirectory.hasSuffix("/Library/Application Support/VoiceBar") else {
            throw SmokeTestError("Expected the VoiceBar base directory to live under Application Support.")
        }

        guard pronunciationPath.hasSuffix("/Library/Application Support/VoiceBar/pronunciation-dictionary.json") else {
            throw SmokeTestError("Expected the pronunciation dictionary to use the documented Application Support path.")
        }

        guard appProfilesPath.hasSuffix("/Library/Application Support/VoiceBar/app-profiles.json") else {
            throw SmokeTestError("Expected app profiles to use the documented Application Support path.")
        }

        guard modelCacheBaseDirectory.hasSuffix("/Library/Application Support/VoiceBar/huggingface") else {
            throw SmokeTestError("Expected the Hugging Face download base to stay under VoiceBar's Application Support path.")
        }

        guard modelRepoCachePath.hasSuffix("/Library/Application Support/VoiceBar/huggingface/models/argmaxinc/ttskit-coreml") else {
            throw SmokeTestError("Expected the documented TTSKit model cache proof path to stay under VoiceBar's private Application Support tree.")
        }

        guard tokenizerRepoCachePath.hasSuffix("/Library/Application Support/VoiceBar/huggingface/models/Qwen/Qwen3-0.6B") else {
            throw SmokeTestError("Expected the tokenizer repo cache to stay under the same private VoiceBar Hugging Face tree.")
        }
    }

    private static func assertTTSKitEnginesStartConfiguredForOnDemandLoad() async throws {
        let premiumEngine = TTSKitPremiumEngine()
        let quickEngine = TTSKitQuickEngine()

        let premiumAvailability = await premiumEngine.availability
        let quickAvailability = await quickEngine.availability
        let premiumSnapshot = await premiumEngine.runtimeSnapshot
        let quickSnapshot = await quickEngine.runtimeSnapshot

        guard premiumAvailability.isAvailable, premiumAvailability.reason?.contains("Configured for on-demand load.") == true else {
            throw SmokeTestError("Expected the Premium engine to start in the documented on-demand configuration.")
        }

        guard premiumAvailability.reason?.contains("First use remains unverified") == true else {
            throw SmokeTestError("Expected the Premium engine to preserve the documented first-use warning before model preparation.")
        }

        guard quickAvailability.isAvailable, quickAvailability.reason?.contains("Configured for on-demand load.") == true else {
            throw SmokeTestError("Expected the Quick engine to start in the documented on-demand configuration.")
        }

        guard quickAvailability.reason?.contains("First use remains unverified") == true else {
            throw SmokeTestError("Expected the Quick engine to preserve the documented first-use warning before model preparation.")
        }

        guard premiumSnapshot.identifier == "ttskit-premium", premiumSnapshot.warmState == .cold else {
            throw SmokeTestError("Expected the Premium runtime snapshot to start cold with the documented identifier.")
        }

        guard quickSnapshot.identifier == "ttskit-quick", quickSnapshot.warmState == .cold else {
            throw SmokeTestError("Expected the Quick runtime snapshot to start cold with the documented identifier.")
        }

        let expectedDownloadBaseSuffix = "/Library/Application Support/VoiceBar/huggingface"
        guard premiumEngine.downloadBaseURL.path.hasSuffix(expectedDownloadBaseSuffix) else {
            throw SmokeTestError("Expected the Premium engine to use the private Application Support cache instead of the shared Documents tree.")
        }

        guard quickEngine.downloadBaseURL.path.hasSuffix(expectedDownloadBaseSuffix) else {
            throw SmokeTestError("Expected the Quick engine to use the private Application Support cache instead of the shared Documents tree.")
        }
    }

    private static func assertSpeechRequestChunkerSplitsParagraphsAndPauses() async throws {
        let chunker = SpeechRequestChunker(paragraphPauseMilliseconds: 400)
        let segments = chunker.chunk(
            """
            Hello world. This is VoiceBar.

            Second paragraph here.
            """
        )

        guard segments.count == 3 else {
            throw SmokeTestError("Expected the chunker to split the sample text into three sentence segments.")
        }

        guard segments[0].text == "Hello world." else {
            throw SmokeTestError("Expected the first chunk to preserve the first sentence.")
        }

        guard segments[1].pauseAfterMilliseconds == 400 else {
            throw SmokeTestError("Expected the last sentence in the first paragraph to carry the configured paragraph pause.")
        }

        guard segments[2].pauseAfterMilliseconds == 0 else {
            throw SmokeTestError("Expected the final paragraph to avoid adding a trailing pause.")
        }
    }

    private static func assertSpeechRequestChunkerSplitsLongSentencesIntoSmallerPhrases() async throws {
        let chunker = SpeechRequestChunker(
            paragraphPauseMilliseconds: 400,
            maximumWordsPerSegment: 6
        )
        let segments = chunker.chunk(
            """
            This sentence keeps going for a while, adds another clause here, and should be split into smaller phrases.
            """
        )

        guard segments.count >= 3 else {
            throw SmokeTestError("Expected the chunker to break oversized sentences into multiple smaller phrases.")
        }

        guard segments[0].text == "This sentence keeps going for a while," else {
            throw SmokeTestError("Expected clause punctuation to stay attached to the phrase that triggered the split.")
        }

        guard segments.allSatisfy({ $0.text.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count <= 8 }) else {
            throw SmokeTestError("Expected long-sentence chunking to keep phrases close to the configured size without shredding natural clauses.")
        }
    }

    private static func assertSpeechRequestChunkerGroupsStreamingSegmentsWithoutWholeParagraphBuffering() async throws {
        let chunker = SpeechRequestChunker(
            paragraphPauseMilliseconds: 400,
            maximumWordsPerSegment: 4,
            maximumWordsPerStreamingSegment: 6
        )
        let segments = chunker.chunkForStreaming(
            """
            Alpha beta gamma delta epsilon zeta eta theta iota kappa.

            Second paragraph here.
            """
        )

        guard segments.count == 3 else {
            throw SmokeTestError("Expected streaming chunking to keep long-form playback below whole-paragraph buffering.")
        }

        guard segments[0].text == "Alpha beta gamma delta" else {
            throw SmokeTestError("Expected the first streaming group to keep the opening phrase intact.")
        }

        guard segments[0].pauseAfterMilliseconds == 0 else {
            throw SmokeTestError("Expected intermediate streaming groups to avoid an early paragraph pause.")
        }

        guard segments[1].text == "epsilon zeta eta theta iota kappa." else {
            throw SmokeTestError("Expected the final group in the first paragraph to carry the remaining phrase text.")
        }

        guard segments[1].pauseAfterMilliseconds == 400 else {
            throw SmokeTestError("Expected only the final streaming group in a paragraph to keep the configured pause.")
        }

        guard segments[2].text == "Second paragraph here." else {
            throw SmokeTestError("Expected the next paragraph to begin a fresh streaming group.")
        }

        guard segments[2].pauseAfterMilliseconds == 0 else {
            throw SmokeTestError("Expected the final streaming group to avoid adding a trailing pause.")
        }
    }

    private static func assertDependencyContainerLiveWiresSpeechRuntime() async throws {
        let container = DependencyContainer.live()

        guard type(of: container.playbackController) == QueuedPlaybackController.self else {
            throw SmokeTestError("Expected the live dependency container to wire the real queued playback controller.")
        }

        guard type(of: container.premiumSpeechEngine) == TTSKitPremiumEngine.self else {
            throw SmokeTestError("Expected the live dependency container to wire the premium TTSKit engine.")
        }

        if KokoroPythonSpeechEngine.isRuntimeConfigured() {
            guard type(of: container.quickSpeechEngine) == KokoroPythonSpeechEngine.self else {
                throw SmokeTestError("Expected the live dependency container to wire the Kokoro quick engine when the local runtime is configured.")
            }
        } else {
            guard type(of: container.quickSpeechEngine) == TTSKitQuickEngine.self else {
                throw SmokeTestError("Expected the live dependency container to keep the TTSKit quick engine when the Kokoro runtime is unavailable.")
            }
        }

        guard type(of: container.textNormalizationService) == DefaultTextNormalizationService.self else {
            throw SmokeTestError("Expected the live dependency container to wire the default text normalization service.")
        }

        guard type(of: container.pronunciationService) == JSONPronunciationService.self else {
            throw SmokeTestError("Expected the live dependency container to wire the JSON-backed pronunciation service.")
        }

        guard type(of: container.appProfileStore) == JSONAppProfileStore.self else {
            throw SmokeTestError("Expected the live dependency container to wire the JSON-backed app profile store.")
        }
    }

    private static func assertQueuedPlaybackControllerQueuesAndReplaysRequests() async throws {
        let diagnostics = InMemoryDiagnosticsCapture()
        let premiumEngine = FakeSpeechEngine(
            identifier: "premium-engine",
            yieldedChunks: [
                SpeechChunk(
                    textFragment: "Hello",
                    sequenceNumber: 0,
                    audioSamples: [0.1, 0.2],
                    sampleRate: 24_000
                )
            ],
            chunkDelayNanoseconds: 50_000_000
        )
        let quickEngine = FakeSpeechEngine(
            identifier: "quick-engine",
            yieldedChunks: [
                SpeechChunk(
                    textFragment: "Quick",
                    sequenceNumber: 0,
                    audioSamples: [0.3, 0.4],
                    sampleRate: 24_000
                )
            ]
        )
        let player = FakeAudioChunkPlayer()
        let controller = QueuedPlaybackController(
            premiumSpeechEngine: premiumEngine,
            quickSpeechEngine: quickEngine,
            diagnostics: diagnostics,
            player: player
        )

        try await controller.submit(
            SpeechRequest(text: "First request", preferredMode: .premium)
        )
        try await controller.submit(
            SpeechRequest(text: "Second request", preferredMode: .quick)
        )

        try await waitUntil("queued playback controller to drain the first two requests") {
            let state = await controller.state()
            return state.status == .idle && state.queuedRequestCount == 0
        }

        let stateAfterQueue = await controller.state()
        guard stateAfterQueue.currentEngineIdentifier == "quick-engine" else {
            throw SmokeTestError("Expected the final queued request to leave the quick engine as the last active engine.")
        }

        let enqueuedChunksAfterQueue = await player.enqueuedChunkCount()
        guard enqueuedChunksAfterQueue == 2 else {
            throw SmokeTestError("Expected the fake player to receive one audio chunk per queued request.")
        }

        try await controller.replayLast()

        try await waitUntil("replay last to finish") {
            let state = await controller.state()
            return state.status == .idle && state.queuedRequestCount == 0
        }

        let totalEnqueuedChunks = await player.enqueuedChunkCount()
        guard totalEnqueuedChunks == 3 else {
            throw SmokeTestError("Expected replayLast() to enqueue the last accepted request one more time.")
        }

        let recentEvents = await diagnostics.recentEvents(limit: 10)
        guard recentEvents.contains(where: { $0.name == "playback.completed" }) else {
            throw SmokeTestError("Expected the controller to record a playback completion diagnostic.")
        }
    }

    private static func assertQueuedPlaybackControllerForwardsPrebufferHints() async throws {
        let diagnostics = InMemoryDiagnosticsCapture()
        let premiumEngine = FakeSpeechEngine(
            identifier: "premium-engine",
            yieldedChunks: [
                SpeechChunk(
                    textFragment: "Buffered",
                    sequenceNumber: 0,
                    audioSamples: [0.1, 0.2],
                    sampleRate: 24_000,
                    prebufferLeadDuration: 0.6
                ),
                SpeechChunk(
                    textFragment: "",
                    sequenceNumber: 1,
                    audioSamples: [0.3, 0.4],
                    sampleRate: 24_000,
                    prebufferLeadDuration: 1.2
                )
            ]
        )
        let player = FakeAudioChunkPlayer()
        let controller = QueuedPlaybackController(
            premiumSpeechEngine: premiumEngine,
            quickSpeechEngine: FakeSpeechEngine(identifier: "quick-engine", yieldedChunks: []),
            diagnostics: diagnostics,
            player: player
        )

        try await controller.submit(
            SpeechRequest(text: "Buffered playback", preferredMode: .premium)
        )

        try await waitUntil("buffer-hint playback to finish") {
            let state = await controller.state()
            return state.status == .idle && state.queuedRequestCount == 0
        }

        let recordedHints = await player.recordedPrebufferLeadDurations()
        guard recordedHints == [0.6, 1.2] else {
            throw SmokeTestError("Expected the controller to forward every emitted prebuffer hint into the audio player until playback finishes.")
        }
    }

    private static func assertAudioChunkPlayerPrebufferPolicyGrowsBufferBeforeFirstFlush() async throws {
        let firstChunk = SpeechChunk(
            textFragment: "Buffered",
            sequenceNumber: 0,
            audioSamples: [0.1, 0.2],
            sampleRate: 24_000,
            prebufferLeadDuration: 0.6
        )
        let laterChunk = SpeechChunk(
            textFragment: "",
            sequenceNumber: 1,
            audioSamples: [0.3, 0.4],
            sampleRate: 24_000,
            prebufferLeadDuration: 1.2
        )

        guard AudioChunkPlayerPrebufferPolicy.nextBufferDuration(
            currentBufferDuration: nil,
            bufferThresholdMet: false,
            incomingChunk: firstChunk
        ) == 0.6 else {
            throw SmokeTestError("Expected the player to arm prebuffering from the first buffered chunk of a segment.")
        }

        guard AudioChunkPlayerPrebufferPolicy.nextBufferDuration(
            currentBufferDuration: 0.6,
            bufferThresholdMet: false,
            incomingChunk: laterChunk
        ) == 1.2 else {
            throw SmokeTestError("Expected later hints to grow the initial prebuffer before the first flush commits playback.")
        }

        guard AudioChunkPlayerPrebufferPolicy.nextBufferDuration(
            currentBufferDuration: 1.2,
            bufferThresholdMet: false,
            incomingChunk: firstChunk
        ) == 1.2 else {
            throw SmokeTestError("Expected the player to keep the larger in-flight buffer target when a later hint is smaller.")
        }
    }

    private static func assertAudioChunkPlayerPrebufferPolicyIgnoresHintsAfterFirstFlush() async throws {
        let laterChunk = SpeechChunk(
            textFragment: "",
            sequenceNumber: 1,
            audioSamples: [0.3, 0.4],
            sampleRate: 24_000,
            prebufferLeadDuration: 1.2
        )

        guard AudioChunkPlayerPrebufferPolicy.nextBufferDuration(
            currentBufferDuration: 1.2,
            bufferThresholdMet: true,
            incomingChunk: laterChunk
        ) == nil else {
            throw SmokeTestError("Expected the player to ignore repeated prebuffer hints after the first buffered flush has already started playback.")
        }
    }

    private static func assertQueuedPlaybackControllerStopsAndClearsQueue() async throws {
        let diagnostics = InMemoryDiagnosticsCapture()
        let premiumEngine = FakeSpeechEngine(
            identifier: "premium-engine",
            yieldedChunks: [
                SpeechChunk(
                    textFragment: "Streaming",
                    sequenceNumber: 0,
                    audioSamples: [0.1, 0.2],
                    sampleRate: 24_000
                ),
                SpeechChunk(
                    textFragment: "",
                    sequenceNumber: 1,
                    audioSamples: [0.2, 0.3],
                    sampleRate: 24_000
                )
            ],
            chunkDelayNanoseconds: 150_000_000
        )
        let quickEngine = FakeSpeechEngine(
            identifier: "quick-engine",
            yieldedChunks: [
                SpeechChunk(
                    textFragment: "Quick",
                    sequenceNumber: 0,
                    audioSamples: [0.4, 0.5],
                    sampleRate: 24_000
                )
            ]
        )
        let player = FakeAudioChunkPlayer()
        let controller = QueuedPlaybackController(
            premiumSpeechEngine: premiumEngine,
            quickSpeechEngine: quickEngine,
            diagnostics: diagnostics,
            player: player
        )

        try await controller.submit(
            SpeechRequest(text: "Long request", preferredMode: .premium)
        )
        try await controller.submit(
            SpeechRequest(text: "Queued request", preferredMode: .quick)
        )

        try await waitUntil("controller to assign the active engine before stop") {
            let state = await controller.state()
            return state.currentEngineIdentifier == "premium-engine"
        }

        await controller.pause()
        await controller.stop()

        let state = await controller.state()

        guard state.status == .idle else {
            throw SmokeTestError("Expected playback state to return to idle after stop.")
        }

        guard state.queuedRequestCount == 0 else {
            throw SmokeTestError("Expected stop() to clear any queued requests.")
        }

        guard premiumEngine.stopCallCount() == 1 else {
            throw SmokeTestError("Expected stop() to tell the active engine to cancel synthesis work.")
        }

        guard await player.stopCount() >= 1 else {
            throw SmokeTestError("Expected stop() to stop the audio player.")
        }

        let recentEvents = await diagnostics.recentEvents(limit: 5)
        guard recentEvents.contains(where: { $0.name == "playback.stopped" }) else {
            throw SmokeTestError("Expected stop() to record a playback.stopped diagnostic event.")
        }
    }

    private static func assertQueuedPlaybackControllerRetainsReplayAfterStop() async throws {
        let diagnostics = InMemoryDiagnosticsCapture()
        let premiumEngine = FakeSpeechEngine(
            identifier: "premium-engine",
            yieldedChunks: [
                SpeechChunk(
                    textFragment: "Replay",
                    sequenceNumber: 0,
                    audioSamples: [0.1, 0.2],
                    sampleRate: 24_000
                )
            ],
            chunkDelayNanoseconds: 120_000_000
        )
        let controller = QueuedPlaybackController(
            premiumSpeechEngine: premiumEngine,
            quickSpeechEngine: FakeSpeechEngine(identifier: "quick-engine", yieldedChunks: []),
            diagnostics: diagnostics,
            player: FakeAudioChunkPlayer()
        )

        try await controller.submit(
            SpeechRequest(text: "Replay after stop", preferredMode: .premium)
        )

        try await waitUntil("playback to assign the premium engine before replay stop") {
            let state = await controller.state()
            return state.currentEngineIdentifier == "premium-engine"
        }

        await controller.stop()

        let stoppedState = await controller.state()
        guard stoppedState.lastRequest?.text == "Replay after stop" else {
            throw SmokeTestError("Expected stop() to retain the last request for Replay.")
        }

        try await controller.replayLast()

        try await waitUntil("replay after stop to finish") {
            let state = await controller.state()
            return state.status == .idle && state.queuedRequestCount == 0
        }

        let recentEvents = await diagnostics.recentEvents(limit: 20)
        guard premiumEngine.synthesizeCallCount() == 2 else {
            throw SmokeTestError("Expected Replay after Stop to synthesize the retained request again.")
        }

        guard recentEvents.contains(where: { $0.name == "playback.stop.completed" }) else {
            throw SmokeTestError("Expected stop() to record playback.stop.completed.")
        }

        guard recentEvents.contains(where: { $0.name == "playback.replay.started" }) else {
            throw SmokeTestError("Expected Replay after Stop to record playback.replay.started.")
        }
    }

    private static func assertQueuedPlaybackControllerReplayRestartsPausedPlayback() async throws {
        let diagnostics = InMemoryDiagnosticsCapture()
        let premiumEngine = FakeSpeechEngine(
            identifier: "premium-engine",
            yieldedChunks: [
                SpeechChunk(
                    textFragment: "Paused",
                    sequenceNumber: 0,
                    audioSamples: [0.1, 0.2],
                    sampleRate: 24_000
                ),
                SpeechChunk(
                    textFragment: "Replay",
                    sequenceNumber: 1,
                    audioSamples: [0.2, 0.3],
                    sampleRate: 24_000
                )
            ],
            chunkDelayNanoseconds: 120_000_000
        )
        let player = FakeAudioChunkPlayer()
        let controller = QueuedPlaybackController(
            premiumSpeechEngine: premiumEngine,
            quickSpeechEngine: FakeSpeechEngine(identifier: "quick-engine", yieldedChunks: []),
            diagnostics: diagnostics,
            player: player
        )

        try await controller.submit(
            SpeechRequest(text: "Replay from pause", preferredMode: .premium)
        )

        try await waitUntil("playback to start before paused replay") {
            let state = await controller.state()
            return state.status == .speaking
        }

        await controller.pause()
        try await controller.replayLast()

        try await waitUntil("replay from pause to finish") {
            let state = await controller.state()
            return state.status == .idle && state.queuedRequestCount == 0
        }

        let recentEvents = await diagnostics.recentEvents(limit: 25)
        guard premiumEngine.stopCallCount() == 1 else {
            throw SmokeTestError("Expected Replay from a paused run to stop the old synthesis before restarting.")
        }

        guard premiumEngine.synthesizeCallCount() == 2 else {
            throw SmokeTestError("Expected Replay from a paused run to start the retained request again instead of queueing behind paused playback.")
        }

        guard await player.stopCount() >= 1 else {
            throw SmokeTestError("Expected Replay from a paused run to stop the paused audio player before restarting.")
        }

        guard recentEvents.contains(where: { $0.name == "playback.replay.submitted" }) else {
            throw SmokeTestError("Expected Replay from a paused run to record playback.replay.submitted.")
        }
    }

    private static func assertQueuedPlaybackControllerPausesAndResumesPlayback() async throws {
        let diagnostics = InMemoryDiagnosticsCapture()
        let premiumEngine = FakeSpeechEngine(
            identifier: "premium-engine",
            yieldedChunks: [
                SpeechChunk(
                    textFragment: "One",
                    sequenceNumber: 0,
                    audioSamples: [0.1, 0.2],
                    sampleRate: 24_000
                ),
                SpeechChunk(
                    textFragment: "Two",
                    sequenceNumber: 1,
                    audioSamples: [0.2, 0.3],
                    sampleRate: 24_000
                ),
                SpeechChunk(
                    textFragment: "Three",
                    sequenceNumber: 2,
                    audioSamples: [0.3, 0.4],
                    sampleRate: 24_000
                )
            ],
            chunkDelayNanoseconds: 80_000_000
        )
        let quickEngine = FakeSpeechEngine(
            identifier: "quick-engine",
            yieldedChunks: []
        )
        let player = FakeAudioChunkPlayer()
        let controller = QueuedPlaybackController(
            premiumSpeechEngine: premiumEngine,
            quickSpeechEngine: quickEngine,
            diagnostics: diagnostics,
            player: player
        )

        try await controller.submit(
            SpeechRequest(text: "Pause me", preferredMode: .premium)
        )

        try await waitUntil("playback to start speaking before pause") {
            let state = await controller.state()
            return state.status == .speaking
        }

        await controller.pause()

        let pausedState = await controller.state()
        guard pausedState.status == .paused else {
            throw SmokeTestError("Expected pause() to move the controller into the paused state.")
        }

        guard await player.isPaused() else {
            throw SmokeTestError("Expected pause() to pause the audio player.")
        }

        await controller.resume()

        let resumedState = await controller.state()
        guard resumedState.status == .speaking else {
            throw SmokeTestError("Expected resume() to move the controller back into the speaking state.")
        }

        guard await player.isPaused() == false else {
            throw SmokeTestError("Expected resume() to resume the audio player.")
        }

        try await waitUntil("paused playback to finish after resume") {
            let state = await controller.state()
            return state.status == .idle
        }

        let recentEvents = await diagnostics.recentEvents(limit: 10)
        guard recentEvents.contains(where: { $0.name == "playback.paused" }) else {
            throw SmokeTestError("Expected pause() to record a playback.paused diagnostic event.")
        }

        guard recentEvents.contains(where: { $0.name == "playback.resumed" }) else {
            throw SmokeTestError("Expected resume() to record a playback.resumed diagnostic event.")
        }
    }

    private static func assertQueuedPlaybackControllerStopDoesNotDegradeAutoMode() async throws {
        let diagnostics = InMemoryDiagnosticsCapture()
        let premiumEngine = FakeSpeechEngine(
            identifier: "premium-engine",
            yieldedChunks: [
                SpeechChunk(
                    textFragment: "Auto",
                    sequenceNumber: 0,
                    audioSamples: [0.1, 0.2],
                    sampleRate: 24_000
                ),
                SpeechChunk(
                    textFragment: "Still auto",
                    sequenceNumber: 1,
                    audioSamples: [0.2, 0.3],
                    sampleRate: 24_000
                )
            ],
            chunkDelayNanoseconds: 120_000_000
        )
        let quickEngine = FakeSpeechEngine(
            identifier: "quick-engine",
            yieldedChunks: [
                SpeechChunk(
                    textFragment: "Quick fallback",
                    sequenceNumber: 0,
                    audioSamples: [0.4, 0.5],
                    sampleRate: 24_000
                )
            ]
        )
        let controller = QueuedPlaybackController(
            premiumSpeechEngine: premiumEngine,
            quickSpeechEngine: quickEngine,
            diagnostics: diagnostics,
            player: FakeAudioChunkPlayer(),
            premiumFailureThreshold: 2
        )

        for attempt in 1...2 {
            try await controller.submit(
                SpeechRequest(text: "Auto stop \(attempt)", preferredMode: .auto)
            )

            try await waitUntil("auto-mode run \(attempt) to start on premium") {
                let state = await controller.state()
                return state.currentEngineIdentifier == "premium-engine"
            }

            await controller.stop()
        }

        try await controller.submit(
            SpeechRequest(text: "Auto should stay premium", preferredMode: .auto)
        )

        try await waitUntil("post-stop auto playback to finish") {
            let state = await controller.state()
            return state.status == .idle
        }

        let finalState = await controller.state()
        let quickCallCount = quickEngine.synthesizeCallCount()
        let recentEvents = await diagnostics.recentEvents(limit: 20)

        guard quickCallCount == 0 else {
            throw SmokeTestError("Expected stop-triggered cancellations to avoid forcing quick fallback work.")
        }

        guard finalState.currentEngineIdentifier == "premium-engine" else {
            throw SmokeTestError("Expected Auto mode to stay on premium after user-initiated stops.")
        }

        guard recentEvents.contains(where: { $0.name == "playback.completed" }) else {
            throw SmokeTestError("Expected the later Auto request to still complete after earlier user-initiated stops.")
        }

        guard recentEvents.contains(where: { $0.name == "engine.auto.degraded" }) == false else {
            throw SmokeTestError("Expected stop-triggered cancellations to avoid emitting engine.auto.degraded.")
        }
    }

    private static func assertQueuedPlaybackControllerStopDoesNotClobberNewPlayback() async throws {
        let diagnostics = InMemoryDiagnosticsCapture()
        let premiumEngine = FakeSpeechEngine(
            identifier: "premium-engine",
            yieldedChunks: [
                SpeechChunk(
                    textFragment: "Long",
                    sequenceNumber: 0,
                    audioSamples: [0.1, 0.2],
                    sampleRate: 24_000
                )
            ],
            chunkDelayNanoseconds: 120_000_000,
            stopDelayNanoseconds: 120_000_000
        )
        let quickEngine = FakeSpeechEngine(
            identifier: "quick-engine",
            yieldedChunks: [
                SpeechChunk(
                    textFragment: "Fresh",
                    sequenceNumber: 0,
                    audioSamples: [0.3, 0.4],
                    sampleRate: 24_000
                )
            ]
        )
        let player = FakeAudioChunkPlayer()
        let controller = QueuedPlaybackController(
            premiumSpeechEngine: premiumEngine,
            quickSpeechEngine: quickEngine,
            diagnostics: diagnostics,
            player: player
        )

        try await controller.submit(
            SpeechRequest(text: "First request", preferredMode: .premium)
        )

        try await waitUntil("initial playback to assign the premium engine") {
            let state = await controller.state()
            return state.currentEngineIdentifier == "premium-engine"
        }

        let stopTask = Task {
            await controller.stop()
        }

        try await Task.sleep(nanoseconds: 20_000_000)

        try await controller.submit(
            SpeechRequest(text: "Second request", preferredMode: .quick)
        )

        await stopTask.value

        try await waitUntil("new playback submitted during stop to finish") {
            let state = await controller.state()
            return state.status == .idle && state.queuedRequestCount == 0
        }

        let finalState = await controller.state()
        guard finalState.currentEngineIdentifier == "quick-engine" else {
            throw SmokeTestError("Expected a request submitted during stop() to survive and finish on its chosen engine.")
        }

        guard quickEngine.synthesizeCallCount() == 1 else {
            throw SmokeTestError("Expected the request submitted during stop() to start once the stop work completed.")
        }

        guard await player.enqueuedChunkCount() >= 1 else {
            throw SmokeTestError("Expected the post-stop request to enqueue audio after the earlier stop finished.")
        }
    }

    private static func assertQueuedPlaybackControllerStopBeforeEnqueueSuppressesAudio() async throws {
        let diagnostics = BlockingDiagnosticsCapture(blockedEventName: "playback.first-audio")
        let premiumEngine = FakeSpeechEngine(
            identifier: "premium-engine",
            yieldedChunks: [
                SpeechChunk(
                    textFragment: "Blocked",
                    sequenceNumber: 0,
                    audioSamples: [0.1, 0.2],
                    sampleRate: 24_000
                )
            ]
        )
        let player = FakeAudioChunkPlayer()
        let controller = QueuedPlaybackController(
            premiumSpeechEngine: premiumEngine,
            quickSpeechEngine: FakeSpeechEngine(identifier: "quick-engine", yieldedChunks: []),
            diagnostics: diagnostics,
            player: player
        )

        try await controller.submit(
            SpeechRequest(text: "Cancel before enqueue", preferredMode: .premium)
        )

        try await waitUntil("blocked first-audio diagnostics gate") {
            await diagnostics.isBlocked
        }

        await controller.stop()
        await diagnostics.releaseBlockedEvent()

        try await waitUntil("controller to settle after stop-before-enqueue") {
            let state = await controller.state()
            return state.status == .idle
        }

        guard await player.enqueuedChunkCount() == 0 else {
            throw SmokeTestError("Expected stop() to suppress any post-cancel audio enqueue after first-audio diagnostics unblock.")
        }
    }

    private static func assertQueuedPlaybackControllerStopDoesNotRecordCompletedPlayback() async throws {
        let diagnostics = InMemoryDiagnosticsCapture()
        let premiumEngine = FakeSpeechEngine(
            identifier: "premium-engine",
            yieldedChunks: [
                SpeechChunk(
                    textFragment: "Clean stop",
                    sequenceNumber: 0,
                    audioSamples: [0.1, 0.2],
                    sampleRate: 24_000
                )
            ],
            chunkDelayNanoseconds: 120_000_000,
            finishesCleanlyOnStop: true
        )
        let quickEngine = FakeSpeechEngine(
            identifier: "quick-engine",
            yieldedChunks: [
                SpeechChunk(
                    textFragment: "Replacement",
                    sequenceNumber: 0,
                    audioSamples: [0.3, 0.4],
                    sampleRate: 24_000
                )
            ]
        )
        let controller = QueuedPlaybackController(
            premiumSpeechEngine: premiumEngine,
            quickSpeechEngine: quickEngine,
            diagnostics: diagnostics,
            player: FakeAudioChunkPlayer()
        )

        try await controller.submit(
            SpeechRequest(text: "Stop me cleanly", preferredMode: .premium)
        )

        try await waitUntil("clean-stop playback to start on premium") {
            let state = await controller.state()
            return state.currentEngineIdentifier == "premium-engine"
        }

        await controller.stop()

        try await controller.submit(
            SpeechRequest(text: "Replacement request", preferredMode: .quick)
        )

        try await waitUntil("replacement playback to finish after clean stop") {
            let state = await controller.state()
            return state.status == .idle && state.queuedRequestCount == 0
        }

        let finalState = await controller.state()
        let recentEvents = await diagnostics.recentEvents(limit: 20)
        let completionEvents = recentEvents.filter { $0.name == "playback.completed" }

        guard finalState.currentEngineIdentifier == "quick-engine" else {
            throw SmokeTestError("Expected the replacement request to own the final playback state after a clean stop.")
        }

        guard completionEvents.count == 1 else {
            throw SmokeTestError("Expected only the replacement request to record playback.completed after a clean stop.")
        }
    }

    private static func assertQueuedPlaybackControllerStopDuringDrainSuppressesDrainDiagnostic() async throws {
        let diagnostics = InMemoryDiagnosticsCapture()
        let premiumEngine = FakeSpeechEngine(
            identifier: "premium-engine",
            yieldedChunks: [
                SpeechChunk(
                    textFragment: "Drain cancellation",
                    sequenceNumber: 0,
                    audioSamples: [0.1, 0.2],
                    sampleRate: 24_000
                )
            ]
        )
        let controller = QueuedPlaybackController(
            premiumSpeechEngine: premiumEngine,
            quickSpeechEngine: premiumEngine,
            diagnostics: diagnostics,
            player: FakeAudioChunkPlayer(drainDelayNanoseconds: 250_000_000)
        )

        try await controller.submit(
            SpeechRequest(text: "Stop while draining", preferredMode: .premium)
        )

        try await waitUntil("playback to finish generation before drain cancellation") {
            let recentEvents = await diagnostics.recentEvents(limit: 20)
            return recentEvents.contains { $0.name == "playback.completed" }
        }

        await controller.stop()

        try await waitUntil("stop during drain to settle") {
            let state = await controller.state()
            return state.status == .idle && state.queuedRequestCount == 0
        }

        let recentEvents = await diagnostics.recentEvents(limit: 20)
        guard recentEvents.contains(where: { $0.name == "playback.drained" }) == false else {
            throw SmokeTestError("Expected stop() during drain to suppress playback.drained diagnostics.")
        }
    }

    private static func assertQueuedPlaybackControllerFallsBackToQuickWhenPremiumFails() async throws {
        let diagnostics = InMemoryDiagnosticsCapture()
        let premiumEngine = FakeSpeechEngine(
            identifier: "premium-engine",
            yieldedChunks: [],
            synthesizeError: FakeSpeechError.syntheticFailure("Premium failed to synthesize")
        )
        let quickEngine = FakeSpeechEngine(
            identifier: "quick-engine",
            yieldedChunks: [
                SpeechChunk(
                    textFragment: "Fallback audio",
                    sequenceNumber: 0,
                    audioSamples: [0.2, 0.3],
                    sampleRate: 24_000
                )
            ]
        )
        let player = FakeAudioChunkPlayer()
        let controller = QueuedPlaybackController(
            premiumSpeechEngine: premiumEngine,
            quickSpeechEngine: quickEngine,
            diagnostics: diagnostics,
            player: player
        )

        try await controller.submit(
            SpeechRequest(text: "Needs fallback", preferredMode: .premium)
        )

        try await waitUntil("fallback playback to finish") {
            let state = await controller.state()
            return state.status == .idle
        }

        let state = await controller.state()
        guard state.currentEngineIdentifier == "quick-engine" else {
            throw SmokeTestError("Expected the controller to finish on the quick engine after a premium failure.")
        }

        guard quickEngine.synthesizeCallCount() == 1 else {
            throw SmokeTestError("Expected the quick engine to handle the fallback request.")
        }

        let recentEvents = await diagnostics.recentEvents(limit: 10)
        guard recentEvents.contains(where: { $0.name == "engine.fallback" }) else {
            throw SmokeTestError("Expected the controller to record the engine.fallback diagnostic.")
        }
    }

    private static func assertQueuedPlaybackControllerKeepsExplicitPremiumWhenCold() async throws {
        let diagnostics = InMemoryDiagnosticsCapture()
        let premiumEngine = FakeSpeechEngine(
            identifier: "premium-engine",
            yieldedChunks: [
                SpeechChunk(
                    textFragment: "Premium audio",
                    sequenceNumber: 0,
                    audioSamples: [0.2, 0.3],
                    sampleRate: 24_000
                )
            ],
            runtimeSnapshot: SpeechEngineRuntimeSnapshot(
                identifier: "premium-engine",
                warmState: .cold
            )
        )
        let quickEngine = FakeSpeechEngine(
            identifier: "quick-engine",
            yieldedChunks: [
                SpeechChunk(
                    textFragment: "Quick audio",
                    sequenceNumber: 0,
                    audioSamples: [0.2, 0.3],
                    sampleRate: 24_000
                )
            ]
        )
        let controller = QueuedPlaybackController(
            premiumSpeechEngine: premiumEngine,
            quickSpeechEngine: quickEngine,
            diagnostics: diagnostics,
            player: FakeAudioChunkPlayer()
        )

        try await controller.submit(
            SpeechRequest(text: "Cold premium should degrade", preferredMode: .premium)
        )

        try await waitUntil("cold-premium playback to finish") {
            let state = await controller.state()
            return state.status == .idle
        }

        guard premiumEngine.synthesizeCallCount() == 1 else {
            throw SmokeTestError("Expected explicit Premium playback to keep using the premium engine even while it is still cold.")
        }

        guard quickEngine.synthesizeCallCount() == 0 else {
            throw SmokeTestError("Expected explicit Premium playback to avoid silently degrading to Quick.")
        }

        let recentEvents = await diagnostics.recentEvents(limit: 10)
        guard recentEvents.contains(where: { $0.name == "engine.premium.degraded" }) == false else {
            throw SmokeTestError("Expected explicit Premium playback to skip the cold-premium degradation diagnostic.")
        }
    }

    private static func assertQueuedPlaybackControllerTemporarilyStartsQuickWhenAutoUsesColdPremium() async throws {
        let diagnostics = InMemoryDiagnosticsCapture()
        let premiumEngine = FakeSpeechEngine(
            identifier: "premium-engine",
            yieldedChunks: [],
            runtimeSnapshot: SpeechEngineRuntimeSnapshot(
                identifier: "premium-engine",
                warmState: .cold
            )
        )
        let quickEngine = FakeSpeechEngine(
            identifier: "quick-engine",
            yieldedChunks: [
                SpeechChunk(
                    textFragment: "Quick audio",
                    sequenceNumber: 0,
                    audioSamples: [0.2, 0.3],
                    sampleRate: 24_000
                )
            ]
        )
        let controller = QueuedPlaybackController(
            premiumSpeechEngine: premiumEngine,
            quickSpeechEngine: quickEngine,
            diagnostics: diagnostics,
            player: FakeAudioChunkPlayer()
        )

        try await controller.submit(
            SpeechRequest(text: "Cold premium should degrade in auto", preferredMode: .auto)
        )

        try await waitUntil("cold-premium auto degradation playback to finish") {
            let state = await controller.state()
            return state.status == .idle
        }

        guard premiumEngine.synthesizeCallCount() == 0 else {
            throw SmokeTestError("Expected Auto mode to keep the cold-premium degradation path.")
        }

        guard quickEngine.synthesizeCallCount() == 1 else {
            throw SmokeTestError("Expected the quick engine to handle the temporary cold-premium degradation in Auto mode.")
        }

        let recentEvents = await diagnostics.recentEvents(limit: 10)
        guard recentEvents.contains(where: { $0.name == "engine.auto.degraded" }) else {
            throw SmokeTestError("Expected Auto mode to record the cold-premium degradation diagnostic.")
        }
    }

    private static func assertQueuedPlaybackControllerFallsBackWhenPremiumOnlyProducesParagraphPause() async throws {
        let diagnostics = InMemoryDiagnosticsCapture()
        let premiumEngine = FakeSpeechEngine(
            identifier: "premium-engine",
            yieldedChunks: [
                SpeechChunk(
                    textFragment: "",
                    sequenceNumber: 0,
                    audioSamples: Array(repeating: 0, count: 20),
                    sampleRate: 24_000,
                    isParagraphPause: true
                )
            ]
        )
        let quickEngine = FakeSpeechEngine(
            identifier: "quick-engine",
            yieldedChunks: [
                SpeechChunk(
                    textFragment: "Fallback speech",
                    sequenceNumber: 0,
                    audioSamples: [0.2, 0.3],
                    sampleRate: 24_000
                )
            ]
        )
        let player = FakeAudioChunkPlayer()
        let controller = QueuedPlaybackController(
            premiumSpeechEngine: premiumEngine,
            quickSpeechEngine: quickEngine,
            diagnostics: diagnostics,
            player: player
        )

        try await controller.submit(
            SpeechRequest(text: "Paragraph pause should not count", preferredMode: .premium)
        )

        try await waitUntil("paragraph-pause-only fallback playback to finish") {
            let state = await controller.state()
            return state.status == .idle
        }

        let state = await controller.state()
        guard state.currentEngineIdentifier == "quick-engine" else {
            throw SmokeTestError("Expected pause-only premium output to fall back to the quick engine.")
        }

        guard quickEngine.synthesizeCallCount() == 1 else {
            throw SmokeTestError("Expected the quick engine to run when premium produced only paragraph-pause samples.")
        }

        let recentEvents = await diagnostics.recentEvents(limit: 10)
        guard recentEvents.contains(where: { $0.name == "engine.fallback" }) else {
            throw SmokeTestError("Expected pause-only premium output to record the fallback diagnostic.")
        }
    }

    private static func assertQueuedPlaybackControllerDegradesAutoAfterRepeatedPremiumFailures() async throws {
        let diagnostics = InMemoryDiagnosticsCapture()
        let premiumEngine = FakeSpeechEngine(
            identifier: "premium-engine",
            yieldedChunks: [],
            synthesizeError: FakeSpeechError.syntheticFailure("Premium kept failing")
        )
        let quickEngine = FakeSpeechEngine(
            identifier: "quick-engine",
            yieldedChunks: [
                SpeechChunk(
                    textFragment: "Quick audio",
                    sequenceNumber: 0,
                    audioSamples: [0.3, 0.4],
                    sampleRate: 24_000
                )
            ]
        )
        let controller = QueuedPlaybackController(
            premiumSpeechEngine: premiumEngine,
            quickSpeechEngine: quickEngine,
            diagnostics: diagnostics,
            player: FakeAudioChunkPlayer(),
            premiumFailureThreshold: 2
        )

        try await controller.submit(
            SpeechRequest(text: "Auto one", preferredMode: .auto)
        )
        try await controller.submit(
            SpeechRequest(text: "Auto two", preferredMode: .auto)
        )
        try await controller.submit(
            SpeechRequest(text: "Auto three", preferredMode: .auto)
        )

        try await waitUntil("auto degradation run to finish") {
            let state = await controller.state()
            return state.status == .idle
        }

        guard premiumEngine.synthesizeCallCount() == 2 else {
            throw SmokeTestError("Expected the premium engine to be skipped after two consecutive failures in Auto mode.")
        }

        let recentEvents = await diagnostics.recentEvents(limit: 20)
        guard recentEvents.contains(where: { $0.name == "engine.auto.degraded" }) else {
            throw SmokeTestError("Expected Auto mode degradation to be recorded once the failure threshold is reached.")
        }
    }

    private static func assertThrowsBootstrapError(
        _ failureMessage: String,
        operation: () async throws -> Void
    ) async throws {
        do {
            try await operation()
            throw SmokeTestError(failureMessage)
        } catch is VoiceBarBootstrapError {
            // Prompt 002 smoke coverage expects bootstrap stubs to fail until their owner lanes land.
        } catch let error as SmokeTestError {
            throw error
        } catch {
            throw SmokeTestError(
                "Expected VoiceBarBootstrapError but received \(type(of: error)): \(error.localizedDescription)"
            )
        }
    }

    private static func assertThrowsTextCaptureError(
        _ expectedError: TextCaptureError,
        _ failureMessage: String,
        operation: () async throws -> Void
    ) async throws {
        do {
            try await operation()
            throw SmokeTestError(failureMessage)
        } catch let error as TextCaptureError {
            guard error == expectedError else {
                throw SmokeTestError("Expected \(expectedError.localizedDescription) but received \(error.localizedDescription).")
            }
        } catch let error as SmokeTestError {
            throw error
        } catch {
            throw SmokeTestError(
                "Expected TextCaptureError but received \(type(of: error)): \(error.localizedDescription)"
            )
        }
    }

    private static func makeClipboardClient(string: String = "Unused clipboard") -> ClipboardClient {
        ClipboardClient(
            string: {
                string
            },
            changeCount: {
                0
            },
            snapshot: {
                ClipboardSnapshot(items: [])
            },
            restore: { _ in
            },
            waitForChange: { _, _ in
                false
            }
        )
    }

    private static func waitUntil(
        _ description: String,
        retries: Int = 100,
        sleepNanoseconds: UInt64 = 20_000_000,
        condition: () async -> Bool
    ) async throws {
        for _ in 0..<retries {
            if await condition() {
                return
            }

            try await Task.sleep(nanoseconds: sleepNanoseconds)
        }

        throw SmokeTestError("Timed out while waiting for \(description).")
    }

    private static func makeTemporaryDirectoryURL() throws -> URL {
        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true,
            attributes: nil
        )
        return directoryURL
    }

    private static func setPosixPermissions(
        _ directoryURL: URL,
        to permissions: Int
    ) throws {
        try FileManager.default.setAttributes(
            [.posixPermissions: permissions],
            ofItemAtPath: directoryURL.path
        )
    }

}

private struct SmokeTestError: LocalizedError {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    var errorDescription: String? {
        message
    }
}

private final class ClipboardState: @unchecked Sendable {
    // The smoke harness shares this helper across async closures, so the lock
    // keeps the synthetic clipboard state coherent under @unchecked Sendable.
    private let lock = NSLock()
    private var storedCurrentString: String
    private var storedChangeCount: Int

    init(
        currentString: String,
        changeCount: Int
    ) {
        self.storedCurrentString = currentString
        self.storedChangeCount = changeCount
    }

    func currentString() -> String {
        lock.lock()
        defer { lock.unlock() }
        return storedCurrentString
    }

    func changeCount() -> Int {
        lock.lock()
        defer { lock.unlock() }
        return storedChangeCount
    }

    func setCurrentString(_ currentString: String) {
        lock.lock()
        storedCurrentString = currentString
        lock.unlock()
    }

    func setChangeCount(_ changeCount: Int) {
        lock.lock()
        storedChangeCount = changeCount
        lock.unlock()
    }
}

private final class FakeSpeechEngine: @unchecked Sendable, SpeechEngine {
    let identifier: String

    private let yieldedChunks: [SpeechChunk]
    private let synthesizeError: Error?
    private let chunkDelayNanoseconds: UInt64
    private let stopDelayNanoseconds: UInt64
    private let finishesCleanlyOnStop: Bool
    private let runtimeSnapshotValue: SpeechEngineRuntimeSnapshot
    private let lock = NSLock()
    private var storedSynthesizeCallCount = 0
    private var storedStopCallCount = 0
    private var storedStopGeneration = 0

    init(
        identifier: String,
        yieldedChunks: [SpeechChunk],
        synthesizeError: Error? = nil,
        chunkDelayNanoseconds: UInt64 = 0,
        stopDelayNanoseconds: UInt64 = 0,
        finishesCleanlyOnStop: Bool = false,
        runtimeSnapshot: SpeechEngineRuntimeSnapshot? = nil
    ) {
        self.identifier = identifier
        self.yieldedChunks = yieldedChunks
        self.synthesizeError = synthesizeError
        self.chunkDelayNanoseconds = chunkDelayNanoseconds
        self.stopDelayNanoseconds = stopDelayNanoseconds
        self.finishesCleanlyOnStop = finishesCleanlyOnStop
        self.runtimeSnapshotValue = runtimeSnapshot ?? SpeechEngineRuntimeSnapshot(
            identifier: identifier,
            warmState: .warm
        )
    }

    var availability: SpeechEngineAvailability {
        get async {
            SpeechEngineAvailability(isAvailable: true)
        }
    }

    var runtimeSnapshot: SpeechEngineRuntimeSnapshot {
        get async {
            runtimeSnapshotValue
        }
    }

    func prepare() async throws {}

    func synthesize(_ request: SpeechRequest) -> AsyncThrowingStream<SpeechChunk, Error> {
        lock.lock()
        storedSynthesizeCallCount += 1
        let stopGeneration = storedStopGeneration
        lock.unlock()

        return AsyncThrowingStream { continuation in
            Task {
                if let synthesizeError {
                    continuation.finish(throwing: synthesizeError)
                    return
                }

                for chunk in yieldedChunks {
                    if chunkDelayNanoseconds > 0 {
                        try? await Task.sleep(nanoseconds: chunkDelayNanoseconds)
                    }

                    if Task.isCancelled {
                        continuation.finish(throwing: CancellationError())
                        return
                    }

                    if currentStopGeneration() != stopGeneration {
                        if finishesCleanlyOnStop {
                            continuation.finish()
                        } else {
                            continuation.finish(throwing: CancellationError())
                        }
                        return
                    }

                    continuation.yield(chunk)
                }

                continuation.finish()
            }
        }
    }

    func stop() async {
        if stopDelayNanoseconds > 0 {
            try? await Task.sleep(nanoseconds: stopDelayNanoseconds)
        }

        incrementStopState()
    }

    func synthesizeCallCount() -> Int {
        lock.lock()
        defer { lock.unlock() }
        return storedSynthesizeCallCount
    }

    func stopCallCount() -> Int {
        lock.lock()
        defer { lock.unlock() }
        return storedStopCallCount
    }

    private func currentStopGeneration() -> Int {
        lock.lock()
        defer { lock.unlock() }
        return storedStopGeneration
    }

    private func incrementStopState() {
        lock.lock()
        storedStopCallCount += 1
        storedStopGeneration += 1
        lock.unlock()
    }
}

private actor FakeAudioChunkPlayer: AudioChunkPlayer {
    private var storedEnqueuedChunkCount = 0
    private var storedStopCount = 0
    private var storedPaused = false
    private var storedPrebufferLeadDurations: [TimeInterval] = []
    private let drainDelayNanoseconds: UInt64

    init(drainDelayNanoseconds: UInt64 = 0) {
        self.drainDelayNanoseconds = drainDelayNanoseconds
    }

    func enqueue(_ chunk: SpeechChunk) async throws {
        guard chunk.audioSamples.isEmpty == false else {
            return
        }

        if let prebufferLeadDuration = chunk.prebufferLeadDuration {
            storedPrebufferLeadDurations.append(prebufferLeadDuration)
        }

        storedEnqueuedChunkCount += 1
    }

    func pause() async {
        storedPaused = true
    }

    func resume() async {
        storedPaused = false
    }

    func stop() async {
        storedPaused = false
        storedStopCount += 1
    }

    func waitUntilDrained() async {
        if drainDelayNanoseconds > 0 {
            try? await Task.sleep(nanoseconds: drainDelayNanoseconds)
        }
    }

    func isPaused() async -> Bool {
        storedPaused
    }

    func enqueuedChunkCount() async -> Int {
        storedEnqueuedChunkCount
    }

    func stopCount() async -> Int {
        storedStopCount
    }

    func recordedPrebufferLeadDurations() async -> [TimeInterval] {
        storedPrebufferLeadDurations
    }
}

private actor BlockingDiagnosticsCapture: DiagnosticsCapture {
    private let blockedEventName: String
    private var events: [DiagnosticEvent] = []
    private var blocked = false
    private var blockedContinuation: CheckedContinuation<Void, Never>?

    init(blockedEventName: String) {
        self.blockedEventName = blockedEventName
    }

    func record(_ event: DiagnosticEvent) async {
        events.append(event)

        guard event.name == blockedEventName else {
            return
        }

        blocked = true
        await withCheckedContinuation { continuation in
            blockedContinuation = continuation
        }
        blocked = false
    }

    func recentEvents(limit: Int) async -> [DiagnosticEvent] {
        Array(events.suffix(limit))
    }

    var isBlocked: Bool {
        blocked
    }

    func releaseBlockedEvent() {
        blockedContinuation?.resume()
        blockedContinuation = nil
    }
}

private actor InMemoryDictationSnippetStore: DictationSnippetStore {
    private var snippets: [DictationSnippet]

    init(snippets: [DictationSnippet]) {
        self.snippets = snippets
    }

    func loadSnippets() async throws -> [DictationSnippet] {
        snippets
    }

    func replaceSnippets(_ snippets: [DictationSnippet], creatingBackup: Bool) async throws -> URL? {
        self.snippets = snippets
        return nil
    }
}

private actor InMemoryDictationActionStore: DictationActionRegistryStore {
    private let actions: [DictationActionDefinition]

    init(actions: [DictationActionDefinition]) {
        self.actions = actions
    }

    func loadActions() async throws -> [DictationActionDefinition] {
        actions
    }
}

private actor DictationFormatterRecorder: DictationFormatterService {
    private var requests: [DictationFormattingRequest] = []

    func availability() async -> DictationServiceAvailability {
        DictationServiceAvailability(
            isAvailable: true,
            reason: "Synthetic formatter ready."
        )
    }

    func format(_ request: DictationFormattingRequest) async throws -> DictationFormatterResponse {
        requests.append(request)
        return DictationFormatterResponse(
            cleanedText: request.transcript,
            formattedText: request.transcript,
            detectedMode: .dictation,
            snippetApplications: request.appliedSnippets,
            actionCandidates: [],
            shouldInsertText: true,
            confidence: 0.9
        )
    }

    func recordedRequests() -> [DictationFormattingRequest] {
        requests
    }
}

private actor UnderPunctuatingDictationFormatter: DictationFormatterService {
    func availability() async -> DictationServiceAvailability {
        DictationServiceAvailability(
            isAvailable: true,
            reason: "Synthetic formatter returns under-punctuated text."
        )
    }

    func format(_ request: DictationFormattingRequest) async throws -> DictationFormatterResponse {
        let normalizedTranscript = request.transcript
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()

        let formattedText = normalizedTranscript.hasPrefix("can you")
            ? "Can you send me the latest build status."
            : "Hello world!"

        return DictationFormatterResponse(
            cleanedText: formattedText,
            formattedText: formattedText,
            detectedMode: .dictation,
            snippetApplications: request.appliedSnippets,
            actionCandidates: [],
            shouldInsertText: true,
            confidence: 0.8
        )
    }
}

private actor EmptyDictationFormatter: DictationFormatterService {
    func availability() async -> DictationServiceAvailability {
        DictationServiceAvailability(
            isAvailable: true,
            reason: "Synthetic formatter returns empty dictation text."
        )
    }

    func format(_ request: DictationFormattingRequest) async throws -> DictationFormatterResponse {
        DictationFormatterResponse(
            cleanedText: "",
            formattedText: "",
            detectedMode: .dictation,
            snippetApplications: request.appliedSnippets,
            actionCandidates: [],
            shouldInsertText: false,
            confidence: 0.2
        )
    }
}

private actor ActionCandidateDictationFormatter: DictationFormatterService {
    func availability() async -> DictationServiceAvailability {
        DictationServiceAvailability(
            isAvailable: true,
            reason: "Synthetic formatter returns an unsafe action candidate."
        )
    }

    func format(_ request: DictationFormattingRequest) async throws -> DictationFormatterResponse {
        DictationFormatterResponse(
            cleanedText: request.transcript,
            formattedText: "Please tidy this note.",
            detectedMode: .dictation,
            snippetApplications: request.appliedSnippets,
            actionCandidates: [
                DictationActionCandidate(
                    actionID: "example-local-notes",
                    triggerPhrase: "open example local notes",
                    confidence: 0.99
                )
            ],
            shouldInsertText: true,
            confidence: 0.9
        )
    }
}

private actor FailingDictationFormatter: DictationFormatterService {
    func availability() async -> DictationServiceAvailability {
        DictationServiceAvailability(
            isAvailable: true,
            reason: "Synthetic formatter intentionally stalls."
        )
    }

    func format(_ request: DictationFormattingRequest) async throws -> DictationFormatterResponse {
        throw DictationRuntimeError.formattingFailed("Synthetic formatter stall.")
    }
}

private actor TimeoutDictationFormatter: DictationFormatterService {
    func availability() async -> DictationServiceAvailability {
        DictationServiceAvailability(
            isAvailable: true,
            reason: "Synthetic formatter that always times out."
        )
    }

    func format(_ request: DictationFormattingRequest) async throws -> DictationFormatterResponse {
        throw DictationRuntimeError.formattingFailed(
            "Ollama formatter timed out after 2s using llama3.2:3b. VoiceBar inserted deterministic output without LLM cleanup."
        )
    }
}

private enum FakeSpeechError: LocalizedError {
    case syntheticFailure(String)

    var errorDescription: String? {
        switch self {
        case .syntheticFailure(let message):
            return message
        }
    }
}
