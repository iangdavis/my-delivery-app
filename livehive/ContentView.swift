import ActivityKit
import SwiftUI
import LiveHive

struct ContentView: View {
    @AppStorage("livehive.publicKey") private var publicKey = ""
    @AppStorage("mydelivery.apiOrigin") private var apiOrigin = "https://live-activities.onrender.com"
    @AppStorage("apns.deviceToken") private var apnsToken = ""

    @State private var activity: Activity<DeliveryAttributes>?
    @State private var message = "Start a Live Activity, then lock the phone."

    var body: some View {
        VStack(spacing: 12) {
            Text(message)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let id = activity?.id {
                Text(id)
                    .font(.system(.footnote, design: .monospaced))
                    .textSelection(.enabled)
            }

            if !apnsToken.isEmpty {
                Text("APNs token: ...\(apnsToken.suffix(6))")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }

            // Configuration fields for app & demo API origin
            TextField("lh_pub_...", text: $publicKey)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(.system(.body, design: .monospaced))
                .padding(.horizontal)
                .disableAutocorrection(true)

            TextField("My Delivery API origin (https://host)", text: $apiOrigin)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(.system(.body, design: .monospaced))
                .padding(.horizontal)
                .disableAutocorrection(true)

            Button("Start") { start() }
                .disabled(publicKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding()
        .buttonStyle(.borderedProminent)
    }

    private func start() {
        let key = publicKey.trimmingCharacters(in: .whitespacesAndNewlines)
        LiveHive.configure(publicKey: key)

        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            message = "Enable Live Activities in Settings."
            return
        }

        do {
            let activity = try Activity.request(
                attributes: DeliveryAttributes(),
                content: .init(state: .init(status: "preparing", eta: 12), staleDate: nil),
                pushType: .token
            )
            self.activity = activity
            LiveHive.register(activity)
            message = "Started. Scheduling server-driven updates..."

            let origin = apiOrigin.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !origin.isEmpty else {
                message = "Started. No API origin set. Use the Live Hive dashboard to send a test update."
                return
            }

            var base = origin
            if base.hasSuffix("/") { base.removeLast() }
            guard let url = URL(string: "\(base)/demo/start") else {
                message = "Started. Invalid API origin"
                return
            }

            struct StartBody: Codable { let activity_id: String }

            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")

            do {
                req.httpBody = try JSONEncoder().encode(StartBody(activity_id: activity.id))
            } catch {
                message = "Started. Failed to build request body: \(error.localizedDescription)"
                return
            }

            Task {
                do {
                    let (data, resp) = try await URLSession.shared.data(for: req)
                    if let http = resp as? HTTPURLResponse {
                        if http.statusCode == 202 {
                            message = "Started. Server accepted demo start and will update/end the activity."
                        } else {
                            let bodyText = String(data: data, encoding: .utf8) ?? ""
                            message = "Started. Server returned \(http.statusCode): \(bodyText)"
                        }
                    } else {
                        message = "Started. Server response received."
                    }
                } catch {
                    message = "Started. Failed to contact server: \(error.localizedDescription)"
                }
            }
        } catch {
            message = error.localizedDescription
        }
    }
}
