import SwiftUI
import AVFoundation
import UserNotifications

struct RestView: View {
    let initialRestTime: Int
    @Binding var isPresented: Bool
    @State private var timeRemaining: Int
    @State private var timer: Timer?
    @State private var showThemeSelector = false
    @ObservedObject var parentThemeManager: ThemeManager
    @StateObject private var localThemeManager = ThemeManager()
    @State private var actualRestTime: Int = 0
    @State private var showingCompletionAlert = false
    @State private var longPressTimer: Timer?
    @State private var isLongPressing = false
    @State private var longPressProgress: CGFloat = 0
    @State private var isLongPressCompleted = false
    
    init(restTime: Int, isPresented: Binding<Bool>, parentThemeManager: ThemeManager) {
        self.initialRestTime = restTime
        self._isPresented = isPresented
        self._timeRemaining = State(initialValue: restTime * 60)
        self._parentThemeManager = ObservedObject(wrappedValue: parentThemeManager)
    }
    
    // 添加一个计算属性来获取顶部安全区域
    private var topSafeAreaInset: CGFloat {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            return window.safeAreaInsets.top
        }
        return 47 // 默认值
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景视频或图片
                if let videoName = localThemeManager.currentTheme.backgroundVideo {
                    VideoPlayerView(videoName: videoName)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .edgesIgnoringSafeArea(.all)
                        .transition(.opacity)
                        .id(localThemeManager.currentTheme.id)
                } else {
                    Image(localThemeManager.currentTheme.backgroundImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .edgesIgnoringSafeArea(.all)
                        .transition(.opacity)
                }
                
                // 主要内容
                VStack(spacing: 0) {
                    // 顶部工具栏
                    HStack {
                        Spacer()
                        Button(action: {
                            showThemeSelector = true
                        }) {
                            Image(systemName: "gearshape")
                                .font(.system(size: 28))
                                .foregroundColor(.white)
                        }
                        .padding(.top, topSafeAreaInset)
                        .padding(.trailing, 30)
                    }
                    
                    Spacer()
                }
                
                // 中央倒计时组件
                VStack(spacing: 25) {
                    Text("Take a break")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(.white)
                    
                    TimerView(timeRemaining: timeRemaining)
                        .padding()
                    
                    Button(action: {}) {
                        VStack(spacing: 8) {
                            Text("结束休息")
                                .foregroundColor(.white)
                                .frame(width: 160, height: 45)
                                .background(Color.black.opacity(0.3))
                                .cornerRadius(22.5)
                            
                            // 长按时显示的进度条
                            if isLongPressing {
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(Color.white.opacity(0.3))
                                        .frame(width: 160, height: 3)
                                    
                                    Rectangle()
                                        .fill(Color.white)
                                        .frame(width: 160 * longPressProgress, height: 3)
                                }
                                .frame(width: 160)
                                .cornerRadius(1.5)
                            }
                        }
                    }
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                if longPressTimer == nil {
                                    isLongPressing = true
                                    withAnimation(.linear(duration: 2)) {
                                        longPressProgress = 1
                                    }
                                    longPressTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
                                        showingCompletionAlert = true
                                        timer?.invalidate()
                                    }
                                }
                            }
                            .onEnded { _ in
                                longPressTimer?.invalidate()
                                longPressTimer = nil
                                isLongPressing = false
                                longPressProgress = 0
                            }
                    )
                }
                .offset(y: -30) // 微调整体位置，使视觉上更居中
                
                // 主题选择弹窗
                if showThemeSelector {
                    ThemeSelectorView(
                        isShowing: $showThemeSelector,
                        themeManager: localThemeManager
                    )
                }
            }
            .ignoresSafeArea()
        }
        .ignoresSafeArea()
        .alert("休息报告", isPresented: $showingCompletionAlert) {
            Button("返回首页") {
                // 只有超过1分钟才记录
                let minutes = actualRestTime / 60
                if minutes >= 1 {
                    StatsManager.shared.updateStats(restTime: minutes * 60)
                }
                isPresented = false
            }
        } message: {
            Text("本次休息时长: \(formatTime(actualRestTime))")
        }
        .onAppear {
            // 设置默认主题（夏夜）
            localThemeManager.switchTheme(to: 5)
            startTimer()
            requestNotificationPermission()
            // 暂停父级音频
            parentThemeManager.pauseAudio()
        }
        .onDisappear {
            timer?.invalidate()
            // 停止本地音频并恢复父级音频
            localThemeManager.stopAudio()
            parentThemeManager.resumeAudio()
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                print("通知权限已获取")
            }
        }
    }
    
    private func scheduleNotification() {
        let content = UNMutableNotificationContent()
        content.title = "休息时间结束"
        content.body = "该开始工作啦！"
        content.sound = UNNotificationSound.default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
                actualRestTime += 1
            } else {
                timer?.invalidate()
                AudioServicesPlaySystemSound(1005)
                showingCompletionAlert = true  // 显示统计弹窗
            }
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let seconds = seconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

struct TimerView: View {
    let timeRemaining: Int
    
    var hours: Int {
        timeRemaining / 3600
    }
    
    var minutes: Int {
        (timeRemaining % 3600) / 60
    }
    
    var seconds: Int {
        timeRemaining % 60
    }
    
    var body: some View {
        HStack(spacing: 20) {
            TimeBlock(value: hours, unit: "时")
            TimeBlock(value: minutes, unit: "分")
            TimeBlock(value: seconds, unit: "秒")
        }
    }
}

struct TimeBlock: View {
    let value: Int
    let unit: String
    
    var body: some View {
        VStack {
            Text("\(value)")
                .font(.system(size: 50, weight: .bold))
                .foregroundColor(.white)
            Text(unit)
                .font(.system(size: 16))
                .foregroundColor(.white)
        }
        .frame(width: 80, height: 100)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(15)
    }
}

// 主题选择器视图
struct ThemeSelectorView: View {
    @Binding var isShowing: Bool
    @ObservedObject var themeManager: ThemeManager
    @State private var showingExtendedThemes = false
    @State private var volume: Double = 0.5 // 音量控制状态
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    withAnimation {
                        if showingExtendedThemes {
                            showingExtendedThemes = false
                        } else {
                            isShowing = false
                        }
                    }
                }
            
            VStack(spacing: 0) {
                // 顶部标题栏
                HStack {
                    if showingExtendedThemes {
                        Button(action: {
                            withAnimation {
                                showingExtendedThemes = false
                            }
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                        }
                        .padding(16)
                        .padding(.top, 16)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation {
                            showingExtendedThemes = false
                            isShowing = false
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    }
                    .padding(16)
                    .padding(.top, 16)
                }
                
                Text(showingExtendedThemes ? "More" : "环境主题")
                    .foregroundColor(.white)
                    .font(.system(size: 18))
                    .padding(.top, 10)
                
                if showingExtendedThemes {
                    // 扩展主题网格
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 20) {
                        ForEach(themeManager.extendedThemes) { theme in
                            ThemeButton(
                                icon: theme.icon,
                                text: theme.name,
                                isSelected: themeManager.currentTheme.id == theme.id
                            )
                            .onTapGesture {
                                withAnimation {
                                    themeManager.switchTheme(to: theme.id)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 20)
                } else {
                    // 基础主题网格
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                        ForEach(themeManager.themes) { theme in
                            ThemeButton(
                                icon: theme.icon,
                                text: theme.name,
                                isSelected: themeManager.currentTheme.id == theme.id
                            )
                            .onTapGesture {
                                withAnimation {
                                    themeManager.switchTheme(to: theme.id)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 20)
                }
                    
                Spacer()
                
                if !showingExtendedThemes {
                    Button(action: {
                        withAnimation {
                            showingExtendedThemes = true
                        }
                    }) {
                        Text("更多主题")
                            .foregroundColor(.white)
                            .font(.system(size: 16))
                            .padding(.vertical, 8)
                            .padding(.horizontal, 20)
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(15)
                    }
                    .padding(.top, 10)
                    .padding(.bottom, 20)
                }
                // 音量控制
                        HStack {
                            Image(systemName: "speaker.wave.2")
                                .foregroundColor(.white)
                            Slider(value: $volume, in: 0...1) { _ in
                                themeManager.setVolume(Float(volume))
                            }
                            .accentColor(.white)
                        }
                        .padding(.horizontal, 30)
                        .padding(.bottom, 40)
            }
            .frame(width: 280, height: 530)
            .background(Color.black.opacity(0.7))
            .cornerRadius(20)
            .shadow(radius: 10)
        }
    }
}
