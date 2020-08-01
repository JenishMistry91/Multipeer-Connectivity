//
//  ViewController.swift
//  Multipeer Connectivity
//
//  Created by Jenish Mistry on 01/08/20.
//  Copyright © 2020 Jenish Mistry. All rights reserved.
//

import UIKit
import CoreData
import MultipeerConnectivity

class ViewController: UIViewController {
    
    // MARK: - Attributes -
    @IBOutlet weak var tableView: UITableView!
    
    let tableCellIdentifier = "TextTableCell"
    
    var arrayCoreDataModel: [NSManagedObject] = []
    let entityKey = "Multipeer"
    let attributeTextKey = "text"
    
    var peerID: MCPeerID!
    var mcSession: MCSession!
    var mcAdvertiserAssistant: MCAdvertiserAssistant!
    
    var imagePicker: ImagePicker!
    
    // MARK: - Life Cycle -
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setUpView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
    }
    
    // MARK: - Helper Methods -
    func setUpView() {
        fetchRecord()
        self.tableView.register(UINib(nibName: tableCellIdentifier, bundle: nil), forCellReuseIdentifier: tableCellIdentifier)
        
        peerID = MCPeerID(displayName: UIDevice.current.name)
        mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        mcSession.delegate = self
        
        self.imagePicker = ImagePicker(presentationController: self, delegate: self)
        
    }
    
    // Host connection
    func hostSession() {
        mcAdvertiserAssistant = MCAdvertiserAssistant(serviceType: "ioscreator-chat", discoveryInfo: nil, session: mcSession)
        mcAdvertiserAssistant.start()
        
    }
    
    // Join connection
    func joinSession() {
        let mcBrowser = MCBrowserViewController(serviceType: "ioscreator-chat", session: mcSession)
        mcBrowser.delegate = self
        present(mcBrowser, animated: true)
    }
    
    // Open dialog box for accepting text
    func openDialogForSendText() {
        let alert = UIAlertController(title: "Send Text", message: "Enter a text" , preferredStyle: .alert)
        let saveAction = UIAlertAction(title: "Create", style: .default) { [unowned self] action in
            guard let textField = alert.textFields?.first, let enteredName = textField.text else {
                return
            }
            self.saveRecord(name: enteredName)
            self.reloadTableData()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addTextField()
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }
    
    // Send Image
    func sendImage(img: UIImage) {
        if mcSession.connectedPeers.count > 0 {
            if let imageData = img.pngData() {
                do {
                    try mcSession.send(imageData, toPeers: mcSession.connectedPeers, with: .reliable)
                } catch let error as NSError {
                    let ac = UIAlertController(title: "Send error", message: error.localizedDescription, preferredStyle: .alert)
                    ac.addAction(UIAlertAction(title: "OK", style: .default))
                    present(ac, animated: true)
                }
            }
        }
    }
    
    // Reload tableview data
    func reloadTableData() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    // MARK: - UIButton Action Methods -
    @IBAction func btnConnectTapped(_ sender: Any) {
        let alert = UIAlertController(title: "", message: "Do you want to Host or Join session?", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Host Session", style: .default , handler:{ (UIAlertAction)in
            self.hostSession()
        }))
        alert.addAction(UIAlertAction(title: "Join Session", style: .default , handler:{ (UIAlertAction)in
            self.joinSession()
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler:{ (UIAlertAction)in
            print("User click Dismiss button")
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func btnAddTapped(_ sender: Any) {
        let alert = UIAlertController(title: "Send a message via", message: "", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Send Text", style: .default , handler:{ (UIAlertAction)in
            self.openDialogForSendText()
        }))
        alert.addAction(UIAlertAction(title: "Send Location", style: .default , handler:{ (UIAlertAction)in
            print("User click Approve button")
        }))
        alert.addAction(UIAlertAction(title: "Send Image", style: .default , handler:{ (UIAlertAction)in
            self.imagePicker.present(from: self.view)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler:{ (UIAlertAction)in
            print("User click Dismiss button")
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
}

// MARK: - UITableView Data Source/ Delegate Methods -
extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrayCoreDataModel.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.tableCellIdentifier) as? TextTableCell
        configCell(cell: cell!, indexPath: indexPath)
        return cell!
    }
    
    // Delete button method of tableview cell
    func configCell(cell: TextTableCell, indexPath: IndexPath) {
        let arrayData = arrayCoreDataModel[indexPath.row]
        cell.btnDelete.tag = indexPath.row
        cell.btnDelete.addTarget(self, action: #selector(deleteMethod(_:)), for: .touchUpInside)
        cell.btnShare.tag = indexPath.row
        cell.btnShare.addTarget(self, action: #selector(shareMethod(_:)), for: .touchUpInside)
        cell.setTextData(text: (arrayData.value(forKey: attributeTextKey) as? String)!)
    }
    
    @objc func deleteMethod(_ sender: UIButton) {
        let exitingName = arrayCoreDataModel[sender.tag].value(forKey: attributeTextKey) as! String
        let alert = UIAlertController(title: "Alert", message: "Are you sure want to delete this record?" , preferredStyle: .alert)
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { action in
            self.deleteRecord(exitingName: exitingName, indexPathRow: sender.tag)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }
    
    @objc func shareMethod(_ sender: UIButton) {
        let arrayData = arrayCoreDataModel[sender.tag]
        let message = "\(arrayData.value(forKey: attributeTextKey) as! String)"
        let messageToSend = message.data(using: String.Encoding.utf8, allowLossyConversion: false)
        
        do {
            try self.mcSession.send(messageToSend!, toPeers: self.mcSession.connectedPeers, with: .unreliable)
        }
        catch {
            print("Error sending message")
        }
    }
}

// MARK: -  MCSession Delegate & MCBrowserViewController Delegate Methods -

extension ViewController: MCSessionDelegate, MCBrowserViewControllerDelegate {
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .connected:
            print("Connected: \(peerID.displayName)")
        case .connecting:
            print("Connecting: \(peerID.displayName)")
        case .notConnected:
            print("Not Connected: \(peerID.displayName)")
        @unknown default:
            print("fatal error")
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        DispatchQueue.main.async { [unowned self] in
            let message = NSString(data: data as Data, encoding: String.Encoding.utf8.rawValue)! as String
            self.saveRecord(name: message)
            self.reloadTableData()
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        
    }
    
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true, completion: nil)
        
    }
    
    
}

// MARK: - ImagePicker Delegate Methods -
extension ViewController: ImagePickerDelegate {
    func didSelect(image: UIImage?) {
        if image != nil {
            
            //save to core data
            
            // reload tableview
            
            //self.sendImage(img: image!)
        }
    }
}

// MARK: - CRUD Operation Methods -
extension ViewController {
    
    // -----------------------------> Save record into CoreData <--------------------------------------//
    // --------------------------------------------------------------------------------------------//
    
    func saveRecord(name: String) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let managedContext = appDelegate.persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: self.entityKey, in: managedContext)!
        let textValue = NSManagedObject.init(entity: entity, insertInto: managedContext)
        textValue.setValue(name, forKey: self.attributeTextKey)
        
        do {
            try managedContext.save()
            self.arrayCoreDataModel.append(textValue)
            print("Data saved in DB...!!")
        } catch let error as NSError {
            print("Could not save in DB: \(error) , \(error.userInfo)")
            managedContext.rollback()
        }
    }
    
    // -----------------------------> Fetch record from CoreData <--------------------------------------//
    // --------------------------------------------------------------------------------------------//
    
    func fetchRecord() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityKey)
        
        do {
            arrayCoreDataModel = try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch Data: \(error) , \(error.userInfo)")
        }
    }
    
    // -----------------------------> Delete record from CoreData <--------------------------------------//
    // --------------------------------------------------------------------------------------------//
    func deleteRecord(exitingName: String, indexPathRow: Int) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest.init(entityName: self.entityKey)
        fetchRequest.predicate = NSPredicate(format: "text = %@", exitingName)
        
        do {
            let result = try managedContext.fetch(fetchRequest)
            let objectToDelete = result[0] as! NSManagedObject
            managedContext.delete(objectToDelete)
            do{
                try managedContext.save()
                self.arrayCoreDataModel.remove(at: indexPathRow)
                self.tableView.deleteRows(at: [IndexPath(row: indexPathRow, section: 0)], with: .left)
            } catch let error as NSError{
                print("Data deleted... but could not saved in DB: \(error), \(error.userInfo)")
            }
        } catch let error as NSError{
            print("Could not delete data: \(error), \(error.userInfo)")
        }
    }
}

