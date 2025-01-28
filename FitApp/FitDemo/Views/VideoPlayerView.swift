import SwiftUI
import AVKit

struct VideoPlayerView: UIViewRepresentable {
    let videoName: String
    
    func makeUIView(context: Context) -> UIView {
        return VideoPlayerUIView(frame: .zero, videoName: videoName)
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

class VideoPlayerUIView: UIView {
    private var playerLayer = AVPlayerLayer()
    private var playerLooper: AVPlayerLooper?
    
    init(frame: CGRect, videoName: String) {
        super.init(frame: frame)
        
        guard let path = Bundle.main.path(forResource: videoName, ofType: "mp4") else {
            print("找不到视频文件: \(videoName).mp4")
            return
        }
        
        let player = AVQueuePlayer()
        let videoURL = URL(fileURLWithPath: path)
        let playerItem = AVPlayerItem(url: videoURL)
        
        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(playerLayer)
        
        // 创建循环播放器
        playerLooper = AVPlayerLooper(player: player, templateItem: playerItem)
        player.play()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
}