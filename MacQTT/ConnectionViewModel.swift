//
//  ConnectionViewModel.swift
//  MacQTT
//
//  Created by Łukasz Jasiński on 31/03/2026.
//

import Foundation
import Observation
import SwiftData
import CocoaMQTT

@Observable
class ConnectionViewModel {
    var topics: [TopicNode] = []
    var activeService: MQTTService?
    var connectedIDs: Set<PersistentIdentifier> = []
    private var services: [PersistentIdentifier: MQTTService] = [:]

    func connect(to connection: Connection) async {
        for (id, service) in services {
            service.disconnect()
            services.removeValue(forKey: id)
            connectedIDs.remove(id)
        }
        topics = []
        let connectionID = connection.persistentModelID
        let service = MQTTService(host: connection.host, port: UInt16(connection.port), login: connection.login, password: connection.password, useTLS: connection.useTLS)
        service.onConnectionStateChanged = { [weak self] isConnected in
            if isConnected {
                self?.connectedIDs.insert(connectionID)
            } else {
                self?.connectedIDs.remove(connectionID)
            }
        }
        activeService = service
        services[connectionID] = service
        service.connect()
        
        for await message in service.messageStream {
            handleMessage(message.payload, topic: message.topic)
        }
    }
    
    func publish(topic: String, payload: String, qos: Int, retained: Bool) {
        let mqttQos: CocoaMQTTQoS
        switch qos {
        case 1: mqttQos = .qos1
        case 2: mqttQos = .qos2
        default: mqttQos = .qos0
        }
        activeService?.publish(topic: topic, payload: payload, qos: mqttQos, retained: retained)
    }

    func clearHistory(path: String) {
        clearInTree(path: path, nodes: &topics)
    }

    private func clearInTree(path: String, nodes: inout [TopicNode]) {
        for i in nodes.indices {
            if nodes[i].path == path {
                nodes[i].history = []
                return
            }
            clearInTree(path: path, nodes: &nodes[i].children)
        }
    }

    func disconnect(connection: Connection) {
        let id = connection.persistentModelID
        services[id]?.disconnect()
        services.removeValue(forKey: id)
        connectedIDs.remove(id)
        topics = []
    }

    @MainActor
    private func handleMessage(_ paylad: String, topic: String) {
        let parts = topic.split(separator: "/").map(String.init)
        insertIntoTree(parts: parts, paylad: paylad, nodes: &topics)
    }
    
    private func insertIntoTree(parts: [String], paylad: String, nodes: inout [TopicNode], parentPath: String = "") {
        guard let first = parts.first else { return }
        let rest = Array(parts.dropFirst())
        let currentPath = parentPath.isEmpty ? first : "\(parentPath)/\(first)"

        if let index = nodes.firstIndex(where: { $0.name == first }) {
            nodes[index].path = currentPath
            if rest.isEmpty {
                nodes[index].history.append(MessageEntry(value: paylad, timestamp: Date()))
                let limit = UserDefaults.standard.integer(forKey: "historyLimit")
                let cap = limit > 0 ? limit : 500
                if nodes[index].history.count > cap {
                    nodes[index].history.removeFirst()
                }
            } else {
                insertIntoTree(parts: rest, paylad: paylad, nodes: &nodes[index].children, parentPath: currentPath)
            }
        } else {
            var newNode = TopicNode(name: first, path: currentPath)
            if rest.isEmpty {
                newNode.history.append(MessageEntry(value: paylad, timestamp: Date()))
            } else {
                insertIntoTree(parts: rest, paylad: paylad, nodes: &newNode.children, parentPath: currentPath)
            }
            nodes.append(newNode)
        }
    }
    
}
