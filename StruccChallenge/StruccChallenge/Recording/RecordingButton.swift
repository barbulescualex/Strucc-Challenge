//
//  RecordingButton.swift
//  StruccChallenge
//
//  Created by Alex Barbulescu on 2020-05-30.
//  Copyright © 2020 ca.alexs. All rights reserved.
//

import UIKit

/* Informs delegate when recording starts or stops */
protocol RecordingButtonDelegate : AnyObject {
    func didStartRecording(_ button: RecordingButton)
    func didStopRecording(_ button: RecordingButton)
}

/* Simple view for recording button */
class RecordingButton: UIView {
    //MARK:- Vars
    //logic state
    private(set) var recording = false
    
    public weak var delegate : RecordingButtonDelegate?
    
    //internal UI state
    private var size : CGFloat
    private var circlePath : CGPath
    private var squarePath : CGPath
    
    //MARK:- View Components
    private let backgroundView : UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        view.alpha = 0.7
        return view
    }()
    
    private var shapeLayer = CAShapeLayer()
    
    //MARK:- Init
    public init(withSize size: CGFloat) {
        self.size = size
        self.circlePath = CALayerHelper.makeCirclePath(inSize: size, withScale: 0.838)
        self.squarePath = CALayerHelper.makeSquarePath(inSize: size, withScale: 0.338, cornerRadius: 4)
        super.init(frame: .zero)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    //MARK:- View Setup
    fileprivate func setupView(){
        //self
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .clear
        
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: size),
            widthAnchor.constraint(equalToConstant: size)
        ])
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap(_:)))
        addGestureRecognizer(tapGesture)
        
        //background view
        addSubview(backgroundView)
        NSLayoutConstraint.constrain(firstView: backgroundView, toSecondView: self)
        backgroundView.layer.cornerRadius = size/2
        
        //starting shape
        shapeLayer.path = circlePath
        shapeLayer.fillColor = UIColor.systemRed.cgColor
        
        layer.addSublayer(shapeLayer)
    }
    
    //MARK:- Actions
    @objc fileprivate func didTap(_ sender: UIButton){
        if recording {
            delegate?.didStopRecording(self)
        } else {
            delegate?.didStartRecording(self)
        }
        recording = !recording
        changeSublayer()
    }
    
    //MARK:- Functions
    fileprivate func changeSublayer(){
        let animation = CABasicAnimation(keyPath: "path")
        animation.fromValue = recording ? circlePath : squarePath
        animation.toValue = recording ? squarePath : circlePath
        animation.duration = 0.15
        animation.timingFunction = .init(name: CAMediaTimingFunctionName.easeInEaseOut)
        
        shapeLayer.add(animation, forKey: animation.keyPath)
        shapeLayer.path = recording ? squarePath : circlePath
    }
    
}

