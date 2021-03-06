//
//  BackupViewController.swift
//  18phone
//
//  Created by 戴全艺 on 16/9/18.
//  Copyright © 2016年 Kratos. All rights reserved.
//

import UIKit
import Contacts

class BackupViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    var contactCount = 0
    
    let titles = ["本地通讯录", "云端通讯录", "同步通讯录", "恢复通讯录", "自动同步"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
        tableView.dataSource = self
        tableView.delegate = self
        let store = CNContactStore()
        let keysToFetch = [CNContactFormatter.descriptorForRequiredKeys(for: .fullName)]
        let fetchRequest = CNContactFetchRequest(keysToFetch: keysToFetch)
        try! store.enumerateContacts(with: fetchRequest) { contact, stop in
            self.contactCount = self.contactCount + 1
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.backup_cell_a)
        cell!.textLabel!.text = titles[indexPath.row]
        cell?.selectionStyle = .none
        
        switch indexPath.row {
        case 0:
            cell!.detailTextLabel!.text = "\(contactCount)人"
            
            break
        case 1:
            if let upsucceedCount = UserDefaults.standard.string(forKey: "upsucceedCount") {
                cell!.detailTextLabel!.text = "\(upsucceedCount)人"
            } else {
                cell!.detailTextLabel!.text = "未备份"
            }
            break
        case 2:
            if let backupEndTime = UserDefaults.standard.string(forKey: "backupEndTime") {
                cell!.detailTextLabel!.text = "上次同步\(backupEndTime)"
            } else {
                cell!.detailTextLabel!.text = "未备份"
            }
            break
        case 3:
            cell?.selectionStyle = .default
            break
        case 4:
            let autoSwitch = UISwitch(frame: CGRect(x: 0, y: 0, width: 51, height: 31))
            autoSwitch.isOn = UserDefaults.standard.bool(forKey: "auto_backup")
            cell?.accessoryView = autoSwitch
            autoSwitch.addTarget(self, action: #selector(switchAction(_:)), for: .valueChanged)
            break
        default:
            break
        }
        return cell!
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.1
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.001
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row == 3 {
            let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
            let okAction = UIAlertAction(title: "好的", style: .default, handler: nil)
            alertController.addAction(okAction)
            let confirm = UIAlertController(title: "校验", message: "请输入登录密码", preferredStyle: .alert)
            confirm.addTextField(configurationHandler: { textField in
                textField.placeholder = "请输入登录密码"
            })
            let cancel = UIAlertAction(title: "取消", style: .cancel, handler: nil)
            let confirmOK = UIAlertAction(title: "确认", style: .default, handler: { action in
                if confirm.textFields![0].text == UserDefaults.standard.string(forKey: "password") {
                    MBProgressHUD.showAdded(to: self.view, animated: true)
                    if let userID = UserDefaults.standard.string(forKey: "userID") {
                        APIUtil.downloadContact(userID) { downloadContactInfos in
                            if downloadContactInfos.codeStatus == 1 {
                                for contactInfo in downloadContactInfos.contactInfos {
                                    let store = CNContactStore()
                                    let keysToFetch = [CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
                                                       CNContactImageDataKey,
                                                       CNContactThumbnailImageDataKey,
                                                       CNContactImageDataAvailableKey,
                                                       CNContactPhoneNumbersKey,
                                                       CNContactPhoneticGivenNameKey,
                                                       CNContactPhoneticFamilyNameKey] as [Any]
                                    do {
                                        let contact = try store.unifiedContact(withIdentifier: contactInfo.PhoneID!, keysToFetch: keysToFetch as! [CNKeyDescriptor]).mutableCopy() as! CNMutableContact
                                        contact.familyName = ""
                                        contact.givenName = contactInfo.Name!
                                        var phoneNumbers = [CNLabeledValue<CNPhoneNumber>]()
                                        for phoneNumber in contactInfo.Mobile!.components(separatedBy: ",") {
                                            phoneNumbers.append(CNLabeledValue(label: CNLabelPhoneNumberMobile, value: CNPhoneNumber(stringValue: phoneNumber)))
                                        }
                                        contact.phoneNumbers = phoneNumbers
                                        let appContactInfo = App.realm.objects(AppContactInfo.self).filter("identifier == '\(contact.identifier)'").first!
                                        try! App.realm.write {
                                            appContactInfo.sex = contactInfo.Sex!
                                            if contactInfo.Area != nil {
                                                appContactInfo.area = contactInfo.Area!
                                            }
                                        }
                                        let saveRequest = CNSaveRequest()
                                        saveRequest.update(contact)
                                        try store.execute(saveRequest)
                                    }catch {
                                        let contact = CNMutableContact()
                                        contact.familyName = ""
                                        contact.givenName = contactInfo.Name!
                                        var phoneNumbers = [CNLabeledValue<CNPhoneNumber>]()
                                        for phoneNumber in contactInfo.Mobile!.components(separatedBy: ",") {
                                            phoneNumbers.append(CNLabeledValue(label: CNLabelPhoneNumberMobile, value: CNPhoneNumber(stringValue: phoneNumber)))
                                        }
                                        contact.phoneNumbers = phoneNumbers
                                        let appContactInfo = AppContactInfo()
                                        try! App.realm.write {
                                            appContactInfo.identifier = contact.identifier
                                            appContactInfo.sex = contactInfo.Sex!
                                            if contactInfo.Area != nil {
                                                appContactInfo.area = contactInfo.Area!
                                            }
                                            appContactInfo.age = contactInfo.Age!
                                            if contactInfo.PersonalSignature != nil {
                                                appContactInfo.signature = contactInfo.PersonalSignature!
                                            }
                                        }
                                        let store = CNContactStore()
                                        let saveRequest = CNSaveRequest()
                                        saveRequest.add(contact, toContainerWithIdentifier:nil)
                                        try! store.execute(saveRequest)
                                    }
                                }
                                alertController.message = "恢复成功"
                                SwiftEventBus.post("reloadContacts")
                            } else {
                                alertController.message = downloadContactInfos.codeInfo
                            }
                            self.present(alertController, animated: true, completion: nil)
                            MBProgressHUD.hide(for: self.view, animated: true)
                        }
                    }
                } else {
                    alertController.message = "密码错误"
                    self.present(alertController, animated: true, completion: nil)
                }
            })
            confirm.addAction(confirmOK)
            confirm.addAction(cancel)
            present(confirm, animated: true, completion: nil)
        }
    }
    
    func switchAction(_ sender: UISwitch) {
        let userDefaults = UserDefaults.standard
        userDefaults.set(sender.isOn, forKey: "auto_backup")
        userDefaults.synchronize()
    }
    
    @IBAction func backupContacts(_ sender: UIButton) {
        MBProgressHUD.showAdded(to: view, animated: true)
        let alertController = UIAlertController(title: nil, message: "备份成功", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "好的", style: .default, handler: nil)
        alertController.addAction(okAction)
        if let userID = UserDefaults.standard.string(forKey: "userID") {
            let store = CNContactStore()
            let keysToFetch = [CNContactFormatter.descriptorForRequiredKeys(for: .fullName), CNContactPhoneNumbersKey as CNKeyDescriptor, CNContactThumbnailImageDataKey as CNKeyDescriptor, CNContactImageDataAvailableKey as CNKeyDescriptor]
            let fetchRequest = CNContactFetchRequest(keysToFetch: keysToFetch)
            var contactBackups = [[String : Any]]()
            try! store.enumerateContacts(with: fetchRequest) { contact, stop in
                var phones = ""
                for number in contact.phoneNumbers {
                    let phoneNumber = number.value.stringValue
                    if phones.isEmpty {
                        phones = phoneNumber
                    } else {
                        phones = phones + "," + phoneNumber
                    }
                }
                let appContactInfo = App.realm.objects(AppContactInfo.self).filter("identifier == '\(contact.identifier)'").first!
                var contactBackup: [String : Any] = ["phoneID":contact.identifier, "userID":userID, "name":contact.familyName + contact.givenName,"mobile":phones, "sex":appContactInfo.sex, "age":appContactInfo.age, "area":appContactInfo.area]
                if contact.imageDataAvailable {
                    contactBackup["imageBase64String"] = contact.thumbnailImageData!.base64EncodedString()
                } else {
                    contactBackup["imageBase64String"] = ""
                }
                contactBackups.append(contactBackup)
            }
            let contactBackupsJson = try! JSONSerialization.data(withJSONObject: contactBackups, options: JSONSerialization.WritingOptions.prettyPrinted)
            let jsonString = NSString(data: contactBackupsJson, encoding: String.Encoding.utf8.rawValue)
            APIUtil.uploadContact(jsonString as! String, callBack: { backupContactInfo in
                if backupContactInfo.codeStatus == 1 {
                    MBProgressHUD.hide(for: self.view, animated: true)
                    self.present(alertController, animated: true, completion: nil)
                    self.tableView.cellForRow(at: IndexPath(row: 1, section: 0))?.detailTextLabel?.text = "\(backupContactInfo.upsucceedCount!)人"
                    self.tableView.cellForRow(at: IndexPath(row: 2, section: 0))?.detailTextLabel?.text = "上次同步\(backupContactInfo.endTime!)"
                    let userDefaults = UserDefaults.standard
                    userDefaults.set(backupContactInfo.endTime, forKey: "backupEndTime")
                    userDefaults.set(backupContactInfo.upsucceedCount, forKey: "upsucceedCount")
                    userDefaults.synchronize()
                }
            })
        }
    }
}
