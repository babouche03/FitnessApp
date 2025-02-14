//
//  FitDemoApp.swift
//  FitDemo
//
//  Created by boyifan on 2024/10/14.
//

import SwiftUI

@main
struct FitDemoApp: App {
    @AppStorage("isDarkMode") private var isDarkMode = true
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // 应用启动时设置保存的主题
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                        windowScene.windows.forEach { window in
                            window.overrideUserInterfaceStyle = isDarkMode ? .dark : .light
                        }
                    }
                }
        }
    }
}
