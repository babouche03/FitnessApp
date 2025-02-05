import SwiftUI
import AVFoundation
import MediaPlayer

struct ContentView: View {
    @StateObject private var themeManager = ThemeManager()
    @State private var selectedTab = 0  // 添加选中标签状态
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                // 首页
                HomePage(themeManager: themeManager)
                    .tabItem {
                        EmptyView()
                    }
                    .tag(0)
                
                // 环境
                NavigationView {
                    MoodPage()
                }
                .tabItem {
                    EmptyView()
                }
                .tag(1)
                
                // 我的
                NavigationView {
                    MyPage()
                }
                .tabItem {
                    EmptyView()
                }
                .tag(2)
            }
            .overlay(CustomTabBar(selectedTab: $selectedTab), alignment: .bottom)  // 传递绑定
            
            .accentColor(.white) // 为整个 TabView 设置强调色
            .onAppear {
                // 音频初始化
                do {
                    try AVAudioSession.sharedInstance().setActive(true)
                    themeManager.playThemeAudio()
                } catch {
                    print("激活音频会话失败: \(error)")
                }
            }
        }
    }
}

// 添加自定义TabBar视图
struct CustomTabBar: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack {
            TabBarButton(iconName: "house", title: "", isSelected: selectedTab == 0) {
                selectedTab = 0
            }
            
            TabBarButton(iconName: "globe.americas", title: "", isSelected: selectedTab == 1) {
                selectedTab = 1
            }
            
            TabBarButton(iconName: "person", title: "", isSelected: selectedTab == 2) {
                selectedTab = 2
            }
        }
        .padding(.horizontal, 46)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 46)
                .fill(Color.black.opacity(0.5))
                .frame(width: 300, height: 60)  
        )
        .padding(.horizontal)
        .padding(.bottom, -15)
    }
}

struct TabBarButton: View {
    let iconName: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: iconName)
                .font(.system(size: 26))  // 图标尺寸
                .foregroundColor(isSelected ? .white : .gray)
                .frame(maxWidth: .infinity)
        }
    }
}

struct HomePage: View {
    @State private var isViewingImage = false
    @State private var isShowingPopup = false
    @State private var customMessage = UserDefaults.standard.string(forKey: "customMessage") ?? "Today is good day"
    @State private var isEditingMessage = false
    @State private var tempMessage = ""
    @State private var volume: Double = 0.5 // 音量控制状态
    @State private var selectedTheme: Int = 0 // 添加选中主题的状态，默认选择第一个
    @State private var showingExtendedThemes = false
    @ObservedObject var themeManager: ThemeManager
    
    var body: some View {
        NavigationView {
            ZStack {
                if !isViewingImage {
                    // 背景视频或图片
                    if let videoName = themeManager.currentTheme.backgroundVideo {
                        VideoPlayerView(videoName: videoName)
                            .edgesIgnoringSafeArea(.all)
                            .transition(.opacity)
                            .id(themeManager.currentTheme.id)
                    } else {
                        Image(themeManager.currentTheme.backgroundImage)
                            .resizable()
                            .scaledToFill()
                            .edgesIgnoringSafeArea(.all)
                            .transition(.opacity)
                    }

                    VStack {
                        Spacer().frame(height: 40) // 顶部间距
                        HStack {
                            // 修改顶部问候语区域
                            Text(customMessage)
                                .font(.system(size: 20))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.leading, 30)
                            
                            
                            // 添加编辑按钮
                            Button(action: {
                                tempMessage = customMessage
                                isEditingMessage = true
                            }) {
                                Image(systemName: "square.and.pencil")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                            }
                            .padding(.trailing, 20)
                            
                            Spacer()
                            // 保留原有的齿轮图标
                            Image(systemName: "gearshape")
                                .font(.system(size: 28))
                                .onTapGesture {
                                    withAnimation {
                                        isShowingPopup.toggle()
                                    }
                                }
                                .padding(.trailing, 30)
                        }

                        Spacer() // 使问候语与按钮分开

                        // 圆形功能按钮
                        HStack(spacing: 40) {
                            CircularButton(iconName: "moon.stars", 
                                         text: "歇会", 
                                         themeManager: themeManager)
                            CircularButton(iconName: "pencil", 
                                         text: "专注", 
                                         themeManager: themeManager)
                            CircularButton(iconName: "leaf", 
                                         text: "呼吸", 
                                         themeManager: themeManager)
                        }
                        .transition(.opacity)

                        Spacer().frame(height: 30) // 按钮与底部导航栏间距
                    }
                }

                // 观赏模式 
                if isViewingImage {
                    if let videoName = themeManager.currentTheme.backgroundVideo {
                        VideoPlayerView(videoName: videoName)
                            .edgesIgnoringSafeArea(.all)
                            .onTapGesture {
                                withAnimation {
                                    isViewingImage.toggle()
                                }
                            }
                            .transition(.opacity)
                            .id(themeManager.currentTheme.id)
                    } else {
                        Image(themeManager.currentTheme.backgroundImage)
                            .resizable()
                            .scaledToFill()
                            .edgesIgnoringSafeArea(.all)
                            .onTapGesture {
                                withAnimation {
                                    isViewingImage.toggle()
                                }
                            }
                            .transition(.opacity)
                    }
                }

                // 弹窗和模糊背景
                if isShowingPopup {
                    Color.black.opacity(0.7)
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture {
                            withAnimation {
                                if showingExtendedThemes {
                                    showingExtendedThemes = false
                                } else {
                                    isShowingPopup = false
                                }
                            }
                        }

                    VStack(spacing: 0) {
                        // 顶部关闭按钮
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
                                    isShowingPopup = false
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
                            // 扩展主题网格布局 (3x3)
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 20) {
                                ForEach(themeManager.extendedThemes) { theme in
                                    ThemeButton(
                                        icon: theme.icon,
                                        text: theme.name,
                                        isSelected: selectedTheme == theme.id
                                    )
                                    .onTapGesture {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedTheme = theme.id
                                            themeManager.switchTheme(to: theme.id)
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 20)
                        } else {
                            // 原有主题网格布局 (2x3)
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 20) {
                                ForEach(themeManager.themes) { theme in
                                    ThemeButton(
                                        icon: theme.icon,
                                        text: theme.name,
                                        isSelected: selectedTheme == theme.id
                                    )
                                    .onTapGesture {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedTheme = theme.id
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

                // 添加编辑弹窗
                if isEditingMessage {
                    Color.black.opacity(0.7)
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture {
                            isEditingMessage = false
                        }
                    
                    VStack(spacing: 20) {
                        TextField("输入新的文本", text: $tempMessage)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)
                        
                        HStack(spacing: 30) {
                            Button("取消") {
                                isEditingMessage = false
                            }
                            .foregroundColor(.white)
                            
                            Button("确定") {
                                customMessage = tempMessage
                                UserDefaults.standard.set(customMessage, forKey: "customMessage")
                                isEditingMessage = false
                            }
                            .foregroundColor(.white)
                        }
                    }
                    .frame(width: 280, height: 150)
                    .background(Color.gray.opacity(0.9))
                    .cornerRadius(20)
                    .shadow(radius: 10)
                }
            }
            .onTapGesture {
                // 进入观赏模式
                if !isShowingPopup && !isEditingMessage {
                    withAnimation {
                        isViewingImage.toggle()
                    }
                } 
            }
        }
    }
}

struct CircularButton: View {
    var iconName: String
    var text: String
    @State private var showingRestModal = false
    @State private var showingFocusModal = false
    @State private var selectedRestTime: Double = 10
    @State private var selectedRestInterval: Double = 30 // 休息提醒间隔(分钟)
    @State private var showRestView = false
    @State private var showFocusView = false
    @State private var disableRestReminder = false
    @ObservedObject var themeManager: ThemeManager
    
    var body: some View {
        ZStack {
            VStack {
                Button(action: {
                    if text == "歇会" {
                        showingRestModal = true
                    } else if text == "专注" {
                        showingFocusModal = true
                    }
                }) {
                    Image(systemName: iconName)
                        .resizable()
                        .frame(width: 30, height: 30)
                        .padding()
                        .background(Color.gray.opacity(0.5))
                        .clipShape(Circle())
                }

                Text(text)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .padding(.top, 8)
            }
        }
        // 休息模式弹窗
        .sheet(isPresented: $showingRestModal) {
            RestSettingModal(selectedTime: $selectedRestTime, 
                           showRestView: $showRestView, 
                           showModal: $showingRestModal)
                .presentationDetents([.height(280)])
                .presentationBackground(.ultraThinMaterial)
                .presentationCornerRadius(30)
        }
        // 专注模式弹窗
        .sheet(isPresented: $showingFocusModal) {
            FocusSettingModal(
                selectedInterval: $selectedRestInterval,
                disableReminder: $disableRestReminder,
                showFocusView: $showFocusView,
                showModal: $showingFocusModal
            )
                .presentationDetents([.height(330)])
                .presentationBackground(.ultraThinMaterial)
                .presentationCornerRadius(30)
        }
        // 休息页面
        .fullScreenCover(isPresented: $showRestView) {
            RestView(restTime: Int(selectedRestTime), 
                    isPresented: $showRestView,
                    parentThemeManager: themeManager)
        }
        // 专注页面
        .fullScreenCover(isPresented: $showFocusView) {
            FocusView(
                isPresented: $showFocusView,
                restInterval: disableRestReminder ? 0 : Int(selectedRestInterval)
            )
        }
    }
}

struct RestSettingModal: View {
    @Binding var selectedTime: Double
    @Binding var showRestView: Bool
    @Binding var showModal: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            // 标题和关闭按钮
            HStack {
                Text("休息")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    showModal = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.system(size: 22))
                }
            }
            .padding(.horizontal)
            .padding(.top)
            
            // 时间选择器
            VStack(spacing: 8) {
                HStack {
                    Text("\(Int(selectedTime))")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)
                    Text("分钟")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }
                
                Slider(value: $selectedTime, in: 1...60, step: 1)
                    .tint(.white)
                    .padding(.horizontal)
            }
            .padding(.vertical)
            
            // 确认按钮
            Button(action: {
                showModal = false
                // 添加短暂延迟确保 sheet 完全关闭后再显示全屏视图
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showRestView = true
                }
            }) {
                Text("真得歇会儿")
                    .foregroundColor(.white)
                    .frame(width: 180, height: 45)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.black.opacity(0.8), Color.gray]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(22.5)
                    .shadow(color: .white.opacity(0.3), radius: 5, x: 0, y: 3)
            }
            .padding(.vertical)
        }
        .padding(.bottom)
    }
}

// 专注设置弹窗
struct FocusSettingModal: View {
    @Binding var selectedInterval: Double
    @Binding var disableReminder: Bool
    @Binding var showFocusView: Bool
    @Binding var showModal: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            // 标题和关闭按钮
            HStack {
                Text("专注")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    showModal = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.system(size: 22))
                }
            }
            .padding(.horizontal)
            .padding(.top)
            
            // 时间选择器
            VStack(spacing: 8) {
                HStack {
                    Text("休息频次：")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .padding(.trailing, 10)
                    Text("\(Int(selectedInterval))")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)
                    Text("分钟/次")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }
                
                Slider(value: $selectedInterval, in: 15...120, step: 15)
                    .tint(.white)
                    .padding(.horizontal)
            }
            .padding(.vertical)
            
            // 禁用提醒选项
            Toggle("不需要提醒休息", isOn: $disableReminder)
                .foregroundColor(.white)
                .padding(.horizontal)
                .toggleStyle(
                    SwitchToggleStyle(tint: Color.black.opacity(0.5))
                )
            
            // 确认按钮
            Button(action: {
                showModal = false
                // 添加短暂延迟确保 sheet 完全关闭后再显示全屏视图
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showFocusView = true
                }
            }) {
                Text("专注之旅")
                    .foregroundColor(.white)
                    .frame(width: 180, height: 45)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.black.opacity(0.8), Color.gray]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(22.5)
                    .shadow(color: .white.opacity(0.3), radius: 5, x: 0, y: 3)
            }
            .padding(.vertical)
        }
        .padding(.bottom)
    }
}

// 更新 ThemeButton 样式
struct ThemeButton: View {
    let icon: String
    let text: String
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // 选中状态的圆形背景
                if isSelected {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 50, height: 50)
                }
                
                Text(icon)
                    .font(.system(size: 24))
            }
            
            Text(text)
                .foregroundColor(.white)
                .font(.system(size: 14))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }
}

// 添加音量控制扩展
extension MPVolumeView {
    static func setVolume(_ volume: Float) {
        let volumeView = MPVolumeView()
        let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            slider?.value = volume
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
