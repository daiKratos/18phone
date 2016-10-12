//
//  RegisterViewController.swift
//  18phone
//
//  Created by 戴全艺 on 16/10/8.
//  Copyright © 2016年 Kratos. All rights reserved.
//

import UIKit

class RegisterViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {

    var titles = ["请输入手机号", "请输入密码", "请确认密码", "请输入验证码"]
    
    var phoneNumber = ""
    
    var password = ""
    
    var passwordConfirm = ""
    
    var verifyCode = ""
    
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
        tableView.dataSource = self
        tableView.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.row != 3 {
            let cell = tableView.dequeueReusableCellWithIdentifier(R.reuseIdentifier.register_cell_a)
            cell?.titleLabel.text = titles[indexPath.row]
            cell?.contentField.delegate = self
            cell?.contentField.tag = indexPath.row
            
            switch indexPath.row {
            case 0:
                cell?.contentField.keyboardType = .NumberPad
                cell?.contentField.becomeFirstResponder()
                ViewUtil.setupNumberBar(cell!.contentField)
                break
            case 1,2:
                cell?.contentField.keyboardType = .Default
                break
            default:
                break
            }
            return cell!
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier(R.reuseIdentifier.register_cell_b)
            cell?.titleLabel.text = titles[indexPath.row]
            cell?.contentField.delegate = self
            cell?.contentField.tag = indexPath.row
            cell?.idCodeBtn.addTarget(self, action: #selector(codeBtnVerification(_:)), forControlEvents: .TouchUpInside)
            ViewUtil.setupNumberBar(cell!.contentField)
            
            return cell!
        }
    }
    
    func codeBtnVerification(sender: VerifyCodeButton) {
        sender.timeFailBeginFrom(60)
    }
    
    @IBAction func cancel(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }

    @IBAction func submit(sender: UIButton) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .Alert)
        let okAction = UIAlertAction(title: "好的", style: .Default, handler: nil)
        alertController.addAction(okAction)
        if phoneNumber.isEmpty {
            alertController.message = "请输入手机号"
            presentViewController(alertController, animated: true, completion: nil)
            return
        }
        if !PhoneUtil.isMobileNumber(phoneNumber) {
            alertController.message = "输入的手机号格式不正确"
            presentViewController(alertController, animated: true, completion: nil)
            return
        }
        if password.isEmpty {
            alertController.message = "请输入密码"
            presentViewController(alertController, animated: true, completion: nil)
            return
        }
        if passwordConfirm.isEmpty {
            alertController.message = "请再次输入密码"
            presentViewController(alertController, animated: true, completion: nil)
            return
        }
        if verifyCode.isEmpty {
            alertController.message = "请输入验证码"
            presentViewController(alertController, animated: true, completion: nil)
            return
        }
        if password != passwordConfirm {
            alertController.message = "两次输入的密码不匹配"
            presentViewController(alertController, animated: true, completion: nil)
            return
        }
        presentViewController(R.storyboard.main.kTabBarController()!, animated: true, completion: nil)
    }
    
    func textFieldDidChange(textField: UITextField) {
        switch textField.tag {
        case 0:
            phoneNumber = textField.text!
            break
        case 1:
            password = textField.text!
            break
        case 2:
            passwordConfirm = textField.text!
            break
        case 3:
            verifyCode = textField.text!
            break
        default:
            break
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    deinit {
        print("RegisterViewController deinit")
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
