//
//  livehiveApp.swift
//  livehive
//
//  Created by user268424 on 8/17/26.
//

import Foundation
import SwiftUI
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { byte in String(format: "%02.2hhx", byte) }.joined()
        print("APNs device token:", token)
        UserDefaults.standard.set(token, forKey: "apns.deviceToken")
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications:", error)
    }
}

@main
struct livehiveApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
