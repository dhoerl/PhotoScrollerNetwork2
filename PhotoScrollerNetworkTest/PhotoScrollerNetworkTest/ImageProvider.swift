//
//  ImageProvider.swift
//  PhotoScrollerNetworkTest
//
//  Created by David Hoerl on 2/6/20.
//  Copyright © 2020 Self. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import PhotoScrollerSwiftPackage

// ObservableObjectPublisher

struct ImageFetch {
    let url: URL
    var result: Result<UIView, Error>
}

final class ImageProvider: ObservableObject {

    static func fileURL(name: String) -> URL {
        let path = Bundle.main.path(forResource: name, ofType: "jpg")!
        let url = URL(fileURLWithPath: path)
        return url
    }

    @Published var result: ImageFetch?

    private var currentFetch: AnyCancellable?


    func fetchImage(url: URL) {

        // For internet up and down, must do this first (more times is fine)
        AssetFetcher.startMonitoring(onQueue: nil)

        // might have one in progress
        if let currentFetch = currentFetch { currentFetch.cancel() }

        let imageProvider = TiledImageBuilder(size: CGSize(width: 320, height: 320), orientation: 0 /*, queue: AssetFetcher.assetQueue, delegate: nil */)
        imageProvider.open()

        currentFetch = AssetFetcher(url: url)
            .sink(receiveCompletion: { (completion) in
                switch completion {
                case .finished:
                    break
                    //print("SUCCESS:", data.count, UIImage(data: data) ?? "WTF")
                case .failure(let error):
                    print("ERROR:", error)
                }
                DispatchQueue.main.async {
                    imageProvider.close()
                }
            },
            receiveValue: { (d) in
                d.withUnsafeBytes { (bufPtr: UnsafeRawBufferPointer) in
                    if let addr = bufPtr.baseAddress {
                        let ptr: UnsafePointer<UInt8> = addr.assumingMemoryBound(to: UInt8.self)
                        imageProvider.write(ptr, maxLength: bufPtr.count)
                    }
                }
            })
/*
        data.withUnsafeMutableBytes({ (bufPtr: UnsafeMutableRawBufferPointer) -> Void in
            if let addr = bufPtr.baseAddress {
                let ptr: UnsafeMutablePointer<UInt8> = addr.assumingMemoryBound(to: UInt8.self)
                buffer[0] = ptr
            }
        })
*/

    }

}
