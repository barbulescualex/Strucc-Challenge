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
    static let foregroundVideoTrackID = CMPersistentTrackID(1)
    static let foregroundAudioTrackID = CMPersistentTrackID(2)
    
    static let backgroundVideoTrackID = CMPersistentTrackID(3)
    static let backgroundAudioTrackID = CMPersistentTrackID(4)
    
    //MARK:- Setup
    public func start(){
        //reset current filter singleton incase this is a new preview session
        CurrentFilter.shared.filter = nil
        
        DispatchQueue.global(qos: .userInteractive).async {
            //get the 2 urls
            let directory = FileManager.default.temporaryDirectory

            let foregroundURL = directory.appendingPathComponent("video1.mp4")
            let backgroundURL = directory.appendingPathComponent("video2.mp4")

            //get asset representation for the 2 videos
            let foregroundAsset = AVAsset(url: foregroundURL)
            let backgroundAsset = AVAsset(url: backgroundURL)

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
            guard let composition = self.makeComposition(from: foregroundAsset, backgroundAsset: backgroundAsset) else {return}

            //make video composition
            let videoCompostion = self.makeVideoComposition(fromComposition: composition)

            //start playing video!
            self.makeAndStartPlayer(fromComposition: composition, usingVideoComposition: videoCompostion)
        }
    }
    
    /* returns a composition with both the video and audio tracks from both assets */
    fileprivate func makeComposition(from foregroundAsset: AVAsset, backgroundAsset: AVAsset) -> AVMutableComposition? {
        //create composition
        let composition = AVMutableComposition()
        
        //find time duration
        let timeDuration = foregroundAsset.duration > backgroundAsset.duration ? backgroundAsset.duration : foregroundAsset.duration

        //male time range
        let timeRange = CMTimeRangeMake(start: .zero, duration: timeDuration)

        //place wanted tracks from the 2 videos inside composition
        
        //foreground video track
        guard let foregroundVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: PreviewManager.foregroundVideoTrackID) else {
            print("couldn't make foregroundVideoTrack")
            DispatchQueue.main.async {
                self.delegate?.previewError(self)
            }
            return nil
        }
        
        do {
            //fine if call to tracks on asset blocks, thread has nothing else to do until the track is available
            try foregroundVideoTrack.insertTimeRange(timeRange, of: foregroundAsset.tracks(withMediaType: .video)[0], at: .zero)
        } catch {
            print("failed to load foregroundVideoTrack with error: ", error.localizedDescription)
            DispatchQueue.main.async {
                self.delegate?.previewError(self)
            }
            return nil
        }

        //background video track
        guard let backgroundVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: PreviewManager.backgroundVideoTrackID) else {
            print("coudln't make backgroundVideoTrack")
            return nil
        }

        do {
            try backgroundVideoTrack.insertTimeRange(timeRange, of: backgroundAsset.tracks(withMediaType: .video)[0], at: .zero)
        } catch {
            print("failed to load backgroundVideoTrack with error: ", error.localizedDescription)
            DispatchQueue.main.async {
                self.delegate?.previewError(self)
            }
            return nil
        }

        //foreground audio track
        guard let foregroundAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: PreviewManager.foregroundAudioTrackID) else {
            print("coudln't make foregroundAudioTrack")
            DispatchQueue.main.async {
                self.delegate?.previewError(self)
            }
            return nil
        }

        do {
            try foregroundAudioTrack.insertTimeRange(timeRange, of: foregroundAsset.tracks(withMediaType: .audio)[0], at: .zero)
        } catch {
            print("failed to load foregroundAudioTrack with error: ", error.localizedDescription)
            DispatchQueue.main.async {
                self.delegate?.previewError(self)
            }
        }

        //background audio track
        guard let backgroundAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: PreviewManager.backgroundAudioTrackID) else {
            print("coudln't make backgroundAudioTrack")
            DispatchQueue.main.async {
                self.delegate?.previewError(self)
            }
            return nil
        }

        do {
            try backgroundAudioTrack.insertTimeRange(timeRange, of: backgroundAsset.tracks(withMediaType: .audio)[0], at: .zero)
        } catch {
            print("failed to load backgroundAudioTrack with error: ", error.localizedDescription)
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
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidReachEnd(_:)), name: .AVPlayerItemDidPlayToEndTime, object: nil)
        
        //get layer and pass to delegate
        let playerLayer = AVPlayerLayer(player: player)
        
        DispatchQueue.main.async {
            self.delegate?.previewLayerReady(playerLayer: playerLayer, self)
            //start playing after delegate adds layer as sublayer
            self.player?.play()
            self.delegate?.previewStarted(self)
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
    
    public func pause(){
        player?.pause()
    }
    
    //MARK:- Notification Handlers
    @objc fileprivate func playerItemDidReachEnd(_ notification: NSNotification) {
        player?.seek(to: .zero)
        player?.play()
    }
    
    //MARK:- Deinit
    deinit {
        //player item has a strong reference to the Custom Compositor which leads to a memory leak
        player?.replaceCurrentItem(with: nil)
        NotificationCenter.default.removeObserver(self)
    }
}

//MARK:- Current Filter Singleton

/* singleton that the CustomCompositor can access to get the current filter that it should apply */
class CurrentFilter: NSObject {
    static let shared = CurrentFilter()
    
    public var filter : CIFilter?
}
