import SwiftUI

struct PermissionsScreen: View {
    @ObservedObject var viewModel: PermissionsViewModel

    var body: some View {
        VStack(spacing: 16) {
            Text("Permission Status")
                .font(.title2)

            ScrollView {
                VStack(alignment: .center, spacing: 12) {
                    if let message = viewModel.healthConnectStatusMessage {
                        Text("HealthKit Status")
                            .font(.headline)

                        Text(message)
                            .multilineTextAlignment(.center)

                        Text("""
                        To grant HealthKit permissions, tap "Give Permissions" and follow the prompts. You can also manage permissions later under Privacy & Security > Health > MasterProjectiOS in the Settings app.

                        Note: If there's no HealthKit data available for a particular data type, the app may show that permission is not granted — even if it actually is.
                        """)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                        .padding(.bottom)
                    }

                    if !viewModel.readPermissions.isEmpty {
                        Text("Read Permissions")
                            .font(.headline)

                        ForEach(viewModel.readPermissions, id: \.0) { label, granted in
                            PermissionItem(label: label, granted: granted)
                        }
                    }
                }
                .padding()
            }

            Button("Give Permissions") {
                viewModel.requestPermissions()
            }
            .buttonStyle(.borderedProminent)

            Button("Reload Status") {
                viewModel.refreshPermissions()
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}

struct PermissionItem: View {
    let label: String
    let granted: Bool

    var body: some View {
        HStack {
            Text(granted ? "✅" : "❌")
            Text(label)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
