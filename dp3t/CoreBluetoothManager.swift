//
//  CoreBluetoothManager.swift
//  dp3t
//
//  Created by Jatin Mathur on 8/11/20.
//  Copyright © 2020 Jatin Mathur. All rights reserved.
//

import Foundation
import CoreBluetooth

// defines an encounter with another device
struct DeviceEncounter {
    var ID: String // 26 byte identifier
    var distance: NSNumber // RSSI distance
}

protocol BluetoothManagerDelegate: AnyObject {
    func peripheralsDidUpdate()
}

protocol BluetoothManager {
    var deviceEncounters: Dictionary<String, [DeviceEncounter]> { get }
    var delegate: BluetoothManagerDelegate? { get set }
    func startAdvertising(with name: String)
    func startScanning()
}

class CoreBluetoothManager: NSObject, BluetoothManager {
    // MARK: - Public properties
    weak var delegate: BluetoothManagerDelegate?
    private(set) var deviceEncounters = Dictionary<String, [DeviceEncounter]>() {
        didSet {
            delegate?.peripheralsDidUpdate()
        }
    }

    // MARK: - Public methods
    func startAdvertising(with name: String) {
        print("trying to advertise")
        self.name = name
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        print("advertising")
    }
    
    func startScanning() {
        print("trying to scan")
        centralManager = CBCentralManager(delegate: self, queue: nil)
        print("scanning")
    }

    // MARK: - Private properties
    private var peripheralManager: CBPeripheralManager?
    private var centralManager: CBCentralManager?
    private var name: String?
}

extension CoreBluetoothManager: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        print("updated peripheral state")
        if peripheral.state == .poweredOn {
            print("powered on peripheral")
            if peripheral.isAdvertising {
                peripheral.stopAdvertising()
            }
            let uuid = CBUUID(string: Constants.SERVICE_UUID.rawValue)
            var advertisingData: [String : Any] = [
                CBAdvertisementDataServiceUUIDsKey: [uuid]
            ]
            advertisingData[CBAdvertisementDataLocalNameKey] = name
            self.peripheralManager?.startAdvertising(advertisingData)
        } else {
            #warning("handle other states")
        }
    }
}

extension CoreBluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("updated central state")
        if central.state == .poweredOn {
             print("powered on central manager")
            if central.isScanning {
                central.stopScan()
            }
            let uuid = CBUUID(string: Constants.SERVICE_UUID.rawValue)
            central.scanForPeripherals(withServices: [uuid])
        } else {
            #warning("Error handling")
        }
    }
    
    // called every time the device encounters someone
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        for (k,_) in deviceEncounters {
            print("KEY: " + k)
        }
        let otherID = advertisementData[CBAdvertisementDataLocalNameKey] as? String
        if otherID != nil {
            print("advertising data id: " + otherID!)
            let de = DeviceEncounter(ID: otherID!, distance: RSSI)
            let time = dateToCoarseTime(date: Date())
            if deviceEncounters[time] != nil {
                // add to existing list
                var existingEncounters = deviceEncounters[time]
                existingEncounters!.append(de)
                print("inserted into existing list")
            } else {
                // create the key and list
                let initialList: [DeviceEncounter] = [de]
                deviceEncounters[time] = initialList
                print("created new list")
            }
        } else {
            print("advertising data id: nil")
        }
    }
}

// turns date into a coarse time Y/M/D
func dateToCoarseTime(date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy/MM/dd"
    return formatter.string(from: date)
}

