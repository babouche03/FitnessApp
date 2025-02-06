import SwiftUI

struct MoodPage: View {
    @State private var isFlipped = false
    @State private var moodValue: Double = 5.0  // 新增：心情值（0-10）
    @State private var displayedText = ""  // 添加用于显示打字效果的状态
    private let fullText = "今天感觉怎么样"  // 完整文本
    @State private var showDiaryOptions = false
    @State private var showDiaryEdit = false
    @State private var typingTimer: Timer?

    var body: some View {
        ZStack {
            // 背景渐变保持不变
            LinearGradient(gradient: Gradient(colors: [Color.black, Color.blue]), 
                         startPoint: .top, 
                         endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)
            
            // 主要内容使用翻页效果
            ZStack {
                // 正面：心情记录页
                if !isFlipped {
                    ZStack {
                        // 切换按钮放在最上层
                        VStack {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    isFlipped.toggle()
                                }
                            }) {
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Image(systemName: "arrow.right")
                                            .foregroundColor(.white)
                                    )
                                    .opacity(/*@START_MENU_TOKEN@*/0.7/*@END_MENU_TOKEN@*/)
                            }
                            .padding(.top, 60)  // 使用负值将按钮向上移动
                            
                            Spacer()
                        }
                        .zIndex(1)  // 确保按钮在最上层
                        .ignoresSafeArea(.all, edges: .top)  // 忽略顶部安全区域
                        
                        mainMoodContent
                    }
                    .rotation3DEffect(
                        .degrees(isFlipped ? 180 : 0),
                        axis: (x: 0.0, y: 1.0, z: 0.0)
                    )
                }
                
                // 背面：历史记录页
                if isFlipped {
                    ZStack {
                        // 切换按钮放在最上层
                        VStack {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    isFlipped.toggle()
                                }
                            }) {
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Image(systemName: "arrow.left")
                                            .foregroundColor(.white)
                                    )
                                    .opacity(/*@START_MENU_TOKEN@*/0.7/*@END_MENU_TOKEN@*/)
                            }
                            .padding(.top, 60)  // 使用负值将按钮向上移动
                            
                            Spacer()
                        }
                        .zIndex(1)  // 确保按钮在最上层
                        .ignoresSafeArea(.all, edges: .top)  // 忽略顶部安全区域
                        
                        HistoryPage()
                    }
                    .rotation3DEffect(
                        .degrees(isFlipped ? 0 : -180),
                        axis: (x: 0.0, y: 1.0, z: 0.0)
                    )
                }
            }
            .gesture(
                DragGesture()
                    .onEnded { gesture in
                        if gesture.translation.width < -50 && !isFlipped {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                isFlipped.toggle()
                            }
                        } else if gesture.translation.width > 50 && isFlipped {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                isFlipped.toggle()
                            }
                        }
                    }
            )
        }
    }
    
    // 将原有的主要内容移到计算属性中
    private var mainMoodContent: some View {
        VStack {
            // 添加顶部空间，为切换按钮留出位置
            Spacer()
                .frame(height: 90)
            
            Text(displayedText)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(height: 30)
                .onAppear {
                    startTypingAnimation()
                }
                .onDisappear {
                    typingTimer?.invalidate()
                    typingTimer = nil
                }
            
            Spacer()

            // 表情图标部分
            MoodFace(value: moodValue)
                .frame(width: 150, height: 150)
                .padding()

            Spacer()

            // 心情选择按钮部分
            VStack(spacing: 20) {
                HStack(){
                    Text("今日心情指数:")
                        .font(.title2)
                        .foregroundColor(.white)
                    Text(String(format: "%.1f", moodValue))
                        .font(.title)
                        .foregroundColor(.white)
                }
                .padding(.bottom, 20)
                MoodSlider(value: $moodValue)
                    .frame(height: 40)
                    .padding(.horizontal, 50)
            }
            .padding(.bottom, 50)

            // 记录按钮
            Button(action: {
                showDiaryOptions = true
            }) {
                Text("记录今天")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 30)
                            .stroke(Color.white.opacity(0.3), lineWidth: 3)
                    )
                .cornerRadius(30)
                .shadow(color: .white.opacity(0.2), radius: 8, x: 0, y: 0)
            }
            .padding(.horizontal, 50)
            .confirmationDialog("选择操作", isPresented: $showDiaryOptions) {
                Button("继续上次日记") {
                    if let lastDiary = DiaryManager.shared.getAllDiaries().first {
                        DiaryManager.shared.setCurrentDraft(lastDiary)
                        showDiaryEdit = true
                    }
                }
                Button("新建日记") {
                    DiaryManager.shared.setCurrentDraft(nil)
                    showDiaryEdit = true
                }
            }
            .sheet(isPresented: $showDiaryEdit) {
                if let draft = DiaryManager.shared.getCurrentDraft() {
                    // 继续上次日记
                    DiaryEditView(isEditing: true, existingDiary: draft, moodValue: moodValue)
                } else {
                    // 新建日记
                    DiaryEditView(moodValue: moodValue)
                }
            }

            Spacer()
        }
    }
    
    // 打字动画函数
    private func startTypingAnimation() {
        typingTimer?.invalidate()
        typingTimer = nil
        
        displayedText = ""  // 重置文本
        var charIndex = 0
        
        typingTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { timer in
            if charIndex < fullText.count {
                let index = fullText.index(fullText.startIndex, offsetBy: charIndex)
                displayedText += String(fullText[index])
                charIndex += 1
            } else {
                timer.invalidate()  // 停止计时器
                typingTimer = nil
                // 等待一段时间后重新开始动画
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    startTypingAnimation()
                }
            }
        }
    }
}

// 自定义心情滑动条
struct MoodSlider: View {
    @Binding var value: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // 背景条
                Capsule()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [.red, .yellow, .green]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)
                
                // 滑动手柄
                Circle()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.5), lineWidth: 1)
                    )
                    .frame(width: 30, height: 30)
                    .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
                    .offset(x: (geometry.size.width - 30) * CGFloat(value / 10.0))
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                let newValue = 10 * gesture.location.x / geometry.size.width
                                value = min(max(newValue, 0), 10)
                            }
                    )
            }
        }
    }
}

// 自定义表情面部
struct MoodFace: View {
    let value: Double
    
    private var faceColor: Color {
        if value < 5 {
            return Color.red.opacity(0.8).blend(with: .yellow.opacity(0.8), percentage: value / 5)
        } else {
            return Color.yellow.opacity(0.8).blend(with: .green.opacity(0.8), percentage: (value - 5) / 5)
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            
            ZStack {
                Circle()
                    .fill(faceColor)
                
                // 眼睛
                HStack(spacing: width * 0.2) {
                    Circle().fill(.black).frame(width: width * 0.1)
                    Circle().fill(.black).frame(width: width * 0.1)
                }
                .offset(y: -height * 0.1)
                
                // 嘴巴
                Path { path in
                    let startPoint = CGPoint(x: width * 0.2, y: height * 0.65)
                    let endPoint = CGPoint(x: width * 0.8, y: height * 0.65)
                    let controlPoint = CGPoint(
                        x: width * 0.5,
                        y: height * (0.65 + (value - 5) * 0.04) // 基准点
                    )
                    
                    path.move(to: startPoint)
                    path.addQuadCurve(to: endPoint, control: controlPoint)
                }
                .stroke(.black, lineWidth: 3)
            }
        }
    }
}

// 颜色混合扩展
extension Color {
    func blend(with color: Color, percentage: Double) -> Color {
        let percent = max(0, min(1, percentage))
        if percent == 0 {
            return self
        } else if percent == 1 {
            return color
        } else {
            return Color(uiColor: UIColor(self).blend(with: UIColor(color), percentage: percent))
        }
    }
}

// UIColor 的混合扩展
extension UIColor {
    func blend(with color: UIColor, percentage: Double) -> UIColor {
        let percent = CGFloat(max(0, min(1, percentage)))
        
        var (r1, g1, b1, a1): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
        var (r2, g2, b2, a2): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
        
        self.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        color.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        
        return UIColor(
            red: r1 + (r2 - r1) * percent,
            green: g1 + (g2 - g1) * percent,
            blue: b1 + (b2 - b1) * percent,
            alpha: a1 + (a2 - a1) * percent
        )
    }
}

struct BottomBarButton: View {
    let imageName: String

    var body: some View {
        Button(action: {
            print("\(imageName) 按钮点击")
        }) {
            Image(systemName: imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
                .foregroundColor(.white)
        }
    }
}

struct MoodPage_Previews: PreviewProvider {
    static var previews: some View {
        MoodPage()
    }
}
