//
//  CAHelper.swift
//  StruccChallenge
//
//  Created by Alex Barbulescu on 2020-05-30.
//  Copyright © 2020 ca.alexs. All rights reserved.
//

import UIKit

/* Abstract path making code for the recording button */

class CALayerHelper {
    static func makeCirclePath(inSize size: CGFloat, withScale scale: CGFloat) -> CGPath {
        let circleSize = CGSize(width: size*scale, height: size*scale)
        let circleOrigin = CGPoint(x: (size - circleSize.width)/2, y: (size - circleSize.height)/2)
        let circleRect = CGRect(origin: circleOrigin, size: circleSize)
        let cornerRadius = circleSize.height/2
        
        return UIBezierPath(roundedRect: circleRect, cornerRadius: cornerRadius).cgPath
    }
    
    static func makeSquarePath(inSize size: CGFloat, withScale scale: CGFloat, cornerRadius radius: CGFloat) -> CGPath {
        let squareSize = CGSize(width: size*scale, height: size*scale)
        let squareOrigin = CGPoint(x: (size - squareSize.width)/2, y: (size - squareSize.height)/2)
        let squareRect = CGRect(origin: squareOrigin, size: squareSize)
        
        return UIBezierPath(roundedRect: squareRect, cornerRadius: radius).cgPath
    }
}
