//
//  CoreBluetoothManager.swift
//  dp3t
//
//  Created by Jatin Mathur on 8/11/20.
//  Copyright © 2020 Jatin Mathur. All rights reserved.
//

import UIKit
import Foundation
import CoreBluetooth


protocol BluetoothManagerDelegate: AnyObject {
    func peripheralsDidUpdate()
}

protocol BluetoothManager {
    var delegate: BluetoothManagerDelegate? { get set }
    func startAdvertising(with name: String)
    func startScanning()
}

class CoreBluetoothManager: NSObject, BluetoothManager {
    // MARK: - Public properties
    weak var delegate: BluetoothManagerDelegate?
    
    init(dateManager: DateManager) {
        dateHandler = dateManager
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
    private var deviceEncounterKnownKey = "device_encounter_known_dict"
    private var deviceEncounterUnknownKey = "device_encounter_unknown_dict"
    private var dateHandler: DateManager // helps with mocking time
}

extension CoreBluetoothManager: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        print("updated peripheral state")
        if peripheral.state == .poweredOn {
            print("powered on peripheral")
            if peripheral.isAdvertising {
                peripheral.stopAdvertising()
            }
            let uuid = CBUUID(string: ConstantsString.SERVICE_UUID.rawValue)
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
    // returns the dict of known encounters saved on disk
    func getEncounterKnownDict() -> Dictionary<String, Array<String>> {
        let dict = UserDefaults.standard.value(forKey: deviceEncounterKnownKey) as? Dictionary<String, Array<String>>
        if dict == nil {
            // dict does not exist
            return [:]
        }
        return dict!
    }
    // returns the dict of unknown encounters saved on disk
    func getEncounterUnKnownDict() -> Dictionary<String, Int> {
        var dict = UserDefaults.standard.value(forKey: deviceEncounterUnknownKey) as? Dictionary<String, Int>
        if dict == nil {
            // create the dictionary because it does not exist
            dict = [:]
        }
        return dict!
    }
    // update the dict of known encounters saved on disk
    func updateEncounterKnownDict(newDict: Dictionary<String, Array<String>>) {
        UserDefaults.standard.set(newDict, forKey: deviceEncounterKnownKey)
    }
    // update the dict of unknown encounters saved on disk
    func updateEncounterUnKnownDict(newDict: Dictionary<String, Int>) {
        return UserDefaults.standard.set(newDict, forKey: deviceEncounterUnknownKey)
    }
    // return a set of known encountered ids on a day
    func getKnownEncounteredEphIdsOnDay(date: Date) -> Set<String>? {
        let deviceEncounterKnown = getEncounterKnownDict()
        let time = dateToCoarseTime(date: date)
        let dayEncounters = deviceEncounterKnown[time]
        if dayEncounters == nil {
            return nil
        }
        var dayEncountersID: Set<String> = []
        for deID in dayEncounters! {
            dayEncountersID.insert(deID)
        }
        return dayEncountersID
    }
    // return the number of unknown encountered ids on a day
    func getUnknownEncounteredEphIdsOnDay(date: Date) -> Int {
        let deviceEncounterUnknown = getEncounterUnKnownDict()
        let time = dateToCoarseTime(date: date)
        let dayEncounters = deviceEncounterUnknown[time]
        if dayEncounters == nil {
            return 0
        }
        return dayEncounters!
    }
    // delete all daya
    func deleteAllKeys() {
        UserDefaults.standard.removeObject(forKey: deviceEncounterKnownKey)
        UserDefaults.standard.removeObject(forKey: deviceEncounterUnknownKey)
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("updated central state")
        if central.state == .poweredOn {
             print("powered on central manager")
            if central.isScanning {
                central.stopScan()
            }
            let uuid = CBUUID(string: ConstantsString.SERVICE_UUID.rawValue)
            central.scanForPeripherals(withServices: [uuid])
        } else {
            #warning("Error handling")
        }
    }
    
    // called every time the device encounters someone
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        handleDiscovery(advertisementData: advertisementData, rssi: RSSI)
    }
    
    func handleDiscovery(advertisementData: [String: Any], rssi RSSI: NSNumber) {
        var deviceEncounterKnown = getEncounterKnownDict()
        var deviceEncounterUnKnown = getEncounterUnKnownDict()
        let ephID = advertisementData[CBAdvertisementDataLocalNameKey] as? String
        if ephID != nil {
            print("advertising data id: " + ephID!)
            let time = dateToCoarseTime(date: dateHandler.currentDate())
            if deviceEncounterKnown[time] != nil {
                // add to existing list
                var existingEncounters = deviceEncounterKnown[time]
                existingEncounters!.append(ephID!)
                print("inserted into existing list")
            } else {
                // create the key and list
                let initialSet: Array<String> = [ephID!]
                deviceEncounterKnown[time] = initialSet
                print("created new list")
            }
        } else {
            print("advertising data id: nil")
            let time = dateToCoarseTime(date: dateHandler.currentDate())
            if deviceEncounterUnKnown[time] != nil {
                // add to existing list
                let existingEncounters = deviceEncounterUnKnown[time]
                deviceEncounterUnKnown[time] = existingEncounters! + 1
            } else {
                // create the key and value
                deviceEncounterUnKnown[time] = 1
            }
        }
        updateEncounterKnownDict(newDict: deviceEncounterKnown)
        updateEncounterUnKnownDict(newDict: deviceEncounterUnKnown)
    }
    
    // expires keys older than 14 days old
    func checkAndExpireOldKeys() {
        var deviceEncounterKnown = getEncounterKnownDict()
        var deviceEncounterUnKnown = getEncounterUnKnownDict()
        let daySub = DateComponents(day: -ConstantsInt.EXPIRE_DAYS.rawValue)
        let lastOkDate = Calendar.current.date(byAdding: daySub, to: dateHandler.currentDate())
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = ConstantsString.DATE_STR.rawValue
        
        // update known encounters
        var toDrop: [String] = [] // to remove
        for (k, _) in deviceEncounterKnown {
            let date = dateFormatter.date(from: k)
            if date! < lastOkDate! {
                toDrop.append(k)
            }
        }
        for k in toDrop {
            deviceEncounterKnown.removeValue(forKey: k)
        }
        
        // update unknown encounters
        toDrop = [] // to remove
        for (k, _) in deviceEncounterUnKnown {
            let date = dateFormatter.date(from: k)
            if date! < lastOkDate! {
                toDrop.append(k)
            }
        }
        for k in toDrop {
            deviceEncounterUnKnown.removeValue(forKey: k)
        }
        updateEncounterKnownDict(newDict: deviceEncounterKnown)
        updateEncounterUnKnownDict(newDict: deviceEncounterUnKnown)
    }
}

// turns date into a coarse time YYYY-MM-DD
func dateToCoarseTime(date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = ConstantsString.DATE_STR.rawValue
    return formatter.string(from: date)
}
