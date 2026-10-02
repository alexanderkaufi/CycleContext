import SwiftUI

struct EntriesView: View {
    @EnvironmentObject private var store: CyclePreviewStore
    @State private var isAddingEntry = false
    @State private var editingEntry: EntryPreview?

    var body: some View {
        ScreenContainer(
            title: "screen.entries.title",
            actionIcon: "plus",
            action: { isAddingEntry = true }
        ) {
            SectionHeader(verbatimTitle: store.activeProfile.displayName)

            if store.activeEntries.isEmpty {
                IOSCard {
                    ContentUnavailableView(
                        "entries.empty.title",
                        systemImage: "square.and.pencil",
                        description: Text("entries.empty.body")
                    )
                }
            } else {
                IOSCard {
                    ForEach(store.activeEntries) { entry in
                        Button {
                            editingEntry = entry
                        } label: {
                            EntryRow(entry: entry)
                        }
                        .buttonStyle(.plain)

                        if entry.id != store.activeEntries.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $isAddingEntry) {
            EntryEditorView(profileName: store.activeProfile.displayName, initialDate: Date()) { title, note, date, wellbeing in
                store.addEntry(title: title, note: note, date: date, wellbeing: wellbeing)
            }
        }
        .sheet(item: $editingEntry) { entry in
            EntryEditorView(
                profileName: store.activeProfile.displayName,
                entry: entry,
                initialDate: entry.date,
                onSave: { title, note, date, wellbeing in
                    store.saveEntry(entry, title: title, note: note, date: date, wellbeing: wellbeing)
                },
                onDelete: {
                    store.deleteEntry(entry)
                }
            )
        }
    }
}

private struct EntryRow: View {
    var entry: EntryPreview

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: entry.phase.icon)
                .foregroundStyle(entry.phase.tint)
                .frame(width: 30, height: 30)
                .background(entry.phase.tint.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(entry.title.isEmpty ? String(localized: "entry.defaultTitle") : entry.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    if entry.isDemo {
                        Label("entries.demo.badge", systemImage: "info.circle")
                            .labelStyle(.titleAndIcon)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if !entry.note.isEmpty {
                    Text(entry.note)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let wellbeing = entry.wellbeing {
                    if !wellbeing.summary.isEmpty {
                        Text(wellbeing.summary)
                            .font(.caption)
                            .foregroundStyle(entry.phase.tint)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if !wellbeing.supportNeed.isEmpty {
                        Label(wellbeing.supportNeed, systemImage: "hands.sparkles.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            Image(systemName: "chevron.forward")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
                .padding(.top, 4)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

struct EntryEditorView: View {
    var profileName: String
    var entry: EntryPreview?
    var onSave: (String, String, Date, WellbeingSnapshot?) -> Void
    var onDelete: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var note: String
    @State private var date: Date
    @State private var bleeding: BleedingLevel?
    @State private var pain: PainLevel?
    @State private var energy: DailyEnergyLevel?
    @State private var supportNeed: String
    @State private var confirmsDeletion = false

    init(
        profileName: String,
        entry: EntryPreview? = nil,
        initialDate: Date,
        onSave: @escaping (String, String, Date, WellbeingSnapshot?) -> Void,
        onDelete: (() -> Void)? = nil
    ) {
        self.profileName = profileName
        self.entry = entry
        self.onSave = onSave
        self.onDelete = onDelete
        _title = State(initialValue: entry?.title ?? "")
        _note = State(initialValue: entry?.note ?? "")
        _date = State(initialValue: entry?.date ?? initialDate)
        _bleeding = State(initialValue: entry?.wellbeing?.bleeding)
        _pain = State(initialValue: entry?.wellbeing?.pain)
        _energy = State(initialValue: entry?.wellbeing?.energy)
        _supportNeed = State(initialValue: entry?.wellbeing?.supportNeed ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("entry.section.person") {
                    LabeledContent("entry.profile", value: profileName)
                }

                Section("entry.section.wellbeing") {
                    DatePicker("entry.date", selection: $date, displayedComponents: .date)

                    Picker("entry.bleeding", selection: $bleeding) {
                        Text("entry.notRecorded").tag(nil as BleedingLevel?)
                        ForEach(BleedingLevel.allCases) { level in
                            Text(level.title).tag(level as BleedingLevel?)
                        }
                    }

                    Picker("entry.pain", selection: $pain) {
                        Text("entry.notRecorded").tag(nil as PainLevel?)
                        ForEach(PainLevel.allCases) { level in
                            Text(level.title).tag(level as PainLevel?)
                        }
                    }

                    Picker("entry.energy", selection: $energy) {
                        Text("entry.notRecorded").tag(nil as DailyEnergyLevel?)
                        ForEach(DailyEnergyLevel.allCases) { level in
                            Text(level.title).tag(level as DailyEnergyLevel?)
                        }
                    }

                    TextField("entry.supportNeed.placeholder", text: $supportNeed, axis: .vertical)
                        .lineLimit(1...4)
                }

                Section("entry.section.optionalNote") {
                    TextField("entry.title", text: $title)
                    TextField("entry.note", text: $note, axis: .vertical)
                        .lineLimit(3...8)
                }

                if onDelete != nil {
                    Section {
                        Button("entry.delete", role: .destructive) {
                            confirmsDeletion = true
                        }
                    }
                }
            }
            .navigationTitle(
                entry == nil
                    ? String(localized: "entry.add.title")
                    : String(localized: "entry.edit.title")
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("common.save") {
                        onSave(title, note, date, wellbeing)
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
            .confirmationDialog(
                "entry.delete.confirmationTitle",
                isPresented: $confirmsDeletion,
                titleVisibility: .visible
            ) {
                Button("entry.delete", role: .destructive) {
                    onDelete?()
                    dismiss()
                }
                Button("common.cancel", role: .cancel) {}
            }
        }
    }

    private var wellbeing: WellbeingSnapshot? {
        let snapshot = WellbeingSnapshot(
            bleeding: bleeding,
            pain: pain,
            energy: energy,
            supportNeed: supportNeed.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        return snapshot.isEmpty ? nil : snapshot
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || wellbeing != nil
    }
}

struct EntriesView_Previews: PreviewProvider {
    static var previews: some View {
        EntriesView()
            .cyclePreviewEnvironment()
            .previewDisplayName("Einträge")
    }
}
