//
//  CoreBluetoothManager.swift
//  dp3t
//
//  Created by Jatin Mathur on 8/11/20.
//  Copyright © 2020 Jatin Mathur. All rights reserved.
//

import Foundation
import CoreBluetooth

protocol BluetoothManagerDelegate: AnyObject {
    func peripheralsDidUpdate()
}

protocol BluetoothManager {
    var peripherals: Dictionary<UUID, CBPeripheral> { get }
    var delegate: BluetoothManagerDelegate? { get set }
    func startAdvertising(with name: String)
    func startScanning()
}

class CoreBluetoothManager: NSObject, BluetoothManager {
    // MARK: - Public properties
    weak var delegate: BluetoothManagerDelegate?
    private(set) var peripherals = Dictionary<UUID, CBPeripheral>() {
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

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        peripherals[peripheral.identifier] = peripheral
        print("got peripheral: " + peripheral.identifier.uuidString)
        let local = advertisementData[CBAdvertisementDataLocalNameKey] as? String
        if local != nil {
            print("advertising data name: " + local!)
        } else {
            print("advertising data name: nil")
        }
    }
}
