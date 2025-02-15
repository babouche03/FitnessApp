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
    
    private let userDefaults = UserDefaults.standard
    private let diariesKey = "savedDiaries"
    private let currentDraftKey = "currentDraft"
    
    init() {
        loadDiaries()
    }
    
    func saveDiary(_ diary: DiaryEntry) {
        if let index = diaries.firstIndex(where: { $0.id == diary.id }) {
            // 更新现有日记
            diaries[index] = diary
        } else {
            // 添加新日记
            diaries.append(diary)
        }
        currentDraft = nil
        saveToDisk()
    }
    
    func getCurrentDraft() -> DiaryEntry? {
        return currentDraft
    }
    
    func setCurrentDraft(_ diary: DiaryEntry?) {
        currentDraft = diary
        // 保存草稿到磁盘
        if let draft = diary {
            if let encoded = try? JSONEncoder().encode(draft) {
                userDefaults.set(encoded, forKey: currentDraftKey)
            }
        } else {
            userDefaults.removeObject(forKey: currentDraftKey)
        }
    }
    
    func getAllDiaries() -> [DiaryEntry] {
        return diaries.sorted { $0.date > $1.date }
    }
    
    func deleteDiary(withId id: UUID) {
        if let index = diaries.firstIndex(where: { $0.id == id }) {
            diaries.remove(at: index)
            saveToDisk()
        }
    }
    
    private func saveToDisk() {
        if let encoded = try? JSONEncoder().encode(diaries) {
            userDefaults.set(encoded, forKey: diariesKey)
        }
        // 当保存日记时，清除当前草稿
        userDefaults.removeObject(forKey: currentDraftKey)
    }
    
    private func loadDiaries() {
        if let savedData = userDefaults.data(forKey: diariesKey),
           let decoded = try? JSONDecoder().decode([DiaryEntry].self, from: savedData) {
            diaries = decoded
        }
        
        // 加载草稿
        if let draftData = userDefaults.data(forKey: currentDraftKey),
           let decoded = try? JSONDecoder().decode(DiaryEntry.self, from: draftData) {
            currentDraft = decoded
        }
    }
}
