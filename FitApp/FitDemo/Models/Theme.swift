struct Theme: Identifiable {
    let id: Int
    let name: String
    let icon: String
    let backgroundImage: String
    let backgroundVideo: String?
    let audioName: String
}

// 添加扩展来定义所有主题
extension Theme {
    static let allThemes: [Theme] = [
        // 基础主题
        Theme(id: 0, name: "森林", icon: "🌳", backgroundImage: "forest_bg", backgroundVideo: nil, audioName: "forest"),
        Theme(id: 1, name: "雨点", icon: "💧", backgroundImage: "rain_bg", backgroundVideo: "rain", audioName: "rain"),
        Theme(id: 2, name: "海滩", icon: "🏖️", backgroundImage: "beach_bg", backgroundVideo: "beach", audioName: "beach"),
        Theme(id: 3, name: "徒步", icon: "⛰️", backgroundImage: "hike1", backgroundVideo: nil, audioName: "hike"),
        Theme(id: 4, name: "极光", icon: "✨", backgroundImage: "desert_bg", backgroundVideo: "aurora", audioName: "aurora"),
        Theme(id: 5, name: "夏夜", icon: "🌙", backgroundImage: "summernight", backgroundVideo: nil, audioName: "summernight"),
        
        // 扩展主题
        Theme(id: 6, name: "柴火", icon: "🔥", backgroundImage: "bonfire_bg", backgroundVideo: "bonfire", audioName: "bonfire"),
        Theme(id: 7, name: "餐厅", icon: "🍽", backgroundImage: "restaurant_bg", backgroundVideo: "restaurant", audioName: "restaurant"),
        Theme(id: 8, name: "秋日", icon: "🍁", backgroundImage: "autumn", backgroundVideo: nil, audioName: "autumn"),
        Theme(id: 9, name: "公路", icon: "🚦", backgroundImage: "highway", backgroundVideo: nil, audioName: "highway"),
        Theme(id: 10, name: "键盘", icon: "⌨", backgroundImage: "keyboard", backgroundVideo: nil, audioName: "keyboard"),
        Theme(id: 11, name: "茶馆", icon: "🍵", backgroundImage: "teahouse", backgroundVideo: nil, audioName: "teahouse"),
        Theme(id: 12, name: "泉水", icon: "⛲️", backgroundImage: "spring_bg", backgroundVideo: "spring", audioName: "spring"),
        Theme(id: 13, name: "寺庙", icon: "🏮", backgroundImage: "temple", backgroundVideo: nil, audioName: "temple"),
        Theme(id: 14, name: "梦境", icon: "💭", backgroundImage: "dream_bg", backgroundVideo: "dream", audioName: "dream")
    ]
}
