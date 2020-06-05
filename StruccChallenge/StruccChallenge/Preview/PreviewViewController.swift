//
//  PreviewViewController.swift
//  StruccChallenge
//
//  Created by Alex Barbulescu on 2020-05-31.
//  Copyright © 2020 ca.alexs. All rights reserved.
//

import UIKit
import AVFoundation

class PreviewViewController: UIViewController {
    //MARK:- Vars
    fileprivate var previewManager: PreviewManager?
    
    //MARK:- View Components
    fileprivate let carouselView = FilterCarouselView(withModel: [])
    
    fileprivate let cancelButton : UIButton = {
        let button = UIButton()
        let image = UIImage(named: "Exit")
        button.setImage(image, for: .normal)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowRadius = 4
        button.layer.shadowOffset = .zero
        button.layer.shadowOpacity = 0.8
        return button
    }()
    
    fileprivate var playerLayer : AVPlayerLayer?
    
    //just for the animation in
    fileprivate var recordingButton = RecordingButton(withSize: 70)
    
    //MARK:- Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupCarouselFilters()
        setupManager()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //independent of the animations in animateIn()
        UIView.animate(withDuration: 0.1) {
            self.cancelButton.alpha = 1
        }
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
        
        //recordingButton
        view.addSubview(recordingButton)
        NSLayoutConstraint.activate([
            recordingButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            recordingButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -(blackBarHeight+5))
        ])
        
        //carousel
        view.addSubview(carouselView)
        NSLayoutConstraint.activate([
            carouselView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            carouselView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            carouselView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            carouselView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.25)
        ])
        carouselView.isUserInteractionEnabled = false
        carouselView.alpha = 0
        carouselView.currentFilterView.alpha = 0
        carouselView.currentFilterLabel.alpha = 0
        
        view.addSubview(carouselView.currentFilterView)
        view.addSubview(carouselView.currentFilterLabel)
        NSLayoutConstraint.activate([
            carouselView.currentFilterView.heightAnchor.constraint(equalToConstant: 70),
            carouselView.currentFilterView.widthAnchor.constraint(equalToConstant: 70),
            carouselView.currentFilterView.centerXAnchor.constraint(equalTo: carouselView.centerXAnchor),
            carouselView.currentFilterView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -(blackBarHeight+30)),
            
            carouselView.currentFilterLabel.centerXAnchor.constraint(equalTo: carouselView.centerXAnchor),
            carouselView.currentFilterLabel.topAnchor.constraint(equalTo: carouselView.currentFilterView.bottomAnchor),
            carouselView.currentFilterLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -blackBarHeight)
        ])
        
        carouselView.currentFilterView.layer.cornerRadius = 70/2
        
        //cancel button
        view.addSubview(cancelButton)
        NSLayoutConstraint.activate([
            cancelButton.heightAnchor.constraint(equalToConstant: 17),
            cancelButton.widthAnchor.constraint(equalToConstant: 17),
            cancelButton.topAnchor.constraint(equalTo: view.topAnchor, constant: blackBarHeight + 6.5),
            cancelButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -11.5)
        ])
        cancelButton.alpha = 0
        
        cancelButton.addTarget(self, action: #selector(cancelTapped(_:)), for: .touchUpInside)
    }
    
    fileprivate func setupCarouselFilters(){
        let model = [
            FilterModel(image: UIImage(named: "ThumbNoFilter"), displayName: "No Filter", filterName: nil),
            FilterModel(image: UIImage(named: "ThumbNoir"), displayName: "Noir", filterName: "CIPhotoEffectNoir"),
            FilterModel(image: UIImage(named: "ThumbChrome"), displayName: "Chrome", filterName: "CIPhotoEffectChrome"),
            FilterModel(image: UIImage(named: "ThumbInstant"), displayName: "Instant", filterName: "CIPhotoEffectInstant"),
        ]
        carouselView.model = model
        carouselView.delegate = self
    }
    
    fileprivate func setupManager(){
        previewManager = PreviewManager()
        previewManager?.delegate = self
        previewManager?.start()
    }
    
    //MARK:- Actions
    @objc fileprivate func cancelTapped(_ sender: UIButton) {
        //pause the player so the audio doesn't continue until the manager is deallocated
        previewManager?.pause()
        animateOut()
    }
    
    //MARK:- Functions
    fileprivate func addPlayerLayer(_ playerLayer: AVPlayerLayer) {
        view.layer.insertSublayer(playerLayer, below: recordingButton.layer)
        playerLayer.frame = view.layer.frame
        playerLayer.opacity = 0
        self.playerLayer = playerLayer
    }
    
    fileprivate func animateIn(){
        //this is going to "transform" the recording button into the carousel view
        fadePlayerLayer(visible: true)
        carouselView.updateLayout()
        UIView.animate(withDuration: 0.15, animations: { [weak self] in
            guard let self = self else {return}
            self.recordingButton.transform = CGAffineTransform(translationX: 0, y: -25)
        }) {[weak self] _ in
            guard let self = self else {return}
            UIView.animate(withDuration: 0.15, animations: {
                self.recordingButton.alpha = 0
                self.carouselView.alpha = 1
                self.carouselView.currentFilterView.alpha = 1
                self.carouselView.currentFilterLabel.alpha = 1
                for iv in self.carouselView.imageViews {
                    iv.alpha = 1
                }
            }) { [weak self] _ in
                guard let self = self else {return}
                self.carouselView.isUserInteractionEnabled = true
                self.recordingButton.transform = .identity
            }
        }
        
    }
    
    fileprivate func animateOut(){
        fadePlayerLayer(visible: false)
        UIView.animate(withDuration: 0.15, animations: {
            for iv in self.carouselView.imageViews {
                iv.alpha = 0
            }
            self.carouselView.transform = CGAffineTransform(translationX: 0, y: 25)
            self.carouselView.currentFilterView.transform = CGAffineTransform(translationX: 0, y: 25)
            self.carouselView.currentFilterLabel.alpha = 0
        }) { [weak self] _ in
            guard let self = self else {return}
            UIView.animate(withDuration: 0.15, animations: {
                self.carouselView.currentFilterView.alpha = 0
                self.recordingButton.alpha = 1
                self.cancelButton.alpha = 0
            }) { [weak self] _ in
                guard let self = self else {return}
                self.dismiss(animated: false, completion: nil)
            }
        }
    }
    
    fileprivate func fadePlayerLayer(visible: Bool){
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = visible ? 0 : 1
        animation.toValue = visible ? 1 : 0
        animation.duration = 0.2
        animation.timingFunction = .init(name: CAMediaTimingFunctionName.easeInEaseOut)
        playerLayer?.add(animation, forKey: nil)
        playerLayer?.opacity = visible ? 1 : 0
    }
    
}

//MARK:- PreviewManagerDelegate
extension PreviewViewController : PreviewManagerDelegate {
    func previewStarted(_ manager: PreviewManager) {
        self.animateIn()
    }
    
    func previewLayerReady(playerLayer: AVPlayerLayer, _ manager: PreviewManager) {
        addPlayerLayer(playerLayer)
    }
    
    func previewError(_ manager: PreviewManager) {
        let warning = UIAlertController(title: "Ooops", message: "Couldn't load your videos", preferredStyle: .alert)
        warning.addAction(UIAlertAction(title: "Try again", style: .default, handler: { [weak self] _ in
            guard let self = self else {return}
            //take user back to recording screen
            self.animateOut()
        }))
        self.present(warning, animated: true, completion: nil)
    }
}

//MARK:- FilterCarouselViewDelegate
extension PreviewViewController : FilterCarouselViewDelegate {
    func didSelectModel(model: FilterModel, view: FilterCarouselView) {
        previewManager?.changeFilterTo(filterWithName: model.filterName)
    }
    
}
