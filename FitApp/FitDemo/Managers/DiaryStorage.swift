import Foundation

class DiaryStorage {
    static let shared = DiaryStorage()
    
    private let fileManager = FileManager.default
    
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private var diariesDirectory: URL {
        let diariesDir = documentsDirectory.appendingPathComponent("Diaries")
        if !fileManager.fileExists(atPath: diariesDir.path) {
            try? fileManager.createDirectory(at: diariesDir, withIntermediateDirectories: true)
        }
        return diariesDir
    }
    
    private var indexFilePath: URL {
        documentsDirectory.appendingPathComponent("diary_index.json")
    }
    
    private var draftFilePath: URL {
        documentsDirectory.appendingPathComponent("current_draft.json")
    }
    
    // 日记索引结构
    struct DiaryIndex: Codable {
        var entries: [DiaryIndexEntry]
    }
    
    struct DiaryIndexEntry: Codable {
        let id: UUID
        let date: Date
        let mood: Double
    }
    
    private init() {}
    
    // 保存日记
    func saveDiary(_ diary: DiaryEntry) throws {
        let diaryDir = diariesDirectory.appendingPathComponent(diary.id.uuidString)
        
        // 如果目录已存在，先删除所有现有图片
        if fileManager.fileExists(atPath: diaryDir.path) {
            // 获取目录中的所有文件
            let files = try fileManager.contentsOfDirectory(atPath: diaryDir.path)
            // 删除所有图片文件
            for file in files where file.starts(with: "image_") {
                try fileManager.removeItem(atPath: diaryDir.appendingPathComponent(file).path)
            }
        } else {
            // 如果目录不存在，创建它
            try fileManager.createDirectory(at: diaryDir, withIntermediateDirectories: true)
        }
        
        // 保存文本内容
        let contentFile = diaryDir.appendingPathComponent("content.txt")
        try diary.content.write(to: contentFile, atomically: true, encoding: .utf8)
        
        // 保存新的图片
        for (index, imageData) in diary.imageData.enumerated() {
            let imageFile = diaryDir.appendingPathComponent("image_\(index).jpg")
            try imageData.write(to: imageFile)
        }
        
        // 保存视频URL
        let videoURLsFile = diaryDir.appendingPathComponent("videos.json")
        let videoURLsData = try JSONEncoder().encode(diary.videoURLs)
        try videoURLsData.write(to: videoURLsFile)
        
        // 更新索引
        try updateIndex(for: diary)
    }
    
    // 读取日记
    func loadDiary(withId id: UUID) throws -> DiaryEntry {
        let diaryDir = diariesDirectory.appendingPathComponent(id.uuidString)
        
        // 读取文本内容
        let contentFile = diaryDir.appendingPathComponent("content.txt")
        let content = try String(contentsOf: contentFile, encoding: .utf8)
        
        // 读取图片
        var imageDataArray: [Data] = []
        var index = 0
        while true {
            let imageFile = diaryDir.appendingPathComponent("image_\(index).jpg")
            if fileManager.fileExists(atPath: imageFile.path) {
                let imageData = try Data(contentsOf: imageFile)
                imageDataArray.append(imageData)
                index += 1
            } else {
                break
            }
        }
        
        // 读取视频URL
        let videoURLsFile = diaryDir.appendingPathComponent("videos.json")
        let videoURLs: [String]
        if fileManager.fileExists(atPath: videoURLsFile.path) {
            let videoURLsData = try Data(contentsOf: videoURLsFile)
            videoURLs = try JSONDecoder().decode([String].self, from: videoURLsData)
        } else {
            videoURLs = []
        }
        
        // 从索引中获取基本信息
        guard let indexEntry = try loadIndex().entries.first(where: { $0.id == id }) else {
            throw NSError(domain: "DiaryStorage", code: 404)
        }
        
        return DiaryEntry(
            id: id,
            date: indexEntry.date,
            mood: indexEntry.mood,
            content: content,
            imageData: imageDataArray,
            videoURLs: videoURLs
        )
    }
    
    // 删除日记
    func deleteDiary(withId id: UUID) throws {
        let diaryDir = diariesDirectory.appendingPathComponent(id.uuidString)
        try fileManager.removeItem(at: diaryDir)
        
        // 更新索引
        var index = try loadIndex()
        index.entries.removeAll { $0.id == id }
        try saveIndex(index)
    }
    
    // 获取所有日记
    func getAllDiaries() throws -> [DiaryEntry] {
        let index = try loadIndex()
        return try index.entries.map { try loadDiary(withId: $0.id) }
    }
    
    // 保存草稿
    func saveDraft(_ diary: DiaryEntry?) throws {
        if let diary = diary {
            let data = try JSONEncoder().encode(diary)
            try data.write(to: draftFilePath)
        } else if fileManager.fileExists(atPath: draftFilePath.path) {
            try fileManager.removeItem(at: draftFilePath)
        }
    }
    
    // 读取草稿
    func loadDraft() throws -> DiaryEntry? {
        guard fileManager.fileExists(atPath: draftFilePath.path) else { return nil }
        let data = try Data(contentsOf: draftFilePath)
        return try JSONDecoder().decode(DiaryEntry.self, from: data)
    }
    
    private func loadIndex() throws -> DiaryIndex {
        if fileManager.fileExists(atPath: indexFilePath.path) {
            let data = try Data(contentsOf: indexFilePath)
            return try JSONDecoder().decode(DiaryIndex.self, from: data)
        }
        return DiaryIndex(entries: [])
    }
    
    private func saveIndex(_ index: DiaryIndex) throws {
        let data = try JSONEncoder().encode(index)
        try data.write(to: indexFilePath)
    }
    
    private func updateIndex(for diary: DiaryEntry) throws {
        var index = try loadIndex()
        if let existingIndex = index.entries.firstIndex(where: { $0.id == diary.id }) {
            index.entries[existingIndex] = DiaryIndexEntry(id: diary.id, date: diary.date, mood: diary.mood)
        } else {
            index.entries.append(DiaryIndexEntry(id: diary.id, date: diary.date, mood: diary.mood))
        }
        try saveIndex(index)
    }
}