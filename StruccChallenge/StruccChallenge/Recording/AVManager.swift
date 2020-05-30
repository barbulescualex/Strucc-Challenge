//
//  CameraManager.swift
//  StruccChallenge
//
//  Created by Alex Barbulescu on 2020-05-30.
//  Copyright © 2020 ca.alexs. All rights reserved.
//

import UIKit
import AVFoundation


/* Manages the capture session, provides camera preview and posts errors. Manages permissions necessary permissions. */
class AVManager : NSObject {
    
    //MARK:- Init
    public override init(){
        super.init()
    }
    
}

//MARK:- Permissions
extension AVManager {
    //camera
    static func checkCameraPermissions(completionHandler: @escaping(Bool)->()) {
        let cameraAuthStatus =  AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        
        switch cameraAuthStatus {
        case .authorized:
            completionHandler(true)
        case .denied:
            completionHandler(false)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler:
                { (authorized) in
                 completionHandler(authorized)
            })
        case .restricted:
            completionHandler(false)
        @unknown default:
            completionHandler(false)
       }
    }
    
    //audio
    static func checkAudioPermissions(completionHandler: @escaping(Bool)->()) {
        let audioAuthStatus =  AVCaptureDevice.authorizationStatus(for: AVMediaType.audio)
        
        switch audioAuthStatus {
        case .authorized:
            completionHandler(true)
        case .denied:
            completionHandler(false)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: AVMediaType.audio, completionHandler:
                { (authorized) in
                    completionHandler(authorized)
            })
        case .restricted:
            completionHandler(false)
        @unknown default:
            completionHandler(false)
        }
    }
}
