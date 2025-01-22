//
//  SettingsView.swift
//  fullmoon
//
//  Created by Jordan Singer on 10/4/24.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appManager: AppManager
    @Environment(\.dismiss) var dismiss
    @Binding var currentThread: Thread?
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("OpenAI API Key", text: $appManager.openAIApiKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("API Configuration")
                } footer: {
                    Text("Your OpenAI API key is stored securely in the keychain")
                }

                Section {
                    NavigationLink(destination: AppearanceSettingsView()) {
                        Label("appearance", systemImage: "paintpalette")
                    }
                    
                    NavigationLink(destination: ChatsSettingsView(currentThread: $currentThread)) {
                        Label("chats", systemImage: "message")
                    }
                }
                
                Section {
                    NavigationLink(destination: CreditsView()) {
                        Text("credits")
                    }
                }
                
                Section {} footer: {
                    HStack {
                        Spacer()
                        VStack(spacing: 4) {
                            Image(systemName: appManager.getMoonPhaseIcon())
                                .foregroundStyle(.quaternary)
                            Text("v\(Bundle.main.releaseVersionNumber ?? "0").\(Bundle.main.buildVersionNumber ?? "0")")
                                .font(.footnote)
                                .foregroundStyle(.tertiary)
                            Image(.madeByMainframe)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .foregroundStyle(.tertiary)
                            #if os(macOS)
                                .frame(height: 16)
                                .padding(.top, 11)
                            #else
                                .frame(height: 18)
                                .padding(.top, 16)
                            #endif
                        }
                        Spacer()
                    }
                    .padding(.vertical)
                }
                
            }
            .formStyle(.grouped)
            .navigationTitle("settings")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS) || os(visionOS)
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                    }
                }
                #elseif os(macOS)
                ToolbarItem(placement: .destructiveAction) {
                    Button(action: { dismiss() }) {
                        Text("close")
                    }
                }
                #endif
            }
        }
        #if !os(visionOS)
        .tint(appManager.appTintColor.getColor())
        #endif
        .environment(\.dynamicTypeSize, appManager.appFontSize.getFontSize())
    }
}

extension Bundle {
    var releaseVersionNumber: String? {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }
    var buildVersionNumber: String? {
        return infoDictionary?["CFBundleVersion"] as? String
    }
}

#Preview {
    SettingsView(currentThread: .constant(nil))
        .environmentObject(AppManager())
}
