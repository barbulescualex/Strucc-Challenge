//
//  FilterCarousel.swift
//  StruccChallenge
//
//  Created by Alex Barbulescu on 2020-06-01.
//  Copyright © 2020 ca.alexs. All rights reserved.
//

import UIKit

/* notifies delegate a new filter has been selected */
protocol FilterCarouselViewDelegate : AnyObject {
    func didSelectModel(model: FilterModel, view: FilterCarouselView)
}

/* Carousel view to display filters */
class FilterCarouselView: UIView {
    //MARK:- Vars
    public var model : [FilterModel] = [] {
        didSet{
            startPos = 2
            modelPos = 0
            updateView()
        }
    }
    
    public weak var delegate : FilterCarouselViewDelegate?
    
    //internal state
    fileprivate var modelPos = 0
    fileprivate var currentFilterIndex = 0
    fileprivate var startPos = 2
    
    fileprivate var spacingBetweenPreviews : CGFloat = 0
    
    //MARK:- View Components
    public let currentFilterLabel : UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.font = UIFont(name: "PostGrotesk-Bold", size: 14)
        label.layer.shadowColor = UIColor.black.cgColor
        label.layer.shadowRadius = 4
        label.layer.shadowOffset = .zero
        label.layer.shadowOpacity = 0.8
        return label
    }()
    
    public let currentFilterView : UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.borderColor = UIColor.white.cgColor
        view.layer.borderWidth = 4
        return view
    }()
    
    public var imageViews : [UIImageView] = []
    
    //MARK:- Init
    public init(withModel model: [FilterModel]) {
        super.init(frame: .zero)
        setupView()
        self.model = model
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK:- View Setup
    fileprivate func setupView(){
        translatesAutoresizingMaskIntoConstraints = false
        
        //create the 7 image views which house the filter preview images and set them up, 5 visible, 2 off screen and used for transitions
        for i in 0..<7 {
            let imageView = UIImageView()
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.tag = i
            imageView.contentMode = .scaleAspectFill
            imageView.alpha = 0
            imageViews.append(imageView)
            if i != 3 {
                addSubview(imageView)
                NSLayoutConstraint.activate([
                    imageView.widthAnchor.constraint(equalToConstant: 42),
                    imageView.heightAnchor.constraint(equalToConstant: 42)
                ])
                imageView.layer.cornerRadius = 42/2
                imageView.clipsToBounds = true
            } else {
                let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(tappedFilter(_:)))
                imageView.addGestureRecognizer(tapRecognizer)
                imageView.isUserInteractionEnabled = true
            }
        }
        
        //gesture recognizers
        let rightSwipeRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(swipedFilters(_:)))
        rightSwipeRecognizer.direction = .right
        addGestureRecognizer(rightSwipeRecognizer)
        
        let leftSwipeRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(swipedFilters(_:)))
        leftSwipeRecognizer.direction = .left
        addGestureRecognizer(leftSwipeRecognizer)
        
        //let the swipe gestures through since these are not part of this view's hierarchy
        currentFilterView.isUserInteractionEnabled = false
        currentFilterLabel.isUserInteractionEnabled = false
    }
    
    /* called by superview after it has positioned the currentFilterView and label so that the rest of the view can configure itself accordingly */
    public func updateLayout(){
        //updated center imageView to be in the currentFilterView
        currentFilterView.addSubview(imageViews[3])
        NSLayoutConstraint.constrain(firstView: imageViews[3], toSecondView: currentFilterView, withEqualSpacing: 4)
        imageViews[3].layer.cornerRadius = (70-4*2)/2
        imageViews[3].clipsToBounds = true
        
        //get equal spacing between all the inactive filter views around the center active view
        let halfCurrentFilterViewWidth = currentFilterView.frame.width/2
        let inactiveFilterViewWidth = imageViews[0].frame.width
        spacingBetweenPreviews = (self.bounds.width/2 - (inactiveFilterViewWidth*2 + halfCurrentFilterViewWidth))/3

        NSLayoutConstraint.activate([//from left to right
            imageViews[1].centerYAnchor.constraint(equalTo: currentFilterView.centerYAnchor),
            imageViews[1].leadingAnchor.constraint(equalTo: leadingAnchor, constant: spacingBetweenPreviews),

            imageViews[2].centerYAnchor.constraint(equalTo: currentFilterView.centerYAnchor),
            imageViews[2].leadingAnchor.constraint(equalTo: imageViews[1].trailingAnchor, constant: spacingBetweenPreviews),

            imageViews[4].centerYAnchor.constraint(equalTo: currentFilterView.centerYAnchor),
            imageViews[4].leadingAnchor.constraint(equalTo: currentFilterView.trailingAnchor, constant: spacingBetweenPreviews),

            imageViews[5].centerYAnchor.constraint(equalTo: currentFilterView.centerYAnchor),
            imageViews[5].leadingAnchor.constraint(equalTo: imageViews[4].trailingAnchor, constant: spacingBetweenPreviews),
            
            //image views outside bounds
            imageViews[0].centerYAnchor.constraint(equalTo: currentFilterView.centerYAnchor),
            imageViews[0].trailingAnchor.constraint(equalTo: imageViews[1].leadingAnchor, constant: -spacingBetweenPreviews),
            
            imageViews[6].centerYAnchor.constraint(equalTo: currentFilterView.centerYAnchor),
            imageViews[6].leadingAnchor.constraint(equalTo: imageViews[5].trailingAnchor, constant: spacingBetweenPreviews)
        ])
    }
    
    //MARK:- Carousel Functions
    @objc fileprivate func tappedFilter(_ sender: UITapGestureRecognizer){
        guard let tag = sender.view?.tag else {return}
        
        if tag < startPos {return} //out of bounds
        
        //find model idx user is refering to
        let newFilterIndex = currentFilterIndex - (3 - tag)
        updateCarousel(toIndex: newFilterIndex)
    }
    
    @objc fileprivate func swipedFilters(_ sender: UISwipeGestureRecognizer){
        var direction : UISwipeGestureRecognizer.Direction = .left
        switch sender.direction {
        case .right:
            direction = .right
        case .left:
            direction = .left
        default:
            return
        }
        
        let newFilterIndex = currentFilterIndex + ((direction == .left) ? 1 : -1)
        updateCarousel(toIndex: newFilterIndex)
    }
    
    fileprivate func updateCarousel(toIndex index: Int){
        if index >= model.count || index < 0 || index == currentFilterIndex { return } //out of bounds
        
        let animateToLeft = index > currentFilterIndex
        let increment = animateToLeft ? 1 : -1
        let animationDuration = 0.2/Double(abs(index-currentFilterIndex))
        
        delegate?.didSelectModel(model: model[index], view: self)
        self.isUserInteractionEnabled = false
        updateCarouselHelper(startIndex: currentFilterIndex + increment, increment: increment, targetIndex: index, animationDuration: animationDuration)
        self.isUserInteractionEnabled = true
    }
    
    fileprivate func updateCarouselHelper(startIndex index: Int, increment: Int, targetIndex: Int, animationDuration: Double){
        let done = (index == targetIndex)
        
        let nextIndex = index + increment
        let animateToLeft = nextIndex > currentFilterIndex
        
        updatePositions(forIndex: index)
        
        updateViewAnimated(toLeft: animateToLeft, duration: animationDuration) {
            if done {
                //update label
                self.currentFilterLabel.text = self.model[self.currentFilterIndex].displayName
                return
            }
            self.updateCarouselHelper(startIndex: nextIndex, increment: increment, targetIndex: targetIndex, animationDuration: animationDuration)
        }
    }
    
    fileprivate func updatePositions(forIndex index: Int){
        var newStartPos = 3 - index
               
        if startPos == 0 { //only the model moves it's start position
           modelPos = modelPos + (index - currentFilterIndex)
           newStartPos = 0
        }

        if modelPos < 0 { //back to start of model visible
           modelPos = 0
           newStartPos = 3 - index
        }

        currentFilterIndex = index
        startPos = newStartPos
    }
    
    fileprivate func updateView(){
        var cpos = startPos //for carousel
        var mpos = modelPos //for model
        
        for iv in imageViews {
            iv.transform = .identity
            iv.image = nil
        }
        while(cpos < 5 && mpos < model.count) {
            let filter = model[mpos]
            imageViews[cpos+1].image = filter.image
            cpos += 1
            mpos += 1
        }
        currentFilterLabel.text = model[currentFilterIndex].displayName
    }
    
    fileprivate func updateViewAnimated(toLeft left: Bool, duration: Double, completion: @escaping()->Void){
        var cpos = startPos //for carousel
        var mpos = modelPos //for model
        
        let activePreviewWidth = imageViews[3].frame.width
        let inactivePreviewWidth = imageViews[0].frame.width
        
        let scaleFromInactiveToActive = CGFloat(activePreviewWidth)/CGFloat(inactivePreviewWidth)
        let scaleFromActiveToInactive = CGFloat(inactivePreviewWidth)/CGFloat(activePreviewWidth)
        
        let delta = activePreviewWidth - inactivePreviewWidth
        let borderWidth = (currentFilterView.frame.width - activePreviewWidth)/2
        
        //distance to travel for inactive to inactive
        let distanceA = spacingBetweenPreviews + inactivePreviewWidth
        
        //distance to travel for inactive to active
        let distanceB = spacingBetweenPreviews + activePreviewWidth - delta/2 + borderWidth
        
        //distance to travel for active to inactive
        let distanceC = spacingBetweenPreviews + inactivePreviewWidth + delta/2 + borderWidth
        
        UIView.animate(withDuration: duration, animations: {
            self.imageViews[left ? 6 : 0].transform = CGAffineTransform(translationX: (left ? -1 : 1)*distanceA, y: 0)
            self.imageViews[left ? 5 : 1].transform = CGAffineTransform(translationX: (left ? -1 : 1)*distanceA, y: 0)
            self.imageViews[left ? 4 : 2].transform = CGAffineTransform(scaleX: scaleFromInactiveToActive, y: scaleFromInactiveToActive).concatenating(CGAffineTransform(translationX: (left ? -1 : 1)*distanceB, y: 0))
            self.imageViews[3].transform = CGAffineTransform(scaleX: scaleFromActiveToInactive, y: scaleFromActiveToInactive).concatenating( CGAffineTransform(translationX: (left ? -1 : 1)*distanceC, y: 0))
            self.imageViews[left ? 2 : 4].transform = CGAffineTransform(translationX: (left ? -1 : 1)*distanceA, y: 0)
            self.imageViews[left ? 1 : 5].transform = CGAffineTransform(translationX: (left ? -1 : 1)*distanceA, y: 0)
            self.imageViews[left ? 0 : 6].transform = CGAffineTransform(translationX: (left ? -1 : 1)*distanceA, y: 0)
            self.layoutIfNeeded()
        }) { _ in
            for iv in self.imageViews {
                iv.transform = .identity
                iv.image = nil
            }
            while(cpos < 7 && mpos < self.model.count) {
                let filter = self.model[mpos]
                self.imageViews[cpos].image = filter.image
                    cpos += 1
                    mpos += 1
            }
            completion()
        }
    }
    
}


