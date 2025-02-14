import SwiftUI

struct MeditationView: View {
    @Binding var isPresented: Bool
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 0.3
    let themeManager: ThemeManager
    @State private var meditationTime: Int = 0
    @State private var timer: Timer?
    @State private var showingCompletionAlert = false
    
    var body: some View {
        ZStack {
            // 深海渐变背景
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0/255, green: 12/255, blue: 66/255),   // 深蓝色
                    Color(red: 2/255, green: 44/255, blue: 100/255)   // 中蓝色
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
            
            // 添加微妙的波浪效果
            WaveView()
                .opacity(0.1)
            
            VStack {
                Spacer()
                
                // 主呼吸气泡
                ZStack {
                    // 外层光晕
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 180, height: 180)
                        .scaleEffect(scale * 1.2)
                    
                    // 主气泡
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(opacity),
                                    Color.white.opacity(opacity * 0.5)
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: 75
                            )
                        )
                        .frame(width: 150, height: 150)
                        .scaleEffect(scale)
                        .shadow(color: .white.opacity(0.2), radius: 10)
                }
                .animation(
                    Animation
                        .easeInOut(duration: 4)
                        .repeatForever(autoreverses: true),
                    value: scale
                )
                
                Spacer()
                
                // 结束按钮
                Button(action: {
                    showingCompletionAlert = true
                }) {
                    Text("结束")
                        .foregroundColor(.white)
                        .frame(width: 120, height: 45)
                        .background(
                            RoundedRectangle(cornerRadius: 22.5)
                                .fill(Color.white.opacity(0.2))
                        )
                }
                .padding(.bottom, 50)
            }
            
            // 装饰性小气泡
            ForEach(0..<5) { index in
                SmallBubble()
            }
        }
        .alert("冥想成果", isPresented: $showingCompletionAlert) {
            Button("返回首页") {
                let minutes = meditationTime / 60
                if minutes >= 1 {
                    StatsManager.shared.updateStats(meditationTime: minutes * 60)
                }
                timer?.invalidate()
                isPresented = false
            }
        } message: {
            Text("本次冥想时长: \(formatTime(meditationTime))")
        }
        .onAppear {
            withAnimation {
                scale = 1.5
                opacity = 0.4
            }
            themeManager.playMeditationAudio()
            startTimer()
        }
        .onDisappear {
            themeManager.playThemeAudio()
            timer?.invalidate()
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            meditationTime += 1
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let seconds = seconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

// 波浪效果视图
struct WaveView: View {
    @State private var phase = 0.0
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let timeNow = timeline.date.timeIntervalSinceReferenceDate
                let angle = timeNow.remainder(dividingBy: 2)
                let offset = angle * 30
                
                context.translateBy(x: 0, y: size.height * 0.5)
                
                let path = Path { p in
                    p.move(to: CGPoint(x: 0, y: 0))
                    
                    for x in stride(from: 0, through: size.width, by: 1) {
                        let relativeX = x / 50
                        let y = sin(relativeX + offset) * 10
                        p.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                
                context.stroke(path, with: .color(.white.opacity(0.3)), lineWidth: 2)
            }
        }
    }
}

// 小气泡视图
struct SmallBubble: View {
    @State private var position = CGPoint(
        x: CGFloat.random(in: 50...300),
        y: CGFloat.random(in: 100...700)
    )
    @State private var scale: CGFloat = 0.3
    @State private var opacity: Double = 0.0
    
    var body: some View {
        Circle()
            .fill(Color.white.opacity(0.3))
            .frame(width: 20, height: 20)
            .scaleEffect(scale)
            .opacity(opacity)
            .position(position)
            .onAppear {
                let randomDuration = Double.random(in: 3...6)
                withAnimation(
                    Animation
                        .easeInOut(duration: randomDuration)
                        .repeatForever(autoreverses: true)
                ) {
                    scale = .random(in: 0.5...0.8)
                    opacity = .random(in: 0.1...0.3)
                    position.y -= 50
                }
            }
    }
}

struct MeditationView_Previews: PreviewProvider {
    static var previews: some View {
        MeditationView(isPresented: .constant(true), themeManager: ThemeManager())
    }
}