//
//  RecordingViewController.swift
//  StruccChallenge
//
//  Created by Alex Barbulescu on 2020-05-30.
//  Copyright © 2020 ca.alexs. All rights reserved.
//

import UIKit
import AVFoundation

/* For first stage of the app, the recording scene */
class RecordingViewController: UIViewController {
    //MARK:- Vars
    fileprivate var recordingManager : RecordingManager?
    
    fileprivate var videoNumber = 0
    
    fileprivate var firstLoad = true
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    //MARK:- View Components
    fileprivate let recordingButton = RecordingButton(withSize: 70)
    
    fileprivate let switchCameraButton : UIButton = {
        let button = UIButton()
        let image = UIImage(named: "SwitchCamera")
        button.setImage(image, for: .normal)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowRadius = 4
        button.layer.shadowOffset = .zero
        button.layer.shadowOpacity = 0.8
        return button
    }()
    
    fileprivate var previewLayer : AVCaptureVideoPreviewLayer?

    //MARK:- Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        checkPermissions()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if firstLoad {
            firstLoad = false
            return
        }
        //will trigger sessionStarted callback which will then start the writer which will then enable the UI
        recordingManager?.startSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        recordingManager?.stopSession()
    }
    
    //MARK:- Setup
    fileprivate func setupView(){
        //self
        view.backgroundColor = .black
        
        //get black bar size (will be even on top and bottom) to position UI elements on the video frames themselves
        
        let videoWidthRatioOnScreen = view.bounds.width/1080.0
        let heightOfVideoOnScreen = 1920.0*videoWidthRatioOnScreen
        var blackBarHeight = (view.bounds.height - heightOfVideoOnScreen)/2
        if blackBarHeight < 0 {
            blackBarHeight = 0
        }
        
        //recording button
        view.addSubview(recordingButton)
        
        NSLayoutConstraint.activate([
            recordingButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            recordingButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -(blackBarHeight+5))
        ])
        
        recordingButton.isUserInteractionEnabled = false
        recordingButton.delegate = self
        
        //camera button
        view.addSubview(switchCameraButton)
        
        NSLayoutConstraint.activate([
            switchCameraButton.heightAnchor.constraint(equalToConstant: 22),
            switchCameraButton.widthAnchor.constraint(equalToConstant: 20),
            switchCameraButton.topAnchor.constraint(equalTo: view.topAnchor, constant: blackBarHeight + 6),
            switchCameraButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10)
        ])
        
        switchCameraButton.isUserInteractionEnabled = false
        switchCameraButton.addTarget(self, action: #selector(switchCamera(_:)), for: .touchUpInside)
    }
    
    fileprivate func setupRecordingManager(){
        recordingManager = RecordingManager()
        recordingManager?.delegate = self
        recordingManager?.configureAndStart()
    }
    
    //MARK:- Actions
    @objc fileprivate func switchCamera(_ sender: UIButton){
        recordingManager?.switchCamera()
    }
    
    //MARK:- Functions
    fileprivate func checkPermissions(){
        RecordingManager.checkCameraPermissions { [weak self] allowed in
            guard let self = self else {return}
            if allowed {
                //check if audio is allowed
                RecordingManager.checkAudioPermissions { [weak self] allowed in
                    guard let self = self else {return}
                    DispatchQueue.main.async {
                        if allowed {
                            //user can use the app
                            self.setupRecordingManager()
                        } else {
                            let warning = UIAlertController(title: "No Microphone Acess", message: "Please Allow Microphone Access In Settings", preferredStyle: .alert)
                            warning.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: { (action: UIAlertAction) in
                                let settingsUrl = URL(string: UIApplication.openSettingsURLString)!
                                UIApplication.shared.open(settingsUrl)
                            }))
                            self.present(warning, animated: true)
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    //redirect user to allow camera access
                    let warning = UIAlertController(title: "No Camera Acess", message: "Please Allow Camera Access In Settings", preferredStyle: .alert)
                    warning.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: { (action: UIAlertAction) in
                        let settingsUrl = URL(string: UIApplication.openSettingsURLString)!
                        UIApplication.shared.open(settingsUrl)
                    }))
                    self.present(warning, animated: true)
                }
            }
        }
    }
    
    fileprivate func animateOut(){
        fadePreviewLayer(visible: false)
        UIView.animate(withDuration: 0.1, animations: {
            self.switchCameraButton.alpha = 0
        }) { [weak self] _ in
            guard let self = self else {return}
            let previewVC = PreviewViewController()
            previewVC.modalPresentationStyle = .fullScreen
            previewVC.modalTransitionStyle = .crossDissolve
            self.present(previewVC, animated: false) {
                self.videoNumber = 0
                self.switchCameraButton.alpha = 1
            }
        }
    }
    
    fileprivate func fadePreviewLayer(visible: Bool){
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = visible ? 0 : 1
        animation.toValue = visible ? 1 : 0
        animation.duration = 0.2
        animation.timingFunction = .init(name: CAMediaTimingFunctionName.easeInEaseOut)
        previewLayer?.add(animation, forKey: nil)
        previewLayer?.opacity = visible ? 1 : 0
    }

}

//MARK:- Recording Button Delegate
extension RecordingViewController : RecordingButtonDelegate {
    func didStartRecording(_ button: RecordingButton) {
        //tell manager to start recording
        recordingManager?.startRecording()

        //don't let user switch camera
        switchCameraButton.isUserInteractionEnabled = false
    }
    
    func didStopRecording(_ button: RecordingButton) {
        //tell manager to stop recording
        recordingManager?.stopRecording()

        //disable capture button, once writer finishes and next writer starts, capture button will work again
        recordingButton.isUserInteractionEnabled = false

        //turn on camera switching
        switchCameraButton.isUserInteractionEnabled = true
    }
    
    
}

//MARK:- AVManagerDelegate
extension RecordingViewController : RecordingDelegate {
    func writerReady(manager: RecordingManager) {
        //enable recording, writer is ready so users can record, they can also flip camera before recording
        recordingButton.isUserInteractionEnabled = true
        switchCameraButton.isUserInteractionEnabled = true
    }
    
    func writerError(manager: RecordingManager) {
        let warning = UIAlertController(title: "Ooops", message: "Couldn't write to disk!", preferredStyle: .alert)
        warning.addAction(UIAlertAction(title: "Try again", style: .default, handler: { [weak self] _ in
            guard let self = self else {return}
           
            //deallocate recording manager, try process again
            self.recordingManager = nil
           
            //remove preview layer (if there)
            self.previewLayer?.removeFromSuperlayer()
           
            self.setupRecordingManager()
        }))
    }
    
    func writerFinished(manager: RecordingManager) {
        if videoNumber < 2 { //we still need second video
            videoNumber += 1
            manager.setupWriter(forVideoNumber: videoNumber)
        } else {
            print("captured 2 videos!")
            //go to next screen
            animateOut()
        }
    }
    
    func sessionStarted(manager: RecordingManager) {
        fadePreviewLayer(visible: true)
        //setup writer
        videoNumber += 1
        manager.setupWriter(forVideoNumber: videoNumber)
    }
    
    func sessionError(manager: RecordingManager) {
        let warning = UIAlertController(title: "Ooops", message: "Couldn't start camera", preferredStyle: .alert)
        warning.addAction(UIAlertAction(title: "Try again", style: .default, handler: { [weak self] _ in
            guard let self = self else {return}
            
            //deallocate recording manager, try process again
            self.recordingManager = nil
            
            //remove preview layer (if there)
            self.previewLayer?.removeFromSuperlayer()
            
            self.setupRecordingManager()
        }))
    }
    
    func sessionPreviewLayerReady(previewLayer layer: AVCaptureVideoPreviewLayer, manager: RecordingManager) {
        //add preview layer to our view hierarchy
        previewLayer = layer
        view.layer.insertSublayer(layer, below: recordingButton.layer)
        layer.frame = self.view.layer.frame
        
        previewLayer?.opacity = 0
    }
    
    
}

