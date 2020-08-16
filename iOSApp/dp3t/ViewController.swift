//
//  ViewController.swift
//  dp3t
//
//  Created by Jatin Mathur on 8/11/20.
//  Copyright © 2020 Jatin Mathur. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    var bluetoothManager: CoreBluetoothManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        bluetoothManager = CoreBluetoothManager()
        
        // generate this randomly, remove dashes for conciseness
        // can only do 26 bytes
        let name = "1F5B29BF17254A85BD64D91889"
        bluetoothManager.startAdvertising(with: name)
        bluetoothManager.startScanning()
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
}

