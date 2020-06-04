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
        return button
    }()
    
    fileprivate var playerLayer : AVPlayerLayer?
    
    //MARK:- Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupCarouselFilters()
        setupManager()
    }
    
    //MARK:- Setup
    fileprivate func setupView(){
        //self
        view.backgroundColor = .black
        
        //carousel
        view.addSubview(carouselView)
        NSLayoutConstraint.activate([
            carouselView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            carouselView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            carouselView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            carouselView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.25)
        ])
        carouselView.isUserInteractionEnabled = false
        
        //cancel button
        view.addSubview(cancelButton)
        NSLayoutConstraint.activate([
            cancelButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            cancelButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12)
        ])
        
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
        self.dismiss(animated: true, completion: nil)
    }
    
    //MARK:- Functions
    fileprivate func addPlayerLayer(_ playerLayer: AVPlayerLayer) {
        view.layer.insertSublayer(playerLayer, below: carouselView.layer)
        playerLayer.frame = view.layer.frame
        self.playerLayer = playerLayer
    }
    
}

//MARK:- PreviewManagerDelegate
extension PreviewViewController : PreviewManagerDelegate {
    func previewStarted(_ manager: PreviewManager) {
        carouselView.isUserInteractionEnabled = true
    }
    
    func previewLayerReady(playerLayer: AVPlayerLayer, _ manager: PreviewManager) {
        addPlayerLayer(playerLayer)
    }
    
    func previewError(_ manager: PreviewManager) {
        let warning = UIAlertController(title: "Ooops", message: "Couldn't load your videos", preferredStyle: .alert)
        warning.addAction(UIAlertAction(title: "Try again", style: .default, handler: { [weak self] _ in
            guard let self = self else {return}
            //take user back to recording screen
            self.dismiss(animated: true, completion: nil)
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
