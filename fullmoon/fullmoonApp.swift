//
//  fullmoonApp.swift
//  fullmoon
//
//  Created by Jordan Singer on 10/4/24.
//

import SwiftUI

@main
struct fullmoonApp: App {
    @StateObject var appManager = AppManager()
    @State var assistant: AssistantManager?
    @State var llm = LLMEvaluator()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: [Thread.self, Message.self])
                .environmentObject(appManager)
                .environment(llm)
                .environment(assistant ?? AssistantManager(client: appManager.openAIClient))
                .task {
                    assistant = AssistantManager(client: appManager.openAIClient)
                }
                .environment(DeviceStat())
        }
    }
}
