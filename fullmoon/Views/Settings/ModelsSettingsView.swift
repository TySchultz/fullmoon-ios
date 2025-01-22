//
//  ModelsSettingsView.swift
//  fullmoon
//
//  Created by Jordan Singer on 10/5/24.
//

import SwiftUI

struct ModelsSettingsView: View {
    @EnvironmentObject var appManager: AppManager
    @Environment(AssistantManager.self) var assistant
    
    var body: some View {
        Form {
            Section(header: Text("OpenAI Configuration")) {
                SecureField("API Key", text: $appManager.openAIApiKey)
                TextField("Assistant ID", text: $appManager.openAIAssistantId)
                
                if appManager.openAIApiKey.isEmpty {
                    Text("Get your API key from OpenAI")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Configuration")
    }
}

#Preview {
    ModelsSettingsView()
        .environmentObject(AppManager())
        .environment(AssistantManager(client: OpenAIClient(apiKey: "")))
}
