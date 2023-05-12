//
//  VideoPlayerViewController.swift
//  RapsodoApp
//
//  Created by Ömer Faruk Başaran on 8.05.2023.
//

import UIKit
import AVKit

class VideoPlayerViewController: UIViewController {

    var videoURL: URL?

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let videoURL = videoURL else {
            print("Video URL is nil")
            return
        }

        let player = AVPlayer(url: videoURL)
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player

        addChild(playerViewController)
        view.addSubview(playerViewController.view)
        playerViewController.view.frame = view.frame
        playerViewController.didMove(toParent: self)

        player.play()
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
