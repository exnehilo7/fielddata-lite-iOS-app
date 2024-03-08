//
//  Sounds.swift
//  FERN
//
//  Created by Hopp, Dan on 12/14/23. Code from https://www.rockhoppertech.com/blog/apple-system-sounds/
//

import Foundation
import AVFoundation

public struct playSound {
    // Assign an ID to the sound
    func createSysSound(fileName: String) -> SystemSoundID {
        var mySysSound: SystemSoundID = .zero
        
        // The actual file can be in your bundle, on the file system, or in iCloud.
//        guard let url = Bundle.main.url(forResource: fileName, withExtension: fileExt) else {
//        print("cound not get URL")
//        return .zero
//    }
        let url = URL(fileURLWithPath: fileName)

        let osstatus = AudioServicesCreateSystemSoundID(url as CFURL, &mySysSound)
        if osstatus != noErr { // or kAudioServicesNoError. same thing.
            print("could not create system sound")
            print("osstatus: \(osstatus)")
        }
        return mySysSound
    }
    
    // Complete sound
    func playSuccess() {
        
        var complete: SystemSoundID = .zero
        
        if complete == .zero {
            complete = createSysSound(fileName: "/System/Library/Audio/UISounds/payment_success.caf")
        }
        AudioServicesPlaySystemSound(complete)
    }
    
    //Error alert
    func playError() {
        
        var complete: SystemSoundID = .zero
        
        if complete == .zero {
            complete = createSysSound(fileName: "/System/Library/Audio/UISounds/SIMToolkitNegativeACK.caf")
        }
        AudioServicesPlaySystemSound(complete)
        // Add a vibrate
        AudioServicesPlaySystemSoundWithCompletion(kSystemSoundID_Vibrate, nil)
    }

    // Ding!
    func playDing() {
        
        var complete: SystemSoundID = .zero
        
        if complete == .zero {
            complete = createSysSound(fileName: "/System/Library/Audio/UISounds/SIMToolkitPositiveACK.caf")
        }
        AudioServicesPlaySystemSound(complete)
        // Add a vibrate
        AudioServicesPlaySystemSoundWithCompletion(kSystemSoundID_Vibrate, nil)
    }
}
