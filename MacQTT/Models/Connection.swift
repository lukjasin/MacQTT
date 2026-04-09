//
//  Connection.swift
//  MacQTT
//
//  Created by Łukasz Jasiński on 30/03/2026.
//

import Foundation
import SwiftData

@Model
class Connection {
    var name: String
    var login: String
    var password: String
    var host: String
    var port: Int
    var useTLS: Bool
    var timeout: Int
    
    init(name: String = "", login: String = "", password: String = "", host: String = "", port: Int = 1883, useTLS: Bool = false, timeout: Int = 60) {
        self.name = name
        self.login = login
        self.password = password
        self.host = host
        self.port = port
        self.useTLS = useTLS
        self.timeout = timeout
    }
}
