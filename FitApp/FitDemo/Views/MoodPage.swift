import SwiftUI

struct MoodPage: View {
    @State private var selectedMood: String? = nil
    @State private var displayedText = ""  // 添加用于显示打字效果的状态
    private let fullText = "今天感觉怎么样"  // 完整文本

    var body: some View {
        VStack {
            // 修改顶部标题为动态文字
            Text(displayedText)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.top, 50)
                .onAppear {
                    startTypingAnimation()
                }

            Spacer()

            // 表情图标
            Image(systemName: selectedMood == "开心" ? "face.smiling.fill" : selectedMood == "难过" ? "face.dashed.fill" : "face.smiling")
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
                .foregroundColor(.yellow)
                .padding()

            Spacer()

            // 心情选择
            HStack(spacing: 40) {
                MoodButton(color: .red, label: "难过", selectedMood: $selectedMood)
                MoodButton(color: .blue, label: "一般", selectedMood: $selectedMood)
                MoodButton(color: .yellow, label: "开心", selectedMood: $selectedMood)
            }
            .padding(.bottom, 40)

            // 记录按钮
            Button(action: {
                print("记录：\(selectedMood ?? "未选择")")
            }) {
                Text("记录今天")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray)
                    .cornerRadius(30)
            }
            .padding(.horizontal, 50)

            Spacer()

        }
        .background(LinearGradient(gradient: Gradient(colors: [Color.black, Color.blue]), startPoint: .top, endPoint: .bottom).edgesIgnoringSafeArea(.all))
    }
    
    // 打字动画函数
    private func startTypingAnimation() {
        displayedText = ""  // 重置文本
        var charIndex = 0
        Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { timer in
            if charIndex < fullText.count {
                let index = fullText.index(fullText.startIndex, offsetBy: charIndex)
                displayedText += String(fullText[index])
                charIndex += 1
            } else {
                timer.invalidate()  // 停止计时器
                // 等待一段时间后重新开始动画
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    startTypingAnimation()
                }
            }
        }
    }
}

struct MoodButton: View {
    let color: Color
    let label: String
    @Binding var selectedMood: String?

    var body: some View {
        VStack {
            Circle()
                .fill(color)
                .frame(width: 50, height: 50)
                .onTapGesture {
                    selectedMood = label
                }
            Text(label)
                .foregroundColor(.white)
                .font(.caption)
        }
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
