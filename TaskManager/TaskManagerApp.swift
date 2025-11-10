//
//  TaskManagerApp.swift
//  TaskManager
//
//  Created by Maty Pierník on 10.11.2025.
//

import SwiftUI
import AppKit

@main
struct TaskManagerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Also ensure activation on appear (defensive).
                    NSApp.activate(ignoringOtherApps: true)
                }
        }
    }
    init() {
        // Activate the app early so accessibility elements are available for UI automation.
        // Doing this in init ensures it runs as soon as the app starts.
        NSApp.activate(ignoringOtherApps: true)
    }
}
