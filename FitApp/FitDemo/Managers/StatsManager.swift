import Foundation

class StatsManager: ObservableObject {
    @Published var dailyStats: [Date: DailyStats] = [:]
    
    struct DailyStats: Codable {
        var focusTime: Int = 0      // 专注时间（秒）
        var restTime: Int = 0       // 休息时间（秒）
        var meditationTime: Int = 0 // 冥想时间（秒）
        var drivingDistance: Double = 0.0 // 行驶里程（公里）
    }
    
    // 单例模式
    static let shared = StatsManager()
    
    private init() {
        loadStats()
    }
    
    // 获取今日数据
    func getTodayStats() -> DailyStats {
        let today = Calendar.current.startOfDay(for: Date())
        return dailyStats[today] ?? DailyStats()
    }
    
    // 获取指定日期数据
    func getStats(for date: Date) -> DailyStats {
        let startOfDay = Calendar.current.startOfDay(for: date)
        return dailyStats[startOfDay] ?? DailyStats()
    }
    
    // 获取总计数据
    func getTotalStats() -> DailyStats {
        dailyStats.values.reduce(DailyStats()) { result, stats in
            DailyStats(
                focusTime: result.focusTime + stats.focusTime,
                restTime: result.restTime + stats.restTime,
                meditationTime: result.meditationTime + stats.meditationTime,
                drivingDistance: result.drivingDistance + stats.drivingDistance
            )
        }
    }
    
    // 更新数据
    func updateStats(focusTime: Int? = nil, restTime: Int? = nil, meditationTime: Int? = nil, drivingDistance: Double? = nil) {
        let today = Calendar.current.startOfDay(for: Date())
        var todayStats = dailyStats[today] ?? DailyStats()
        
        // 只接受按分钟取整的时间
        if let focusTime = focusTime, focusTime >= 60 {
            todayStats.focusTime += focusTime
        }
        if let restTime = restTime, restTime >= 60 {
            todayStats.restTime += restTime
        }
        if let meditationTime = meditationTime, meditationTime >= 60 {
            todayStats.meditationTime += meditationTime
        }
        if let drivingDistance = drivingDistance {
            todayStats.drivingDistance += drivingDistance
        }
        
        dailyStats[today] = todayStats
        saveStats()
    }
    
    // 清除所有数据
    func clearAllStats() {
        dailyStats.removeAll()
        saveStats()
    }
    
    // 保存数据到本地
    private func saveStats() {
        if let encoded = try? JSONEncoder().encode(dailyStats) {
            UserDefaults.standard.set(encoded, forKey: "dailyStats")
        }
    }
    
    // 从本地加载数据
    private func loadStats() {
        if let data = UserDefaults.standard.data(forKey: "dailyStats"),
           let decoded = try? JSONDecoder().decode([Date: DailyStats].self, from: data) {
            dailyStats = decoded
        }
    }
}