//
//  RecordingViewController.swift
//  StruccChallenge
//
//  Created by Alex Barbulescu on 2020-05-30.
//  Copyright © 2020 ca.alexs. All rights reserved.
//

import UIKit

/* For first stage of the app, the recording scene */
class RecordingViewController: UIViewController {
    //MARK:- Vars
    
    
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
        
        //camera button
        view.addSubview(switchCameraButton)
        
        NSLayoutConstraint.activate([
            switchCameraButton.heightAnchor.constraint(equalToConstant: 24.6),
            switchCameraButton.widthAnchor.constraint(equalToConstant: 22),
            switchCameraButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            switchCameraButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -25)
        ])
        
        switchCameraButton.isUserInteractionEnabled = false
    }
    
    fileprivate func setup(){
        //enable buttons
        self.recordingButton.isUserInteractionEnabled = true
        self.switchCameraButton.isUserInteractionEnabled = true
    }
    
    //MARK:- Functions
    fileprivate func checkPermissions(){
        AVManager.checkCameraPermissions { [weak self] allowed in
            guard let self = self else {return}
            if allowed {
                //check if audio is allowed
                AVManager.checkAudioPermissions { [weak self] allowed in
                    guard let self = self else {return}
                    DispatchQueue.main.async {
                        if allowed {
                            //user can use the app
                            self.setup()
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

