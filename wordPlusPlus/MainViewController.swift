//
//  MainViewController.swift
//  wordPlusPlus
//
//  Created by David Lam on 6/10/16.
//  Copyright © 2016 David Lam. All rights reserved.
//

import UIKit
import RandomColorSwift
import AVFoundation
import DynamicColor
import RxSwift
import RxCocoa



class MainViewController: UIViewController {

    @IBOutlet weak var volumeControlSlider: UISlider!
    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet var swipeGestureRecognizer: UISwipeGestureRecognizer!
    @IBOutlet weak var playButton: UIButton!
    
    let disposeBag = DisposeBag()

    var viewModel = PlayerViewModel()
   
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.speechSynthesizer.delegate = self
        
        setupAudioSession()
        textLabel.text = "Press play to start"
        viewModel.speechSynthesizer.continueSpeaking()
        
        _ = volumeControlSlider.rx.value.asControlProperty()
        .subscribe(onNext: { (sliderValue) in
            self.viewModel.volume = sliderValue
        }).addDisposableTo(self.disposeBag)
        
        _ = viewModel.currentWordSignal.subscribe(onNext: { (newWord) in
            let newColor = randomColor(luminosity: Luminosity.bright)
            self.textLabel.textColor = newColor
            self.view.backgroundColor = newColor.complemented()
            self.textLabel.text = newWord
        })
        
        _ = playButton.rx.controlEvent(.touchUpInside).asControlEvent()
        .throttle(0.1, scheduler: MainScheduler.instance)
        .subscribe({ _ in
            self.updatePlayState()
            let imageForState = self.viewModel.playState.iconForState()
            self.playButton.setImage(imageForState, for: UIControlState.normal)
            let isPlaying = (self.viewModel.playState == .play)
            guard let sharedDefaults = UserDefaults(suiteName: "group.WordPlusPlusExtensionSharingDefaults") else {
                return
            }

            sharedDefaults.set(isPlaying, forKey: "isPlaying")
        })
        
        setUserDefaultsListener()
    }
    
    func setUserDefaultsListener(){
        guard let sharedDefaults = UserDefaults(suiteName: "group.WordPlusPlusExtensionSharingDefaults") else {
            return
        }
        sharedDefaults.addObserver(self, forKeyPath: "isPlaying", options: NSKeyValueObservingOptions.new, context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "isPlaying" {

            dump("i'm here baby")
            guard let sharedDefaults = UserDefaults(suiteName: "group.WordPlusPlusExtensionSharingDefaults") else {
                return
            }
            let viewControllerPlaying = viewModel.playState == .play
            let isPlaying = sharedDefaults.bool(forKey: "isPlaying")
            if isPlaying != viewControllerPlaying {
                    self.updatePlayState()
                    let imageForState = self.viewModel.playState.iconForState()
                    self.playButton.setImage(imageForState, for: UIControlState.normal)
            }
        }
    }
    
    deinit {
        guard let sharedDefaults = UserDefaults(suiteName: "group.WordPlusPlusExtensionSharingDefaults") else {
            return
        }
        sharedDefaults.removeObserver(self, forKeyPath: "isPlaying")
    }
    
    fileprivate func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, mode: AVAudioSessionModeSpokenAudio, options: AVAudioSessionCategoryOptions.mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
        }
        catch {
            NSLog("error found")
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func updatePlayState() {
        self.viewModel.updatePlayState()
        switch self.viewModel.playState {
        case .play:
            break
        case .pause:
            textLabel.text = "Paused"
        }
    }

}

// MARK: - SpeechSynthesizer Delegate

extension MainViewController: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        viewModel.nextWord()
    }
}
