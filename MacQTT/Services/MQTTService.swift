//
//  MQTTService.swift
//  MacQTT
//
//  Created by Łukasz Jasiński on 30/03/2026.
//

import Foundation
import CocoaMQTT

@MainActor
class MQTTService {

    private let client: CocoaMQTT
    private var continuation: AsyncStream<(topic: String, payload: String)>.Continuation?
    private var bridgeDelegate: BridgeDelegate?

    let messageStream: AsyncStream<(topic: String, payload: String)>
    var onConnectionStateChanged: ((Bool) -> Void)?

    init(host: String, port: UInt16, login: String = "", password: String = "", useTLS: Bool = false) {
        let clientID = "MacQTT-" + UUID().uuidString
        client = CocoaMQTT(clientID: clientID, host: host, port: port)

        if !login.isEmpty {
            client.username = login
            client.password = password
        }

        if useTLS {
            client.enableSSL = true
        }

        var tempContinuation: AsyncStream<(topic: String, payload: String)>.Continuation?
        messageStream = AsyncStream { continuation in
            tempContinuation = continuation
        }
        continuation = tempContinuation
    }

    func connect() {
        let del = BridgeDelegate(
            onConnected: { [weak self] in
                self?.client.subscribe("#")
                self?.client.subscribe("$SYS/#")
                self?.onConnectionStateChanged?(true)
            },
            onDisconnected: { [weak self] in
                self?.onConnectionStateChanged?(false)
            },
            onMessage: { [weak self] topic, payload in
                self?.receive(topic: topic, payload: payload)
            }
        )
        bridgeDelegate = del
        client.delegate = del
        _ = client.connect()
    }

    func publish(topic: String, payload: String, qos: CocoaMQTTQoS = .qos0, retained: Bool = false) {
        let message = CocoaMQTTMessage(topic: topic, payload: Array(payload.utf8), qos: qos, retained: retained)
        client.publish(message)
    }

    func disconnect() {
        client.disconnect()
        continuation?.finish()
    }

    private func receive(topic: String, payload: String) {
        continuation?.yield((topic: topic, payload: payload))
    }
}

@MainActor
private class BridgeDelegate: NSObject, CocoaMQTTDelegate {
    private let onConnected: () -> Void
    private let onDisconnected: () -> Void
    private let onMessage: (String, String) -> Void

    init(onConnected: @escaping () -> Void, onDisconnected: @escaping () -> Void, onMessage: @escaping (String, String) -> Void) {
        self.onConnected = onConnected
        self.onDisconnected = onDisconnected
        self.onMessage = onMessage
    }

    func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16) {
        onMessage(message.topic, message.string ?? "")
    }

    func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        if ack == .accept {
            onConnected()
        }
    }
    func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {}
    func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {}
    func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopics success: NSDictionary, failed: [String]) {}
    func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopics topics: [String]) {}
    func mqttDidPing(_ mqtt: CocoaMQTT) {}
    func mqttDidReceivePong(_ mqtt: CocoaMQTT) {}
    func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: (any Error)?) {
        onDisconnected()
    }
}
