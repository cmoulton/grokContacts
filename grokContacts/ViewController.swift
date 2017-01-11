//
//  ViewController.swift
//  grokContacts
//
//  Created by Christina Moulton on 2016-12-20.
//  Copyright © 2016 Teak Mobile Inc. All rights reserved.
//

import Foundation
import UIKit

class ViewController: UIViewController {
  var emailsToInvite: [String]?
  var phoneNumbersToInvite: [String]?
  
  @IBOutlet weak var displayLabel: UILabel!
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    var textToDisplay = ""
    
    if let emailsToInvite = emailsToInvite,
      emailsToInvite.count > 0 {
      textToDisplay.append("Emails to Invite:\n")
      textToDisplay.append("\(emailsToInvite)\n")
    } else {
      textToDisplay.append("No Emails to Invite\n\n")
    }
    
    if let phoneNumbersToInvite = phoneNumbersToInvite,
      phoneNumbersToInvite.count > 0 {
      textToDisplay.append("Phone Numbers to Invite:\n")
      textToDisplay.append("\(phoneNumbersToInvite)")
    } else {
      textToDisplay.append("No Phone Numbers to Invite")
    }
   
    displayLabel.text = textToDisplay
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    super.prepare(for: segue, sender: sender)
    if segue.identifier == "showSelectContactsViewController" {
      if let inviteContactsViewController = segue.destination as? InviteContactsViewController {
        inviteContactsViewController.delegate = self
      }
    }
  }
}

extension ViewController: InviteContactsDelegate {
  func inviteContacts(_ phoneContacts: [String], emailContacts: [String]) {
    emailsToInvite = emailContacts
    phoneNumbersToInvite = phoneContacts
  }
}
