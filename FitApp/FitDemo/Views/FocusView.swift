import SwiftUI
import UserNotifications

struct FocusView: View {
    @Binding var isPresented: Bool
    let restInterval: Int // 休息提醒间隔(分钟)
    
    @State private var focusTime: Int = 0 // 专注时长(秒)
    @State private var timer: Timer?
    @State private var showingExitAlert = false
    @State private var showingCompletionAlert = false
    
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
            
            VStack(spacing: 50) {
                Text("专注时间")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(.white)
                
                Text(formattedTime)
                    .font(.system(size: 60, weight: .bold))
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(20)
                
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
        }
        .alert("确认结束专注?", isPresented: $showingExitAlert) {
            Button("取消", role: .cancel) { }
            Button("确认", role: .destructive) {
                showingCompletionAlert = true
            }
        }
        .alert("专注成果", isPresented: $showingCompletionAlert) {
            Button("返回首页") {
                timer?.invalidate()
                isPresented = false
            }
        } message: {
            Text("本次专注时长: \(formattedTime)")
        }
        .onAppear {
            startTimer()
            if restInterval > 0 {
                scheduleRestReminders()
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            focusTime += 1
        }
    }
    
    private func scheduleRestReminders() {
        let content = UNMutableNotificationContent()
        content.title = "休息提醒"
        content.body = "已经专注了\(restInterval)分钟，建议休息一下哦！"
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