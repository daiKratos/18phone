//
//  EditUserViewController.swift
//  18phone
//
//  Created by Kratos on 9/25/16.
//  Copyright © 2016 Kratos. All rights reserved.
//

import UIKit
import MobileCoreServices

class EditUserViewController: UITableViewController, UITextFieldDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, NJImageCropperDelegate {
    
    var lastScrollOffset: CGFloat = 0.0
    
    let ORIGINAL_MAX_WIDTH: CGFloat = 640.0
    
    var userID: String?
    
    var age = -1
    
    var sex = Sex.unknown.rawValue
    
    let headPhotoImage = R.image.head_photo_default()
    
    var userData: UserData?
    
    //    var userInfo = [String: Any]()
    
    @IBOutlet weak var headPhoto: UIImageView!
    
    @IBOutlet weak var nameField: UITextField!
    
    @IBOutlet weak var sexLabel: UILabel!
    
    @IBOutlet weak var ageLabel: UILabel!
    
    @IBOutlet weak var areaLabel: UILabel!
    
    @IBOutlet weak var signField: UITextField!
    
    @IBOutlet weak var addressField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
        if userData?.headImageUrl != nil {
            headPhoto.piQ_imageFromUrl(userData!.headImageUrl!, placeholderImage: headPhotoImage!)
        } else {
            headPhoto.image = headPhotoImage
        }
        if userData != nil {
            if userData?.name != nil {
                nameField.text = userData?.name
            }
            if userData?.sex == Sex.male.rawValue {
                sexLabel.text = "男"
            } else if userData?.sex == Sex.female.rawValue {
                sexLabel.text = "女"
            }
            if userData?.provinceCity != nil {
                areaLabel.text = userData?.provinceCity
            }
            if userData?.personalSignature != nil {
                signField.text = userData?.personalSignature
            }
            if userData!.age! != -1 {
                ageLabel.text = "\(userData!.age!)岁"
            }
            age = userData!.age!
            sex = userData!.sex!
        }
        nameField.delegate = self
        signField.delegate = self
        addressField.delegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 7
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let cell = tableView.cellForRow(at: indexPath)
        hideKeyBoard()
        let sexChoices = ["男", "女"]
        switch indexPath.row {
        case 0:
            Async.main {
                self.headphotoSheet()
            }
            break
        case 2:
            ActionSheetStringPicker.show(withTitle: "", rows: sexChoices, initialSelection: 0, doneBlock: { picker, selectedIndex, selectedValue in
                self.sex = selectedIndex + 1
                self.sexLabel.text = sexChoices[selectedIndex]
            }, cancel: { _ in
                
            }, origin: cell)
            break
        case 3:
            ActionSheetDatePicker.show(withTitle: "生日", datePickerMode: .date, selectedDate: Date(), doneBlock: { picker, selectedValue, selectedIndex in
                let birthday = selectedValue as! Date
                if birthday > Date() {
                    print("")
                }
                self.age = DateUtil.getAgeFromBirthday((birthday))
                self.ageLabel.text =  "\(self.age)岁"
            }, cancel: { _ in
                
            }, origin: cell)
            break
        case 4:
            let areaPicker = SelectView(zgqFrame: Screen.bounds, selectCityTtitle: "地区")
            areaPicker?.showCityView({ province, city, district in
                let provinceStr = province![province!.startIndex..<province!.index(province!.endIndex, offsetBy: -1)]
                let cityStr = city![city!.startIndex..<city!.index(city!.endIndex, offsetBy: -1)]
                switch provinceStr {
                case "北京", "上海", "天津", "重庆":
                    self.areaLabel.text = provinceStr
                    break
                default:
                    self.areaLabel.text = provinceStr + cityStr
                    break
                }
            })
            break
        default:
            break
        }
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == tableView {
            let y = scrollView.contentOffset.y
            if y < lastScrollOffset {
                hideKeyBoard()
            }
            lastScrollOffset = y
        }
    }
    
    @IBAction func save(_ sender: UIBarButtonItem) {
        if nameField.text!.characters.count > 6 {
            let alertController = UIAlertController(title: nil, message: "姓名不能超过6个字符", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "好的", style: .default, handler: nil)
            alertController.addAction(okAction)
            present(alertController, animated: true, completion: nil)
            return
        }
        var userInfo = [String:Any]()
        userInfo["UserID"] = userID
        userInfo["Sex"] = "\(sex)"
        userInfo["Name"] = nameField.text!
        userInfo["Age"] = "\(age)"
        userInfo["ProvinceCity"] = areaLabel.text!
        userInfo["AddressDetail"] = addressField.text!
        userInfo["PersonalSignature"] = signField.text!
        var imageUrl: URL?
        if headPhoto.image != nil && headPhoto.image != headPhotoImage {
            let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
            let filePath = paths[0].appending("/\(userID!).jpeg")
            imageUrl = URL(fileURLWithPath: filePath)
            do {
                try UIImageJPEGRepresentation(headPhoto.image!, 1.0)?.write(to: imageUrl!)
            }catch {
                print("got an error write: \(error)")
            }
            userInfo["HeadPhotoImage"] = Upload(fileUrl: imageUrl!)
        }
        APIUtil.editUserInfo(userInfo, callBack: { editUser in
            SwiftEventBus.post("reloadUserInfo")
            _ = self.navigationController?.popViewController(animated: true)
        })
    }
    
    @IBAction func editHeadphoto(_ sender: UITapGestureRecognizer) {
        headphotoSheet()
    }
    
    // MARK: - camera utility
    
    func isCameraAvailable() -> Bool {
        return UIImagePickerController.isSourceTypeAvailable(.camera)
    }
    
    func isFrontCameraAvailable() -> Bool {
        return UIImagePickerController.isCameraDeviceAvailable(.front)
    }
    
    func isPhotoLibraryAvailable() -> Bool {
        return UIImagePickerController.isSourceTypeAvailable(.photoLibrary)
    }
    
    func cameraSupportsMedia(_ paramMediaType: String, sourceType: UIImagePickerControllerSourceType) -> Bool {
        var result = false
        if paramMediaType.isEmpty {
            return false
        }
        let availableMediaTypes = UIImagePickerController.availableMediaTypes(for: sourceType)
        for (_, mediaType) in availableMediaTypes!.enumerated() {
            if mediaType == paramMediaType {
                result = true
                break
            }
        }
        
        return result
    }
    
    func doesCameraSupportTakingPhotos() -> Bool {
        return cameraSupportsMedia(kUTTypeImage as String, sourceType: .camera)
    }
    
    // MARK: - image scale utility
    
    func imageByScalingToMaxSize(_ sourceImage: UIImage) -> UIImage? {
        if sourceImage.size.width < ORIGINAL_MAX_WIDTH {
            return sourceImage
        }
        var btWidth: CGFloat = 0.0
        var btHeight: CGFloat = 0.0
        if sourceImage.size.width > sourceImage.size.height {
            btHeight = ORIGINAL_MAX_WIDTH
            btWidth = sourceImage.size.width * (ORIGINAL_MAX_WIDTH / sourceImage.size.height)
        } else {
            btWidth = ORIGINAL_MAX_WIDTH
            btHeight = sourceImage.size.height * (ORIGINAL_MAX_WIDTH / sourceImage.size.width)
        }
        let targetSize = CGSize(width: btWidth, height: btHeight)
        return imageByScalingAndCroppingForSourceImage(sourceImage, targetSize: targetSize)
    }
    
    func imageByScalingAndCroppingForSourceImage(_ sourceImage: UIImage, targetSize: CGSize) -> UIImage? {
        var newImage: UIImage? = nil
        let imageSize = sourceImage.size
        let width = imageSize.width
        let height = imageSize.height
        let targetWidth = targetSize.width
        let targetHeight = targetSize.height
        var scaleFactor: CGFloat = 0.0
        var scaledWidth = targetWidth
        var scaledHeight = targetHeight
        var thumbnailPoint = CGPoint(x: 0.0,y: 0.0)
        if !imageSize.equalTo(targetSize)
        {
            let widthFactor = targetWidth / width
            let heightFactor = targetHeight / height
            
            if widthFactor > heightFactor {
                scaleFactor = widthFactor // scale to fit height
            } else {
                scaleFactor = heightFactor // scale to fit width
            }
            
            scaledWidth  = width * scaleFactor
            scaledHeight = height * scaleFactor
            
            // center the image
            if widthFactor > heightFactor
            {
                thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5
            }
            else if widthFactor < heightFactor {
                thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5
            }
        }
        UIGraphicsBeginImageContext(targetSize) // this will crop
        var thumbnailRect = CGRect.zero
        thumbnailRect.origin = thumbnailPoint
        thumbnailRect.size.width  = scaledWidth
        thumbnailRect.size.height = scaledHeight
        
        sourceImage.draw(in: thumbnailRect)
        newImage = UIGraphicsGetImageFromCurrentImageContext()
        if newImage == nil {
            print("could not scale image")
        }
        
        //pop the context to get back to the default
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    func headphotoSheet() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "拍照", style: .default) { action in
            if self.isCameraAvailable() && self.doesCameraSupportTakingPhotos() {
                let controller = UIImagePickerController()
                controller.sourceType = .camera
                if self.isFrontCameraAvailable() {
                    controller.cameraDevice = .front
                }
                controller.mediaTypes = [kUTTypeImage as String]
                controller.delegate = self
                self.present(controller, animated: true, completion: nil)
            }
        })
        alertController.addAction(UIAlertAction(title: "相册", style: .default) { action in
            if self.isPhotoLibraryAvailable() {
                let controller = UIImagePickerController()
                controller.sourceType = .photoLibrary
                controller.mediaTypes = [kUTTypeImage as String]
                controller.delegate = self
                self.present(controller, animated: true, completion: nil)
            }
        })
        alertController.addAction(UIAlertAction(title: "取消", style: .cancel) { action in
            
        })
        present(alertController, animated: true, completion: nil)
    }
    
    func hideKeyBoard() {
        if nameField.isFirstResponder {
            nameField.resignFirstResponder()
        }
        if signField.isFirstResponder {
            signField.resignFirstResponder()
        }
        if addressField.isFirstResponder {
            addressField.resignFirstResponder()
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // MARK: - UIImagePickerControllerDelegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion: {
            var portraitImg = info["UIImagePickerControllerOriginalImage"] as! UIImage
            portraitImg = self.imageByScalingToMaxSize(portraitImg)!
            let imgEditorVC = NJImageCropperViewController(image: portraitImg, cropFrame: CGRect(x: 0.0, y: 100.0, width: Screen.width, height: Screen.width) , limitScaleRatio: 3)
            imgEditorVC?.delegate = self
            self.present(imgEditorVC!, animated: true, completion: nil)
        })
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - VPImageCropperDelegate
    
    func imageCropper(_ cropperViewController: NJImageCropperViewController!, didFinished editedImage: UIImage!) {
        headPhoto.image = editedImage
        cropperViewController.dismiss(animated: true, completion: nil)
    }
    
    func imageCropperDidCancel(_ cropperViewController: NJImageCropperViewController!) {
        cropperViewController.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - UINavigationControllerDelegate
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        
    }
    
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        
    }
}
