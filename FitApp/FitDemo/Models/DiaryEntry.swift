import SwiftUI

struct DiaryEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    let mood: Double
    let content: String
    let imageData: [Data]  // 改用 Data 类型存储图片
    let videoURLs: [String]  // 存储视频URL的字符串表示
    
    // 用于UI显示的计算属性
    var images: [UIImage] {
        return imageData.compactMap { UIImage(data: $0) }
    }
    
    var videos: [URL] {
        return videoURLs.compactMap { URL(string: $0) }
    }
    
    init(date: Date, mood: Double, content: String, images: [UIImage], videos: [URL]) {
        self.id = UUID()
        self.date = date
        self.mood = mood
        self.content = content
        self.imageData = images.compactMap { $0.jpegData(compressionQuality: 0.7) }
        self.videoURLs = videos.map { $0.absoluteString }
    }
    
    // 用于从持久化数据创建实例
    init(id: UUID, date: Date, mood: Double, content: String, imageData: [Data], videoURLs: [String]) {
        self.id = id
        self.date = date
        self.mood = mood
        self.content = content
        self.imageData = imageData
        self.videoURLs = videoURLs
    }
}

class DiaryManager {
    static let shared = DiaryManager()
    private var diaries: [DiaryEntry] = []
    private var currentDraft: DiaryEntry?
    
    private init() {
        loadDiaries()
    }
    
    func saveDiary(_ diary: DiaryEntry) {
        do {
            try DiaryStorage.shared.saveDiary(diary)
            loadDiaries()
        } catch {
            print("保存日记失败: \(error)")
        }
    }
    
    func getCurrentDraft() -> DiaryEntry? {
        return currentDraft
    }
    
    func setCurrentDraft(_ diary: DiaryEntry?) {
        currentDraft = diary
        do {
            try DiaryStorage.shared.saveDraft(diary)
        } catch {
            print("保存草稿失败: \(error)")
        }
    }
    
    func getAllDiaries() -> [DiaryEntry] {
        return diaries
    }
    
    func deleteDiary(withId id: UUID) {
        do {
            try DiaryStorage.shared.deleteDiary(withId: id)
            loadDiaries()
        } catch {
            print("删除日记失败: \(error)")
        }
    }
    
    private func loadDiaries() {
        do {
            diaries = try DiaryStorage.shared.getAllDiaries().sorted { $0.date > $1.date }
        } catch {
            print("加载日记失败: \(error)")
            diaries = []
        }
    }
}