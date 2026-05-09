import SwiftUI
import VoiceBarCore

private struct AppProfileDraft {
    var bundleIdentifier: String
    var preferredMode: SpeechMode
    var stylePreset: String
    var handlingMode: TextHandlingMode
    var skipCodeBlocks: Bool
    var skipInlineCode: Bool
    var allowClipboardFallback: Bool
    var pacingMultiplierText: String

    init(profile: AppProfile? = nil) {
        bundleIdentifier = profile?.bundleIdentifier ?? ""
        preferredMode = profile?.preferredMode ?? .quick
        stylePreset = profile?.stylePreset ?? SpeechStyleCatalog.defaultPresetName
        handlingMode = profile?.normalizationOptions.resolvedHandlingMode ?? .proseFirst
        skipCodeBlocks = profile?.normalizationOptions.skipCodeBlocks ?? true
        skipInlineCode = profile?.normalizationOptions.skipInlineCode ?? false
        allowClipboardFallback = profile?.allowClipboardFallback ?? false

        if let pacingMultiplier = profile?.pacingMultiplier {
            pacingMultiplierText = String(format: "%.2f", pacingMultiplier)
        } else {
            pacingMultiplierText = ""
        }
    }

    func toProfile() -> AppProfile {
        let trimmedPacing = pacingMultiplierText.trimmingCharacters(in: .whitespacesAndNewlines)
        let pacingMultiplier = trimmedPacing.isEmpty ? nil : Double(trimmedPacing)

        return AppProfile(
            bundleIdentifier: bundleIdentifier,
            preferredMode: preferredMode,
            stylePreset: stylePreset,
            normalizationOptions: NormalizationOptions(
                handlingMode: handlingMode,
                headingsOnly: handlingMode == .headingsOnly,
                skipCodeBlocks: skipCodeBlocks,
                skipInlineCode: skipInlineCode
            ),
            pacingMultiplier: pacingMultiplier,
            allowClipboardFallback: allowClipboardFallback
        )
    }
}

private struct SnippetDraft {
    var id: String
    var label: String
    var triggersText: String
    var expansion: String
    var enabled: Bool
    var importMetadata: DictationSnippetImportMetadata?

    init(snippet: DictationSnippet? = nil) {
        id = snippet?.id ?? UUID().uuidString
        label = snippet?.label ?? ""
        triggersText = snippet?.triggers.joined(separator: "\n") ?? ""
        expansion = snippet?.expansion ?? ""
        enabled = snippet?.enabled ?? true
        importMetadata = snippet?.importMetadata
    }

    func toSnippet() -> DictationSnippet {
        let normalizedLabel = label.trimmingCharacters(in: .whitespacesAndNewlines)
        let triggerPhrases = triggersText
            .components(separatedBy: .newlines)
            .flatMap { $0.components(separatedBy: ",") }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }
        let uniqueTriggerPhrases = DictationSnippetTriggerUtilities.uniquedTriggers(triggerPhrases)

        return DictationSnippet(
            id: id,
            label: normalizedLabel.isEmpty ? nil : normalizedLabel,
            triggers: uniqueTriggerPhrases,
            expansion: expansion,
            enabled: enabled,
            importMetadata: importMetadata
        )
    }

    mutating func addLabelAsTrigger() {
        let triggers = triggerLines
        triggersText = DictationSnippetTriggerUtilities.addingLabelAsTrigger(
            label: label,
            to: triggers
        )
        .joined(separator: "\n")
    }

    mutating func addCommonSpeechAliases() {
        let aliases = DictationSnippetTriggerUtilities.conservativeSpeechAliases(for: label)
        triggersText = DictationSnippetTriggerUtilities.uniquedTriggers(triggerLines + aliases)
            .joined(separator: "\n")
    }

    var canAddLabelAsTrigger: Bool {
        let trimmedLabel = label.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedLabel.isEmpty == false else {
            return false
        }

        let labelKey = DictationSnippetTriggerUtilities.triggerComparisonKey(trimmedLabel)
        return triggerLines.contains { trigger in
            DictationSnippetTriggerUtilities.triggerComparisonKey(trigger) == labelKey
        } == false
    }

    var canAddCommonSpeechAliases: Bool {
        let existingTriggers = Set(triggerLines.map(DictationSnippetTriggerUtilities.triggerComparisonKey))
        return DictationSnippetTriggerUtilities.conservativeSpeechAliases(for: label).contains { alias in
            existingTriggers.contains(DictationSnippetTriggerUtilities.triggerComparisonKey(alias)) == false
        }
    }

    private var triggerLines: [String] {
        triggersText
            .components(separatedBy: .newlines)
            .flatMap { $0.components(separatedBy: ",") }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }
    }
}

struct SettingsRootView: View {
    @Bindable var appState: VoiceBarAppState
    @State private var selectedProfileBundleIdentifier: String?
    @State private var profileDraft = AppProfileDraft()
    @State private var formatterModelDraft = ""
    @State private var selectedSnippetID: String?
    @State private var snippetDraft = SnippetDraft()
    @State private var snippetPendingDeletion: DictationSnippet?
    @FocusState private var isFormatterModelFocused: Bool

    var body: some View {
        TabView(
            selection: Binding(
                get: { appState.selectedSettingsTab },
                set: { appState.selectSettingsTab($0) }
            )
        ) {
            generalSettingsTab
                .tabItem {
                    Label(SettingsTab.general.title, systemImage: SettingsTab.general.systemImage)
                }
                .tag(SettingsTab.general)

            dictationTab
                .tabItem {
                    Label(SettingsTab.dictation.title, systemImage: SettingsTab.dictation.systemImage)
                }
                .tag(SettingsTab.dictation)

            voicesAndStyleTab
                .tabItem {
                    Label(SettingsTab.voicesStyle.title, systemImage: SettingsTab.voicesStyle.systemImage)
                }
                .tag(SettingsTab.voicesStyle)

            textHandlingTab
                .tabItem {
                    Label(SettingsTab.textHandling.title, systemImage: SettingsTab.textHandling.systemImage)
                }
                .tag(SettingsTab.textHandling)

            perAppProfilesTab
                .tabItem {
                    Label(SettingsTab.perAppProfiles.title, systemImage: SettingsTab.perAppProfiles.systemImage)
                }
                .tag(SettingsTab.perAppProfiles)

            hotkeysTab
                .tabItem {
                    Label(SettingsTab.hotkeys.title, systemImage: SettingsTab.hotkeys.systemImage)
                }
                .tag(SettingsTab.hotkeys)

            diagnosticsTab
                .tabItem {
                    Label(SettingsTab.diagnostics.title, systemImage: SettingsTab.diagnostics.systemImage)
                }
                .tag(SettingsTab.diagnostics)

            advancedTab
                .tabItem {
                    Label(SettingsTab.advanced.title, systemImage: SettingsTab.advanced.systemImage)
                }
                .tag(SettingsTab.advanced)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(minWidth: 780, minHeight: 540)
        .onAppear(perform: handleSettingsAppear)
        .onChange(of: selectedProfileBundleIdentifier) {
            profileDraft = AppProfileDraft(profile: selectedProfile)
        }
        .onChange(of: appState.knownProfiles.count, handleProfileCountChanged)
        .onChange(of: appState.preferences.formatterModelIdentifier, handleFormatterModelChanged)
        .onChange(of: selectedSnippetID) {
            snippetDraft = SnippetDraft(snippet: selectedSnippet)
        }
        .onChange(of: appState.dictationSnippets, handleSnippetsChanged)
        .alert(
            "Delete Snippet?",
            isPresented: Binding(
                get: { snippetPendingDeletion != nil },
                set: { shouldPresent in
                    if shouldPresent == false {
                        snippetPendingDeletion = nil
                    }
                }
            ),
            presenting: snippetPendingDeletion
        ) { snippet in
            Button("Delete", role: .destructive) {
                Task {
                    await appState.deleteDictationSnippet(id: snippet.id)
                    selectedSnippetID = appState.dictationSnippets.first?.id
                    snippetDraft = SnippetDraft(snippet: selectedSnippet)
                    snippetPendingDeletion = nil
                }
            }
            Button("Cancel", role: .cancel) {
                snippetPendingDeletion = nil
            }
        } message: { snippet in
            Text("VoiceBar will remove '\(displayLabel(for: snippet))' from the local snippets file after creating a backup.")
        }
    }

    private var selectedProfile: AppProfile? {
        appState.knownProfiles.first { $0.bundleIdentifier == selectedProfileBundleIdentifier }
    }

    private var selectedSnippet: DictationSnippet? {
        appState.dictationSnippets.first { $0.id == selectedSnippetID }
    }

    private var generalSettingsTab: some View {
        Form {
            Section("Playback Defaults") {
                Picker(
                    "Default Engine",
                    selection: Binding(
                        get: { appState.preferences.selectedMode },
                        set: { appState.selectMode($0) }
                    )
                ) {
                    ForEach(SpeechMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }

                Toggle(
                    "Preload Premium Engine in Background",
                    isOn: Binding(
                        get: { appState.preferences.preloadPremiumEngine },
                        set: { appState.setPreloadPremiumEngine($0) }
                    )
                )

                Toggle(
                    "Show Floating Controller During Playback",
                    isOn: Binding(
                        get: { appState.preferences.floatingControllerEnabled },
                        set: { appState.setFloatingControllerEnabled($0) }
                    )
                )
            }

            Section("Launch at Login") {
                Toggle(
                    "Launch VoiceBar at Login",
                    isOn: Binding(
                        get: { appState.launchAtLoginStatus.isEnabled },
                        set: { appState.setLaunchAtLoginEnabled($0) }
                    )
                )
                .disabled(appState.launchAtLoginStatus.canToggle == false)

                Text(appState.launchAtLoginStatus.detail)
                    .foregroundStyle(.secondary)
            }

            Section("Current Runtime") {
                LabeledContent("Playback State", value: appState.playbackState.status.rawValue.capitalized)
                LabeledContent("Current Engine", value: appState.playbackState.currentEngineIdentifier ?? "None")
                LabeledContent("Current Voice", value: appState.currentVoiceSummary)
                LabeledContent("Queued Requests", value: "\(appState.playbackState.queuedRequestCount)")
            }
        }
        .formStyle(.grouped)
    }

    private var voicesAndStyleTab: some View {
        Form {
            Section("Voice") {
                Picker(
                    "Default Voice",
                    selection: Binding(
                        get: { appState.preferences.selectedVoiceIdentifier },
                        set: { appState.selectVoice(identifier: $0) }
                    )
                ) {
                    ForEach(appState.availableVoices) { voice in
                        Text("\(voice.displayName) · \(voice.nativeLanguage)").tag(voice.id)
                    }
                }

                if let currentVoice = appState.currentVoiceOption {
                    Text(currentVoice.voiceDescription)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Style") {
                Picker(
                    "Default Style Preset",
                    selection: Binding(
                        get: { appState.preferences.selectedStylePresetName },
                        set: { appState.selectStylePreset($0) }
                    )
                ) {
                    ForEach(appState.availableStylePresets) { preset in
                        Text(preset.name).tag(preset.name)
                    }
                }

                TextEditor(
                    text: Binding(
                        get: { appState.preferences.customStyleInstruction },
                        set: { appState.updateCustomStyleInstruction($0) }
                    )
                )
                .font(.body)
                .frame(minHeight: 120)
                .disabled(appState.preferences.selectedStylePresetName != SpeechStyleCatalog.customPresetName)

                Text(
                    appState.preferences.selectedStylePresetName == SpeechStyleCatalog.customPresetName
                        ? "This custom instruction is passed straight into the 1.7B instruction-capable path. Leave it blank to fall back to VoiceBar's named presets."
                        : "Named style presets now resolve to the real operator-approved instruction text instead of just sending their label."
                )
                .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    private var dictationTab: some View {
        Form {
            Section("Dictation Runtime") {
                Button(dictationControlTitle) {
                    Task {
                        await appState.toggleDictation()
                    }
                }
                .disabled(appState.isDictationProcessing)

                Text(appState.dictationStatus)
                    .foregroundStyle(.secondary)

                Text(appState.dictationRuntimeSummary)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            Section("Formatter") {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        Text("Model")
                            .foregroundStyle(.secondary)
                            .frame(width: 52, alignment: .leading)

                    TextField("Model", text: Binding(
                        get: { formatterModelDraft },
                        set: { formatterModelDraft = $0 }
                    ))
                    .textFieldStyle(.roundedBorder)
                    .focused($isFormatterModelFocused)
                    .onSubmit {
                        applyFormatterModelDraft()
                    }
                    .onChange(of: isFormatterModelFocused) {
                        if isFormatterModelFocused == false {
                            applyFormatterModelDraft()
                        }
                    }

                    Button("Apply") {
                        applyFormatterModelDraft()
                    }
                    .disabled(formatterModelDraft.trimmingCharacters(in: .whitespacesAndNewlines) == appState.preferences.formatterModelIdentifier)
                    }

                    HStack(spacing: 10) {
                        Text("Mode")
                            .foregroundStyle(.secondary)
                            .frame(width: 52, alignment: .leading)

                    Picker("Mode", selection: Binding(
                        get: { appState.preferences.dictationFormattingMode },
                        set: { appState.setDictationFormattingMode($0) }
                    )) {
                        ForEach(DictationFormattingMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 340)
                    }

                    HStack(spacing: 10) {
                        Text("Quality")
                            .foregroundStyle(.secondary)
                            .frame(width: 52, alignment: .leading)

                    Picker("Quality", selection: Binding(
                        get: { appState.preferences.dictationFormatterQualityMode },
                        set: { appState.setDictationFormatterQualityMode($0) }
                    )) {
                        ForEach(DictationFormatterQualityMode.allCases, id: \.self) { qualityMode in
                            Text(qualityMode.rawValue).tag(qualityMode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 340)
                    }
                }

                Text("Dictation is formatted using Ollama. Quality controls how long VoiceBar waits for local cleanup before falling back to deterministic snippet-expanded insertion.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                LabeledContent("Resolved Model", value: appState.dictationRuntimeSummary
                    .components(separatedBy: "\n")
                    .first(where: { $0.hasPrefix("Formatter model:") })?
                    .replacingOccurrences(of: "Formatter model: ", with: "")
                    ?? "Unknown")
            }

            Section("Output") {
                HStack(spacing: 16) {
                    Toggle("Insert at Cursor", isOn: Binding(
                        get: { appState.preferences.insertDictationAtCursor },
                        set: { appState.setInsertDictationAtCursor($0) }
                    ))

                    Toggle("Auto-Run Actions", isOn: Binding(
                        get: { appState.preferences.autoRunTrustedActions },
                        set: { appState.setAutoRunTrustedActions($0) }
                    ))

                    Toggle("Audio Confirmation", isOn: Binding(
                        get: { appState.preferences.dictationAudioConfirmationEnabled },
                        set: { appState.setDictationAudioConfirmationEnabled($0) }
                    ))
                }
                .font(.callout)

                Text("Actions only run from the local allowlist. Shell commands from the formatter are never executed.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 10) {
                    Toggle("Save Recent Dictations for Recovery", isOn: Binding(
                        get: { appState.preferences.saveRecentDictationsForRecovery },
                        set: { appState.setSaveRecentDictationsForRecovery($0) }
                    ))

                    Stepper(
                        "Keep last \(appState.preferences.dictationHistoryRetentionLimit) dictation\(appState.preferences.dictationHistoryRetentionLimit == 1 ? "" : "s")",
                        value: Binding(
                            get: { appState.preferences.dictationHistoryRetentionLimit },
                            set: { appState.setDictationHistoryRetentionLimit($0) }
                        ),
                        in: VoiceBarPreferences.minimumDictationHistoryRetentionLimit...VoiceBarPreferences.maximumDictationHistoryRetentionLimit,
                        step: 1
                    )
                    .disabled(appState.preferences.saveRecentDictationsForRecovery == false)

                    Text("VoiceBar saves the raw transcript and final formatted text locally before insertion, so a wrong cursor or failed paste does not lose the dictation. Diagnostics still record counts only, not dictated text.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 4)
            }

            Section("Files") {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Snippets")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(VoiceBarStorageLocation.dictationSnippetsURL.lastPathComponent)
                            .font(.callout)
                    }
                    Spacer()
                    Button("Show") {
                        appState.revealSnippetStoreInFinder()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Actions")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(VoiceBarStorageLocation.dictationActionsURL.lastPathComponent)
                            .font(.callout)
                    }
                    Spacer()
                    Button("Show") {
                        appState.revealActionRegistryInFinder()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }

            Section("Local Snippets") {
                snippetManagementPanel

                Text(appState.snippetManagementStatus)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }

            Section("Wispr Flow Snippets") {
                HStack(spacing: 10) {
                    Button {
                        Task {
                            await appState.previewWisprFlowSnippetImport()
                        }
                    } label: {
                        Label("Preview Import", systemImage: "doc.text.magnifyingglass")
                    }
                    .buttonStyle(.bordered)
                    .disabled(appState.isWisprFlowSnippetImportInFlight)

                    Button {
                        Task {
                            await appState.applyWisprFlowSnippetImport()
                        }
                    } label: {
                        Label("Apply Import", systemImage: "square.and.arrow.down")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(appState.isWisprFlowSnippetImportInFlight)

                    Button {
                        Task {
                            await appState.reloadDictationSnippets()
                        }
                    } label: {
                        Label("Reload", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)

                    Button {
                        appState.revealWisprFlowImportReportsInFinder()
                    } label: {
                        Label("Show Reports", systemImage: "folder")
                    }
                    .buttonStyle(.bordered)
                }

                Text(appState.snippetImportStatus)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }

            Section("Recent Dictations") {
                dictationHistoryPanel

                Text(appState.dictationHistoryStatus)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }

            if !appState.lastDictationSummary.isEmpty {
                Section("Last Result") {
                    Text(appState.lastDictationSummary)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            }
        }
        .formStyle(.grouped)
    }

    private var dictationHistoryPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Button {
                    Task {
                        await appState.reloadDictationHistory()
                    }
                } label: {
                    Label("Reload", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)

                Button {
                    appState.copyLastDictationToClipboard()
                } label: {
                    Label("Copy Last Dictation", systemImage: "doc.on.doc")
                }
                .buttonStyle(.bordered)
                .disabled(appState.canCopyLastDictation == false)

                Button {
                    Task {
                        await appState.retryInsertLastDictation()
                    }
                } label: {
                    Label("Retry Insert Last Dictation", systemImage: "arrow.uturn.forward")
                }
                .buttonStyle(.bordered)
                .disabled(appState.canRetryLastDictation == false)

                Spacer()

                Button(role: .destructive) {
                    Task {
                        await appState.clearDictationHistory()
                    }
                } label: {
                    Label("Clear History", systemImage: "trash")
                }
                .buttonStyle(.bordered)
                .disabled(appState.recentDictationHistoryEntries.isEmpty)
            }

            if appState.recentDictationHistoryEntries.isEmpty {
                ContentUnavailableView(
                    "No recent dictations",
                    systemImage: "text.bubble",
                    description: Text("Enable local recovery above, then VoiceBar will save the raw transcript and formatted text before each insertion.")
                )
                .frame(maxWidth: .infinity, minHeight: 160)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(appState.recentDictationHistoryEntries) { entry in
                            dictationHistoryEntryCard(entry)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .frame(minHeight: 220, maxHeight: 420)
            }
        }
    }

    private func dictationHistoryEntryCard(_ entry: DictationHistoryEntry) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(entry.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.callout.weight(.semibold))
                    Text("\(entry.formattedCharacterCount.formatted()) formatted characters · \(entry.formatterPath.rawValue)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button("Copy") {
                    appState.copyDictationHistoryEntry(id: entry.id)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button("Retry Insert") {
                    Task {
                        await appState.retryInsertDictationHistoryEntry(id: entry.id)
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(appState.canRetryLastDictation == false)
            }

            Text(entry.formattedText)
                .font(.body)
                .lineLimit(4)
                .textSelection(.enabled)

            DisclosureGroup("Raw transcript and insertion details") {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Raw transcript")
                        .font(.caption.weight(.semibold))
                    Text(entry.rawTranscript)
                        .font(.caption)
                        .textSelection(.enabled)

                    Text(entry.insertionSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)

                    if let frontmostBundleIdentifier = entry.frontmostBundleIdentifier {
                        Text("Target application: \(frontmostBundleIdentifier)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                }
                .padding(.top, 4)
            }
            .font(.caption)
        }
        .padding(10)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
    }

    private var snippetManagementPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(appState.dictationSnippets.count) snippets")
                    .font(.headline)

                Spacer()

                Button {
                    selectedSnippetID = nil
                    snippetDraft = SnippetDraft()
                } label: {
                    Label("New", systemImage: "plus")
                }
                .buttonStyle(.bordered)

                Button {
                    Task {
                        await appState.reloadDictationSnippets()
                    }
                } label: {
                    Label("Reload", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
            }

            HStack(alignment: .top, spacing: 14) {
                snippetList
                    .frame(minWidth: 220, idealWidth: 260, maxWidth: 320, minHeight: 260)

                snippetEditor
                    .frame(maxWidth: .infinity, minHeight: 260)
            }
        }
    }

    private var snippetList: some View {
        Group {
            if appState.dictationSnippets.isEmpty {
                ContentUnavailableView("No snippets", systemImage: "text.badge.plus")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(selection: $selectedSnippetID) {
                    ForEach(appState.dictationSnippets) { snippet in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(displayLabel(for: snippet))
                                .lineLimit(1)

                            Text("\(snippet.triggers.count) trigger phrases")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        .padding(.vertical, 3)
                        .tag(Optional(snippet.id))
                    }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }
        }
    }

    private var snippetEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(selectedSnippet == nil ? "Create Snippet" : "Edit Snippet")
                        .font(.headline)
                    Text("Labels are display names. Trigger phrases and aliases are the exact phrases VoiceBar listens for.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Toggle("Enabled", isOn: $snippetDraft.enabled)
                    .toggleStyle(.switch)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Label")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("Display name only", text: $snippetDraft.label)
                    .textFieldStyle(.roundedBorder)
                Text("The label is not a spoken trigger unless it also appears below.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Trigger Phrases And Aliases")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Add every phrase you want to say, one per line.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextEditor(text: $snippetDraft.triggersText)
                    .font(.body)
                    .frame(minHeight: 82)
                    .overlay {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.25))
                    }

                HStack(spacing: 8) {
                    Button {
                        snippetDraft.addLabelAsTrigger()
                    } label: {
                        Label("Add Label as Trigger", systemImage: "text.badge.plus")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(snippetDraft.canAddLabelAsTrigger == false)

                    Button {
                        snippetDraft.addCommonSpeechAliases()
                    } label: {
                        Label("Add Speech Aliases", systemImage: "text.word.spacing")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(snippetDraft.canAddCommonSpeechAliases == false)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Expansion Text")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextEditor(text: $snippetDraft.expansion)
                    .font(.body)
                    .frame(minHeight: 116)
                    .overlay {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.25))
                    }
            }

            HStack {
                Button {
                    Task {
                        let snippet = snippetDraft.toSnippet()
                        await appState.saveDictationSnippet(snippet)
                        selectedSnippetID = snippet.id
                    }
                } label: {
                    Label("Save", systemImage: "checkmark")
                }
                .buttonStyle(.borderedProminent)
                .disabled(snippetDraft.triggersText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    || snippetDraft.expansion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Button {
                    snippetDraft = SnippetDraft(snippet: selectedSnippet)
                } label: {
                    Label("Reset", systemImage: "arrow.uturn.backward")
                }
                .buttonStyle(.bordered)

                Spacer()

                Button(role: .destructive) {
                    snippetPendingDeletion = selectedSnippet
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .buttonStyle(.bordered)
                .disabled(selectedSnippet == nil)
            }
        }
    }

    private var dictationControlTitle: String {
        if appState.isDictationRecording {
            return "Stop Dictation"
        }

        if appState.isDictationProcessing {
            return "Transcribing Dictation..."
        }

        return "Start Dictation"
    }

    private var holdToTalkDisplayString: String {
        switch appState.preferences.holdToTalkMode {
        case .optionShortcut:
            return appState.preferences.holdToTalkShortcut.displayString
        case .functionKeyExperimental:
            return "Function key (Fn)"
        }
    }

    private var holdToTalkModifierLabel: String {
        switch appState.preferences.holdToTalkMode {
        case .optionShortcut:
            return "Option"
        case .functionKeyExperimental:
            return "Function key (Fn)"
        }
    }

    private var holdToTalkModifierSystemImage: String {
        switch appState.preferences.holdToTalkMode {
        case .optionShortcut:
            return "option"
        case .functionKeyExperimental:
            return "globe"
        }
    }

    private var textHandlingTab: some View {
        Form {
            Section("Capture Method") {
                LabeledContent("Status", value: appState.accessibilitySummary)

                Toggle(
                    "Use Clipboard Fallback",
                    isOn: Binding(
                        get: { appState.preferences.copyFallbackEnabled },
                        set: { appState.setCopyFallbackEnabled($0) }
                    )
                )

                Text("When Accessibility capture fails, VoiceBar can fall back to clipboard copy. Configure per-app behavior in the Per-App Profiles tab.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    private var perAppProfilesTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Per-App Profiles")
                    .font(.title3.weight(.semibold))
                Text("Tune engine, style, text handling, and fallback behavior for specific apps.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .top, spacing: 16) {
                profileListCard
                    .frame(minWidth: 280, idealWidth: 330, maxWidth: 380, maxHeight: .infinity)

                profileEditorCard
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 12)
    }

    private var profileListCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Profiles")
                    .font(.headline)
                Spacer()
                Button("New") {
                    selectedProfileBundleIdentifier = nil
                    profileDraft = AppProfileDraft()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }

            if appState.knownProfiles.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("No profiles yet")
                        .font(.callout.weight(.medium))
                    Text("Create a profile for Safari, Notes, Codex, or another app bundle identifier.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(Color(NSColor.controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                List(selection: $selectedProfileBundleIdentifier) {
                    ForEach(appState.knownProfiles) { profile in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(profile.bundleIdentifier)
                                .font(.callout.weight(.semibold))
                                .lineLimit(1)
                            Text("\(profile.preferredMode.rawValue) · \(profile.stylePreset)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        .padding(.vertical, 5)
                        .tag(Optional(profile.bundleIdentifier))
                    }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }
        }
        .padding(14)
        .background(Color(NSColor.windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var profileEditorCard: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(selectedProfileBundleIdentifier == nil ? "Create Profile" : "Selected Profile")
                            .font(.headline)
                        Text(selectedProfileBundleIdentifier ?? "New app-specific override")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    Button("Save Profile") {
                        Task {
                            await appState.saveProfile(profileDraft.toProfile())
                        }
                    }
                    .keyboardShortcut(.return, modifiers: .command)
                    .buttonStyle(.borderedProminent)
                    .disabled(profileDraft.bundleIdentifier.isEmpty)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("App")
                        .font(.subheadline.weight(.semibold))
                    TextField("Bundle identifier, e.g. com.apple.Safari", text: $profileDraft.bundleIdentifier)
                        .textFieldStyle(.roundedBorder)
                }

                Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 16, verticalSpacing: 14) {
                    GridRow {
                        Text("Engine")
                            .foregroundStyle(.secondary)
                        Picker("Engine", selection: $profileDraft.preferredMode) {
                            ForEach(SpeechMode.allCases, id: \.self) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .labelsHidden()
                        .frame(maxWidth: 260)
                    }

                    GridRow {
                        Text("Style")
                            .foregroundStyle(.secondary)
                        Picker("Style", selection: $profileDraft.stylePreset) {
                            ForEach(appState.availableStylePresets) { preset in
                                Text(preset.name).tag(preset.name)
                            }
                        }
                        .labelsHidden()
                        .frame(maxWidth: 320)
                    }

                    GridRow {
                        Text("Text Handling")
                            .foregroundStyle(.secondary)
                        Picker("Text Handling", selection: $profileDraft.handlingMode) {
                            ForEach(TextHandlingMode.allCases, id: \.self) { mode in
                                Text(mode.displayName).tag(mode)
                            }
                        }
                        .labelsHidden()
                        .frame(maxWidth: 320)
                    }

                    GridRow {
                        Text("Pacing")
                            .foregroundStyle(.secondary)
                        HStack(spacing: 8) {
                            TextField("1.00", text: $profileDraft.pacingMultiplierText)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 84)
                            Text("multiplier")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Capture Rules")
                        .font(.subheadline.weight(.semibold))
                    Toggle("Skip code blocks", isOn: $profileDraft.skipCodeBlocks)
                    Toggle("Skip inline code", isOn: $profileDraft.skipInlineCode)
                    Toggle("Allow clipboard fallback", isOn: $profileDraft.allowClipboardFallback)
                }

                Text("Profiles apply after saving. Clipboard fallback should stay off unless a specific app blocks Accessibility selection capture.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(18)
        }
        .background(Color(NSColor.windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var hotkeysTab: some View {
        Form {
            Section {
                Toggle(
                    "Enable Global Hotkeys",
                    isOn: Binding(
                        get: { appState.preferences.hotkeysEnabled },
                        set: { appState.setHotkeysEnabled($0) }
                    )
                )

                if !appState.hotkeyStatusMessage.isEmpty {
                    Text(appState.hotkeyStatusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Shortcuts") {
                VStack(spacing: 12) {
                    ForEach(HotkeyAction.allCases) { action in
                        HStack {
                            Toggle(
                                "",
                                isOn: Binding(
                                    get: { appState.preferences.shortcut(for: action).isEnabled },
                                    set: { isEnabled in
                                        var updatedShortcut = appState.preferences.shortcut(for: action)
                                        updatedShortcut.isEnabled = isEnabled
                                        appState.updateHotkey(updatedShortcut, for: action)
                                    }
                                )
                            )
                            .toggleStyle(.checkbox)
                            .labelsHidden()

                            Text(action.title)
                                .frame(width: 140, alignment: .leading)

                            HStack(spacing: 4) {
                                Picker(
                                    "",
                                    selection: Binding(
                                        get: { appState.preferences.shortcut(for: action).keyCode },
                                        set: { keyCode in
                                            var updatedShortcut = appState.preferences.shortcut(for: action)
                                            updatedShortcut.keyCode = keyCode
                                            appState.updateHotkey(updatedShortcut, for: action)
                                        }
                                    )
                                ) {
                                    ForEach(HotkeyCatalog.options) { option in
                                        Text(option.label).tag(option.keyCode)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(width: 70)
                                .labelsHidden()

                                Toggle("⌃", isOn: Binding(
                                    get: { appState.preferences.shortcut(for: action).control },
                                    set: { control in
                                        var updatedShortcut = appState.preferences.shortcut(for: action)
                                        updatedShortcut.control = control
                                        appState.updateHotkey(updatedShortcut, for: action)
                                    }
                                ))
                                .toggleStyle(.button)
                                .font(.caption)

                                Toggle("⌥", isOn: Binding(
                                    get: { appState.preferences.shortcut(for: action).option },
                                    set: { option in
                                        var updatedShortcut = appState.preferences.shortcut(for: action)
                                        updatedShortcut.option = option
                                        appState.updateHotkey(updatedShortcut, for: action)
                                    }
                                ))
                                .toggleStyle(.button)
                                .font(.caption)

                                Toggle("⇧", isOn: Binding(
                                    get: { appState.preferences.shortcut(for: action).shift },
                                    set: { shift in
                                        var updatedShortcut = appState.preferences.shortcut(for: action)
                                        updatedShortcut.shift = shift
                                        appState.updateHotkey(updatedShortcut, for: action)
                                    }
                                ))
                                .toggleStyle(.button)
                                .font(.caption)

                                Toggle("⌘", isOn: Binding(
                                    get: { appState.preferences.shortcut(for: action).command },
                                    set: { command in
                                        var updatedShortcut = appState.preferences.shortcut(for: action)
                                        updatedShortcut.command = command
                                        appState.updateHotkey(updatedShortcut, for: action)
                                    }
                                ))
                                .toggleStyle(.button)
                                .font(.caption)
                            }

                            Spacer()

                            Text(appState.preferences.shortcut(for: action).displayString)
                                .font(.system(.callout, design: .monospaced))
                                .foregroundStyle(appState.preferences.shortcut(for: action).isEnabled ? .primary : .secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(appState.preferences.shortcut(for: action).isEnabled ? Color.accentColor.opacity(0.1) : Color.clear)
                                .cornerRadius(4)
                        }
                    }
                }
            }

            Section("Hold-to-Talk Dictation") {
                Toggle(
                    "Enable Hold-to-Talk",
                    isOn: Binding(
                        get: { appState.preferences.holdToTalkEnabled },
                        set: { appState.setHoldToTalkEnabled($0) }
                    )
                )

                VStack(alignment: .leading, spacing: 12) {
                    Picker(
                        "Hold-to-Talk Mode",
                        selection: Binding(
                            get: { appState.preferences.holdToTalkMode },
                            set: { appState.setHoldToTalkMode($0) }
                        )
                    ) {
                        ForEach(HoldToTalkMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .disabled(appState.preferences.holdToTalkEnabled == false)

                    HStack {
                        Picker(
                            "Key",
                            selection: Binding(
                                get: { appState.preferences.holdToTalkShortcut.keyCode },
                                set: { keyCode in
                                    var updatedShortcut = appState.preferences.holdToTalkShortcut
                                    updatedShortcut.keyCode = keyCode
                                    appState.updateHoldToTalkShortcut(updatedShortcut)
                                }
                            )
                        ) {
                            ForEach(HotkeyCatalog.holdToTalkOptions) { option in
                                Text(option.label).tag(option.keyCode)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 160)
                        .disabled(appState.preferences.holdToTalkEnabled == false
                            || appState.preferences.holdToTalkMode == .functionKeyExperimental)

                        Label(holdToTalkModifierLabel, systemImage: holdToTalkModifierSystemImage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(4)

                        Spacer()

                        Text(holdToTalkDisplayString)
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.accentColor.opacity(0.1))
                            .cornerRadius(6)
                    }

                    Text("Function key (Fn) support depends on macOS, keyboard firmware, and the keyboard setting assigned to Function key (Fn) / Globe key. If unavailable, use Option+Period or an F13-F19 key.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("Option shortcut mode remains restricted to safer Option+punctuation or F13-F19 choices. Letter keys such as Option+D are intentionally hidden because they can emit characters into the focused app.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .formStyle(.grouped)
    }

    private var diagnosticsTab: some View {
        Form {
            Section("Runtime Status") {
                Text(appState.ttsKitStatus)
                    .font(.callout.monospaced())
                Text("Current voice: \(appState.currentVoiceDetail)")
                    .foregroundStyle(.secondary)
            }

            Section("Recent Diagnostics") {
                if appState.recentDiagnosticEvents.isEmpty {
                    Text("No diagnostics captured yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(appState.recentDiagnosticEvents) { event in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(event.name)
                                .font(.headline)
                            Text(event.detail)
                                .font(.callout)
                            Text(event.timestamp.formatted(date: .abbreviated, time: .standard))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            Section("Refresh") {
                Button("Refresh Runtime and Diagnostics") {
                    Task {
                        await appState.refreshSpeechRuntimeStatus()
                        await appState.refreshDiagnostics()
                        await appState.syncPlaybackState()
                    }
                }
            }
        }
        .formStyle(.grouped)
    }

    private var advancedTab: some View {
        Form {
            Section("Storage Paths") {
                Text(VoiceBarStorageLocation.fileURL(named: "pronunciation-dictionary.json").path)
                    .font(.callout.monospaced())
                Text(VoiceBarStorageLocation.fileURL(named: "app-profiles.json").path)
                    .font(.callout.monospaced())
            }

            Section("Known Limits") {
                Text("Global hotkeys, floating-controller focus behavior, and launch-at-login remain app-bundle dependent for full end-to-end validation on this Command Line Tools-only machine.")
                    .foregroundStyle(.secondary)
                Text("A full xcodebuild path is still blocked until a complete Xcode.app is installed or selected.")
                    .foregroundStyle(.secondary)
                Text("Truthful macOS Service registration still needs a real `.app` bundle build path.")
                    .foregroundStyle(.secondary)
            }

            Section("Current Status") {
                Text(appState.statusMessage)
                    .font(.callout)
                Text(appState.diagnosticsSummary)
                    .font(.callout.monospaced())
            }
        }
        .formStyle(.grouped)
    }

    private func applyFormatterModelDraft() {
        let normalizedDraft = formatterModelDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        formatterModelDraft = normalizedDraft

        guard normalizedDraft != appState.preferences.formatterModelIdentifier else {
            return
        }

        appState.updateFormatterModelIdentifier(normalizedDraft)
    }

    private func handleSettingsAppear() {
        if selectedProfileBundleIdentifier == nil {
            selectedProfileBundleIdentifier = appState.knownProfiles.first?.bundleIdentifier
            profileDraft = AppProfileDraft(profile: selectedProfile)
        }

        if formatterModelDraft.isEmpty {
            formatterModelDraft = appState.preferences.formatterModelIdentifier
        }

        if selectedSnippetID == nil {
            selectedSnippetID = appState.dictationSnippets.first?.id
            snippetDraft = SnippetDraft(snippet: selectedSnippet)
        }
    }

    private func handleProfileCountChanged() {
        if selectedProfileBundleIdentifier == nil {
            selectedProfileBundleIdentifier = appState.knownProfiles.first?.bundleIdentifier
        }

        if let selectedProfile {
            profileDraft = AppProfileDraft(profile: selectedProfile)
        }
    }

    private func handleFormatterModelChanged() {
        guard isFormatterModelFocused == false else {
            return
        }

        let currentModelIdentifier = appState.preferences.formatterModelIdentifier
        if formatterModelDraft != currentModelIdentifier {
            formatterModelDraft = currentModelIdentifier
        }
    }

    private func handleSnippetsChanged() {
        let currentSnippetID = selectedSnippetID
        let selectionStillExists = currentSnippetID.map { id in
            appState.dictationSnippets.contains { $0.id == id }
        } ?? false

        if selectionStillExists == false {
            selectedSnippetID = appState.dictationSnippets.first?.id
        }

        snippetDraft = SnippetDraft(snippet: selectedSnippet)
    }

    private func displayLabel(for snippet: DictationSnippet) -> String {
        let label = snippet.label?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let label, label.isEmpty == false {
            return label
        }

        return snippet.triggers.first ?? snippet.id
    }
}
