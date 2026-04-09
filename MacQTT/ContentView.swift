//
//  ContentView.swift
//  MacQTT
//
//  Created by Łukasz Jasiński on 30/03/2026.
//
import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedConnection: Connection?
    @State private var showingNewConnection = false
    @State private var selectedTopicPath: String?
    @State private var viewModel = ConnectionViewModel()
    @State private var pausedAt: Date? = nil
    @State private var showBrokerInfo = false
    @State private var cmdKReconnectTarget: Connection? = nil
    @State private var showNewBrokerAlert = false

    var body: some View {
        NavigationSplitView {
            ConnectionListView(
                selectedConnection: $selectedConnection,
                connectedIDs: viewModel.connectedIDs,
                viewModel: viewModel,
                onConnect: { connection in
                    Task { await viewModel.connect(to: connection) }
                }
            )
                .navigationSplitViewColumnWidth(min: 160, ideal: 200, max: 260)
                .toolbar {
                    ToolbarItem {
                        Button(action: { showingNewConnection = true }) {
                            Label("Add Connection", systemImage: "plus")
                        }
                    }
                }
        } content: {
            if viewModel.topics.isEmpty {
                Text("Select a connection")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                TopicTreeView(
                    topics: viewModel.topics,
                    selectedTopicPath: $selectedTopicPath
                )
            }
        } detail: {
            Group {
                if let path = selectedTopicPath,
                   let node = findNode(path: path, in: viewModel.topics) {
                    MessageDetailView(
                        topic: node.path,
                        history: node.history,
                        pausedAt: $pausedAt,
                        onPublish: { topic, payload, qos, retained in
                            viewModel.publish(topic: topic, payload: payload, qos: qos, retained: retained)
                        },
                        onClearHistory: {
                            viewModel.clearHistory(path: node.path)
                        }
                    )
                } else {
                    Text("Select a topic")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationSplitViewColumnWidth(min: 280, ideal: 350, max: 500)
        }
        .navigationSplitViewStyle(.balanced)
        .sheet(isPresented: $showingNewConnection) {
            ConnectionSetupView(isPresented: $showingNewConnection)
        }
        .onReceive(NotificationCenter.default.publisher(for: .showNewConnection)) { _ in
            showingNewConnection = true
        }
        .sheet(isPresented: $showBrokerInfo) {
            BrokerInfoPopover(topics: viewModel.topics)
        }
        .alert("Reconnect?", isPresented: Binding(
            get: { cmdKReconnectTarget != nil },
            set: { if !$0 { cmdKReconnectTarget = nil } }
        )) {
            Button("Reconnect", role: .destructive) {
                if let connection = cmdKReconnectTarget {
                    cmdKReconnectTarget = nil
                    Task { await viewModel.connect(to: connection) }
                }
            }
            Button("Cancel", role: .cancel) { cmdKReconnectTarget = nil }
        } message: {
            Text("This will drop the current connection and download all topics from scratch.")
        }
        .alert("Switch broker?", isPresented: $showNewBrokerAlert) {
            Button("Connect", role: .destructive) {
                if let connection = selectedConnection {
                    Task { await viewModel.connect(to: connection) }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Connecting to \"\(selectedConnection?.name ?? "")\" requires disconnecting from the current broker.")
        }
        .background {
            Group {
                // Cmd+K
                Button("") {
                    guard let connection = selectedConnection else { return }
                    if viewModel.connectedIDs.isEmpty {
                        Task { await viewModel.connect(to: connection) }
                    } else if viewModel.connectedIDs.contains(connection.persistentModelID) {
                        cmdKReconnectTarget = connection
                    } else {
                        showNewBrokerAlert = true
                    }
                }
                .keyboardShortcut("k", modifiers: .command)
                // Cmd+I
                Button("") {
                    guard !viewModel.connectedIDs.isEmpty else { return }
                    showBrokerInfo = true
                }
                .keyboardShortcut("i", modifiers: .command)
            }
            .hidden()
        }
    }
    
    private func findNode(path: String, in nodes: [TopicNode]) -> TopicNode? {
        for node in nodes {
            if node.path == path {
                return node
            }
            if let found = findNode(path: path, in: node.children) {
                return found
            }
        }
        return nil
    }
}
