//
//  ConnectionEditView.swift
//  MacQTT
//
//  Created by Łukasz Jasiński on 31/03/2026.
//

import SwiftUI

struct ConnectionEditView: View {
    @Environment(\.dismiss) private var dismiss
    var connection: Connection

    @State private var name: String
    @State private var host: String
    @State private var port: String
    @State private var login: String
    @State private var password: String
    @State private var useTLS: Bool
    @State private var timeout: String

    init(connection: Connection) {
        self.connection = connection
        _name = State(initialValue: connection.name)
        _host = State(initialValue: connection.host)
        _port = State(initialValue: String(connection.port))
        _login = State(initialValue: connection.login)
        _password = State(initialValue: connection.password)
        _useTLS = State(initialValue: connection.useTLS)
        _timeout = State(initialValue: String(connection.timeout))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("General") {
                    TextField("Name", text: $name)
                    TextField("Host", text: $host)
                    TextField("Port", text: $port)
                }
                Section("Authorization") {
                    TextField("Login", text: $login)
                    SecureField("Password", text: $password)
                }
                Section("Options") {
                    Toggle("Use TLS", isOn: $useTLS)
                    TextField("Timeout (s)", text: $timeout)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Edit connection")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
        }
        .frame(width: 580, height: 520)
    }

    private func save() {
        connection.name = name
        connection.host = host
        connection.port = Int(port) ?? connection.port
        connection.login = login
        connection.password = password
        connection.useTLS = useTLS
        connection.timeout = Int(timeout) ?? connection.timeout
        dismiss()
    }
}
