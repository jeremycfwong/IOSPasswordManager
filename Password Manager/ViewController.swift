//
//  ViewController.swift
//  Password Manager
//
//  Created by Jeremy Wong on 11/8/2021.
//

import LocalAuthentication
import UIKit

class ViewController: UITableViewController, EditorDelegate {
    // This ensures both view controllers are updated of the passwords the user have modified.
    func editor(_ editor: DetailViewController, didUpdate password: [SavedPassword]) {
        self.password = password
    }
    
    // MARK: - variables
    var password = [SavedPassword]()
    var appPassword = "password"

    var authenticateButton: UIBarButtonItem!
    var spacerButton: UIBarButtonItem!
    var addButton: UIBarButtonItem!
    var editButton: UIBarButtonItem!
    var cancelButton: UIBarButtonItem!
    var deleteButton: UIBarButtonItem!
    var passwordButton : UIBarButtonItem!
    var lockButton: UIBarButtonItem!
    var deleteAllButton: UIBarButtonItem!
    
    var isAuthenticated: Bool = false

    // MARK: - loading view and styling
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.darkGray
        
        // MARK: Navigation bar styling - Pre-authorization
        navigationItem.title = "Please Authenticate to Access Password"
        // connecting to another styling file
        StyleSheet.customiseNavigationBar(for: navigationController)
        
        // Setting the appearance of lower UI bar
        authenticateButton = UIBarButtonItem(title:"Authenticate", style: .done, target: self, action: #selector(authenticateTapped))
        authenticateButton.setTitleTextAttributes([
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 20),
            NSAttributedString.Key.foregroundColor : UIColor.white
        ], for: .normal)
        
        spacerButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        // The setting for the upper controller bar
        toolbarItems = [spacerButton,authenticateButton,spacerButton]
        navigationController?.isToolbarHidden = false
        StyleSheet.customiseToolBar(for:navigationController)
    
        tableView.allowsMultipleSelectionDuringEditing = true
        
        loadData()
        
        // MARK: Navigation bar styling - Post-authorization
        editButton = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(enterEditingMode))
        cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelEditingMode))
        addButton = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(addPassword))
        deleteButton = UIBarButtonItem(title: "Delete", style: .plain, target: self, action: #selector(deleteTapped))
        deleteAllButton = UIBarButtonItem(title: "Delete All", style: .plain, target: self, action: #selector(deleteAllTapped))
        lockButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveEdited))
        
        passwordButton = UIBarButtonItem(title: "Change Password", style: .done, target: self, action: #selector(setPassword))
        passwordButton.setTitleTextAttributes([
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 20),
            NSAttributedString.Key.foregroundColor : UIColor.white
        ], for: .normal)
    }

    // Function to retrieve all previous stored password entries
    func loadData(){
        DispatchQueue.global().async { [weak self] in
            self?.password = DataStore.load()
            self?.sortPassword()
            
            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
        }
    }
    
    // When User switch from the detail view, this ensures the modifications are sorted in the reloaded table
    override func viewWillAppear(_ animated: Bool) {
        sortPassword()
        tableView.reloadData()
    }
    
    // Function that sort the cell entires by date
    func sortPassword(){
        password.sort(by: { $0.date >= $1.date })
    }
    
    // MARK: - table cell settings
    
    // Return the amount of cell by the amount of passwords in the array
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return password.count
    }
    
    // Dequeue cell and specifies the content within the cells
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        // this checks if user are authenticated, hiding password data from unauthorised users
        if isAuthenticated{
            cell.textLabel?.text = password[indexPath.row].source
            cell.detailTextLabel?.text = formatDate(from: password[indexPath.row].date)
            return cell
        } else {
            cell.textLabel?.text = "*****"
            cell.detailTextLabel?.text = "******"
            return cell
        }
    }
    
    // The date in the app are formatted for better user experience
    func formatDate(from date:Date) -> String{
        let dateFormatter = DateFormatter()
        
        // If created today, only time will be shown (eg 00:00)
        if Calendar.current.isDateInToday(date){
            dateFormatter.dateStyle = .none
            dateFormatter.timeStyle = .short
            return dateFormatter.string(from: date)
        }
        
        // If created yesterday, creation date will be shown as Yesterday
        if Calendar.current.isDateInYesterday(date){
            return "Yesterday"
        }
        
        // For any other dates, only the day and month of creation will be shown
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .none
        return dateFormatter.string(from: date)
    }
    
    // This is the configuration for what would happen if cells are tapped
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // This ensures unauthorised users will not be able to select rows
        guard isAuthenticated == true else {
            tableView.deselectRow(at: indexPath, animated: true)
            return }
        // If users are in editor mode, this changes the toolbar for cell modifications
        if tableView.isEditing{
            toolbarItems = [deleteButton, spacerButton, passwordButton, spacerButton, addButton]
        }  else {
            // If not in edit mode, this will allow user to see the details of the cell
            openDetailViewController(infoIndex: indexPath.row)
        }
    }

    // MARK: - Functions for the buttons
    
    // A function to initiate the identifying process
    @objc func authenticateTapped (){
        let context = LAContext()
        var error: NSError?
        
        // Checking if user have biometrics on their phone model
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error){
            // if authentication unsuccessful, show the user the following error
            let reason = "Error, invalid input"
            
            // Authenticate through biometrics
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) {
                [weak self] success, authenticateError in
                
                // Evaluate if the biometric was successful or not
                DispatchQueue.main.async{
                    // If the authentication succeed, let user edit
                    if success {
                        self?.unlockEditing()
                        self?.navigationItem.rightBarButtonItem?.isEnabled = true
                    } else {
                        // If failed, show an alert that the authentication failed
                        let ac = UIAlertController(title: "Authentication failed", message: "Please Try Again.", preferredStyle: .alert)
                        ac.addAction(UIAlertAction(title: "OK", style: .default))
                        self?.present(ac, animated: true)
                    }
                }
            }
        } else {
            // If user device have no biometric, allow user to use in-app password system
            if hasPassword() {
                authenticateWithPassword()
            }
            else {
                // if user had not set a passowrd, let user set passweord
                setPassword()
            }
        }
    }
    
    // MARK: - Password Functions
    @objc func setPassword(){
        // alert to set password
        let ac = UIAlertController(title: "Please set a password", message: nil, preferredStyle: .alert)
        ac.addTextField(){ textField in
            textField.isSecureTextEntry = true
            textField.placeholder = "Password"
        }
        
        // confirmation of password input
        ac.addTextField(){ textField in
            textField.isSecureTextEntry = true
            textField.placeholder = "Confirm Password"
        }
        
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        ac.addAction(UIAlertAction(title: "Confirm", style: .default){ [weak self, weak ac] action in
            guard let password = self?.checkSetPassword(ac: ac) else { return }
            
            // setting the password in the app and store it in the keychainwrapper
            if let passwordKey = self?.appPassword {
                KeychainWrapper.standard.set(password, forKey: passwordKey)
            }
        })
        
        present(ac, animated: true)
    }
        
    // Function to ensure password inputted was consistent
    func checkSetPassword(ac: UIAlertController?) -> String? {
        guard let password1 = getField(ac: ac, field: 0) else {
            setPasswordError(title: "Missing password")
            return nil
        }
        
        guard let password2 = getField(ac: ac, field: 1) else {
            setPasswordError(title: "Missing password confirmation")
            return nil
        }
        
        guard password1 == password2 else {
            setPasswordError(title: "The password doesn't match")
            return nil
        }
        
        return password1
    }
    
    // Function to handle error arising from password setting through alerts
    func setPasswordError (title: String){
        let ac = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        ac.addAction(UIAlertAction(title: "Retry", style: .default) { [weak self] action in
            self?.setPassword()
        })
    }
    
    // Function that seek if user have password set from the keychain wrapper
    func hasPassword() -> Bool{
        return KeychainWrapper.standard.hasValue(forKey: appPassword)
    }
    
    // Function that shows an alert for user to enter their set password
    func authenticateWithPassword() {
        let ac = UIAlertController(title: "Please provide your password.", message: nil, preferredStyle: .alert)
        ac.addTextField(){ textField in
            textField.isSecureTextEntry = true
            textField.placeholder = "Password"
        }
        
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        ac.addAction(UIAlertAction(title: "Submit", style: .default) { [weak self, weak ac] action in
            // Ensure user did input something and value is not NULL
            guard let password = self?.getField(ac: ac, field: 0) else { return }
            
            // This part of the function check if the password match with the one stored in keychainwrapper
            if let passwordKey = self?.appPassword {
                if let storedPassword = KeychainWrapper.standard.string(forKey: passwordKey) {
                    if password == storedPassword {
                        self?.unlockEditing()
                        return
                    }
                }
            }
            // If it didnt pass the logic test, authentication error
            self?.showErrorMessage(title: "Authentication failed", message: "You could not be verified; please try again.")
        })
        present(ac, animated: true)
    }
    
    // This function extracts the user input from the Alert controller
    func getField(ac: UIAlertController?, field: Int) -> String? {
        guard let text = ac?.textFields?[field].text else {
            return nil
        }
        
        guard !text.isEmpty else {
            return nil
        }
        
        return text
    }
    
    
    // MARK: - Error Handling
    
    //General Function to show error messages
    func showErrorMessage(title: String, message: String? = nil) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        
        present(ac, animated: true)
    }

    // MARK: - Functions for Authenticated Users
    // Function to unlock editing setting and update toolbar, navigation bar and reveal cells
    func unlockEditing () {
        isAuthenticated = true
        navigationItem.title = "Password Manager"
        
        toolbarItems = [lockButton,spacerButton, passwordButton, spacerButton, addButton]
        navigationItem.rightBarButtonItems = [editButton]
        tableView.reloadData()
    }

    // Function that changes the toolbar if user tap on the Edit Button on toolbar
    @objc func enterEditingMode(){
        navigationItem.rightBarButtonItems = [cancelButton]
        toolbarItems = [deleteAllButton, spacerButton, passwordButton, spacerButton, addButton]
        setEditing(true, animated: true)
    }
    
    // Function that handle the set eding animation
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
    }
    
    // Function to reset the navigation bar and toolbar to before editing
    @objc func cancelEditingMode(){
        navigationItem.rightBarButtonItems = [editButton]
        toolbarItems = [lockButton, spacerButton, passwordButton, spacerButton, addButton]
        setEditing(false, animated: true)
    }
    
    // MARK: - Functions to modification contorls of Data Cells
    // Function that handles addition of new password entry
    @objc func addPassword(){
        password.append(SavedPassword(source: "Account", date: Date(), password: ""))
        DispatchQueue.global().async { [weak self] in
            if let password = self?.password {
                // update stored on external function
                DataStore.save(password: password)
                
                // Putting the update of UI into the main for faster loading
                DispatchQueue.main.async {
                    self?.openDetailViewController(infoIndex: password.count - 1)
                    self?.tableView.reloadData()
                }
            }
        }
    }
    
    // Function that handle user tapping the delete button
    @objc func deleteTapped(){
        let ac = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        ac.popoverPresentationController?.barButtonItem = deleteButton
        ac.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { [weak self] _ in
            if let selectedRows = self?.tableView.indexPathsForSelectedRows {
                self?.deleteNotes(rows:selectedRows)
            }
        }))
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(ac, animated: true)
    }
    
    // Function that handle the delete call
    func deleteNotes(rows: [IndexPath]){
        // Sorting the rows selected in reversed order to ensure correct data entries are delteed
        var sortedPassword = rows
        sortedPassword = sortedPassword.sorted().reversed()
        
        // loop through the selected rows to remove entries
        for path in sortedPassword{
            password.remove(at: path.row)
        }
        
        // in the background, update the storage so that the items deleted will no longer show up
        DispatchQueue.global().async { [weak self] in
            if let password = self?.password{
                DataStore.save(password: password)
            }
            
            // in main frame, reload data and revert the edit mode
            DispatchQueue.main.async {
                self?.tableView.reloadData()
                self?.cancelEditingMode()
            }
        }
    }
    
    // Function that handles if user want to completely remove all entries from the app
    @objc func deleteAllTapped(){
        let ac = UIAlertController(title: "Are you sure to delete all your entries?", message: nil, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        ac.addAction(UIAlertAction(title: "Confirm", style: .destructive, handler: { [weak self] _ in
            self?.deleteAll()
            
        }))
        present(ac, animated: true)
    }
    
    // Function that handles the execution of deleting all entries
    func deleteAll(){
        password = [SavedPassword]()
        
        // Update in the background so the password array is cleared
        DispatchQueue.global().async { [weak self] in
            if let password = self?.password{
                DataStore.save(password: password)
            }
            
            // Reloading the table to reflect changes
            DispatchQueue.main.async {
                self?.tableView.reloadData()
                self?.cancelEditingMode()
            }
        }
    }
    
    // Function that serve as a final measure to save everything before user lock the App
    @objc func saveEdited(){
        isAuthenticated = false
        navigationItem.rightBarButtonItem = nil
        toolbarItems = [spacerButton,authenticateButton,spacerButton]
        
        DispatchQueue.global().async { [weak self] in
            if let password = self?.password{
                DataStore.save(password: password)
            }
            
            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
        }
        title = "Please Authenticate to Access Password"
    }
  
    // MARK: - Connecting to DetailView
    // function that feeds the parameters required to establish detail view
    func openDetailViewController (infoIndex: Int){
        if let vc = storyboard?.instantiateViewController(identifier: "DetailViewController") as? DetailViewController {
            vc.setParameters(password: password, infoIndex: infoIndex)
            vc.delegate = self
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}
