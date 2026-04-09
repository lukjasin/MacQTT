//
//  TopicNode.swift
//  MacQTT
//
//  Created by Łukasz Jasiński on 30/03/2026.
//
import Foundation

struct MessageEntry: Identifiable, Hashable {
    let id = UUID()
    let value: String
    let timestamp: Date
}

struct TopicNode: Identifiable, Hashable {
    var name: String
    var path: String = ""
    var id: String { path }
    var children: [TopicNode] = []
    var history: [MessageEntry] = []

    var lastMessage: String? { history.last?.value }
    var lastUpdated: Date? { history.last?.timestamp }

    var messageCount: Int { history.count }
    var subtopicCount: Int { children.count }
    var totalMessageCount: Int {
        history.count + children.reduce(0) { $0 + $1.totalMessageCount }
    }

    var optionalChildren: [TopicNode]? {
        children.isEmpty ? nil : children
    }
}
