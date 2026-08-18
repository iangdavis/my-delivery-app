import ActivityKit
import Foundation

struct DeliveryAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var status: String
        var eta: Int
    }
}
