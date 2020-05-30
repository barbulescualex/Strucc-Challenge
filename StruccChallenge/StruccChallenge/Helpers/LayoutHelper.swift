//
//  LayoutHelper.swift
//  StruccChallenge
//
//  Created by Alex Barbulescu on 2020-05-30.
//  Copyright © 2020 ca.alexs. All rights reserved.
//

import UIKit

/* Reduce boilerplate layout code when constraining one view evenly to another */

extension NSLayoutConstraint {
    static func constrain(firstView: UIView, toSecondView secondView: UIView){
        NSLayoutConstraint.activate([
            firstView.topAnchor.constraint(equalTo: secondView.topAnchor),
            firstView.leadingAnchor.constraint(equalTo: secondView.leadingAnchor),
            firstView.trailingAnchor.constraint(equalTo: secondView.trailingAnchor),
            firstView.bottomAnchor.constraint(equalTo: secondView.bottomAnchor)
        ])
    }
    
    static func constrain(firstView: UIView, toSecondView secondView: UIView, withEqualSpacing spacing: CGFloat){
        NSLayoutConstraint.activate([
            firstView.topAnchor.constraint(equalTo: secondView.topAnchor, constant: spacing),
            firstView.leadingAnchor.constraint(equalTo: secondView.leadingAnchor, constant: spacing),
            firstView.trailingAnchor.constraint(equalTo: secondView.trailingAnchor, constant: -spacing),
            firstView.bottomAnchor.constraint(equalTo: secondView.bottomAnchor, constant: -spacing)
        ])
    }
}
