//
//  DateMock.swift
//  dp3t
//
//  Created by Jatin Mathur on 8/16/20.
//  Copyright © 2020 Jatin Mathur. All rights reserved.
//

import UIKit

protocol DateManager {
    func currentDate() -> Date!
}

// real date manager implementation
class DateHandler:DateManager {
   func currentDate() -> Date! {
      return Date()
   }
}

// mocks date
class MockDateHandler:DateManager {
    // default hard-coded date is June 25 2020 at 4:00
    var mockedDate:Date! = Date(timeIntervalSince1970: 1593093600)
    func setDate(date: Date!) {
        mockedDate = date
    }
    
    func currentDate() -> Date! {
        return mockedDate
    }
}


