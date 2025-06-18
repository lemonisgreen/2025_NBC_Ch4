//
//  PermissionManager.swift
//  SherlDog
//
//  Created by 최규현 on 6/17/25.
//

import PhotosUI

class PermissionManager {
    
    static func requestPermission(type: PermissionType, completion: @escaping (Bool) -> ()) {
        switch type {
        case .camera:
            self.requestCameraPermission(completion: completion)
        case .album:
            self.requestAlbumPermission(completion: completion)
        }
    }
    
    private static func requestAlbumPermission(completion: @escaping (Bool) -> ()) {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized, .limited:
                    completion(true)
                case .notDetermined, .denied, .restricted:
                    completion(false)
                @unknown default:
                    completion(false)
                }
            }
        }
    }
    
    private static func requestCameraPermission(completion: @escaping (Bool) -> ()) {
        AVCaptureDevice.requestAccess(for: .video) { request in
            DispatchQueue.main.async {
                completion(request)
            }
        }
    }
}

enum PermissionType {
    case camera, album
}
