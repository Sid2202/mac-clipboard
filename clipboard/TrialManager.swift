import Foundation
import SwiftUI

class TrialManager: ObservableObject {
    static let shared = TrialManager()
    
    @AppStorage("firstLaunchDate") private var firstLaunchDate: Double = 0
    @AppStorage("isProPurchased") var isPro: Bool = false
    
    private let trialDurationInSeconds: TimeInterval = 7 * 24 * 60 * 60 // 7 Days
    
    var daysRemaining: Int {
        if firstLaunchDate == 0 { return 7 }
        let expirationDate = Date(timeIntervalSince1970: firstLaunchDate).addingTimeInterval(trialDurationInSeconds)
        let timeRemaining = expirationDate.timeIntervalSince(Date())
        return max(0, Int(ceil(timeRemaining / (24 * 60 * 60))))
    }
    
    var isTrialExpired: Bool {
        if isPro { return false }
        if firstLaunchDate == 0 { return false } // Should have been set on init
        let expirationDate = Date(timeIntervalSince1970: firstLaunchDate).addingTimeInterval(trialDurationInSeconds)
        return Date() > expirationDate
    }
    
    init() {
        if firstLaunchDate == 0 {
            firstLaunchDate = Date().timeIntervalSince1970
        }
    }
    
    func unlockPro() {
        isPro = true
    }
}
