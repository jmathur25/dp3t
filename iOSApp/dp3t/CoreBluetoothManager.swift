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

// defines an encounter with another device
struct DeviceEncounter {
    var ID: String // 26 byte identifier
    var distance: NSNumber // RSSI distance
}

extension DeviceEncounter: Hashable {
    static func == (lhs: DeviceEncounter, rhs: DeviceEncounter) -> Bool {
        return lhs.ID == rhs.ID
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(ID)
    }
}


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
    private var deviceEncounterKnownKey = "device_encounter_known_dict"
    private var deviceEncounterUnknownKey = "device_encounter_unknown_dict"
    
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
    func getEncounterKnownDict() -> Dictionary<String, Set<DeviceEncounter>> {
        return UserDefaults.standard.value(forKey: deviceEncounterKnownKey) as! Dictionary<String, Set<DeviceEncounter>>
    }
    // returns the dict of unknown encounters saved on disk
    func getEncounterUnKnownDict() -> Dictionary<String, Int> {
        return UserDefaults.standard.value(forKey: deviceEncounterUnknownKey) as! Dictionary<String, Int>
    }
    // update the dict of known encounters saved on disk
    func updateEncounterKnownDict(newDict: Dictionary<String, Set<DeviceEncounter>>) {
        return UserDefaults.standard.set(newDict, forKey: deviceEncounterKnownKey)
    }
    // update the dict of unknown encounters saved on disk
    func updateEncounterUnKnownDict(newDict: Dictionary<String, Int>) {
        return UserDefaults.standard.set(newDict, forKey: deviceEncounterUnknownKey)
    }
    // return a set of encountered ids on a day
    func getEncounteredEphIdsOnDay(date: Date) -> Set<String>? {
        let deviceEncounterKnown = getEncounterKnownDict()
        let time = dateToCoarseTime(date: date)
        let dayEncounters = deviceEncounterKnown[time]
        if dayEncounters == nil {
            return nil
        }
        var dayEncountersID: Set<String> = []
        for de in dayEncounters! {
            dayEncountersID.insert(de.ID)
        }
        return dayEncountersID
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
        var deviceEncounterKnown = getEncounterKnownDict()
        var deviceEncounterUnKnown = getEncounterUnKnownDict()
        let otherID = advertisementData[CBAdvertisementDataLocalNameKey] as? String
        if otherID != nil {
            print("advertising data id: " + otherID!)
            let de = DeviceEncounter(ID: otherID!, distance: RSSI)
            let time = dateToCoarseTime(date: Date())
            if deviceEncounterKnown[time] != nil {
                // add to existing list
                var existingEncounters = deviceEncounterKnown[time]
                existingEncounters!.insert(de)
                print("inserted into existing list")
            } else {
                // create the key and list
                let initialSet: Set<DeviceEncounter> = [de]
                deviceEncounterKnown[time] = initialSet
                deviceEncounterKnown.removeValue(forKey: time)
                print("created new list")
            }
        } else {
            print("advertising data id: nil")
            let time = dateToCoarseTime(date: Date())
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
        let lastOkDate = Calendar.current.date(byAdding: daySub, to: Date())
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
