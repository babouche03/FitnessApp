import SwiftUI

class HapticManager {
    static let shared = HapticManager()
    
    private let selectionFeedback = UISelectionFeedbackGenerator()
    private let impactFeedback = UIImpactFeedbackGenerator(style: .light)
    
    private init() {
        // 预热触觉引擎
        selectionFeedback.prepare()
        impactFeedback.prepare()
    }
    
    func playSelectionHaptic() {
        selectionFeedback.selectionChanged()
    }
    
    func playLightImpact() {
        impactFeedback.impactOccurred()
    }
}

struct HistoryPage: View {
    @State private var diaries: [DiaryEntry] = []
    @State private var activeIndex: Double = 0
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    @State private var showDiaryDetail = false
    @State private var selectedDiary: DiaryEntry?
    @State private var showCalendar = false
    @State private var cardOffset: CGFloat = 0
    @State private var showDeleteConfirmation = false
    @State private var showBurningAnimation = false
    @State private var diaryToDelete: DiaryEntry?
    @State private var isDeleting = false
    @State private var lastActiveIndex: Int = 0
    @ObservedObject var themeManager: ThemeManager
    
    var body: some View {
        GeometryReader { geometry in
            let cardHeight = geometry.size.height * 0.35
            let horizontalPadding: CGFloat = 40
            
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
                
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 120)
                    
                    ZStack {
                        ForEach(-4...4, id: \.self) { relativeIndex in
                            let index = Int(round(activeIndex)) + relativeIndex
                            
                            if index >= 0 && index < diaries.count {
                                ZStack {
                                    if cardOffset < -50 && !isDeleting && index == Int(round(activeIndex)) {
                                        HStack {
                                            Spacer()
                                            Image(systemName: "flame.fill")
                                                .font(.system(size: 50))
                                                .foregroundColor(.red)
                                                .transition(.scale.combined(with: .opacity))
                                                .padding(.trailing, -58)
                                                .onTapGesture {
                                                    diaryToDelete = diaries[index]
                                                    showDeleteConfirmation = true
                                                }
                                        }
                                        .frame(width: geometry.size.width - (horizontalPadding * 2))
                                        .zIndex(2)
                                    }
                                    
                                    HistoryCardView(diary: diaries[index])
                                        .frame(
                                            width: geometry.size.width - (horizontalPadding * 2),
                                            height: cardHeight
                                        )
                                        .onTapGesture {
                                            if cardOffset == 0 && index == Int(round(activeIndex)) {
                                                selectedDiary = diaries[index]
                                                showDiaryDetail = true
                                            }
                                        }
                                }
                                .offset(x: index == Int(round(activeIndex)) ? cardOffset : 0,
                                        y: calculateOffset(for: Double(relativeIndex) - (activeIndex - round(activeIndex))))
                                .scaleEffect(calculateScale(for: Double(relativeIndex) - (activeIndex - round(activeIndex))))
                                .opacity(calculateOpacity(for: Double(relativeIndex) - (activeIndex - round(activeIndex))))
                                .zIndex(calculateZIndex(for: Double(relativeIndex) - (activeIndex - round(activeIndex))))
                                .gesture(
                                    DragGesture()
                                        .onChanged { value in
                                            if index == Int(round(activeIndex)) {
                                                if abs(value.translation.width) > abs(value.translation.height) {
                                                    cardOffset = value.translation.width
                                                }
                                            }
                                        }
                                        .onEnded { value in
                                            if index == Int(round(activeIndex)) {
                                                withAnimation(.spring()) {
                                                    if cardOffset < -100 {
                                                        cardOffset = -100
                                                    } else {
                                                        cardOffset = 0
                                                    }
                                                }
                                            }
                                        }
                                )
                                .simultaneousGesture(
                                    DragGesture()
                                        .onChanged { value in
                                            isDragging = true
                                            if abs(value.translation.height) > abs(value.translation.width) {
                                                let newIndex = activeIndex - value.translation.height / 80 + dragOffset / 80
                                                let maxIndex = max(4.0, Double(diaries.count - 1))
                                                activeIndex = max(0, min(newIndex, maxIndex))
                                                
                                                let currentIndex = Int(round(activeIndex))
                                                if currentIndex != lastActiveIndex {
                                                    HapticManager.shared.playLightImpact()
                                                    lastActiveIndex = currentIndex
                                                }
                                                
                                                dragOffset = value.translation.height
                                            }
                                        }
                                        .onEnded { value in
                                            isDragging = false
                                            let velocity = value.predictedEndTranslation.height - value.translation.height
                                            withAnimation(.spring(
                                                response: 0.5,
                                                dampingFraction: 0.7,
                                                blendDuration: 0.3
                                            )) {
                                                handleDragEnd(velocity: velocity)
                                                dragOffset = 0
                                                
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                    lastActiveIndex = Int(round(activeIndex))
                                                }
                                            }
                                        }
                                )
                            } else {
                                EmptyCardView()
                                    .frame(
                                        width: geometry.size.width - (horizontalPadding * 2),
                                        height: cardHeight
                                    )
                                    .offset(y: calculateOffset(for: Double(relativeIndex) - (activeIndex - round(activeIndex))))
                                    .scaleEffect(calculateScale(for: Double(relativeIndex) - (activeIndex - round(activeIndex))))
                                    .opacity(calculateOpacity(for: Double(relativeIndex) - (activeIndex - round(activeIndex))))
                                    .zIndex(calculateZIndex(for: Double(relativeIndex) - (activeIndex - round(activeIndex))))
                            }
                        }
                    }
                    .frame(height: geometry.size.height * 0.6)
                    .padding(.horizontal, horizontalPadding)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                isDragging = true
                                let newIndex = activeIndex - value.translation.height / 80 + dragOffset / 80
                                let maxIndex = max(4.0, Double(diaries.count - 1))
                                activeIndex = max(0, min(newIndex, maxIndex))
                                dragOffset = value.translation.height
                            }
                            .onEnded { value in
                                isDragging = false
                                let velocity = value.predictedEndTranslation.height - value.translation.height
                                withAnimation(.spring(
                                    response: 0.5,
                                    dampingFraction: 0.7,
                                    blendDuration: 0.3
                                )) {
                                    handleDragEnd(velocity: velocity)
                                    dragOffset = 0
                                }
                            }
                    )
                    .animation(.interactiveSpring(
                        response: 0.5,
                        dampingFraction: 0.7,
                        blendDuration: 0.3
                    ), value: activeIndex)
                    
                    Spacer()
                    
                    Button(action: {
                        showCalendar.toggle()
                    }) {
                        Image(systemName: "calendar")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .padding()
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                            )
                    }
                    .padding(.bottom, 20)
                }
                
                if showBurningAnimation {
                    BurningAnimationView()
                        .ignoresSafeArea()
                }
            }
            .frame(maxHeight: .infinity)
            .onAppear {
                loadDiaries()
            }
            .sheet(isPresented: $showDiaryDetail) {
                if let diary = selectedDiary {
                    DiaryEditView(isEditing: true, existingDiary: diary)
                }
            }
            .onChange(of: showDiaryDetail) { oldValue, newValue in
                if !newValue {
                    loadDiaries()
                }
            }
            .sheet(isPresented: $showCalendar) {
                CalendarView(diaries: diaries, activeIndex: $activeIndex, isPresented: $showCalendar)
            }
            .alert("确认烧毁该记录", isPresented: $showDeleteConfirmation) {
                Button("取消", role: .cancel) {
                    withAnimation {
                        cardOffset = 0
                    }
                }
                Button("删除", role: .destructive) {
                    deleteDiary()
                }
            }
        }
    }
    
    private func loadDiaries() {
        diaries = DiaryManager.shared.getAllDiaries()
        if let selectedDiaryId = selectedDiary?.id,
           let index = diaries.firstIndex(where: { $0.id == selectedDiaryId }) {
            activeIndex = Double(index)
        }
    }
    
    private func handleDragEnd(velocity: CGFloat) {
        let projection = Double(velocity) / -800
        var targetIndex = round(activeIndex + projection)
        let maxIndex = max(4.0, Double(diaries.count - 1))
        targetIndex = max(0, min(targetIndex, maxIndex))
        activeIndex = targetIndex
    }
    
    private func calculateOffset(for relativePosition: Double) -> CGFloat {
        return relativePosition * 60
    }
    
    private func calculateScale(for relativePosition: Double) -> CGFloat {
        let baseScale = 1.0
        let scaleReduction = 0.08
        let scale = baseScale - (abs(relativePosition) * scaleReduction)
        return max(0.7, scale)
    }
    
    private func calculateOpacity(for relativePosition: Double) -> Double {
        let opacity = 1.0 - abs(relativePosition) * 0.2
        return max(0.6, opacity)
    }
    
    private func calculateZIndex(for relativePosition: Double) -> Double {
        return Double(100) - abs(relativePosition) * 20
    }
    
    private func deleteDiary() {
        guard let diary = diaryToDelete else { return }
        isDeleting = true
        
        withAnimation {
            showBurningAnimation = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            DiaryManager.shared.deleteDiary(withId: diary.id)
            loadDiaries()
            
            withAnimation {
                showBurningAnimation = false
                cardOffset = 0
                isDeleting = false
            }
        }
    }
}

struct EmptyCardView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 60) {
            HStack {
                Spacer()
            }
            
            Spacer()
            
            HStack {
                Spacer()
                MoodFace(value: 5.0)
                    .frame(width: 60, height: 60)
                    .opacity(0.3)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.blue.opacity(0.1),
                                    Color.purple.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
}

struct CalendarView: View {
    let diaries: [DiaryEntry]
    @Binding var activeIndex: Double
    @Binding var isPresented: Bool
    @State private var selectedDate: Date
    
    init(diaries: [DiaryEntry], activeIndex: Binding<Double>, isPresented: Binding<Bool>) {
        self.diaries = diaries
        self._activeIndex = activeIndex
        self._isPresented = isPresented
        
        let currentIndex = Int(activeIndex.wrappedValue)
        if currentIndex >= 0 && currentIndex < diaries.count {
            _selectedDate = State(initialValue: diaries[currentIndex].date)
        } else {
            _selectedDate = State(initialValue: Date())
        }
    }
    
    private var dateToIndexMap: [Date: Int] {
        var map: [Date: Int] = [:]
        for (index, diary) in diaries.enumerated() {
            let date = Calendar.current.startOfDay(for: diary.date)
            if map[date] == nil {
                map[date] = index
            }
        }
        return map
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                DatePicker("选择日期", 
                          selection: $selectedDate,
                          displayedComponents: [.date])
                    .datePickerStyle(.graphical)
                    .environment(\.locale, Locale(identifier: "zh_CN"))
                    .onChange(of: selectedDate) { _, newDate in
                        if let index = dateToIndexMap[Calendar.current.startOfDay(for: newDate)] {
                            activeIndex = Double(index)
                            isPresented = false
                        }
                    }
                    .padding(.horizontal)
                    .frame(maxHeight: 400)
                
                Spacer(minLength: 0)
            }
            .navigationTitle("选择日期")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        isPresented = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationCornerRadius(20)
    }
}

struct BurningAnimationView: View {
    @State private var scale: CGFloat = 0.1
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
            
            ForEach(0..<20) { _ in
                Image(systemName: "flame.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.orange)
                    .rotationEffect(.degrees(Double.random(in: -30...30)))
                    .offset(x: CGFloat.random(in: -100...100),
                            y: CGFloat.random(in: -200...200))
                    .scaleEffect(scale)
                    .opacity(opacity)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0)) {
                scale = 1.5
                opacity = 0.8
            }
        }
    }
}
