import SwiftUI
import UserNotifications

struct FocusView: View {
    @Binding var isPresented: Bool
    let restInterval: Int // 休息提醒间隔(分钟)
    
    @State private var focusTime: Int = 0 // 专注时长(秒)
    @State private var timer: Timer?
    @State private var showingExitAlert = false
    @State private var showingCompletionAlert = false
    @State private var showingRestAlert = false // 休息提醒弹窗状态
    @State private var isPaused = false // 计时器暂停状态
    
    // 计算行驶距离（单位：km）
    var drivingDistance: Double {
        // 100km/h = 100km/3600s ≈ 0.0278km/s
        return Double(focusTime) * 0.02
    }
    
    var formattedDistance: String {
        String(format: "%.2f", drivingDistance)
    }
    
    var formattedTime: String {
        let hours = focusTime / 3600
        let minutes = (focusTime % 3600) / 60
        let seconds = focusTime % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    var body: some View {
        ZStack {
            Image("focus")
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)
                .overlay(
                    Color.black.opacity(0.3)
                )
            
            VStack(spacing: 30) {
                Text("专注时间")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(.white)
                
                Text(formattedTime)
                    .font(.system(size: 60, weight: .bold))
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(20)
                
                // 汽车图标
                Image(systemName: "car.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
                
                // 行驶里程显示
                VStack(spacing: 8) {
                    Text("行驶里程")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                    
                    Text("\(formattedDistance) km")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding()
                .background(Color.black.opacity(0.2))
                .cornerRadius(15)
                
                Button(action: {
                    showingExitAlert = true
                }) {
                    Text("结束专注")
                        .foregroundColor(.white)
                        .frame(width: 160, height: 45)
                        .background(Color.red.opacity(0.3))
                        .cornerRadius(22.5)
                }
            }
            
            // 休息提醒弹窗
            if showingRestAlert {
                // 半透明背景遮罩
                VisualEffectView(effect: UIBlurEffect(style: .dark))
                
                // 毛玻璃效果弹窗
                VStack(spacing: 25) {
                    // 标题
                    Text("休息一下吧")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(.white)
                    
                    // 副标题
                    Text("磨刀不误砍柴工")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.8))
                    
                    // 按钮
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showingRestAlert = false
                            isPaused = false
                            startTimer()
                        }
                    }) {
                        Text("我歇好了")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 160, height: 45)
                            .background(
                                RoundedRectangle(cornerRadius: 22.5)
                                    .fill(Color.white.opacity(0.2))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 22.5)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .padding(.top, 10)
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 35)
                .background(
                    // 毛玻璃效果背景
                    ZStack {
                        Color.black
                        
                        // 渐变背景增加深度感
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.1),
                                Color.white.opacity(0.05)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                    .blur(radius: 10)
                )
                .clipShape(RoundedRectangle(cornerRadius: 25))
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
                // 添加弹窗动画
                .transition(.scale.combined(with: .opacity))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showingRestAlert)
            }
        }
        .alert("确认结束专注?", isPresented: $showingExitAlert) {
            Button("取消", role: .cancel) { }
            Button("确认", role: .destructive) {
                UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                showingCompletionAlert = true
            }
        }
        .alert("专注成果", isPresented: $showingCompletionAlert) {
            Button("返回首页") {
                timer?.invalidate()
                UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                isPresented = false
            }
        } message: {
            Text("本次专注时长: \(formattedTime)\n本次行驶里程: \(formattedDistance) km")
        }
        .onAppear {
            startTimer()
            if restInterval > 0 {
                scheduleRestReminders()
            }
        }
        .onDisappear {
            timer?.invalidate()
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        }
    }
    
    private func startTimer() {
        timer?.invalidate() // 确保之前的计时器被清除
        
        if !isPaused {
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                focusTime += 1
                
                // 检查是否需要显示休息提醒
                if restInterval > 0 && focusTime % (restInterval * 60) == 0 {
                    timer?.invalidate() // 暂停计时器
                    isPaused = true
                    showingRestAlert = true
                }
            }
        }
    }
    
    private func scheduleRestReminders() {
        // 系统通知
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        let content = UNMutableNotificationContent()
        content.title = "休息提醒"
        content.body = "您已经专注了\(restInterval)分钟，建议休息一下哦！"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(restInterval * 60),
            repeats: true
        )
        
        let request = UNNotificationRequest(
            identifier: "focusReminder",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }

    
}

struct VisualEffectView: UIViewRepresentable {
    var effect: UIVisualEffect?
    func makeUIView(context: UIViewRepresentableContext<Self>) -> UIVisualEffectView { UIVisualEffectView() }
    func updateUIView(_ uiView: UIVisualEffectView, context: UIViewRepresentableContext<Self>) { uiView.effect = effect }
}

