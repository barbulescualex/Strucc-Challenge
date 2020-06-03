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
    
    //filters
    fileprivate let filter = CIFilter(name: "CIComicEffect")
    fileprivate let alphaFilter = CIFilter(name: "CIColorMatrix")
    fileprivate var context: CIContext?
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
        guard let filter = filter, let transform = transform, let alphaFilter = alphaFilter, let context = context else { request.finishCancelledRequest(); return }
        
        //make sure we have input buffers from the source frames and output buffer for the final frame
        guard let resultingPixelBuffer = request.renderContext.newPixelBuffer() else { request.finishCancelledRequest(); return}
        guard let backgroundPixelBuffer = request.sourceFrame(byTrackID: PreviewManager.videoTrack2ID) else { request.finishCancelledRequest(); return}
        guard let foregorundPixelBuffer = request.sourceFrame(byTrackID: PreviewManager.videoTrack1ID) else { request.finishCancelledRequest(); return}
        
        //lock buffers
        lockBuffersToReadyOnly(pixelBuffers: [backgroundPixelBuffer, foregorundPixelBuffer])
        
        //create CIImages from the respective video frames
        var backgroundCIImage = CIImage(cvImageBuffer: backgroundPixelBuffer)
        var foregroundCIImage = CIImage(cvImageBuffer: foregorundPixelBuffer)
        
        //unlock buffers
        unlockBuffersFromReadOnly(pixelBuffers: [backgroundPixelBuffer, foregorundPixelBuffer])
        
        //apply alpha to foreground image
        alphaFilter.setValue(foregroundCIImage, forKey: kCIInputImageKey)
        if let filteredForegroundCIImage = alphaFilter.outputImage {
            foregroundCIImage = filteredForegroundCIImage
        }
        
        //apply transform to foreground image
        foregroundCIImage = foregroundCIImage.transformed(by: transform)
        
        //apply filter to background image
        filter.setValue(backgroundCIImage, forKey: kCIInputImageKey)
        if let filteredBackgroundCIImage = filter.outputImage {
            backgroundCIImage = filteredBackgroundCIImage
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
