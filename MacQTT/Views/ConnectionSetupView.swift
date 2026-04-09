//
//  ConnectionSetupView.swift
//  MacQTT
//
//  Created by Łukasz Jasiński on 31/03/2026.
//

import SwiftUI
import SwiftData

struct ConnectionSetupView: View {
    @Binding var isPresented: Bool
    @Environment(\.modelContext) private var modelContext
    
    @State private var name: String = ""
    @State private var host: String = ""
    @State private var port: String = "8883"
    @State private var login: String = ""
    @State private var password: String = ""
    @State private var useTLS: Bool = true
    @State private var timeout: String = "60"
    
    var body: some View {
        NavigationStack {
            // frame musi być na NavigationStack, nie na Form — inaczej dotyczy tylko treści, nie okna
            Form {
                Section("General"){
                    TextField("Name", text: $name)
                    TextField("Host", text: $host)
                    TextField("Port", text: $port)
                }
                
                Section("Authorization"){
                    TextField("Login", text: $login)
                    SecureField("Password", text: $password)
                }
                
                Section("Options"){
                    Toggle("Use TLS", isOn: $useTLS)
                    TextField("Timeout (s)", text: $timeout)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("New connection")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
        }
        .frame(width: 560, height: 520)
    }

    private func save(){
    let connection = Connection(name: name, login: login, password: password, host: host, port: Int(port) ?? 1883, useTLS: useTLS, timeout: Int(timeout) ?? 60)
    modelContext.insert(connection)
    isPresented = false
    }
}
