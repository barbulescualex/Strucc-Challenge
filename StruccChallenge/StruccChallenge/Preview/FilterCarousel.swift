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
    fileprivate var layoutUpdated = false
    
    //MARK:- View Components
    private let currentFilterLabel : UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.font = UIFont(name: "PostGrotesk-Bold", size: 14)
        label.shadowColor = UIColor(white: 0, alpha: 0.8)
        label.layer.shadowRadius = 4
        return label
    }()
    
    private let currentFilterView : UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var imageViews : [UIImageView] = []
    
    //MARK:- Init
    public init(withModel model: [FilterModel]) {
        super.init(frame: .zero)
        setupView()
        self.model = model
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK:- Lifecycle
    override func layoutSubviews() {
        super.layoutSubviews()
        updateLayout()
    }
    
    //MARK:- View Setup
    fileprivate func setupView(){
        translatesAutoresizingMaskIntoConstraints = false
        
        //create the 5 image views which house the filter preview images and set them up
        for i in 0..<5 {
            let imageView = UIImageView()
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.tag = i
            imageView.contentMode = .scaleAspectFill
            imageViews.append(imageView)
            if i != 2 {
                addSubview(imageView)
                NSLayoutConstraint.activate([
                    imageView.widthAnchor.constraint(equalToConstant: 42),
                    imageView.heightAnchor.constraint(equalToConstant: 42)
                ])
                imageView.layer.cornerRadius = 42/2
                imageView.clipsToBounds = true
            }
            let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(tappedFilter(_:)))
            imageView.addGestureRecognizer(tapRecognizer)
            imageView.isUserInteractionEnabled = true
        }
        
        //current filter view
        addSubview(currentFilterView)
        addSubview(currentFilterLabel)
        
        currentFilterView.layer.cornerRadius = 70/2
        
        NSLayoutConstraint.activate([
            currentFilterView.heightAnchor.constraint(equalToConstant: 70),
            currentFilterView.widthAnchor.constraint(equalToConstant: 70),
            currentFilterView.centerXAnchor.constraint(equalTo: centerXAnchor),
            currentFilterView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -49),
            
            currentFilterLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            currentFilterLabel.topAnchor.constraint(equalTo: currentFilterView.bottomAnchor, constant: 20)
        ])
        
        currentFilterView.addSubview(imageViews[2])
        NSLayoutConstraint.constrain(firstView: imageViews[2], toSecondView: currentFilterView, withEqualSpacing: 4)
        imageViews[2].layer.cornerRadius = (70-4*2)/2
        imageViews[2].clipsToBounds = true
        
        //gesture recognizers
        let rightSwipeRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(swipedFilters(_:)))
        rightSwipeRecognizer.direction = .right
        addGestureRecognizer(rightSwipeRecognizer)
        
        let leftSwipeRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(swipedFilters(_:)))
        leftSwipeRecognizer.direction = .left
        addGestureRecognizer(leftSwipeRecognizer)
    }
    
    fileprivate func updateLayout(){
        if layoutUpdated { return }
        
        //get equal spacing between all the inactive filter views around the center active view
        let halfCurrentFilterViewWidth = currentFilterView.frame.width/2
        let inactiveFilterViewWidth = imageViews[0].frame.width
        let spacingBetweenPreviews = (self.bounds.width/2 - (inactiveFilterViewWidth*2 + halfCurrentFilterViewWidth))/3

        NSLayoutConstraint.activate([//from left to right
            imageViews[0].centerYAnchor.constraint(equalTo: currentFilterView.centerYAnchor),
            imageViews[0].leadingAnchor.constraint(equalTo: leadingAnchor, constant: spacingBetweenPreviews),

            imageViews[1].centerYAnchor.constraint(equalTo: currentFilterView.centerYAnchor),
            imageViews[1].leadingAnchor.constraint(equalTo: imageViews[0].trailingAnchor, constant: spacingBetweenPreviews),

            imageViews[3].centerYAnchor.constraint(equalTo: currentFilterView.centerYAnchor),
            imageViews[3].leadingAnchor.constraint(equalTo: currentFilterView.trailingAnchor, constant: spacingBetweenPreviews),

            imageViews[4].centerYAnchor.constraint(equalTo: currentFilterView.centerYAnchor),
            imageViews[4].leadingAnchor.constraint(equalTo: imageViews[3].trailingAnchor, constant: spacingBetweenPreviews),
        ])
        
        layoutUpdated = true
    }
    
    //MARK:- Carousel Functions
    @objc fileprivate func tappedFilter(_ sender: UITapGestureRecognizer){
        guard let tag = sender.view?.tag else {return}
        
        if tag < startPos {return} //out of bounds
        
        //find model idx user is refering to
        let newFilterIndex = currentFilterIndex - (2 - tag)
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
        
        var newStartPos = 2 - index
        
        if startPos == 0 { //only the model moves it's start position
            modelPos = modelPos + (index - currentFilterIndex)
            newStartPos = 0
        }
        
        if modelPos < 0 { //back to start of model visible
            modelPos = 0
            newStartPos = 2 - index
        }
        
        currentFilterIndex = index
        startPos = newStartPos
        
        delegate?.didSelectModel(model: model[currentFilterIndex], view: self)
        updateView()
    }
    
    fileprivate func updateView(){
        var cpos = startPos //for carousel
        var mpos = modelPos //for model
        for iv in imageViews {
            iv.image = nil
        }
        while(cpos < 5 && mpos < model.count) {
            let filter = model[mpos]
            imageViews[cpos].image = filter.image
            cpos += 1
            mpos += 1
        }
        currentFilterLabel.text = model[currentFilterIndex].displayName
    }
    
    
}


