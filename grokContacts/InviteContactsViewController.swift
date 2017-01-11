//
//  InviteContactsViewController.swift
//  Squado
//
//  Copyright © 2016 Squado Inc.. All rights reserved.
//

import Foundation
import UIKit
import Contacts

protocol InviteContactsDelegate: class {
  func inviteContacts(_ phoneContacts: [String], emailContacts: [String])
}

class InviteContactsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
  var contactStore = CNContactStore()
  var contacts: [CNContact]?
  var emailsToInvite:[String] = []
  var phoneNumbersToInvite:[String] = []
  
  weak var delegate: InviteContactsDelegate?
  
  @IBOutlet weak var tableView: UITableView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    requestContactsAccess { (accessGranted) in
      if accessGranted {
        print("can view contacts")
        self.fetchContacts { success in
          if success {
            print("got contacts")
            self.tableView.reloadData()
          }
        }
      } else {
        print("can't view contacts")
      }
    }
  }
  
  @IBAction func submit() {
    delegate?.inviteContacts(phoneNumbersToInvite, emailContacts: emailsToInvite)
    let _ = self.navigationController?.popViewController(animated: true)
  }
  
  func requestContactsAccess(_ completionHandler: @escaping (_ accessGranted: Bool) -> Void) {
    let authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
    
    switch authorizationStatus {
    case .authorized:
      completionHandler(true)
      
    case .denied, .notDetermined:
      self.contactStore.requestAccess(for: CNEntityType.contacts, completionHandler: { (access, accessError) -> Void in
        if access {
          completionHandler(access)
        }
        else {
          if authorizationStatus == CNAuthorizationStatus.denied {
            DispatchQueue.main.async { () -> Void in
              let message = "To invite your contacts to Squado, please allow the app to access your contacts through Settings."
              let alertController = UIAlertController(title: "Contacts", message: message, preferredStyle: .alert)
              alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
              
              self.present(alertController, animated: true, completion: nil)
            }
          }
        }
      })
    default:
      completionHandler(false)
    }
  }
  
  func fetchContacts(_ completionHandler: @escaping (_ success: Bool) -> Void) {
    let keysToFetch: [CNKeyDescriptor] = [
      CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
      CNContactEmailAddressesKey as CNKeyDescriptor,
      CNContactPhoneNumbersKey as CNKeyDescriptor,
      CNContactImageDataAvailableKey as CNKeyDescriptor,
      CNContactThumbnailImageDataKey as CNKeyDescriptor
    ]
    
    contacts = []
    // TODO: images?
    
    do {
      let fetchRequest = CNContactFetchRequest(keysToFetch: keysToFetch)
      fetchRequest.sortOrder = .userDefault
      try contactStore.enumerateContacts(with: fetchRequest) {
        (contact, pointer) in
        // only include if they have phone number or email
        if contact.phoneNumbers.count > 0 || contact.emailAddresses.count > 0 {
          self.contacts?.append(contact)
        }
      }
    } catch let error {
      print("\(error)")
      completionHandler(false)
      return
    }
    
    completionHandler(true)
  }
  
  // MARK: - Tableview
  func numberOfSections(in tableView: UITableView) -> Int {
    guard let contacts = contacts else {
      return 0
    }
    return contacts.count
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    guard let contacts = contacts,
      section < contacts.count else {
        return 0
    }
    
    let contact = contacts[section]
    return contact.emailAddresses.count + contact.phoneNumbers.count
  }
  
  func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    guard let contacts = contacts,
      section < contacts.count else {
        return ""
    }
    let contact = contacts[section]
    if let fullname = CNContactFormatter.string(from: contact, style: .fullName) {
      return fullname
    }
    return ""
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
    
    guard let contacts = contacts,
      indexPath.section < contacts.count else {
        return cell
    }
    
    let text = textForIndexPath(indexPath)
    // phone numbers then email Addresses
    let contact = contacts[indexPath.section]
    if indexPath.row < contact.phoneNumbers.count {
      cell.textLabel?.text = "sms: \(text)"
    } else {
      cell.textLabel?.text = "email: \(text)"
    }
    if contact.imageDataAvailable, let thumbnailData = contact.thumbnailImageData {
      cell.imageView?.image = UIImage(data: thumbnailData)
      cell.imageView?.layer.cornerRadius = 4.0
      cell.imageView?.clipsToBounds = true
    } else {
      cell.imageView?.image = nil
    }
    return cell
  }
  
  func textForIndexPath(_ indexPath: IndexPath) -> String {
    guard let contacts = contacts,
      indexPath.section < contacts.count else {
        return ""
    }
    
    let contact = contacts[indexPath.section]
    // phone numbers then email Addresses
    if indexPath.row < contact.phoneNumbers.count {
      let phoneNumber = contact.phoneNumbers[indexPath.row]
      let value = phoneNumber.value
      let text = value.stringValue
      return text
    } else {
      let emailAddress = contact.emailAddresses[indexPath.row - contact.phoneNumbers.count]
      return emailAddress.value as String
    }
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard let contacts = contacts,
      indexPath.section < contacts.count else {
        return
    }
    
    let text = textForIndexPath(indexPath)
    
    let contact = contacts[indexPath.section]
    if indexPath.row < contact.phoneNumbers.count {
      phoneNumbersToInvite.append(text)
    } else {
      emailsToInvite.append(text)
    }
  }
  
  func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
    guard let contacts = contacts,
      indexPath.section < contacts.count else {
        return
    }
    
    let text = textForIndexPath(indexPath)
    
    let contact = contacts[indexPath.section]
    if indexPath.row < contact.phoneNumbers.count {
      phoneNumbersToInvite = phoneNumbersToInvite.filter { $0 != text }
    } else {
      emailsToInvite = emailsToInvite.filter { $0 != text }
    }
  }
}
