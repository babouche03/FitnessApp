import AVFoundation
import SwiftUI

class ThemeManager: ObservableObject {
    @Published var currentTheme: Theme
    private var audioPlayer: AVAudioPlayer?
    
    let themes: [Theme] = [
        Theme(id: 0, name: "森林", icon: "🌳", backgroundImage: "forest_bg", backgroundVideo: nil, audioName: "forest"),
        Theme(id: 1, name: "雨点", icon: "💧", backgroundImage: "rain_bg", backgroundVideo: "rain", audioName: "rain"),
        Theme(id: 2, name: "海滩", icon: "🌈", backgroundImage: "beach_bg", backgroundVideo: nil, audioName: "beach"),
        Theme(id: 3, name: "教室", icon: "🏛", backgroundImage: "classroom_bg", backgroundVideo: nil, audioName: "classroom"),
        Theme(id: 4, name: "灵感", icon: "💡", backgroundImage: "inspiration_bg", backgroundVideo: nil, audioName: "inspiration"),
        Theme(id: 5, name: "冥想", icon: "🧘", backgroundImage: "meditation_bg", backgroundVideo: nil, audioName: "meditation")
    ]
    
    init() {
        self.currentTheme = themes[0]
        setupAudioSession()
        // 初始化后立即播放音频
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.playThemeAudio()
        }
    }
    
    private func setupAudioSession() {
        do {
            // 修改音频会话配置，允许后台播放
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: [.mixWithOthers, .allowAirPlay, .duckOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
            
            // 添加通知监听
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleInterruption),
                name: AVAudioSession.interruptionNotification,
                object: nil
            )
            
            // 添加路由变化监听
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleRouteChange),
                name: AVAudioSession.routeChangeNotification,
                object: nil
            )
        } catch {
            print("设置音频会话失败: \(error)")
        }
    }
    
    // 添加路由变化处理
    @objc private func handleRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        
        switch reason {
        case .oldDeviceUnavailable:
            // 当旧设备不可用时（如拔出耳机），暂停播放
            audioPlayer?.pause()
        case .newDeviceAvailable:
            // 当新设备可用时（如插入耳机），继续播放
            audioPlayer?.play()
        default:
            break
        }
    }
    
    @objc private func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            // 音频被中断（如来电）
            audioPlayer?.pause()
        case .ended:
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                // 中断结束，恢复播放
                audioPlayer?.play()
            }
        @unknown default:
            break
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func switchTheme(to themeId: Int) {
        guard let theme = themes.first(where: { $0.id == themeId }) else { return }
        currentTheme = theme
        playThemeAudio()
    }
    
    func playThemeAudio() {
        // 停止当前播放的音频
        audioPlayer?.stop()
        
        // 获取音频文件路径
        guard let audioPath = Bundle.main.path(forResource: currentTheme.audioName, ofType: "mp3") else {
            print("找不到音频文件: \(currentTheme.audioName).mp3")
            return
        }
        
        do {
            let audioUrl = URL(fileURLWithPath: audioPath)
            audioPlayer = try AVAudioPlayer(contentsOf: audioUrl)
            audioPlayer?.numberOfLoops = -1 // 无限循环
            audioPlayer?.volume = 0.5 // 默认音量
            audioPlayer?.prepareToPlay() // 预加载音频
            audioPlayer?.play()
            print("开始播放音频: \(currentTheme.audioName).mp3")
        } catch {
            print("播放音频失败: \(error.localizedDescription)")
        }
    }
    
    func setVolume(_ volume: Float) {
        audioPlayer?.volume = volume
    }
    
    func stopAudio() {
        audioPlayer?.stop()
    }
    
    // 添加暂停和恢复方法
    func pauseAudio() {
        audioPlayer?.pause()
    }
    
    func resumeAudio() {
        audioPlayer?.play()
    }
}
