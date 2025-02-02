import SwiftUI

struct HistoryCardView: View {
    let diary: DiaryEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 60) {
            HStack {
                Text(diary.date.formatted(.dateTime.year().month().day()))
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Text("心情指数: \(String(format: "%.1f", diary.mood))")
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
            
            Text(String(diary.content.prefix(20)) + "...")
                .font(.body)
                .foregroundColor(.white)
                .lineLimit(3)
            
            HStack {
                Spacer()
                MoodFace(value: diary.mood)
                    .frame(width: 60, height: 60)
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
                                    Color.blue.opacity(0.3),
                                    Color.purple.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        )
    }
}

