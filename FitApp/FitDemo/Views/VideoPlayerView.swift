import SwiftUI
import AVKit

struct VideoPlayerView: UIViewRepresentable {
    let videoName: String
    
    func makeUIView(context: Context) -> UIView {
        return VideoPlayerUIView(frame: .zero, videoName: videoName)
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // 当 videoName 改变时，更新视频播放
        if let videoView = uiView as? VideoPlayerUIView {
            videoView.updateVideo(videoName: videoName)
        }
    }
}

class VideoPlayerUIView: UIView {
    private var playerLayer = AVPlayerLayer()
    private var playerLooper: AVPlayerLooper?
    private var currentVideoName: String?
    
    init(frame: CGRect, videoName: String) {
        super.init(frame: frame)
        setupVideo(videoName: videoName)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateVideo(videoName: String) {
        // 只有当视频名称改变时才更新
        if currentVideoName != videoName {
            setupVideo(videoName: videoName)
        }
    }
    
    private func setupVideo(videoName: String) {
        currentVideoName = videoName
        
        guard let path = Bundle.main.path(forResource: videoName, ofType: "mp4") else {
            print("找不到视频文件: \(videoName).mp4")
            return
        }
        
        // 停止当前播放
        if let oldPlayer = playerLayer.player {
            oldPlayer.pause()
        }
        
        let player = AVQueuePlayer()
        let videoURL = URL(fileURLWithPath: path)
        let playerItem = AVPlayerItem(url: videoURL)
        
        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspectFill
        
        if playerLayer.superlayer == nil {
            layer.addSublayer(playerLayer)
        }
        
        // 创建新的循环播放器
        playerLooper = AVPlayerLooper(player: player, templateItem: playerItem)
        player.play()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
}