//
//  NotificationManager.swift
//  SherlDog
//
//  Created by 최규현 on 4/25/26.
//

import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}
    
    func requestAuthorization() async -> Bool {
        do {
            let center = UNUserNotificationCenter.current()
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }
    
    func scheduleNotification(rainAfter: Double) {
        let content = UNMutableNotificationContent()
        content.title = SDLiteral.Notification.rainNoticeTitle
        content.body = String(format: SDLiteral.Notification.rainNoticeBody, Int(rainAfter))
        content.sound = .default
        content.badge = 1
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: SDLiteral.Notification.rainIdentifier,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if error == nil {
                // 알림 전송 성공
            } else {
                // 알림 전송 실패
            }
        }
    }
}
