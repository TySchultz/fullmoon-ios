//
//  GeniApp.swift
//  Geni
//
//  Created by Jordan Singer on 10/4/24.
//

import SwiftUI

@main
struct GeniApp: App {
    @StateObject var appManager = AppManager()
    @State var assistant: AssistantManager?

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: [Thread.self, Message.self])
                .environmentObject(appManager)
                .environment(assistant ?? AssistantManager(client: appManager.openAIClient))
                .task {
                    assistant = AssistantManager(client: appManager.openAIClient)
                }
        }
    }
}
