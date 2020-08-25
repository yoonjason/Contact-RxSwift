//
//  ViewController.swift
//  contactsReadAndWrite
//
//  Created by twave on 2020/08/25.
//  Copyright © 2020 seokyu. All rights reserved.
//

import UIKit
import Contacts
import RxSwift
import RxCocoa
import NSObject_Rx

class ContactCell : UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var phoneNumberLabel: UILabel!
    
    override func prepareForReuse() {
        nameLabel.text = nil
        phoneNumberLabel.text = nil
    }
    
    func setView(_ contactData : CNContact) {
        nameLabel.text = contactData.familyName + contactData.middleName + contactData.givenName
        
        contactData.phoneNumbers.forEach { [weak self] phoneNumber in
            let number = phoneNumber.value.stringValue
            self?.phoneNumberLabel.text = number
        }
    }
}


class ViewController: UIViewController, UIScrollViewDelegate {
    
    var contacts2 = [CNContact]()
    var contacts = BehaviorSubject<[CNContact]>(value: [])
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        readContacts()
        
        tableView
            .rx
            .setDelegate(self)
            .disposed(by: rx.disposeBag)
        
        contacts.bind(to: tableView.rx.items(cellIdentifier: "ContactCell", cellType: ContactCell.self)) { (index, contactData, cell) in
            cell.setView(contactData)
            cell.selectionStyle = .none
        }
        .disposed(by: rx.disposeBag)
        
        Observable
            .zip(tableView.rx.itemSelected, tableView.rx.modelSelected(CNContact.self))
            .subscribe(onNext : { [weak self] (indexPath, item) in
                item.phoneNumbers.forEach { [weak self] phoneNumber in
                    self?.requestCall(phoneNumber.value.stringValue)
//                    if let number = phoneNumber.value as? CNPhoneNumber, let label = phoneNumber.label {
//                        let localizedLabel = CNLabeledValue<CNPhoneNumber>.localizedString(forLabel: label)
//                        print(localizedLabel)
//                        self?.requestCall(number.stringValue)
//                    }
                }
            })
            .disposed(by: rx.disposeBag)
        
        
    }
    
    private func readContacts(){
        let store = CNContactStore()
        
        store.requestAccess(for: .contacts) { (status, error) in
            guard status else {
                return;
            }
            let request : CNContactFetchRequest = self.getContactFetchRequest()
            
            request.sortOrder = CNContactSortOrder.userDefault
            
            
            try! store.enumerateContacts(with: request, usingBlock: { (contact, stop) in
                
                if !contact.phoneNumbers.isEmpty {
                    self.contacts2.append(contact)
                }
            })
            self.contacts.onNext(self.contacts2)
        }
    }
    
    private func getContactFetchRequest() -> CNContactFetchRequest {
        let keys : [CNKeyDescriptor] = [CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
                                        CNContactPhoneNumbersKey,
                                        CNContactEmailAddressesKey,
                                        CNContactJobTitleKey,
                                        CNContactPostalAddressesKey
            ] as! [CNKeyDescriptor]
        return CNContactFetchRequest(keysToFetch: keys)
    }
    
    private func saveContact() {
        let store = CNContactStore()
        
        store.requestAccess(for: .contacts) { (status, error) in
            guard status else {
                return
            }
            let contact : CNMutableContact = self.getNewContact()
            let request =  CNSaveRequest()
            request.add(contact, toContainerWithIdentifier: nil)
            
            try! store.execute(request)
            
        }
        
    }
    
    
    private func getNewContact() -> CNMutableContact {
        let contact = CNMutableContact()
        contact.givenName = "name"
        contact.familyName = "familyName"
        
        let phone = CNLabeledValue(label: CNLabelPhoneNumberMobile, value: CNPhoneNumber(stringValue: "010-0000-0000"))
        
        
        let tel = CNLabeledValue(label: CNLabelPhoneNumberMain, value: CNPhoneNumber(stringValue: "031-0000-0000"))
        
        contact.phoneNumbers = [phone, tel]
        
        let email : NSString = "yeong806@gmail.com"
        contact.emailAddresses = [CNLabeledValue(label: CNLabelWork, value: email)]
        return contact
    }
    
    func requestCall(_ number: String) {
        if let url = URL(string: "tel://\(number)"), UIApplication.shared.canOpenURL(url) {
            if #available(iOS 10, *) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }else {
                UIApplication.shared.openURL(url)
            }
        }else {
            print("NotCalling")
        }
    }
}

