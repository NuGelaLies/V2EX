//
//  Date+Extensions.swift
//  V2EX
//
//  Created by Joe on 2018/12/7.
//  Copyright © 2018 Joe. All rights reserved.
//

import Foundation


extension Date {
    
    /// SwifterSwift: Hour.
    ///
    ///     Date().hour -> 17 // 5 pm
    ///
    ///     var someDate = Date()
    ///     someDate.hour = 13 // sets someDate's hour to 1 pm.
    ///
    public var hour: Int {
        get {
            return Calendar.current.component(.hour, from: self)
        }
        set {
            let allowedRange = Calendar.current.range(of: .hour, in: .day, for: self)!
            guard allowedRange.contains(newValue) else { return }
            
            let currentHour = Calendar.current.component(.hour, from: self)
            let hoursToAdd = newValue - currentHour
            if let date = Calendar.current.date(byAdding: .hour, value: hoursToAdd, to: self) {
                self = date
            }
        }
    }
    
    /// SwifterSwift: Minutes.
    ///
    ///     Date().minute -> 39
    ///
    ///     var someDate = Date()
    ///     someDate.minute = 10 // sets someDate's minutes to 10.
    ///
    public var minute: Int {
        get {
            return Calendar.current.component(.minute, from: self)
        }
        set {
            let allowedRange = Calendar.current.range(of: .minute, in: .hour, for: self)!
            guard allowedRange.contains(newValue) else { return }
            
            let currentMinutes = Calendar.current.component(.minute, from: self)
            let minutesToAdd = newValue - currentMinutes
            if let date = Calendar.current.date(byAdding: .minute, value: minutesToAdd, to: self) {
                self = date
            }
        }
    }
    
    public static func customDate(hour: Int, minute: Int) -> Date {
        let currentDate = Date()
        let currentCalendar = Calendar.current
        
        let currentComponent = currentCalendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: currentDate)
        
        var resultComponent = DateComponents()
        resultComponent.setValue(currentComponent.year, for: .year)
        resultComponent.setValue(currentComponent.month, for: .month)
        resultComponent.setValue(currentComponent.day, for: .day)
        resultComponent.setValue(hour, for: .hour)
        resultComponent.setValue(minute, for: .minute)
        
        return currentCalendar.date(from: resultComponent)!
    }
    
    
    public static func isBetween(from: (hour: Int, minute: Int), to: (hour: Int, minute: Int)) -> Bool {
        let fromDate: Date = Date.customDate(hour: from.hour, minute: from.minute)
        
        let isMoreThan = (from.hour + from.minute) > (to.hour + to.minute)
        let toDate: Date = Date.customDate(hour: isMoreThan ? to.hour + 24 : to.hour, minute: to.minute)
        
        let currentDate = Date()
        
        log.info(fromDate.YYYYMMDDHHMMSSDateString, toDate.YYYYMMDDHHMMSSDateString, currentDate.YYYYMMDDHHMMSSDateString)
        
        return currentDate.compare(fromDate) == .orderedDescending && currentDate.compare(toDate) == .orderedAscending
    }
}
