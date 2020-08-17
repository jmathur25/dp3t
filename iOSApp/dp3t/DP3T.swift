//
//  DP3T.swift
//  Test
//
//  Created by Ishaan Mathur on 8/15/20.
//  Copyright © 2020 Mathur. All rights reserved.
//

import Foundation
import CryptoKit
import CryptoSwift

class DP3T {
    
    private var date: Date
    private var calendar: Calendar
    
    private var viewController: ViewController?
    
    // setup bluetooth
    var bluetoothManager: CoreBluetoothManager?
    
    init(date: Date, viewController: ViewController? = nil) {
        self.date = date
        self.calendar = Calendar.current
        self.calendar.timeZone = TimeZone(abbreviation: "UTC")!
        self.viewController = viewController
        self.bluetoothManager = CoreBluetoothManager()
        self.bluetoothManager?.startScanning()
        
        updateSKtsAndEphIDs()
        updateCurrentEphID()
    }
    
    static func resetDefaults() {
        let defaults = UserDefaults.standard
        let dictionary = defaults.dictionaryRepresentation()
        dictionary.keys.forEach { key in
            defaults.removeObject(forKey: key)
        }
    }
    
    func getStoredSKts() -> [[String]] {
        return UserDefaults.standard.array(forKey: "storedSKts") as? [[String]] ?? []
    }
    
    func getStoredEphIDs() -> [Any] {
        return UserDefaults.standard.array(forKey: "storedEphIDs") ?? [Any]()
    }
    
    func getStoredDay() -> Int {
        return UserDefaults.standard.integer(forKey: "storedDay")
    }
    
    func getCurrentSKt() -> String {
        return UserDefaults.standard.string(forKey: "currentSKt") ?? ""
    }
    
    func getCurrentEphID() -> String {
        return UserDefaults.standard.string(forKey: "currentEphID") ?? ""
    }
    
    func getCurrentDay() -> Int {
        return Int(date.timeIntervalSinceReferenceDate) / (60 * 60 * 24)
    }
    
    func getMatches() -> Int {
        return UserDefaults.standard.integer(forKey: "matches")
    }
    // recreate a new SKt when the old one has been reported
    func recreateSkt() {
        // wipe data related to old SKT
        UserDefaults.standard.set([], forKey: "storedSKts")
        UserDefaults.standard.set("", forKey: "currentSKt")
        UserDefaults.standard.set(0, forKey: "storedDay")
        // create new SKT and Eph IDs
        updateSKtsAndEphIDs()
        updateCurrentEphID()
    }
    
    func getStartOfNextDay() -> Date {
        var tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!
        tomorrow = calendar.date(bySettingHour: 0, minute: 0, second: 1, of: tomorrow)!
        return tomorrow
    }
    
    func getNextEpoch() -> Date {
        let currentDate = Date()
        
        let hours = calendar.component(.hour, from: currentDate)
        let minutes = calendar.component(.minute, from: currentDate)
        let seconds = calendar.component(.second, from: currentDate)
        var currentEpoch = Double(hours * 60 + minutes)
        currentEpoch += Double(seconds) / 60
        currentEpoch /= Double(Config.EPOCHLENGTH)

        let secondsToNext = (floor(currentEpoch + 1) - currentEpoch) * Double(Config.EPOCHLENGTH) * 60
        let nextDate = currentDate.addingTimeInterval(secondsToNext)
        let nextHours = calendar.component(.hour, from: nextDate)
        let nextMinutes = calendar.component(.minute, from: nextDate)
        return calendar.date(bySettingHour: nextHours, minute: nextMinutes, second: 1, of: nextDate)!
    }
    
    @objc private func updateSKtsAndEphIDs() {
        var storedSKts = getStoredSKts()
        var storedDay = getStoredDay()
        var currentSKt = getCurrentSKt()
        let currentDay = getCurrentDay()

        if storedDay == 0 {
            storedDay = currentDay - 1
        } else if storedDay == currentDay {
            // return out because current day Skt and EphId have been made
            return
        }
        
        // go from last stored day + 1 to current day
        // ex: user last opened on the 100th day and today is 105 (from Jan 1 2001)
        // this would go from 101 to 105 and update Skt
        for day in storedDay + 1..<currentDay + 1 {
            currentSKt = SKtGeneration(previousSKt: currentSKt)
            var dayString = Date(timeIntervalSinceReferenceDate: Double(day * 24 * 60 * 60)).description
            dayString = String(dayString.split(separator: " ")[0])

            storedSKts.append([currentSKt, dayString])
            if storedSKts.count > Config.INFECTIONPERIOD {
                storedSKts.removeFirst()
            }
        }
        
        // now generate today eph ids
        let storedEphIDs = ephIDGeneration(SKt: currentSKt, broadcastKey: Config.BROADCASTKEY, epochLength: Config.EPOCHLENGTH)
        UserDefaults.standard.set(storedSKts, forKey: "storedSKts")
        UserDefaults.standard.set(storedEphIDs, forKey: "storedEphIDs")
        UserDefaults.standard.set(currentDay, forKey: "storedDay")
        UserDefaults.standard.set(currentSKt, forKey: "currentSKt")
        
        print("Current SKT: \(getCurrentSKt())")

//        let timer = Timer(fireAt: getStartOfNextDay(), interval: 0, target: self, selector: #selector(updateSKtsAndEphIDs), userInfo: nil, repeats: false)
//        RunLoop.main.add(timer, forMode: RunLoop.Mode.common)
    }
    
    @objc private func updateCurrentEphID() {
        let storedEphIDs = getStoredEphIDs()

        let hours = calendar.component(.hour, from: date)
        let minutes = calendar.component(.minute, from: date)
        
        let currentEpoch = (hours * 60 + minutes) / Config.EPOCHLENGTH
        if currentEpoch < storedEphIDs.count {
            let currentEphID = storedEphIDs[currentEpoch]
            UserDefaults.standard.set(currentEphID, forKey: "currentEphID")
        }
        
        bluetoothManager?.startAdvertising(with: getCurrentEphID())
        
        print("Broadcasting current ephID: \(getCurrentEphID())")
        
         // run timer
        let timer = Timer(fireAt: getNextEpoch(), interval: 0, target: self, selector: #selector(updateCurrentEphID), userInfo: nil, repeats: false)
        RunLoop.main.add(timer, forMode: RunLoop.Mode.common)
    }
    
    
    private func SKtGeneration(previousSKt: String?) -> String {
        var previousSKt = previousSKt
        
        if previousSKt == nil || previousSKt == "" {
            previousSKt = UUID().uuidString
        }
        
        let hash = SHA256.hash(data: Data(previousSKt!.utf8)).description
        let startIndex = hash.index(hash.startIndex, offsetBy: 15)
        let endIndex = hash.index(hash.endIndex, offsetBy: 0)
        return String(hash[startIndex..<endIndex])
    }
    
    private func ephIDGeneration(SKt: String, broadcastKey: String, epochLength: Int) -> [String] {
        var PRF = try! HMAC(key: SKt, variant: .sha256).authenticate(broadcastKey.bytes).toHexString()
        let index = PRF.index(PRF.endIndex, offsetBy: -Config.EPH_ID_SIZE + 2)
        PRF = String(PRF[index..<PRF.endIndex])
        
        var ephIDs = [String]()
        for i in 0..<(60 * 24 / epochLength) {
            if i < 10 {
                ephIDs.append(PRF + "0" + String(i))
            } else {
                ephIDs.append(PRF + String(i))
            }
        }
        
        return ephIDs.shuffled()
    }
    
    public func getInfectedUsers() {
        let session = URLSession.shared
        let url = URL(string: "\(Config.SERVER_URL)/infected_users_list")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let task = session.dataTask(with: request, completionHandler: { data, response, error in
            guard let data = data, error == nil else { return }

            do {
                let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [Any]
                self.ephIDReconstruction(json: json)
            } catch {
                print(error)
            }
        })
        task.resume()
    }
    
    private func ephIDReconstruction(json: [Any]) {
        var matches = 0
        let formatter = DateFormatter()
        formatter.dateFormat = Config.DATE_STR
        
        print("all recorded ids: \(String(describing: bluetoothManager?.getEncounterKnownDict()))")
        for data in json {
             if let str = data as? String {
                let dict = str.toDictionary()
                var user_SKt = dict["user_id"] as! String
                let user_date = dict["date"] as! String
                
                let formattedDate = formatter.date(from: user_date)!
                let diffInDays = calendar.dateComponents([.day], from: formattedDate, to: date).day
                
                for day in 0..<diffInDays! + 1 {
                    let newDate = calendar.date(byAdding: .day, value: day, to: formattedDate)!
                    let userEphIDs = ephIDGeneration(SKt: user_SKt, broadcastKey: Config.BROADCASTKEY, epochLength: Config.EPOCHLENGTH)

                    let recordedEphIDs = getRecordedEphIDs(day: newDate)
                    if recordedEphIDs == nil {
                        continue
                    }
                    let match = ephIDMatches(userEphIDs: userEphIDs, recordedEphIDs: recordedEphIDs!)
                    if match {
                        matches += 1
                        break
                    }
                    
                    user_SKt = SKtGeneration(previousSKt: user_SKt)
                }
            }
        }
        
        UserDefaults.standard.set(matches, forKey: "matches")
        displayMatches()
    }
    
    private func getRecordedEphIDs(day: Date) -> Set<String>? {
        return bluetoothManager?.getKnownEncounteredEphIdsOnDay(date: day)
    }
    
    private func ephIDMatches(userEphIDs: [String], recordedEphIDs: Set<String>) -> Bool {
        for ephID in userEphIDs {
            if recordedEphIDs.contains(ephID) {
                print("matched \(ephID)")
                return true
            }
        }
        return false
    }
    
    private func displayMatches() {
        let matches = getMatches()
        
        let content = UNMutableNotificationContent()
        content.title = "COVID-19 Contact Tracing Update"
        content.badge = 1
        if matches == 1 {
            content.body = "You have been in contact with 1 infected person in the past day"
        } else {
            content.body = "You have been in contact with " + String(matches) + " infected people in the past day"
        }
        
        DispatchQueue.main.async {
            if self.viewController != nil {
                self.viewController!.matchesLabel.text = content.body
            }
        }
        
        content.sound = UNNotificationSound.default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        if matches != 0 {
            // only send a push if there are some matches
            UNUserNotificationCenter.current().add(request)
        }
    }
    
}

extension String{
    func toDictionary() -> NSDictionary {
        let blankDict : NSDictionary = [:]
        if let data = self.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as! NSDictionary
            } catch {
                print(error.localizedDescription)
            }
        }
        return blankDict
    }
}
