//
//  Constants.swift
//  dp3t
//
//  Created by Jatin Mathur on 8/11/20.
//  Copyright © 2020 Jatin Mathur. All rights reserved.
//

import UIKit

enum ConstantsString: String {
    // shared by everyone on the app
    case SERVICE_UUID = "4DF91029-B356-463E-9F48-BAB077BF3EF5"
    // how dates are stored in the dictionary
    case DATE_STR = "yyyy-MM-dd"
}

enum ConstantsInt: Int {
    // expire devices met more than 14 days ago
    case EXPIRE_DAYS = 14
    case EPH_ID_SIZE = 26
}
