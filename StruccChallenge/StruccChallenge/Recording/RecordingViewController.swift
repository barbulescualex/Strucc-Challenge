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
    let recordingButton = RecordingButton(withSize: 74)
    
    let switchCameraButton : UIButton = {
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
    }
    
    //MARK:- View Setup
    fileprivate func setupView(){
        //self
        view.backgroundColor = .black
        
        //recording button
        view.addSubview(recordingButton)
        
        NSLayoutConstraint.activate([
            recordingButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            recordingButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -32)
        ])
        
        //camera button
        view.addSubview(switchCameraButton)
        
        NSLayoutConstraint.activate([
            switchCameraButton.heightAnchor.constraint(equalToConstant: 24.6),
            switchCameraButton.widthAnchor.constraint(equalToConstant: 22),
            switchCameraButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            switchCameraButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -25)
        ])
    }

}

