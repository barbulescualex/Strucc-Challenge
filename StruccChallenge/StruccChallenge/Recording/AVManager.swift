//
//  AVManager.swift
//  StruccChallenge
//
//  Created by Alex Barbulescu on 2020-05-30.
//  Copyright © 2020 ca.alexs. All rights reserved.
//

import UIKit
import AVFoundation

protocol AVManagerDelegate : AnyObject {
    //tell delegate session started
    func sessionStarted(manager: AVManager)
    
    //tell delegate there's an issue with the session
    func sessionError(manager: AVManager)
    
    //tell delegate it can add the preview to it's view hierarchy
    func sessionPreviewLayerReady(previewLayer layer: AVCaptureVideoPreviewLayer, manager: AVManager)
}

/* Manages the capture session, provides camera preview and posts errors. Manages permissions necessary permissions. */
class AVManager : NSObject {
    //MARK:- Vars
    public weak var delegate : AVManagerDelegate?
    
    fileprivate var captureSession : AVCaptureSession!
    
    //cameras
    fileprivate var backCamera : AVCaptureDevice!
    fileprivate var frontCamera : AVCaptureDevice!
    fileprivate var backInput : AVCaptureInput!
    fileprivate var frontInput : AVCaptureInput!
    
    fileprivate var backCameraOn = true
    
    //microphone
    fileprivate var microphone : AVCaptureDevice!
    fileprivate var microphoneInput : AVCaptureInput!
    
    //outputs
    fileprivate var videoOutput : AVCaptureVideoDataOutput!
    fileprivate var audioOutput : AVCaptureAudioDataOutput!
    
    //MARK:- Init
    public override init(){
        super.init()
    }
    
    //MARK:- Configuration
    public func configureAndStart(){
        if captureSession != nil && captureSession.isRunning { return } //already configured and started
        
        DispatchQueue.global(qos: .userInteractive).async {
            self.captureSession = AVCaptureSession()
            self.register()
            
            self.captureSession.beginConfiguration()
                   
            if self.captureSession.canSetSessionPreset(.hd1920x1080){
                self.captureSession.sessionPreset = .hd1920x1080
            }
            self.captureSession.automaticallyConfiguresCaptureDeviceForWideColor = true
            
            if !self.setupInputs() { //was a problem, end configuration
                return
            }
            
            if !self.setupOutputs() {
                return
            }
            
            self.setupPreviewLayer()
            
            self.captureSession.commitConfiguration()
            self.captureSession.startRunning()
        }
       
    }

    //return boolean incase something was wrong so it capture session doesn't continue configuring in a bad state
    //delegate will deallocate this manager object and try again
    fileprivate func setupInputs() -> Bool {
        //get back camera in descending order of quality (depending on device)
        if let device = AVCaptureDevice.default(.builtInTripleCamera, for: .video, position: .back) {
            backCamera = device
        } else {
            if let device = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) {
                backCamera = device
            } else {
                if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                    backCamera = device
                } else {
                    //no back camera available
                    print("no back camera")
                    DispatchQueue.main.async {
                        self.delegate?.sessionError(manager: self)
                    }
                    return false
                }
            }
        }
        
        guard let bInput = try? AVCaptureDeviceInput(device: backCamera) else {
            print("could not make back input")
            DispatchQueue.main.async {
                self.delegate?.sessionError(manager: self)
            }
            return false
        }
        backInput = bInput

        //get front camera
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
            frontCamera = device
        } else {
            //no front camera
            print("no front camera")
            DispatchQueue.main.async {
                self.delegate?.sessionError(manager: self)
            }
            return false
        }
        
        guard let fInput = try? AVCaptureDeviceInput(device: frontCamera) else {
            print("could not make front input")
            DispatchQueue.main.async {
                self.delegate?.sessionError(manager: self)
            }
            return false
        }
        frontInput = fInput
        
        //set back camera as starting camera
        if captureSession.canAddInput(backInput) {
            captureSession.addInput(backInput)
        } else {
            DispatchQueue.main.async {
                self.delegate?.sessionError(manager: self)
            }
            return false
        }
        
        //get microphone
        if let device = AVCaptureDevice.default(for: .audio) {
            microphone = device
        } else {
            //no microphone
            print("no microphone")
            DispatchQueue.main.async {
                self.delegate?.sessionError(manager: self)
            }
            return false
        }
        
        guard let mInput = try? AVCaptureDeviceInput(device: microphone) else {
            print("could not make mic input")
            DispatchQueue.main.async {
                self.delegate?.sessionError(manager: self)
            }
            return false
        }
        microphoneInput = mInput
        
        //attach microphone to session
        if captureSession.canAddInput(microphoneInput) {
            captureSession.addInput(microphoneInput)
        } else {
            DispatchQueue.main.async {
                self.delegate?.sessionError(manager: self)
            }
            return false
        }
        
        return true //all good
    }
    
    fileprivate func setupOutputs() -> Bool {
        //callback queue
        let avQueue = DispatchQueue(label: "ca.alexs.av-queue", qos: .userInitiated)
        
        //video
        videoOutput = AVCaptureVideoDataOutput()
        videoOutput.alwaysDiscardsLateVideoFrames = true
        
        if captureSession.canAddOutput(videoOutput){
            videoOutput.setSampleBufferDelegate(self, queue: avQueue)
            captureSession.addOutput(videoOutput)
        } else {
            DispatchQueue.main.async {
                self.delegate?.sessionError(manager: self)
            }
            return false
        }
        
        //audio
        audioOutput = AVCaptureAudioDataOutput()
        
        if captureSession.canAddOutput(audioOutput){
            audioOutput.setSampleBufferDelegate(self, queue: avQueue)
            captureSession.addOutput(audioOutput)
        } else {
            DispatchQueue.main.async {
                self.delegate?.sessionError(manager: self)
            }
            return false
        }
        
        return true
    }
    
    fileprivate func setupPreviewLayer(){
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        DispatchQueue.main.async {
            self.delegate?.sessionPreviewLayerReady(previewLayer: previewLayer, manager: self)
        }
    }
    
    //MARK:- Functions
    public func switchCamera(){
        captureSession.beginConfiguration()
        if backCameraOn {
            captureSession.removeInput(backInput)
            if captureSession.canAddInput(frontInput) {
                captureSession.addInput(frontInput)
                backCameraOn = false
            } else {
                //don't switch
                self.captureSession.addInput(self.backInput)
            }
        } else {
            captureSession.removeInput(frontInput)
            if captureSession.canAddInput(backInput) {
                captureSession.addInput(backInput)
                backCameraOn = true
            } else {
                //don't switch
                captureSession.addInput(frontInput)
            }
        }
        //commit config
        captureSession.commitConfiguration()
    }
    
    //MARK:- Notifications
    fileprivate func register(){
        NotificationCenter.default.addObserver(self, selector: #selector(sessionStarted(_:)), name: .AVCaptureSessionDidStartRunning, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(sessionErorr(_:)), name: .AVCaptureSessionRuntimeError, object: nil)
    }
    
    @objc fileprivate func sessionStarted(_ sender: NSNotification) {
        DispatchQueue.main.async {
            self.delegate?.sessionStarted(manager: self)
        }
    }
    
    @objc fileprivate func sessionErorr(_ sender: NSNotification) {
        DispatchQueue.main.async {
            self.delegate?.sessionError(manager: self)
        }
    }
    
    //MARK:- Deinit
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
}

//MARK:- Output Callback
extension AVManager : AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
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
