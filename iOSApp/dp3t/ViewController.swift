//
//  ViewController.swift
//  Test
//
//  Created by Ishaan Mathur on 8/10/20.
//  Copyright © 2020 Mathur. All rights reserved.
//

import UIKit
import CryptoKit
import CryptoSwift
import Foundation

class ViewController: UIViewController, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource {

    @IBOutlet weak var matchesLabel: UILabel!
    @IBOutlet weak var authorizationTextField: UITextField!
    @IBOutlet weak var infectionDayButton: UIButton!
    @IBOutlet weak var submitButton: UIButton!
    
    var infectionDayToolbar = UIToolbar()
    var infectionDayPicker  = UIPickerView()
    var infectionDays: [String] = [String]()
    
    var dp3t: DP3T?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
 
        authorizationTextField.delegate = self
        infectionDayButton.addTarget(self, action: #selector(showInfectionPicker), for: .touchUpInside)
        submitButton.addTarget(self, action: #selector(submit), for: .touchUpInside)
        submitButton.layer.cornerRadius = 7.5
        
        infectionDays = ["Today", "1 Day Ago"]
        for day in 2..<Config.infectionPeriod {
            infectionDays.append(String(day) + " Days Ago")
        }
        
        
        DP3T.resetDefaults()
        dp3t = DP3T(date: Date(), viewController: self)
        dp3t?.getInfectedUsers()
    }
    
    func sendSKt(index: Int) {
        let storedSKts = dp3t!.getStoredSKts()
        if storedSKts.count != 0 {
            var data = [String]()
            if index < storedSKts.count {
                data = storedSKts[index]
            } else {
                data = storedSKts[0]
            }
            
            let parameters = ["user_id": data[0], "date": data[1]]
            let session = URLSession.shared
            let url = URL(string: "http://192.168.1.8:5000/report_infected_user")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            let jsonData = try? JSONSerialization.data(withJSONObject: parameters)
            request.httpBody = jsonData

            let task = session.dataTask(with: request, completionHandler: { data, response, error in
                guard let data = data else {
                    return
                }
                
                let json = String(data: data, encoding: .utf8)
                print(json!)
            })
            task.resume()
        }

    }
    
    @objc func showInfectionPicker(_ sender: UIButton) {
        infectionDayPicker = UIPickerView.init()
        infectionDayPicker.delegate = self
        infectionDayPicker.backgroundColor = UIColor.black
        infectionDayPicker.setValue(UIColor.white, forKey: "textColor")
        infectionDayPicker.autoresizingMask = .flexibleWidth
        infectionDayPicker.contentMode = .center
        infectionDayPicker.frame = CGRect.init(x: 0.0, y: UIScreen.main.bounds.size.height - 300, width: UIScreen.main.bounds.size.width, height: 300)
        self.view.addSubview(infectionDayPicker)

        infectionDayToolbar = UIToolbar.init(frame: CGRect.init(x: 0.0, y: UIScreen.main.bounds.size.height - 300, width: UIScreen.main.bounds.size.width, height: 50))
        infectionDayToolbar.barStyle = .black
        infectionDayToolbar.items = [UIBarButtonItem.init(title: "Done", style: .done, target: self, action: #selector(infectionDayDone))]
        self.view.addSubview(infectionDayToolbar)
    }
    
    @objc func infectionDayDone() {
        infectionDayButton.setTitle(infectionDays[infectionDayPicker.selectedRow(inComponent: 0)], for: .normal)
        infectionDayToolbar.removeFromSuperview()
        infectionDayPicker.removeFromSuperview()
    }
    
    @objc func submit(_ sender: UIButton) {
        CATransaction.begin()
        CATransaction.setCompletionBlock({
            let infectionDaysAgo = self.infectionDayButton.currentTitle
            if infectionDaysAgo != "Choose" {
                var index = 0;
                if infectionDaysAgo != "Today" {
                    index = Int(String(infectionDaysAgo!.split(separator: " ")[0]))!
                }
                index = Config.infectionPeriod - 1 - index
                self.sendSKt(index: index)
            }
        })
        let pulse = CASpringAnimation(keyPath: "transform.scale")
        pulse.duration = 0.15
        pulse.fromValue = 1.0
        pulse.toValue = 0.9
        pulse.autoreverses = true
        pulse.initialVelocity = 0.5
        pulse.damping = 0.8
        sender.layer.add(pulse, forKey: "pulse")
        CATransaction.commit()
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let allowedCharacters = CharacterSet.decimalDigits
        let characterSet = CharacterSet(charactersIn: string)
        
        guard let textFieldText = textField.text,
            let rangeOfTextToReplace = Range(range, in: textFieldText) else {
                return false
        }
        let substringToReplace = textFieldText[rangeOfTextToReplace]
        let count = textFieldText.count - substringToReplace.count + string.count
        
        return allowedCharacters.isSuperset(of: characterSet) && count <= Config.authorizationCodeLength
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return infectionDays.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return infectionDays[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        infectionDayButton.setTitle(infectionDays[row], for: .normal)
    }
}

extension ViewController: UNUserNotificationCenterDelegate {

    //for displaying notification when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {

        completionHandler([.alert, .badge, .sound])
    }

}
