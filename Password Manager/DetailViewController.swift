//
//  DetailViewController.swift
//  Password Manager
//
//  Created by Jeremy Wong on 11/8/2021.
//

import Foundation
import UIKit

// Making a protocol that allow the detialviewcontroller to notify viewcontroller of changes in the password
protocol EditorDelegate {
    func editor(_ editor:DetailViewController, didUpdate password: [SavedPassword])
}

class DetailViewController: UITableViewController {
    // MARK: - Declaring Variables
    var password: [SavedPassword]!
    var infoIndex: Int!
    var delegate: EditorDelegate?
    let account = "account", passwordRow = "passwordData"
    let sectionTitles: [String]
    
    // Button items
    var editButton: UIBarButtonItem!
    var doneButton: UIBarButtonItem!
    var deleteButton: UIBarButtonItem!
    var newButton: UIBarButtonItem!
    var space: UIBarButtonItem!
    
    // Dividng the cells into different section for customisation
    required init?(coder aDecoder: NSCoder) {
        sectionTitles = [account, passwordRow]
        super.init(coder: aDecoder)
    }
    
    // MARK: - Loading View
    override func viewDidLoad() {
        super.viewDidLoad()
        // Ensure the view is successfully loaded with parameters set
        guard isParametersSet() else{
            print("Error")
            navigationController?.popViewController(animated: true)
            return
        }
        
        // Customising the view, toolbar and navigation items
        view.backgroundColor = UIColor.darkGray
        editButton = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(editMode))
        doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(finishEditMode))
        deleteButton = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(deleteTapped))
        newButton = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(newTapped))
        space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        navigationItem.rightBarButtonItems = [space, editButton]
        toolbarItems = [space,deleteButton,space,newButton]
        navigationController?.toolbar.isHidden = false
    }
    
    // Function called by the other viewController to import variables
    func setParameters (password: [SavedPassword], infoIndex: Int){
        self.password = password
        self.infoIndex = infoIndex
    }
    
    // Function to check if passowrd and the index exist in the current view
    func isParametersSet() -> Bool {
            return password != nil && infoIndex != nil
    }
    
    //MARK: - Function for altering Data Cells
    // Function that makes the cell editable and change the UI bar
    @objc func editMode(){
        navigationItem.rightBarButtonItems = [space, doneButton]
        
        for cellRow in 0...sectionTitles.count{
            let indexPath = NSIndexPath(row: cellRow, section: 0)
            let cell = tableView.cellForRow(at: indexPath as IndexPath)
            
            if let cell = cell as? DataCell {
                    cell.dataInput.isUserInteractionEnabled = true
            }
        }
    }
    
    // Function that revert the editing mode setting and trigger save
    @objc func finishEditMode(){
        navigationItem.rightBarButtonItems = [space, editButton]
        saveData()
    }
    
    // Function that save the data into the password array
    func saveData(newEntry: Bool = false){
        // A loop through each section of the detailview to retrieve account name and account password
        for cellRow in 0...sectionTitles.count - 1{
            let indexPath = NSIndexPath(row: cellRow, section: 0)
            let cell = tableView.cellForRow(at: indexPath as IndexPath)
            
            // Make cell uneditable
            if let cell = cell as? DataCell {
                cell.dataInput.isUserInteractionEnabled = false
                cell.dataInput.endEditing(true)
                
                // Renew the data with its respective counterparts
                if cell.dataInput.text != nil || newEntry{
                    switch cell.dataInput.tag {
                    case 0:
                        password[infoIndex].source = cell.dataInput.text!
                    case 1:
                        password[infoIndex].password = cell.dataInput.text!
                    default:
                        print("Error: Item Does not Exist")
                    }
                }
            }
        }
        // Since edit date is the now, it will be set outside of the loop
        password[infoIndex].date = Date()
    
        DispatchQueue.global().async { [weak self] in
            if let password = self?.password{
                DataStore.save(password: password)
            }
        }
    }
    
    // Function allow automatic switch from edit mode if user quit the view
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)        
        finishEditMode()
    }
    
    // MARK: - Table Cells Customisation
    
    // Reserve cell row for 2 sections designed for this view
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sectionTitles.count
    }
    
    // Customisation of rows in the table
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch sectionTitles[indexPath.row] {
        case account:
            let cell = tableView.dequeueReusableCell(withIdentifier: "text", for: indexPath)
            if let cell = cell as? DataCell {
                cell.nameLabel.text = "Account:"
                cell.dataInput.text = password[infoIndex].source
                cell.dataInput.isUserInteractionEnabled = false
                cell.dataInput.autocorrectionType = .no
                cell.dataInput.tag = 0
                return cell
            }
            
        case passwordRow:
            let cell = tableView.dequeueReusableCell(withIdentifier: "text", for: indexPath)
            if let cell = cell as? DataCell {
            cell.nameLabel.text = "Password:"
            cell.dataInput.text = password[infoIndex].password
            cell.dataInput.isUserInteractionEnabled = false
            cell.dataInput.autocorrectionType = .no
            cell.dataInput.tag = 1
            return cell
            }
            
        default:
            break
        }
        return UITableViewCell()
    }
    
    // MARK: - Functions handling interaction
    // Function that creates an alert to confirm if user want to remove the data entry
    @objc func deleteTapped(){
        let ac = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        ac.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { [weak self] _ in
            self?.deleteEntry()
        }))
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(ac, animated: true)
    }
    
    // Function that automatically save progress and create a new entry in the password array
    @objc func newTapped(){
        saveData()

        password.append(SavedPassword(source: "New Account", date: Date(), password: ""))
        
        notifyDelegateDidUpdate(password: password)
        infoIndex = password.count - 1
        
        // Accessing the respective cell to change its data to reflect the new entry
        for cellRow in 0...sectionTitles.count{
            let indexPath = NSIndexPath(row: cellRow, section: 0)
            let cell = tableView.cellForRow(at: indexPath as IndexPath)
            if let cell = cell as? DataCell {
                if cell.dataInput.tag == 0 {
                    cell.dataInput.text! = password[infoIndex].source
                }
            
                if cell.dataInput.tag == 1 {
                    cell.dataInput.text! = password[infoIndex].password
                }
            }
        }
        saveData(newEntry: true)
    }
    
    // Function that delete the entry and notify the storage of overwrite old data
    func deleteEntry(){
        password.remove(at: infoIndex)
        notifyDelegateDidUpdate(password: password)
        
        DispatchQueue.global().async { [weak self] in
            if let password = self?.password{
                DataStore.save(password: password)
            }
            DispatchQueue.main.async {
                self?.infoIndex = nil
                self?.navigationController?.popViewController(animated: true)
            }
        }
    }

    // MARK: - Background Update Function
    // Function that let the other viewcontroller know of the changes to the password array
    func notifyDelegateDidUpdate(password: [SavedPassword]) {
        if let delegate = delegate{
            delegate.editor(self, didUpdate: password)
        }
    }

    // Function that allow the view to show another entry when the previous is deleted
    func updateGuiAfterDeletion (){
        if infoIndex < password.count {
            // reload cell with same index num
            return
        }
        if password.count > 0 {
            infoIndex = password.count - 1
            // reload infoindex
            return
        }
        infoIndex = nil
        navigationController?.popViewController(animated: true)
    }
}

