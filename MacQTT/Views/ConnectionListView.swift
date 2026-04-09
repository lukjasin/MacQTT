//
//  ConnectionListView.swift
//  MacQTT
//
//  Created by Łukasz Jasiński on 31/03/2026.
//

import SwiftUI
import SwiftData

struct ConnectionListView: View {
    @Query var connections: [Connection]
    @Binding var selectedConnection: Connection?
    let connectedIDs: Set<PersistentIdentifier>

    @Environment(\.modelContext) private var modelContext
    @State private var connectionToEdit: Connection?
    @State private var brokerInfoConnection: Connection?
    @State private var reconnectTarget: Connection?
    var viewModel: ConnectionViewModel
    var onConnect: (Connection) -> Void

    var body: some View {
        List(connections, id: \.id, selection: $selectedConnection) { connection in
            HStack {
                Circle()
                    .fill(connectedIDs.contains(connection.persistentModelID) ? Color.green : Color.secondary.opacity(0.4))
                    .frame(width: 8, height: 8)
                Text(connection.name.isEmpty ? "Unnamed" : connection.name)
                Spacer()
                let hasSys = connectedIDs.contains(connection.persistentModelID)
                    && viewModel.topics.contains(where: { $0.name == "$SYS" })
                Button(action: { brokerInfoConnection = connection }) {
                    Image(systemName: "info.circle")
                        .foregroundStyle(hasSys ? Color.primary : Color.secondary.opacity(0.25))
                }
                .buttonStyle(.plain)
                .disabled(!hasSys)
                Button(action: {
                    if connectedIDs.contains(connection.persistentModelID) {
                        reconnectTarget = connection
                    } else {
                        onConnect(connection)
                    }
                }) {
                    Image(systemName: connectedIDs.contains(connection.persistentModelID) ? "bolt.fill" : "bolt")
                        .foregroundStyle(connectedIDs.contains(connection.persistentModelID) ? Color.yellow : Color.secondary)
                }
                .buttonStyle(.plain)
            }
            .tag(connection)
            .contextMenu {
                Button("Edit") {
                    connectionToEdit = connection
                }
                if connectedIDs.contains(connection.persistentModelID) {
                    Button("Disconnect") {
                        viewModel.disconnect(connection: connection)
                    }
                }
                Divider()
                Button("Delete", role: .destructive) {
                    modelContext.delete(connection)
                }
            }
        }
        .listStyle(.sidebar)
        .overlay(alignment: .bottom) {
            Image("connection_watermark_bottom")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 400)
                .foregroundStyle(.secondary)
                .opacity(0.10)
                .offset(y: -15)
                .allowsHitTesting(false)
        }
        .clipped()
        .sheet(item: $connectionToEdit) { connection in
            ConnectionEditView(connection: connection)
        }
        .popover(item: $brokerInfoConnection) { _ in
            BrokerInfoPopover(topics: viewModel.topics)
        }
        .alert("Reconnect?", isPresented: Binding(
            get: { reconnectTarget != nil },
            set: { if !$0 { reconnectTarget = nil } }
        )) {
            Button("Reconnect", role: .destructive) {
                if let connection = reconnectTarget {
                    reconnectTarget = nil
                    onConnect(connection)
                }
            }
            Button("Cancel", role: .cancel) { reconnectTarget = nil }
        } message: {
            Text("This will drop the current connection and download all topics from scratch.")
        }
    }
}

struct BrokerInfoPopover: View {
    let topics: [TopicNode]

    private let keys: [(label: String, path: String)] = [
        ("Version",            "$SYS/broker/version"),
        ("Uptime",             "$SYS/broker/uptime"),
        ("Clients connected",  "$SYS/broker/clients/connected"),
        ("Clients total",      "$SYS/broker/clients/total"),
        ("Messages received",  "$SYS/broker/messages/received"),
        ("Messages sent",      "$SYS/broker/messages/sent"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Broker Info")
                .font(.headline)
                .padding(.bottom, 2)
            Divider()
            ForEach(keys, id: \.path) { item in
                if let value = findValue(path: item.path, in: topics) {
                    HStack(alignment: .top) {
                        Text(item.label)
                            .foregroundStyle(.secondary)
                            .frame(width: 160, alignment: .leading)
                        Text(value)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                    }
                }
            }
        }
        .padding()
        .frame(minWidth: 320)
    }

    private func findValue(path: String, in nodes: [TopicNode]) -> String? {
        for node in nodes {
            if node.path == path { return node.lastMessage }
            if let found = findValue(path: path, in: node.children) { return found }
        }
        return nil
    }
}
