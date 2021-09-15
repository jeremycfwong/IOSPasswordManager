//
//  DataStore.swift
//  Password Manager
//
//  Created by Jeremy Wong on 11/8/2021.
//

import Foundation

// File in charge of the storage and retrieval of password data
class DataStore{
    static let passwordKey = "password"
    
    // background loading
    static func load () -> [SavedPassword] {
        let defaults = UserDefaults.standard
        var password = [SavedPassword]()
        
        if let savedData = defaults.object(forKey: passwordKey) as? Data {
            let jsonDecoder = JSONDecoder()
            password = (try? jsonDecoder.decode([SavedPassword].self, from: savedData)) ?? password
        }
        
        return password
    }
    
    static func save(password: [SavedPassword]){
        let jsonEncoder = JSONEncoder()
        
        if let savedData = try? jsonEncoder.encode(password) {
            let defaults = UserDefaults.standard
            defaults.set(savedData, forKey: passwordKey)
        }
    }
}
