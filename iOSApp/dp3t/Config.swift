//
//  Config.swift
//  Test
//
//  Created by Ishaan Mathur on 8/10/20.
//  Copyright © 2020 Mathur. All rights reserved.
//

class Config {
    
    // URL of backend server, if running locally use your local IP
    public static var SERVER_URL = "http://192.168.1.10:5000"
    
    public static var AUTHCODELENGTH = 6
    // 14 days max infection period
    public static var INFECTIONPERIOD = 14
    // 15 minutes per epoch
    public static var EPOCHLENGTH = 15
    public static var BROADCASTKEY = "dp3t-broadcast-key"
    
    
    public static var BROADCAST_UUID = "4DF91029-B356-463E-9F48-BAB077BF3EF5"
    public static var DATE_STR = "yyyy-MM-dd"
    
    public static var EPH_ID_SIZE = 26
}
