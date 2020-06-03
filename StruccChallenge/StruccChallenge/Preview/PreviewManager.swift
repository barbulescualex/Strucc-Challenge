//
//  PreviewManager.swift
//  StruccChallenge
//
//  Created by Alex Barbulescu on 2020-06-02.
//  Copyright © 2020 ca.alexs. All rights reserved.
//

import UIKit
import AVFoundation

protocol PreviewManagerDelegate : AnyObject {
    /* tells delegate that the preview has started*/
    func previewStarted(_ manager: PreviewManager)
    
    /* tells delegate that the preview layer is ready to be added to the view hierarchy */
    func previewLayerReady(playerLayer: AVPlayerLayer, _ manager: PreviewManager)
    
    /* tells delegate that there is an error with the manager */
    func previewError(_ manager: PreviewManager)
}

/* handles creating an AVComposition from the 2 videos recorded in the recording scene and playing them */
class PreviewManager: NSObject {
    //MARK:- Vars
    public weak var delegate : PreviewManagerDelegate?
    
    //player
    fileprivate var player : AVPlayer?
    
    //track IDs
    static let videoTrack1ID = CMPersistentTrackID(1)
    static let audioTrack1ID = CMPersistentTrackID(2)
    static let videoTrack2ID = CMPersistentTrackID(3)
    static let audioTrack2ID = CMPersistentTrackID(4)
    
    //MARK:- Setup
    public func start(){
        DispatchQueue.global(qos: .userInteractive).async {
            //get the 2 urls
            let directory = FileManager.default.temporaryDirectory

            let url1 = directory.appendingPathComponent("video1.mp4")
            let url2 = directory.appendingPathComponent("video2.mp4")

            //get asset representation for the 2 videos
            let foregroundAsset = AVAsset(url: url1)
            let backgroundAsset = AVAsset(url: url2)

            //check that the assets are composable
            if !foregroundAsset.isComposable {
               DispatchQueue.main.async{
                   self.delegate?.previewError(self)
               }
            }

            if !backgroundAsset.isComposable {
               DispatchQueue.main.async{
                   self.delegate?.previewError(self)
               }
            }

            //make composition from the 2 assets
            guard let composition = self.makeComposition(from: foregroundAsset, asset2: backgroundAsset) else {return}

            //make video composition
            let videoCompostion = self.makeVideoComposition(fromComposition: composition)

            //start playing video!
            self.makeAndStartPlayer(fromComposition: composition, usingVideoComposition: videoCompostion)
        }
    }
    
    /* returns a composition with both the video and audio tracks from both assets */
    fileprivate func makeComposition(from asset1: AVAsset, asset2: AVAsset) -> AVMutableComposition? {
        //create composition
        let composition = AVMutableComposition()
        
        //find time duration
        let timeDuration = asset1.duration > asset2.duration ? asset2.duration : asset1.duration

        //male time range
        let timeRange = CMTimeRangeMake(start: .zero, duration: timeDuration)

        //place wanted tracks from the 2 videos inside composition
        
        //video track 1
        guard let videoTrack1 = composition.addMutableTrack(withMediaType: .video, preferredTrackID: PreviewManager.videoTrack1ID) else {
            print("couldn't make videoTrack1")
            DispatchQueue.main.async {
                self.delegate?.previewError(self)
            }
            return nil
        }
        
        do {
            //fine if call to tracks on asset blocks, thread has nothing else to do until the track is available
            try videoTrack1.insertTimeRange(timeRange, of: asset1.tracks(withMediaType: .video)[0], at: .zero)
        } catch {
            print("failed to load videoTrack1 with error: ", error.localizedDescription)
            DispatchQueue.main.async {
                self.delegate?.previewError(self)
            }
            return nil
        }

        //video track 2
        guard let videoTrack2 = composition.addMutableTrack(withMediaType: .video, preferredTrackID: PreviewManager.videoTrack2ID) else {
            print("coudln't make videoTrack2")
            return nil
        }

        do {
            try videoTrack2.insertTimeRange(timeRange, of: asset2.tracks(withMediaType: .video)[0], at: .zero)
        } catch {
            print("failed to load videoTrack2 with error: ", error.localizedDescription)
            DispatchQueue.main.async {
                self.delegate?.previewError(self)
            }
            return nil
        }

        //audio track 1
        guard let audioTrack1 = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: PreviewManager.audioTrack1ID) else {
            print("coudln't make audioTrack1")
            DispatchQueue.main.async {
                self.delegate?.previewError(self)
            }
            return nil
        }

        do {
            try audioTrack1.insertTimeRange(timeRange, of: asset1.tracks(withMediaType: .audio)[0], at: .zero)
        } catch {
            print("failed to load audioTrack1 with error: ", error.localizedDescription)
            DispatchQueue.main.async {
                self.delegate?.previewError(self)
            }
            print("failed to load audioTrack1 with error: ", error.localizedDescription)
        }

        //audio track 2
        guard let audioTrack2 = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: PreviewManager.audioTrack2ID) else {
            print("coudln't make audioTrack2")
            DispatchQueue.main.async {
                self.delegate?.previewError(self)
            }
            return nil
        }

        do {
            try audioTrack2.insertTimeRange(timeRange, of: asset2.tracks(withMediaType: .audio)[0], at: .zero)
        } catch {
            print("failed to load audioTrack2 with error: ", error.localizedDescription)
            DispatchQueue.main.async {
                self.delegate?.previewError(self)
            }
            return nil
        }
        
        return composition
    }
    
    /* returns a formatted video composition from the composition */
    fileprivate func makeVideoComposition(fromComposition composition: AVComposition) -> AVMutableVideoComposition {
        let videoComposition = AVMutableVideoComposition(propertiesOf: composition)
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        videoComposition.renderSize = CGSize(width: 1080, height: 1920)
        videoComposition.renderScale = 1.0
        videoComposition.customVideoCompositorClass = CustomCompositor.self
        return videoComposition
    }
    
    /* starts a player, returns preview layer to delegate */
    fileprivate func makeAndStartPlayer(fromComposition composition: AVComposition, usingVideoComposition vcomposition: AVVideoComposition) {
        //make player item
        let playerItem = AVPlayerItem(asset: composition)
        playerItem.videoComposition = vcomposition
        
        //make item
        player = AVPlayer(playerItem: playerItem)
        
        //subscribe to end notification
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidReachEnd(notification:)), name: .AVPlayerItemDidPlayToEndTime, object: nil)
        
        //get layer and pass to delegate
        let playerLayer = AVPlayerLayer(player: player)
        
        DispatchQueue.main.async {
            self.delegate?.previewLayerReady(playerLayer: playerLayer, self)
            //start playing after delegate adds layer as sublayer
            self.player?.play()
        }
    }
    //MARK:- Functions
    public func changeFilterTo(filterWithName name: String?) {
        if let name = name {
            if let filter = CIFilter(name: name) {
                CurrentFilter.shared.filter = filter
            } else {
                self.delegate?.previewError(self)
            }
        } else { //no filter
            CurrentFilter.shared.filter = nil
        }
    }
    
    //MARK:- Notification Handlers
    @objc func playerItemDidReachEnd(notification: NSNotification) {
        player?.seek(to: .zero)
        player?.play()
    }
    
    //MARK:- Deinit
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

//MARK:- Current Filter Singleton

/* singleton that the CustomCompositor can access to get the current filter that it should apply */
class CurrentFilter: NSObject {
    static let shared = CurrentFilter()
    
    public var filter : CIFilter?
}
