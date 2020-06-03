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
    var previewManager: PreviewManager?
    
    //MARK:- View Components
    fileprivate let carouselView = FilterCarouselView(withModel: [])
    
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
    
    fileprivate func addPlayerLayer(_ playerLayer: AVPlayerLayer) {
        view.layer.insertSublayer(playerLayer, below: carouselView.layer)
        playerLayer.frame = view.layer.frame
    }
}

//MARK:- PreviewManagerDelegate
extension PreviewViewController : PreviewManagerDelegate {
    func previewStarted(_ manager: PreviewManager) {
        
    }
    
    func previewLayerReady(playerLayer: AVPlayerLayer, _ manager: PreviewManager) {
        addPlayerLayer(playerLayer)
    }
    
    func previewError(_ manager: PreviewManager) {
        
    }
}

//MARK:- FilterCarouselViewDelegate
extension PreviewViewController : FilterCarouselViewDelegate {
    func didSelectModel(model: FilterModel, view: FilterCarouselView) {
        previewManager?.changeFilterTo(filterWithName: model.filterName)
    }
    
}
