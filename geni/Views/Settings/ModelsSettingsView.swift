//
//  ModelsSettingsView.swift
//  fullmoon
//
//  Created by Jordan Singer on 10/5/24.
//

import SwiftUI
import OpenAI

struct ModelsSettingsView: View {
    @EnvironmentObject var appManager: AppManager
    @Environment(AssistantManager.self) var assistant
    
    let availableModels: [Model] = [.gpt4_o, .gpt4_o_mini]
    @State private var selectedModel: Model = .gpt4_o_mini
    
    var body: some View {
        Form {
            Section(header: Text("Model Selection")) {
                Picker("Model", selection: $selectedModel) {
                    ForEach(availableModels, id: \.self) { model in
                        Text(model == .gpt4_o ? "4o" : "4o-mini")
                            .tag(model)
                    }
                }
                .onChange(of: selectedModel) { _, newValue in
                    appManager.currentModelName = newValue == .gpt4_o ? "4o" : "4o-mini"
                    appManager.addInstalledModel(appManager.currentModelName ?? "4o")
                    assistant.updateModel(newValue)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Configuration")
        .onAppear {
            if let currentModel = appManager.currentModelName {
                selectedModel = currentModel == "4o" ? .gpt4_o : .gpt4_o_mini
            }
        }
    }
}

#Preview {
    ModelsSettingsView()
        .environmentObject(AppManager())
        .environment(AssistantManager(client: OpenAIClient(apiKey: "")))
}
