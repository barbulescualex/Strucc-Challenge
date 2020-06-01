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
    
    //MARK:- View Components
    fileprivate let recordingButton = RecordingButton(withSize: 74)
    
    fileprivate let switchCameraButton : UIButton = {
        let button = UIButton()
        let image = UIImage(named: "SwitchCamera")
        button.setImage(image, for: .normal)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    fileprivate var previewLayer : AVCaptureVideoPreviewLayer?

    //MARK:- Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        checkPermissions()
    }
    
    //MARK:- Setup
    fileprivate func setupView(){
        //self
        view.backgroundColor = .black
        
        //recording button
        view.addSubview(recordingButton)
        
        NSLayoutConstraint.activate([
            recordingButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            recordingButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -32)
        ])
        
        recordingButton.isUserInteractionEnabled = false
        recordingButton.delegate = self
        
        //camera button
        view.addSubview(switchCameraButton)
        
        NSLayoutConstraint.activate([
            switchCameraButton.heightAnchor.constraint(equalToConstant: 24.6),
            switchCameraButton.widthAnchor.constraint(equalToConstant: 22),
            switchCameraButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            switchCameraButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -25)
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
        //enable recording, writer is ready so users can record
        recordingButton.isUserInteractionEnabled = true
    }
    
    func writerError(manager: RecordingManager) {
        
    }
    
    func writerFinished(manager: RecordingManager) {
        if videoNumber < 2 { //we still need second video
            videoNumber += 1
            manager.setupWriter(forVideoNumber: videoNumber)
        } else {
            print("captured 2 videos!")
            //go to next screen
            let previewVC = PreviewViewController()
            previewVC.modalPresentationStyle = .fullScreen
            previewVC.modalTransitionStyle = .crossDissolve
            self.present(previewVC, animated: true) {
                //stop camera session..
            }
        }
    }
    
    func sessionStarted(manager: RecordingManager) {
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
        view.layer.insertSublayer(layer, below: recordingButton.layer)
        layer.frame = self.view.layer.frame
    }
    
    
}

