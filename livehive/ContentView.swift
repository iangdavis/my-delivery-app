import ActivityKit
import SwiftUI
import LiveHive

struct ContentView: View {
    @State private var activity: Activity<DeliveryAttributes>?
    @State private var message = "Start a Live Activity, then lock the phone."
    
    var body: some View {
        VStack(spacing: 16) {Text(message)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            if let id = activity?.id {
                Text(id)
                    .font(.system(.footnote, design: .monospaced))
                    .textSelection(.enabled)
            }
            
            Button("Start") { start() }
            Button("Update") { Task { await update() } }
                .disabled(activity == nil)
            Button("End") { Task { await end() } }
                .disabled(activity == nil)
        }
        .padding()
        .buttonStyle(.borderedProminent)
    }
    
    private func start() {
        LiveHive.configure(publicKey: "lh_pub_R9SlWNU7omRbkhKBJXPIht_gVAlRViuT")

        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            message = "Enable Live Activities in Settings."
            return
        }
        do {let activity = try Activity.request(
            attributes: DeliveryAttributes(),
            content: .init(state: .init(status: "preparing", eta: 12), staleDate: nil),
            pushType: .token
        )
            self.activity = activity
            LiveHive.register(activity)
            message = "Started. Lock the phone, then tap Update."
        } catch {
            message = error.localizedDescription
        }
    }
    
    private func update() async {
        guard let activity else { return }
        await activity.update(
            .init(state: .init(status: "driver_arriving", eta: 4), staleDate: nil)
        )
        message = "Updated to driver_arriving / 4 min."
    }
    
    private func end() async {
        guard let activity else { return }
        await activity.end(
            .init(state: .init(status: "delivered", eta: 0), staleDate: nil),
            dismissalPolicy: .immediate
        )
        self.activity = nil
        message = "Ended."
    }
}
