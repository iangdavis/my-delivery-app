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
            message = "Started. Waiting for Live Activity push token..."

            let origin = apiOrigin.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !origin.isEmpty else {
                LiveHive.register(activity)
                message = "Started. No API origin set. Use the Live Hive dashboard to send a test update after registration."
                return
            }

            Task {
                await registerFirstTokenThenStartDemo(activity: activity, publicKey: key, apiOrigin: origin)
            }
        } catch {
            message = error.localizedDescription
        }
    }

    private func registerFirstTokenThenStartDemo(
        activity: Activity<DeliveryAttributes>,
        publicKey: String,
        apiOrigin: String
    ) async {
        do {
            guard let tokenData = await firstPushToken(for: activity) else {
                await MainActor.run {
                    message = "Started. No Live Activity push token was produced."
                }
                return
            }

            let pushToken = tokenData.map { String(format: "%02x", $0) }.joined()
            await MainActor.run {
                message = "Started. Registering Live Activity token..."
            }

            try await registerWithLiveHive(
                activityId: activity.id,
                pushToken: pushToken,
                publicKey: publicKey
            )

            // Keep observing rotations after the first token has been registered.
            LiveHive.register(activity)

            await MainActor.run {
                message = "Started. Token registered. Scheduling server-driven updates..."
            }
            try await startDemo(activityId: activity.id, apiOrigin: apiOrigin)
        } catch {
            await MainActor.run {
                message = "Started. Setup failed: \(error.localizedDescription)"
            }
        }
    }

    private func firstPushToken(for activity: Activity<DeliveryAttributes>) async -> Data? {
        for await tokenData in activity.pushTokenUpdates {
            return tokenData
        }
        return nil
    }

    private func registerWithLiveHive(
        activityId: String,
        pushToken: String,
        publicKey: String
    ) async throws {
        struct RegisterBody: Codable {
            let activity_id: String
            let push_token: String
        }

        guard let url = URL(string: "https://www.livehive.dev/v1/activities/register") else {
            throw DemoError.invalidURL
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(publicKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(
            RegisterBody(activity_id: activityId, push_token: pushToken)
        )

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else {
            throw DemoError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            let bodyText = String(data: data, encoding: .utf8) ?? ""
            throw DemoError.httpStatus(http.statusCode, bodyText)
        }
    }

    private func startDemo(activityId: String, apiOrigin: String) async throws {
        struct StartBody: Codable {
            let activity_id: String
        }

        var base = apiOrigin
        if base.hasSuffix("/") { base.removeLast() }
        guard let url = URL(string: "\(base)/demo/start") else {
            throw DemoError.invalidURL
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(StartBody(activity_id: activityId))

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else {
            await MainActor.run {
                message = "Started. Server response received."
            }
            return
        }

        if http.statusCode == 202 {
            await MainActor.run {
                message = "Started. Server accepted demo start and will update/end the activity."
            }
        } else {
            let bodyText = String(data: data, encoding: .utf8) ?? ""
            throw DemoError.httpStatus(http.statusCode, bodyText)
        }
    }
}

private enum DemoError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpStatus(Int, String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL."
        case .invalidResponse:
            return "Invalid server response."
        case .httpStatus(let status, let body):
            if body.isEmpty {
                return "Server returned \(status)."
            }
            return "Server returned \(status): \(body)"
        }
    }
}
