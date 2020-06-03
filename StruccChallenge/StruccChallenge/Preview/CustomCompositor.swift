//
//  CustomCompositor.swift
//  StruccChallenge
//
//  Created by Alex Barbulescu on 2020-06-02.
//  Copyright © 2020 ca.alexs. All rights reserved.
//

import UIKit
import AVFoundation
import Metal

class CustomCompositor : NSObject, AVVideoCompositing {
    //MARK:- Vars
    var sourcePixelBufferAttributes: [String : Any]? = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
    var requiredPixelBufferAttributesForRenderContext: [String : Any] = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
    
    //alpha filter to apply to foreground video
    fileprivate let alphaFilter = CIFilter(name: "CIColorMatrix")
    
    //context to use core image functions with
    fileprivate var context: CIContext?
    
    //transform to apply to foreground video
    fileprivate var transform : CGAffineTransform?
    
    //MARK:- Init
    override init() {
        super.init()
        setup()
    }
    
    //MARK:- Setup
    /* sets up the necessary components for using Core Image  */
    fileprivate func setup(){
        if let metalDevice = MTLCreateSystemDefaultDevice() {
            context = CIContext(mtlDevice: metalDevice)
        } else {
            context = CIContext()
        }
        
        //create alpha filter
        let colorValues : [CGFloat] = [0,0,0,0.7]
        alphaFilter?.setValue(CIVector(values: colorValues, count: 4), forKey: "inputAVector")
        
        //create transform for foreground video
        transform = CGAffineTransform(scaleX: 0.55, y: 0.55)
        transform = transform?.concatenating(CGAffineTransform(translationX: (1080-0.55*1080)/2, y: (1920 - 0.55*1920)/2))
    }
    
    //MARK:- Requests
    func renderContextChanged(_ newRenderContext: AVVideoCompositionRenderContext) {
        
    }
    
    func startRequest(_ request: AVAsynchronousVideoCompositionRequest) {
        //make sure the necessary tools to adjust the foreground and use Core Image are present
        guard let transform = transform, let alphaFilter = alphaFilter, let context = context else { request.finishCancelledRequest(); return }
        
        //make sure we have input buffers from the source frames and output buffer for the final frame
        guard let resultingPixelBuffer = request.renderContext.newPixelBuffer() else { request.finishCancelledRequest(); return}
        guard let backgroundPixelBuffer = request.sourceFrame(byTrackID: PreviewManager.backgroundVideoTrackID) else { request.finishCancelledRequest(); return}
        guard let foregroundPixelBuffer = request.sourceFrame(byTrackID: PreviewManager.foregroundVideoTrackID) else { request.finishCancelledRequest(); return}
        
        //lock buffers
        lockBuffersToReadyOnly(pixelBuffers: [backgroundPixelBuffer, foregroundPixelBuffer])
        
        //create CIImages from the respective video frames
        var backgroundCIImage = CIImage(cvImageBuffer: backgroundPixelBuffer)
        var foregroundCIImage = CIImage(cvImageBuffer: foregroundPixelBuffer)
        
        //unlock buffers
        unlockBuffersFromReadOnly(pixelBuffers: [backgroundPixelBuffer, foregroundPixelBuffer])
        
        //apply alpha to foreground image
        alphaFilter.setValue(foregroundCIImage, forKey: kCIInputImageKey)
        if let filteredForegroundCIImage = alphaFilter.outputImage {
            foregroundCIImage = filteredForegroundCIImage
        }
        
        //apply transform to foreground image
        foregroundCIImage = foregroundCIImage.transformed(by: transform)
        
        //apply filter to background image (if present)
        if let filterToApply = CurrentFilter.shared.filter {
            filterToApply.setValue(backgroundCIImage, forKey: kCIInputImageKey)
            if let filteredBackgroundCIImage = filterToApply.outputImage {
                backgroundCIImage = filteredBackgroundCIImage
            }
        }
        
        //create final frame
        let resultingCIImage = foregroundCIImage.composited(over: backgroundCIImage)
        context.render(resultingCIImage, to: resultingPixelBuffer)
        request.finish(withComposedVideoFrame: resultingPixelBuffer)
    }
    
    //MARK:- Functions
    fileprivate func lockBuffersToReadyOnly(pixelBuffers: [CVPixelBuffer]){
        for buffer in pixelBuffers {
            CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags.readOnly)
        }
    }
    
    fileprivate func unlockBuffersFromReadOnly(pixelBuffers: [CVPixelBuffer]){
        for buffer in pixelBuffers {
            CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags.readOnly)
        }
    }
    
    
}
