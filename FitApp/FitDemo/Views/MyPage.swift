import SwiftUI

struct MyPage: View {
    @State private var selectedDate = Date()
    @State private var showDatePicker = false
    @State private var showClearDataAlert = false
    
    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(gradient: Gradient(colors: [Color.black, Color.blue]), 
                         startPoint: .top, 
                         endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 25) {
                    Text("\"数据只是路标，感受才是旅程\"")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(.bottom, 40)
                    // 今日数据卡片
                    DailyStatsCard(selectedDate: $selectedDate, showDatePicker: $showDatePicker)
                    
                    // 累计数据卡片
                    TotalStatsCard()
                    
                    // 支持板块
                    SupportSection()
                    
                    // 数据管理
                    DataManagementSection(showAlert: $showClearDataAlert)
                }
                .padding()
            }
        }
        .alert("确认清除数据", isPresented: $showClearDataAlert) {
            Button("取消", role: .cancel) { }
            Button("确认清除", role: .destructive) {
                // TODO: 实现清除数据的逻辑
            }
        } message: {
            Text("此操作将清除所有用户数据，且不可恢复。确认继续吗？")
        }
    }
}

// 今日数据卡片
struct DailyStatsCard: View {
    @Binding var selectedDate: Date
    @Binding var showDatePicker: Bool
    
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
                StatItem(title: "专注时间", value: "2小时", icon: "timer")
                StatItem(title: "放松时间", value: "1小时", icon: "leaf.fill")
                StatItem(title: "冥想时间", value: "30分钟", icon: "brain.head.profile")
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
}

// 累计数据卡片
struct TotalStatsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("累计数据")
                .font(.headline)
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 20) {
                StatItem(title: "总专注", value: "100小时", icon: "timer")
                StatItem(title: "总放松", value: "50小时", icon: "leaf.fill")
                StatItem(title: "总冥想", value: "20小时", icon: "brain.head.profile")
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
}

// 支持板块
struct SupportSection: View {
    @State private var showAbout = false
    
    var body: some View {
        VStack(spacing: 15) {
            Text("支持")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Button(action: {
                sendEmail(to: "babouche0333@gmail.com")
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
                    Text("关于")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.bottom, 10)
                    
                    Text("这是我独立开发的第一款ios app。创作这款App的灵感是我步入大三后学业上的压力加上未来道路选择的迷茫常常使我陷入焦虑之中。在我陷入情绪低潮时,\"公园定律\"拯救了我。去到学校附近的公园待上一段时间极大程度上缓解了我生活中的不快。但由于不是每天都能抽出时间去公园，于是，我产生了在自己手机上创造一个\"公园\"的想法。")
                    
                    Text("其实在此之前,我了解过市面上已经有不少类似功能的产品。但大多功能较为繁杂,且费用对于我一大学生并不算友好。因此我还是坚决要打造一款最适合自己的app。我希望构建一个无联网,无广告，无内购的\"三无\"产品。用户无需担心数据隐私问题，所有数据都保存用户本地，一切数据信息只由用户掌管，与他人无关。")
                    
                    Text("对我来说,这又是一个用爱发电的项目,苹果一年开发者账号的费用属实不便宜,因此大概率明年我不会继续续费(这不会影响已经安装的用户继续使用）。但在未来一年内,如果时间、精力允许,我也许会进行版本更新(计划推出用户自定义主题等功能)。")
                    
                    Text("最后,真心希望这款app能够帮助到您,祝您生活愉快。")
                    
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
        .preferredColorScheme(.dark)  // 强制使用深色模式
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
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

#Preview {
    MyPage()
}
