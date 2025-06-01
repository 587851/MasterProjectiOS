import SwiftUI

struct SettingsScreen: View {
    @ObservedObject var viewModel: SettingsViewModel
    @ObservedObject var patientViewModel: PatientViewModel


    @State private var showTypeSelector = false
    @State private var cleanupMenuExpanded = false
    @State private var freqMenuExpanded = false

    private let cleanupOptions = ["Never", "1 day", "30 days", "90 days", "150 days", "365 days"]
    private let cleanupValues = [0, 1, 30, 90, 150, 365]

    private let frequencyOptions = ["Never", "Every 15 min", "Every Hour", "Every Day", "Every Week", "Every Month"]
    private let frequencyValues = [0, 1, 2, 3, 4, 5]

    private let groupedTypes = [
        "🫀 Vitals": ["Blood Pressure", "Heart Rate", "Heart Rate Variability", "Oxygen Saturation", "Resting Heart Rate", "Respiratory Rate"],
        "🏃 Activity": ["Distance", "Steps", "VO2 Max"],
        "🧍 Body": ["Basal Body Temperature", "Basal Metabolic Rate", "Body Fat", "Body Temperature"]
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                PatientInfoSection(viewModel: patientViewModel)
                Divider()
                
                AllowDuplicatesSection(
                    isOn: viewModel.uiState.allowDuplicates,
                    onToggle: viewModel.setAllowDuplicates
                )

                CleanupAgeSection(
                    selectedValue: viewModel.uiState.cleanupAgeDays,
                    options: cleanupOptions,
                    values: cleanupValues,
                    expanded: $cleanupMenuExpanded,
                    onSelect: viewModel.setCleanupAgeDays
                )

                AutoSyncFrequencySection(
                    selectedValue: viewModel.uiState.autoSyncFrequency,
                    options: frequencyOptions,
                    values: frequencyValues,
                    expanded: $freqMenuExpanded,
                    onSelect: viewModel.setAutoSyncFrequency
                )

                Button("Select Auto-Sync Data Types") {
                    withAnimation {
                        showTypeSelector.toggle()
                    }
                }

                if showTypeSelector {
                    TypeSelectorSection(
                        groupedTypes: groupedTypes,
                        selectedTypes: viewModel.uiState.autoSyncTypes,
                        onTypeChange: viewModel.setAutoSyncTypes
                    )
                }

                if viewModel.showToast, let message = viewModel.message {
                    Text(message)
                        .foregroundColor(.red)
                        .padding(.top)
                }
            }
            .padding()
        }
    }
}

struct PatientInfoSection: View {
    @ObservedObject var viewModel: PatientViewModel

    @State private var givenName: String = ""
    @State private var familyName: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Patient Information")
                .font(.headline)

            TextField("Given Name", text: $givenName)
                .textFieldStyle(.roundedBorder)

            TextField("Family Name", text: $familyName)
                .textFieldStyle(.roundedBorder)

            Button("Save Name") {
                viewModel.updateName(given: givenName, family: familyName)
            }

            Text("Patient ID: \(viewModel.patientInfo.externalID ?? "No ID")")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .onAppear {
            givenName = viewModel.patientInfo.givenName
            familyName = viewModel.patientInfo.familyName
        }
        .padding()
    }
}


struct AllowDuplicatesSection: View {
    let isOn: Bool
    let onToggle: (Bool) -> Void

    var body: some View {
        Toggle("Allow duplicated data to be sent", isOn: Binding(get: { isOn }, set: onToggle))
            .padding()
    }
}

struct CleanupAgeSection: View {
    let selectedValue: Int
    let options: [String]
    let values: [Int]
    @Binding var expanded: Bool
    let onSelect: (Int) -> Void

    var body: some View {
        VStack {
            Text("Auto-delete synced records older than:")
            Menu {
                ForEach(Array(options.enumerated()), id: \.offset) { index, label in
                    Button(label) {
                        onSelect(values[index])
                        expanded = false
                    }
                }
            } label: {
                Label(options[values.firstIndex(of: selectedValue) ?? 0], systemImage: "chevron.down")
                    .padding()
            }
        }
    }
}

struct AutoSyncFrequencySection: View {
    let selectedValue: Int
    let options: [String]
    let values: [Int]
    @Binding var expanded: Bool
    let onSelect: (Int) -> Void

    var body: some View {
        VStack {
            Text("Auto-Sync Frequency")
            Menu {
                ForEach(Array(options.enumerated()), id: \.offset) { index, label in
                    Button(label) {
                        onSelect(values[index])
                        expanded = false
                    }
                }
            } label: {
                Label(options[values.firstIndex(of: selectedValue) ?? 0], systemImage: "chevron.down")
                    .padding()
            }
        }
    }
}
struct TypeSelectorSection: View {
    let groupedTypes: [String: [String]]
    let selectedTypes: Set<String>
    let onTypeChange: (Set<String>) -> Void

    var body: some View {
        VStack(spacing: 12) {
            ForEach(groupedTypes.keys.sorted(), id: \.self) { group in
                TypeGroupView(
                    title: group,
                    types: groupedTypes[group] ?? [],
                    selectedTypes: selectedTypes,
                    onTypeChange: onTypeChange
                )
            }
        }
        .padding()
    }
}

struct TypeGroupView: View {
    let title: String
    let types: [String]
    let selectedTypes: Set<String>
    let onTypeChange: (Set<String>) -> Void

    var body: some View {
        DisclosureGroup(title) {
            ForEach(types, id: \.self) { type in
                Toggle(
                    type,
                    isOn: Binding(
                        get: { selectedTypes.contains(type) },
                        set: { newValue in
                            var updated = selectedTypes
                            if newValue {
                                updated.insert(type)
                            } else {
                                updated.remove(type)
                            }
                            onTypeChange(updated)
                        }
                    )
                )
            }
        }
    }
}
