import SwiftUI

struct HistoryPage: View {
    @State private var diaries: [DiaryEntry] = []
    @State private var activeIndex: Double = 0
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    @State private var showDiaryDetail = false
    @State private var selectedDiary: DiaryEntry?
    
    var body: some View {
        GeometryReader { geometry in
            let cardHeight = geometry.size.height * 0.35
            let horizontalPadding: CGFloat = 40
            
            VStack {
                ZStack {
                    ForEach(-4...4, id: \.self) { relativeIndex in
                        let index = Int(round(activeIndex)) + relativeIndex
                        
                        if index >= 0 && index < diaries.count {
                            HistoryCardView(diary: diaries[index])
                                .frame(
                                    width: geometry.size.width - (horizontalPadding * 2),
                                    height: cardHeight
                                )
                                .offset(y: calculateOffset(for: Double(relativeIndex) - (activeIndex - round(activeIndex))))
                                .scaleEffect(calculateScale(for: Double(relativeIndex) - (activeIndex - round(activeIndex))))
                                .opacity(calculateOpacity(for: Double(relativeIndex) - (activeIndex - round(activeIndex))))
                                .zIndex(calculateZIndex(for: Double(relativeIndex) - (activeIndex - round(activeIndex))))
                                .onTapGesture {
                                    selectedDiary = diaries[index]
                                    showDiaryDetail = true
                                }
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
        }
    }
    
    private func loadDiaries() {
        diaries = DiaryManager.shared.getAllDiaries()
        // 保持当前查看的日记位置
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
