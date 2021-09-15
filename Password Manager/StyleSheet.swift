//
//  StyleSheet.swift
//  Password Manager
//
//  Created by Jeremy Wong on 12/8/2021.
//

import UIKit

// Creating a class called stylesheet to serve as a dedicated file for Navigation and Tool bar
class StyleSheet {
    static func customiseNavigationBar(for navigationController: UINavigationController?){
        guard let navigationBar = navigationController?.navigationBar else { return }
        
        navigationBar.barStyle = .black
        navigationBar.isTranslucent = true
        navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 20.0)]
        navigationBar.tintColor = .white
    }
    
    static func customiseToolBar (for navigationController: UINavigationController?){
        guard let toolbar = navigationController?.toolbar else { return }
        
        toolbar.barStyle = .black
        toolbar.isTranslucent = true
        toolbar.tintColor = .white
    }
}
