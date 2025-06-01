import SwiftUI

struct AppEntryView: View {
    let deps: DependencyProvider

    @Environment(\.modelContext) private var context
    @State private var selectedScreen: Screen = .main

    @ViewBuilder
    private var currentScreen: some View {
        switch selectedScreen {
        case .main:
            MainScreen(viewModel: deps.makeMainViewModel(context: context))
        case .permissions:
            PermissionsScreen(viewModel: deps.makePermissionsViewModel())
        case .settings:
            let manager = deps.makeAutoSyncManager(context: context)
            SettingsScreen(
                viewModel: deps.makeSettingsViewModel(autoSyncManager: manager),
                patientViewModel: deps.makePatientViewModel()
            )
        case .history:
            HistoryScreen(viewModel: deps.makeHistoryViewModel(context: context))
        }
    }

    var body: some View {
        NavigationStack {
            VStack {
                currentScreen
                    .padding()
            }
            .navigationTitle(selectedScreen.label)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        ForEach(Screen.allCases) { screen in
                            Button(action: {
                                selectedScreen = screen
                            }) {
                                Text(screen.label)
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal")
                    }

                }
            }

        }
    }
}
	
