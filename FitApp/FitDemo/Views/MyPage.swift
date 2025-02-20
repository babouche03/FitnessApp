import SwiftUI

struct MyPage: View {
    @State private var selectedDate = Date()
    @State private var showDatePicker = false
    @State private var showClearDataAlert = false
    @ObservedObject var themeManager: ThemeManager
    
    var body: some View {
        ZStack {
            // 背景层
            Group {
                if let videoName = themeManager.currentTheme.backgroundVideo {
                    VideoPlayerView(videoName: videoName)
                        .overlay(BlurView(style: .dark))  // 使用 BlurView
                } else {
                    Image(themeManager.currentTheme.backgroundImage)
                        .resizable()
                        .scaledToFill()
                        .overlay(BlurView(style: .dark))  // 使用 BlurView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .edgesIgnoringSafeArea(.all)
            .allowsHitTesting(false)
            
            // 内容层
            ScrollView {
                VStack(spacing: 25) {
                    Text("\"数据只是路标，感受才是旅程\"")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(.bottom, 32)
                        
                    
                    // 今日数据卡片
                    DailyStatsCard(selectedDate: $selectedDate, showDatePicker: $showDatePicker)
                        .padding(.horizontal, 22)  // 调整卡片两侧边距
                    
                    // 累计数据卡片
                    TotalStatsCard()
                        .padding(.horizontal, 22)  // 调整卡片两侧边距
                    
                    // 支持板块
                    SupportSection()
                        .padding(.horizontal, 22)  // 调整支持板块两侧边距
                    
                    // 数据管理
                    DataManagementSection(showAlert: $showClearDataAlert)
                        .padding(.horizontal, 22)  // 调整数据管理板块两侧边距
                }
                .padding(.vertical)  // 保持垂直方向的内边距
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .alert("确认清除数据", isPresented: $showClearDataAlert) {
            Button("取消", role: .cancel) { }
            Button("确认清除", role: .destructive) {
                // 清除统计数据
                StatsManager.shared.clearAllStats()
                // 清除所有日记数据
                for diary in DiaryManager.shared.getAllDiaries() {
                    DiaryManager.shared.deleteDiary(withId: diary.id)
                }
            }
        } message: {
            Text("此操作将清除所有用户数据（包括所有统计数据和日记数据），且不可恢复。确认继续吗？")
        }
    }
}

// 今日数据卡片
struct DailyStatsCard: View {
    @Binding var selectedDate: Date
    @Binding var showDatePicker: Bool
    @StateObject private var statsManager = StatsManager.shared
    
    var body: some View {
        VStack(spacing: 15) {
            // 日期选择器
            Button(action: { showDatePicker.toggle() }) {
                HStack {
                    Text(selectedDate.formatted(.dateTime.locale(Locale(identifier: "zh_CN")).year().month().day()))
                        .foregroundColor(.white)
                    Image(systemName: "calendar")
                        .foregroundColor(.white)
                }
            }
            .sheet(isPresented: $showDatePicker) {
                DatePicker("选择日期", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .environment(\.locale, Locale(identifier: "zh_CN"))
                    .presentationDetents([.height(400)])
            }
            
            // 数据网格
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 20) {
                let stats = statsManager.getStats(for: selectedDate)
                StatItem(title: "专注时间", 
                        value: formatTime(stats.focusTime), 
                        icon: "timer")
                StatItem(title: "休息时间", 
                        value: formatTime(stats.restTime), 
                        icon: "leaf.fill")
                StatItem(title: "冥想时间", 
                        value: formatTime(stats.meditationTime), 
                        icon: "brain.head.profile")
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        // .overlay(
        //     RoundedRectangle(cornerRadius: 20)
        //         .stroke(Color.black.opacity(0.3), lineWidth: 1)
        // )
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 {
            return "\(hours)时\(minutes)分"
        } else {
            return "\(minutes)分钟"
        }
    }
}

// 累计数据卡片
struct TotalStatsCard: View {
    @StateObject private var statsManager = StatsManager.shared
    @State private var showDrivingDistance = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("累计数据")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(spacing: 15) {
                let totalStats = statsManager.getTotalStats()
                
                Button(action: { showDrivingDistance = true }) {
                    StatItemHorizontal(
                        title: "总专注",
                        value: formatTime(totalStats.focusTime),
                        icon: "timer",
                        color: Color.green.opacity(0.4)
                    )
                }
                
                StatItemHorizontal(
                    title: "总休息",
                    value: formatTime(totalStats.restTime),
                    icon: "leaf.fill",
                    color: Color.blue.opacity(0.4)
                )
                
                StatItemHorizontal(
                    title: "总冥想",
                    value: formatTime(totalStats.meditationTime),
                    icon: "brain.head.profile",
                    color: Color.purple.opacity(0.4)
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .alert("专注之旅", isPresented: $showDrivingDistance) {
            Button("确定", role: .cancel) { }
        } message: {
            Text("您已累计行驶 \(String(format: "%.2f", statsManager.getTotalStats().drivingDistance)) 公里")
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 {
            return "\(hours)时\(minutes)分"
        } else {
            return "\(minutes)分钟"
        }
    }
}

// 新的水平布局统计项组件
struct StatItemHorizontal: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 图标和标题
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            // 数值
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(color)
        .cornerRadius(15)
    }
}

// 支持板块
struct SupportSection: View {
    @State private var showAbout = false
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        VStack(spacing: 15) {
            // 标题栏：支持文字和主题切换按钮
            HStack {
                Text("支持")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                // 主题切换按钮
                Button(action: {
                    isDarkMode.toggle()
                    // 切换系统主题
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                        windowScene.windows.forEach { window in
                            window.overrideUserInterfaceStyle = isDarkMode ? .dark : .light
                        }
                    }
                }) {
                    Image(systemName: colorScheme == .dark ? "sun.max.fill" : "moon.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .padding(5)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
                }
            }
            
            Button(action: {
                sendEmail(to: "babouchess077@gmail.com")
            }) {
                HStack {
                    Image(systemName: "envelope.fill")
                    Text("联系开发者")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .foregroundColor(.white)
            }
            Divider()
                .background(.white)
            
            Button(action: { showAbout = true }) {
                HStack {
                    Image(systemName: "info.circle.fill")
                    Text("关于")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .foregroundColor(.white)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .sheet(isPresented: $showAbout) {
            AboutView()
        }
    }
    
    private func sendEmail(to email: String) {
        if let url = URL(string: "mailto:\(email)") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
    }
}

// 关于页面视图
struct AboutView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("关于Escape")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.bottom, 10)
                    
                    Text("    这是我独立开发的第一款ios App。创作这款App的灵感来于:步入大三后,对未来的迷茫常常使我悲观焦虑。在我陷入情绪低潮时，\"公园定律\"拯救了我。去到学校附近的公园待上一段时间极大程度上缓解了我生活中的不快。但由于不是每天都能抽出时间去公园，于是，我产生了在自己手机上创造一个\"公园\"的想法。")
                    
                    Text("    其实在此之前，我了解过市面上已经有不少类似功能的产品。但大多功能较为繁杂，且费用对于学生并不算友好。因此我还是决定要打造一款最适合自己的App。我希望构建一个无联网，无广告，无内购的\"三无\"产品。用户无需担心数据隐私问题，所有数据都保存用户本地，一切数据信息只由用户掌管，与他人无关。")
                    
                    Text("    对我来说，这又是一个用爱发电的项目，苹果一年开发者账号的费用属实不便宜，因此明年大概率我不会续费(这不会影响已经安装的用户继续使用）。但在未来一年内，如果时间、精力允许，我也许会推出新的版本(计划推出用户自定义主题等功能)。")
                    
                    Text("    最后，真心希望Escape能够帮助到您，祝您生活愉快。😀")
                    
                    HStack {
                        Spacer()
                        Text("—— Babouche 2025.2")
                            .italic()
                    }
                    .padding(.top, 20)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
        // .preferredColorScheme(.dark)  // 强制使用深色模式
    }
}

// 数据管理板块
struct DataManagementSection: View {
    @Binding var showAlert: Bool
    
    var body: some View {
        Button(action: { showAlert = true }) {
            HStack {
                Image(systemName: "trash.fill")
                    .foregroundColor(.red)
                Text("清除所有数据")
                    .foregroundColor(.red)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

// 统计项组件
struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
            Text(value)
                .font(.headline)
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

#Preview {
    MyPage(themeManager: ThemeManager())
}
