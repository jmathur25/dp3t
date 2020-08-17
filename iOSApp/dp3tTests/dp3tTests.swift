//
//  dp3tTests.swift
//  dp3tTests
//
//  Created by Jatin Mathur on 8/11/20.
//  Copyright © 2020 Jatin Mathur. All rights reserved.
//

import CoreBluetooth
import XCTest
@testable import dp3t

class dp3tTests: XCTestCase {

    var bluetoothManager: CoreBluetoothManager!
    // June 10 2020 at 14:00 UTC
    var mockedStartDate:Date! = Date(timeIntervalSince1970: 1591797600)
    // June 25 2020 at 14:00 UTC
    var mockedEndDate:Date! = Date(timeIntervalSince1970: 1593093600)
    // mock date handler
    var mockDateHandler = MockDateHandler()
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        mockDateHandler.setDate(date: mockedEndDate)
        bluetoothManager = CoreBluetoothManager(dateManager: mockDateHandler as DateManager)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        bluetoothManager.deleteAllKeys()
    }

    func testHandleEncounterKnown() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let fakeEphId = "aaaaaaaaaaaaaaaaaaaaaaaaaa"
        let advertisementData: [String : Any] = [CBAdvertisementDataLocalNameKey: fakeEphId]
        let rssi = NSNumber(integerLiteral: -50)
        bluetoothManager.handleDiscovery(advertisementData: advertisementData, rssi: rssi)
        
        let encounterKnown = bluetoothManager.getKnownEncounteredEphIdsOnDay(date: mockedEndDate)
        XCTAssertNotNil(encounterKnown)
        let encounterExpected: Set<String> = [fakeEphId]
        XCTAssert(encounterKnown!.elementsEqual(encounterExpected))
        
        let noEncounter = bluetoothManager.getKnownEncounteredEphIdsOnDay(date: mockedStartDate)
        XCTAssertNil(noEncounter)
    }
    
    func testHandleEncounterUnKnown() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let advertisementData: [String : Any] = [:]
        let rssi = NSNumber(integerLiteral: -50)
        bluetoothManager.handleDiscovery(advertisementData: advertisementData, rssi: rssi)
        let encounterUnknowns = bluetoothManager.getUnknownEncounteredEphIdsOnDay(date: mockedEndDate)
        XCTAssertTrue(encounterUnknowns == 1)
        let noEncounterUnknowns = bluetoothManager.getUnknownEncounteredEphIdsOnDay(date: mockedStartDate)
        XCTAssertTrue(noEncounterUnknowns == 0)
    }
    
    func testExpireOldKeys() throws {
        var fakeEphId = "aaaaaaaaaaaaaaaaaaaaaaaaaa"
        var advertisementData: [String : Any] = [CBAdvertisementDataLocalNameKey: fakeEphId]
        let rssi = NSNumber(integerLiteral: -50)
        bluetoothManager.handleDiscovery(advertisementData: advertisementData, rssi: rssi)
        
        // meet a different id, but earlier in time (outside window)
        fakeEphId = "baaaaaaaaaaaaaaaaaaaaaaaaa"
        advertisementData = [CBAdvertisementDataLocalNameKey: fakeEphId]
        mockDateHandler.setDate(date: mockedStartDate)
        bluetoothManager.handleDiscovery(advertisementData: advertisementData, rssi: rssi)
        
        // reset to current date
        mockDateHandler.setDate(date: mockedEndDate)
        bluetoothManager.checkAndExpireOldKeys()
        
        let encounterKnown = bluetoothManager.getKnownEncounteredEphIdsOnDay(date: mockedEndDate)
        XCTAssertNotNil(encounterKnown)
        let encounterExpected: Set<String> = ["aaaaaaaaaaaaaaaaaaaaaaaaaa"]
        XCTAssert(encounterKnown!.elementsEqual(encounterExpected))
        
        // should be no wiped
        let noEncounter = bluetoothManager.getKnownEncounteredEphIdsOnDay(date: mockedStartDate)
        XCTAssertNil(noEncounter)
    }

}
