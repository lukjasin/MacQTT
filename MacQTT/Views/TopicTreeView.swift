//
//  TopicTreeView.swift
//  MacQTT
//
//  Created by Łukasz Jasiński on 31/03/2026.
//

import SwiftUI
import Combine

// Jeden timer dla całego pliku — wszystkie wiersze go współdzielą
private let highlightTimer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

struct TopicTreeView: View {
    let topics: [TopicNode]
    @Binding var selectedTopicPath: String?
    @AppStorage("showMessagesInTree") var showMessagesInTree: Bool = true
    @AppStorage("highlightOnUpdate") var highlightOnUpdate: Bool = true
    @AppStorage("showCountBadges") var showCountBadges: Bool = true
    @AppStorage("searchHistory") private var searchHistoryData: String = "[]"
    @AppStorage("keyboardNavigationEnabled") var keyboardNavigationEnabled: Bool = true
    @AppStorage("cmdCCopiesValue") var cmdCCopiesValue: Bool = true
    @AppStorage("filterCaseSensitive") var filterCaseSensitive: Bool = false
    @State private var searchText: String = ""
    @State private var expandedPaths: Set<String> = []
    @FocusState private var searchFocused: Bool

    var searchHistory: [String] {
        (try? JSONDecoder().decode([String].self, from: Data(searchHistoryData.utf8))) ?? []
    }

    var filteredTopics: [TopicNode] {
        guard !searchText.isEmpty else { return topics }
        return filterNodes(topics, query: searchText)
    }

    // Spłaszcza drzewo do listy widocznych wierszy według stanu expandedPaths.
    // Węzeł trafia na listę zawsze; jego dzieci — tylko gdy jest rozwinięty.
    var flatItems: [(node: TopicNode, depth: Int)] {
        flattenItems(filteredTopics, depth: 0)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: expandSelected) {
                    Image(systemName: "chevron.down.2")
                }
                .buttonStyle(.plain)
                .disabled(selectedTopicPath == nil)
                .help("Expand subtree from selected topic")

                Button(action: collapseSelected) {
                    Image(systemName: "chevron.up.2")
                }
                .buttonStyle(.plain)
                .disabled(selectedTopicPath == nil)
                .help("Collapse subtree from selected topic")

                TextField("Filter topics...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .focused($searchFocused)
                    .onSubmit { saveToHistory(searchText) }
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                if !searchHistory.isEmpty {
                    Menu {
                        ForEach(searchHistory, id: \.self) { item in
                            Button(item) { searchText = item }
                        }
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundStyle(.secondary)
                    }
                    .menuStyle(.borderlessButton)
                    .fixedSize()
                }
                Button(action: { Exporter.exportTree(topics) }) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(topics.isEmpty ? Color.secondary.opacity(0.3) : Color.secondary)
                }
                .buttonStyle(.plain)
                .disabled(topics.isEmpty)
                .help("Export topic snapshot to CSV")
            }
            .padding(8)

            List(selection: $selectedTopicPath) {
                ForEach(flatItems, id: \.node.path) { item in
                    FlatTopicRow(
                        node: item.node,
                        depth: item.depth,
                        isExpanded: expandedPaths.contains(item.node.path),
                        hasChildren: !item.node.children.isEmpty,
                        showMessagesInTree: showMessagesInTree,
                        highlightOnUpdate: highlightOnUpdate,
                        showCountBadges: showCountBadges,
                        expandedPaths: $expandedPaths,
                        onSelect: { selectedTopicPath = item.node.path },
                        onToggle: { toggle(item.node) }
                    )
                }
            }
            .listStyle(.sidebar)
            .environment(\.defaultMinListRowHeight, 18)
            .onReceive(NotificationCenter.default.publisher(for: .exportTree)) { _ in
                guard !topics.isEmpty else { return }
                Exporter.exportTree(topics)
            }
            .onKeyPress(phases: .down) { press in
                guard keyboardNavigationEnabled else { return .ignored }
                switch press.key {
                case .rightArrow:  return handleRightArrow()
                case .leftArrow:   return handleLeftArrow()
                default:
                    if press.key == KeyEquivalent("f") && press.modifiers == .command {
                        searchFocused = true
                        return .handled
                    }
                    if press.key == KeyEquivalent("c") && press.modifiers == .command {
                        return handleCmdC()
                    }
                    return .ignored
                }
            }
        }
    }

    // MARK: - Przyciski paska

    private func expandSelected() {
        guard let path = selectedTopicPath,
              let node = findNode(path: path, in: topics) else { return }
        expandedPaths.formUnion(allExpandablePaths(of: node))
    }

    private func collapseSelected() {
        guard let path = selectedTopicPath,
              let node = findNode(path: path, in: topics) else { return }
        expandedPaths.subtract(allExpandablePaths(of: node))
    }

    private func toggle(_ node: TopicNode) {
        if expandedPaths.contains(node.path) {
            expandedPaths.remove(node.path)
        } else {
            expandedPaths.insert(node.path)
        }
    }

    // MARK: - Pomocnicze

    private func flattenItems(_ nodes: [TopicNode], depth: Int) -> [(node: TopicNode, depth: Int)] {
        nodes.flatMap { node -> [(TopicNode, Int)] in
            var result: [(TopicNode, Int)] = [(node, depth)]
            if expandedPaths.contains(node.path) {
                result += flattenItems(node.children, depth: depth + 1)
            }
            return result
        }
    }

    private func findNode(path: String, in nodes: [TopicNode]) -> TopicNode? {
        for node in nodes {
            if node.path == path { return node }
            if let found = findNode(path: path, in: node.children) { return found }
        }
        return nil
    }

    private func filterNodes(_ nodes: [TopicNode], query: String) -> [TopicNode] {
        let patterns = query
            .components(separatedBy: CharacterSet(charactersIn: " ,"))
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        return nodes.compactMap { node in
            let matchesSelf = patterns.contains { pattern in matches(path: node.path, pattern: pattern) }
            let filteredChildren = filterNodes(node.children, query: query)
            if matchesSelf || !filteredChildren.isEmpty {
                var result = node
                result.children = filteredChildren
                return result
            }
            return nil
        }
    }

    private func saveToHistory(_ query: String) {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        var history = searchHistory
        history.removeAll { $0 == query }
        history.insert(query, at: 0)
        if history.count > 10 { history = Array(history.prefix(10)) }
        if let data = try? JSONEncoder().encode(history) {
            searchHistoryData = String(data: data, encoding: .utf8) ?? "[]"
        }
    }

    // MARK: - Obsługa klawiatury

    @discardableResult
    private func handleRightArrow() -> KeyPress.Result {
        guard let path = selectedTopicPath,
              let node = findNode(path: path, in: filteredTopics) else { return .ignored }
        guard !node.children.isEmpty else { return .ignored }
        if !expandedPaths.contains(path) {
            // węzeł zwinięty → rozwiń
            expandedPaths.insert(path)
        } else {
            // węzeł rozwinięty → przejdź do pierwszego dziecka
            selectedTopicPath = node.children.first?.path
        }
        return .handled
    }

    @discardableResult
    private func handleLeftArrow() -> KeyPress.Result {
        guard let path = selectedTopicPath else { return .ignored }
        if expandedPaths.contains(path) {
            // węzeł rozwinięty → zwiń go
            expandedPaths.remove(path)
            return .handled
        }
        // węzeł zwinięty lub liść → przejdź do rodzica
        if let parent = findParent(of: path, in: filteredTopics) {
            selectedTopicPath = parent.path
            return .handled
        }
        return .ignored
    }

    @discardableResult
    private func handleCmdC() -> KeyPress.Result {
        guard let path = selectedTopicPath,
              let node = findNode(path: path, in: filteredTopics) else { return .ignored }
        let text: String
        if cmdCCopiesValue, let value = node.lastMessage {
            text = value
        } else {
            text = path
        }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        return .handled
    }

    private func findParent(of childPath: String, in nodes: [TopicNode]) -> TopicNode? {
        for node in nodes {
            if node.children.contains(where: { $0.path == childPath }) { return node }
            if let found = findParent(of: childPath, in: node.children) { return found }
        }
        return nil
    }

    private func matches(path: String, pattern: String) -> Bool {
        if filterCaseSensitive {
            if let regex = try? Regex(pattern) {
                return (try? regex.firstMatch(in: path)) != nil
            }
            return path.contains(pattern)
        } else {
            if let regex = try? Regex(pattern).ignoresCase() {
                return (try? regex.firstMatch(in: path)) != nil
            }
            return path.localizedCaseInsensitiveContains(pattern)
        }
    }
}

// MARK: - FlatTopicRow

private struct FlatTopicRow: View {
    let node: TopicNode
    let depth: Int
    let isExpanded: Bool
    let hasChildren: Bool
    let showMessagesInTree: Bool
    let highlightOnUpdate: Bool
    let showCountBadges: Bool
    @Binding var expandedPaths: Set<String>
    let onSelect: () -> Void
    let onToggle: () -> Void

    @State private var now: Date = .now

    var body: some View {
        HStack(spacing: 0) {
            // Wcięcie odpowiadające głębokości w drzewie
            if depth > 0 {
                Spacer().frame(width: CGFloat(depth) * 16)
            }

            // Trójkąt rozwijania (lub pusty slot dla wyrównania u liści)
            if hasChildren {
                Button(action: onToggle) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 16, height: 16)
                }
                .buttonStyle(.plain)
            } else {
                Spacer().frame(width: 16)
            }

            Spacer().frame(width: 4)

            Text(node.name)

            if showCountBadges {
                if node.subtopicCount > 0 {
                    badge("\(node.subtopicCount)", color: .secondary)
                }
                if node.totalMessageCount > 0 {
                    badge("\(node.totalMessageCount)", color: .accentColor)
                }
            }
            if showMessagesInTree, let message = node.lastMessage {
                Text(message)
                    .foregroundStyle(.secondary)
                    .font(.system(.body, design: .monospaced))
                    .padding(.leading, 4)
            }
        }
        .tag(node.path)
        .contentShape(Rectangle())
        .onTapGesture(count: 1) { onSelect() }
        .simultaneousGesture(TapGesture(count: 2).onEnded { if hasChildren { onToggle() } })
        .listRowInsets(EdgeInsets(top: 1, leading: 6, bottom: 1, trailing: 8))
        .listRowBackground(Color.accentColor.opacity(highlightOpacity))
        .onReceive(highlightTimer) { date in
            guard let lastUpdate = node.lastUpdated,
                  date.timeIntervalSince(lastUpdate) < 1.0 else { return }
            now = date
        }
        .contextMenu {
            if hasChildren {
                Button("Expand subtree") {
                    expandedPaths.formUnion(allExpandablePaths(of: node))
                }
                Button("Collapse subtree") {
                    expandedPaths.subtract(allExpandablePaths(of: node))
                }
                Divider()
            }
            Button("Copy topic path") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(node.path, forType: .string)
            }
            if let message = node.lastMessage {
                Button("Copy value") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(message, forType: .string)
                }
            }
        }
    }

    private var highlightOpacity: Double {
        guard highlightOnUpdate else { return 0 }
        guard let date = node.lastUpdated else { return 0 }
        let elapsed = now.timeIntervalSince(date)
        let fadeIn = 0.15
        let total = 0.9
        guard elapsed >= 0, elapsed < total else { return 0 }
        if elapsed < fadeIn {
            return 0.35 * (elapsed / fadeIn)
        } else {
            return 0.35 * (1.0 - (elapsed - fadeIn) / (total - fadeIn))
        }
    }

    private func badge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2)
            .foregroundStyle(color)
            .padding(.horizontal, 4)
            .padding(.vertical, 1)
            .background(color.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

// Zwraca ścieżki wszystkich węzłów z dziećmi w danym poddrzewie
private func allExpandablePaths(of node: TopicNode) -> Set<String> {
    guard !node.children.isEmpty else { return [] }
    var result: Set<String> = [node.path]
    for child in node.children {
        result.formUnion(allExpandablePaths(of: child))
    }
    return result
}
