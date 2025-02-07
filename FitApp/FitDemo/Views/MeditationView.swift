import SwiftUI

struct MeditationView: View {
    @Binding var isPresented: Bool
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // 背景色
            Color(red: 44/255, green: 51/255, blue: 51/255)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()
                
                // 呼吸气泡
                Circle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 150, height: 150)
                    .scaleEffect(scale)
                    .animation(
                        Animation.easeInOut(duration: 4)
                            .repeatForever(autoreverses: true),
                        value: scale
                    )
                
                Spacer()
                
                // 结束按钮
                Button(action: {
                    isPresented = false
                }) {
                    Text("结束")
                        .foregroundColor(.white)
                        .frame(width: 120, height: 45)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(22.5)
                }
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            // 开始呼吸动画
            withAnimation {
                scale = 1.5
            }
        }
    }
}