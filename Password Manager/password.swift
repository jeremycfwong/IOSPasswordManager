//
//  password.swift
//  Password Manager
//
//  Created by Jeremy Wong on 11/8/2021.
//

import Foundation

// Creating a new class to store passwords
class SavedPassword: Codable{
    var source: String
    var date: Date
    var password: String
    
    // Making it a requriement to provide source, date and password to create a SavedPassword class entry
    init(source: String, date: Date, password: String) {
        self.source = source
        self.date = date
        self.password = password
    }
}

