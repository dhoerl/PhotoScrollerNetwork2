//
//  SceneDelegate.swift
//  PhotoScrollerNetworkTest
//
//  Created by David Hoerl on 1/21/20.
//  Copyright © 2020 Self. All rights reserved.
//

import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var appEnvironment = AppEnvironment()

    @objc
    func orientationChanged() {
        let bounds = UIScreen.main.nativeBounds
        let orientation = UIDevice.current.orientation

        if orientation.isLandscape && bounds.size.height > 1000 {
            if appEnvironment.useSideBySide == false {
                appEnvironment.useSideBySide = true
                print("SIDE changed to TRUE")
            }
        } else if orientation.isPortrait && appEnvironment.useSideBySide == true {
            print("SIDE changed to false")
            appEnvironment.useSideBySide = false
        }
    }

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        // Create the SwiftUI view that provides the window contents.

let fm = freeMemory()
print(fm)
        let contentView = ContentView()

        // Use a UIHostingController as window root view controller.
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(rootView: contentView.environmentObject(appEnvironment))
            self.window = window
            window.makeKeyAndVisible()

            orientationChanged()
            NotificationCenter.default.addObserver(self, selector: #selector(orientationChanged), name: UIDevice.orientationDidChangeNotification, object: nil)
            UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}


func getFreeDiskspace() -> Result<Int64, Error> {
    let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
    do {
        let dictionary = try FileManager.default.attributesOfFileSystem(forPath: paths.last!)
        let freeSize = dictionary[FileAttributeKey.systemFreeSize] as! Int64
        return Result.success(freeSize)
    } catch {
        return Result.failure(error)
    }
}


struct FreeMemory: CustomStringConvertible {
    var description: String {
        var formatter:NumberFormatter = { let f = NumberFormatter(); f.numberStyle = .decimal; return f}()
        func megs(_ val: UInt64) -> String {
            let ret = val / (1024*1025)
            var s = formatter.string(from: NSNumber(value: ret)) ?? "<??>"
            s += " M"

            let newLength = 8 // good for 99G
            let length = s.count
            if length < newLength {
                // Prepend `newLength - length` space characters:
                s = String(repeating: " ", count: newLength - length) + s
            }
            return s
        }
        let format = """
        FreeMemory:
          TotalMemory  = %@
          UsedMemory   = %@
          FreeMemory   = %@
          ResidentSize = %@
          VirtualSize  = %@
        """
        return String(format: format, megs(totlMemory), megs(usedMemory), megs(freeMemory), megs(resident_size), megs(virtual_size))
    }

    var totlMemory: UInt64 = 0
    var usedMemory: UInt64 = 0
    var freeMemory: UInt64 = 0
    var resident_size: UInt64 = 0
    var virtual_size: UInt64 = 0
}

func freeMemory() -> FreeMemory {
    // https://stackoverflow.com/a/43715430/1633251
    var fm = FreeMemory()

    let HOST_BASIC_INFO_COUNT = MemoryLayout<host_basic_info>.stride/MemoryLayout<integer_t>.stride
    var size = mach_msg_type_number_t(HOST_BASIC_INFO_COUNT)

    var hostInfo = host_basic_info()
    let host_port: mach_port_t = mach_host_self()

    let status1 = withUnsafeMutablePointer(to: &hostInfo) {
        $0.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
            host_info(host_port, Int32(HOST_BASIC_INFO), $0, &size)
        }
    }
    if status1 != KERN_SUCCESS {
        print("Status 1 failed:", status1)
        return fm
    }

    var vm_stat = vm_statistics_data_t()
    let HOST_VM_INFO_COUNT = MemoryLayout<vm_statistics_data_t>.stride/MemoryLayout<integer_t>.stride
    var size2 = mach_msg_type_number_t(HOST_VM_INFO_COUNT)

    let status2 = withUnsafeMutablePointer(to: &vm_stat) {
        $0.withMemoryRebound(to: integer_t.self, capacity: Int(size2)) {
            host_statistics(host_port, Int32(HOST_VM_INFO), $0, &size2)
        }
    }

    if status2 != KERN_SUCCESS {
        print("Status 2 failed:", status2)
        return fm
    }

    // Stats in bytes
    var page_size: vm_size_t = vm_size_t()
    let status3 = host_page_size(host_port, &page_size)
    if status3 != KERN_SUCCESS {
        print("Status 2 failed:", status3)
        return fm
    }

    fm.usedMemory = UInt64(vm_stat.active_count + vm_stat.wire_count) * UInt64(page_size)
    fm.freeMemory = UInt64(vm_stat.free_count + vm_stat.inactive_count) * UInt64(page_size) // Inactive can be paged out
    fm.totlMemory = fm.usedMemory + fm.freeMemory

    // https://stackoverflow.com/a/57315975/1633251
    // The `TASK_VM_INFO_COUNT` and `TASK_VM_INFO_REV1_COUNT` macros are too
    // complex for the Swift C importer, so we have to define them ourselves.
    let TASK_VM_INFO_COUNT = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size)
    let TASK_VM_INFO_REV1_COUNT = mach_msg_type_number_t(MemoryLayout.offset(of: \task_vm_info_data_t.min_address)! / MemoryLayout<integer_t>.size)
    var info = task_vm_info_data_t()
    var count = TASK_VM_INFO_COUNT
    let status4 = withUnsafeMutablePointer(to: &info) { infoPtr in
        infoPtr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
            task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), intPtr, &count)
        }
    }

    if status4 != KERN_SUCCESS || count < TASK_VM_INFO_REV1_COUNT {
        print("Status 3 failed:", status3, count, TASK_VM_INFO_REV1_COUNT)
        return fm
    }

    fm.resident_size = UInt64(info.resident_size)
    fm.virtual_size = UInt64(info.virtual_size)

    return fm
}
//    var info: task_basic_info = 0
//    if dump_memory_usage(&info) {
//        fm.resident_size = info.resident_size
//        fm.virtual_size = info.virtual_size
//    }
//
//    //#if MEMORY_DEBUGGING == 0
//    print(String(format: """
//    %@:   \
//    total: %lu \
//    used: %lu \
//    FREE: %lu \
//      [resident=%lu virtual=%lu]
//    """, msg, UInt(mem_total), UInt(mem_used), UInt(mem_free), UInt(fm?.resident_size ?? 0), UInt(fm?.virtual_size ?? 0)))
//    //#endif
//    }

//func freeMemory()->UInt64 {
//    let host_port :mach_port_t = mach_host_self()
//
//    let HOST_BASIC_INFO_COUNT = MemoryLayout<host_basic_info>.stride/MemoryLayout<integer_t>.stride
//    var size = mach_msg_type_number_t(HOST_BASIC_INFO_COUNT)
//    var hostInfo = host_basic_info()
//
//    let status1 = withUnsafeMutablePointer(to: &hostInfo) {
//        $0.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
//            host_info(host_port, Int32(HOST_BASIC_INFO), $0, &size)
//        }
//    }
//
//    print(status1, hostInfo)
//
//    // THE FIX:
//
//    var pageSize: vm_size_t = vm_size_t()
//    //let hostPageSizeKernStatus: kern_return_t = host_page_size(host_port, &pageSize)
//
//
//    var vm_stat = vm_statistics_data_t()
//    let HOST_VM_INFO_COUNT = MemoryLayout<vm_statistics_data_t>.stride/MemoryLayout<integer_t>.stride
//    var size2 = mach_msg_type_number_t(HOST_VM_INFO_COUNT)
//
//    let status2 = withUnsafeMutablePointer(to: &vm_stat) {
//        $0.withMemoryRebound(to: integer_t.self, capacity: Int(size2)) {
//            host_statistics(host_port, Int32(HOST_VM_INFO), $0, &size2)
//            //C:
//            //  (void) host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size);
//
//        }
//    }
//
//    print(status2, vm_stat)
//
//    let freePages = UInt64(vm_stat.free_count)
//    let result = freePages * UInt64(pageSize)
//
//
//    return result
//}
//
