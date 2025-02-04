import SwiftUI

struct RestView: View {
    let restTime: Int
    @Binding var isPresented: Bool
    @State private var timeRemaining: Int
    @State private var timer: Timer?
    
    init(restTime: Int, isPresented: Binding<Bool>) {
        self.restTime = restTime
        self._isPresented = isPresented
        self._timeRemaining = State(initialValue: restTime * 60) // 转换为秒
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.9).edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 30) {
                Text("休息时间")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                
                TimerView(timeRemaining: timeRemaining)
                    .padding()
                
                Button(action: {
                    timer?.invalidate()
                    isPresented = false
                }) {
                    Text("结束休息")
                        .foregroundColor(.white)
                        .frame(width: 200, height: 45)
                        .background(Color.blue)
                        .cornerRadius(22.5)
                }
            }
        }
        .onAppear {
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                timer?.invalidate()
                isPresented = false
            }
        }
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