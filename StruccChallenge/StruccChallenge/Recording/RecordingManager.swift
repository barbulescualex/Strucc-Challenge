//
//  RecordingManager.swift
//  StruccChallenge
//
//  Created by Alex Barbulescu on 2020-05-30.
//  Copyright © 2020 ca.alexs. All rights reserved.
//

import UIKit
import AVFoundation

protocol RecordingDelegate : AnyObject {
    //tells the delegate session started
    func sessionStarted(manager: RecordingManager)
    
    //tells the delegate there's an issue with the session
    func sessionError(manager: RecordingManager)
    
    //tells the delegate it can add the preview to it's view hierarchy
    func sessionPreviewLayerReady(previewLayer layer: AVCaptureVideoPreviewLayer, manager: RecordingManager)
    
    //tells the delegate the writer is ready to start writing
    func writerReady(manager: RecordingManager)
    
    //tells the delegate there's an issue with the writer
    func writerError(manager: RecordingManager)
    
    //tells the delegate the writer finished
    func writerFinished(manager: RecordingManager)
}

/* Manages the capture session, provides camera preview and posts errors. Manages permissions necessary permissions. */
class RecordingManager : NSObject {
    //MARK:- Vars
    public weak var delegate : RecordingDelegate?
    
    fileprivate var captureSession : AVCaptureSession!
    
    //callback queue
    fileprivate let avQueue = DispatchQueue(label: "ca.alexs.av-queue", qos: .userInitiated)
    
    //MARK: Capture Session Vars
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
    
    //MARK: Asset Writer Vars
    //writers
    fileprivate var assetWriter : AVAssetWriter!

    fileprivate var videoWriterInput : AVAssetWriterInput!
    fileprivate var audioWriterInput : AVAssetWriterInput!

    //flags
    fileprivate var writerSessionStarted = false
    
    //MARK:- Init
    public override init(){
        super.init()
    }
    
    //MARK:- Configuration
    public func configureAndStart(){
        if captureSession != nil && captureSession.isRunning { return } //already configured and started
        
        DispatchQueue.global(qos: .userInteractive).async {
            self.setupWriterInputs()
            
            self.captureSession = AVCaptureSession()
            self.register()
            
            self.captureSession.beginConfiguration()
                   
            if self.captureSession.canSetSessionPreset(.hd1920x1080){
                self.captureSession.sessionPreset = .hd1920x1080
            }
            self.captureSession.automaticallyConfiguresCaptureDeviceForWideColor = true
            
            if !self.setupCaptureInputs() { //was a problem, end configuration
                return
            }
            
            if !self.setupCaptureOutputs() {
                return
            }
            
            self.setupPreviewLayer()
            
            self.captureSession.commitConfiguration()
            self.captureSession.startRunning()
        }
       
    }
    
    //MARK: AV Configuration
    
    /*return boolean incase something was wrong so it capture session doesn't continue configuring in a bad state
    delegate will deallocate this manager object and try again*/
    fileprivate func setupCaptureInputs() -> Bool {
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
    
    fileprivate func setupCaptureOutputs() -> Bool {
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
        
        //fix to portrait orientation
        videoOutput.connections.first?.videoOrientation = .portrait
        
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
    
    //MARK: Asset Writer Configuration
    
    /* creates the audio and video input writer objects, reused between writers */
    fileprivate func setupWriterInputs(){
        //video
        videoWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: [
           AVVideoCodecKey: AVVideoCodecType.h264,
           AVVideoWidthKey: 1080,
           AVVideoHeightKey: 1920
        ])
             
        videoWriterInput.expectsMediaDataInRealTime = true

        //audio
        audioWriterInput = AVAssetWriterInput(mediaType: .audio, outputSettings: [
           AVFormatIDKey: kAudioFormatMPEG4AAC,
           AVNumberOfChannelsKey: 1,
           AVSampleRateKey: 44100,
           AVEncoderBitRateKey: 64000,
        ])

        audioWriterInput.expectsMediaDataInRealTime = true
    }
    
    /* sets up a writer for the given url using the writer inputs*/
    fileprivate func setupWriter(withUrl url: URL) {
        //create asset writer
        do {
            assetWriter = try AVAssetWriter(url: url, fileType: .mp4)
        } catch {
            print(error.localizedDescription)
            DispatchQueue.main.async {
                self.delegate?.writerError(manager: self)
            }
            return
        }
        
        //add video input
        if assetWriter.canAdd(videoWriterInput) {
            assetWriter.add(videoWriterInput)
        } else {
            DispatchQueue.main.async {
                self.delegate?.writerError(manager: self)
            }
            return
        }
        
        //add audio input
        if assetWriter.canAdd(audioWriterInput){
            assetWriter.add(audioWriterInput)
        } else {
            DispatchQueue.main.async {
                self.delegate?.writerError(manager: self)
            }
            return
        }
        
        delegate?.writerReady(manager: self)
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
        
        //fix to portrait orientation
        videoOutput.connections.first?.videoOrientation = .portrait
             
        //mirror video if front camera
        videoOutput.connections.first?.isVideoMirrored = !backCameraOn
        
        //commit config
        captureSession.commitConfiguration()
    }
    
    /* setup the writer for the the the specified video number*/
    public func setupWriter(forVideoNumber num: Int){
        //write the video file to tmp directory
        let tmpDirectory = FileManager.default.temporaryDirectory
        let videoURL = tmpDirectory.appendingPathComponent("video\(num).mp4")
        
        //clear out any previous video at this path
        do {
            try FileManager.default.removeItem(at: videoURL)
        } catch {
            //nothing was there or it failed
            print(error.localizedDescription)
        }
        
        setupWriter(withUrl: videoURL)
    }
    
    /* start recording */
    public func startRecording(){
        //start the writer
        assetWriter.startWriting()
    }
    
    /* stop recording */
    public func stopRecording(){
        //stop recording synchronously in AVQueue as that's where the writer is being used
        avQueue.sync {
            videoWriterInput.markAsFinished()
            audioWriterInput.markAsFinished()
            assetWriter.finishWriting { [weak self] in
                guard let self = self else {return}
                self.writerSessionStarted = false
                //tell delegate we're ready for next video
                DispatchQueue.main.async {
                    self.delegate?.writerFinished(manager: self)
                }
            }
        }
    }
    
    public func stopSession(){
        captureSession.stopRunning()
    }
    
    public func startSession(){
        captureSession.startRunning()
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
extension RecordingManager : AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if !CMSampleBufferDataIsReady(sampleBuffer) || assetWriter == nil || assetWriter.status != .writing  { return } //not recording or buffer not valid
        
        if !writerSessionStarted {
            assetWriter.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
            writerSessionStarted = true
        }
        
        if output == videoOutput && videoWriterInput.isReadyForMoreMediaData {
            //write video frames
            videoWriterInput.append(sampleBuffer)
        }
        
        if output == audioOutput && audioWriterInput.isReadyForMoreMediaData {
            //write audio
            audioWriterInput.append(sampleBuffer)
        }
    }
}

//MARK:- Permissions
extension RecordingManager {
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
