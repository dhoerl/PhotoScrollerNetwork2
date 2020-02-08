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

struct ImageResult {
    let name: String
    let url: URL
    var result: Result<TilingView, Error>

    static func newResultFrom(_ old: ImageResult, newResult: Result<TilingView, Error>) -> ImageResult {
        return ImageResult(name: old.name, url: old.url, result: newResult)
    }

    func isSuccess() -> Bool {
        if case .success = result {
            return true
        } else {
            return false
        }
    }

    func tilingView() -> TilingView {
        guard case .success(let ib) = result else { fatalError() }
        return ib
    }

    func errorMsg() -> String {
        guard case .failure(let error) = result else { return "WTF???" }
        return error.localizedDescription
    }
}


final class ImageProvider: ObservableObject {

    static func fileURL(name: String) -> URL {
        let path = Bundle.main.path(forResource: name, ofType: "jpg")!
        let url = URL(fileURLWithPath: path)
        return url
    }

    @Published var imageResult: ImageResult
    var subscriber: AnyCancellable?

    private let kvp: (key: String, url: URL)
    private let imageBuilder: TiledImageBuilder


    init(kvp: (key: String, url: URL)) {
        self.kvp = kvp

        // For internet up and down, must do this first (more times is fine)
        AssetFetcher.startMonitoring(onQueue: nil)

        imageBuilder = TiledImageBuilder(size: CGSize(width: 320, height: 320), orientation: 0 /*, queue: AssetFetcher.assetQueue, delegate: nil */)
        imageResult = ImageResult(name: kvp.key, url: kvp.url, result: .failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Nothing Happened Yet"])))
    }
    deinit {
        subscriber?.cancel()
    }

    func fetch() {
        guard !kvp.key.isEmpty, !imageBuilder.failed, !imageBuilder.finished else { return }
//guard kvp.key.isEmpty else { return }

//        subscriber = future
//        .receive(on: DispatchQueue.main)
//        .eraseToAnyPublisher()
//        .sink(receiveCompletion: { (completion) in
//            switch completion {
//            case .finished:
//                print("FINISHED!!!")
//                //print("SUCCESS:", data.count, UIImage(data: data) ?? "WTF")
//            case .failure(let error):
//                print("ERROR:", error)
//            }
//            },
//            receiveValue: { (ib) in
//                self.imageBuilder = ib
//            }

        imageBuilder.open()

        subscriber = AssetFetcher(url: kvp.url)
            //.eraseToAnyPublisher()
            .sink(receiveCompletion: { (completion) in
                    DispatchQueue.main.async {
                        let result: Result<TilingView, Error>
                        switch completion {
                        case .finished:
                            print("SUCCESS!!!")
                            result = .success(TilingView(imageBuilder: self.imageBuilder))
                            break
                            //print("SUCCESS:", data.count, UIImage(data: data) ?? "WTF")
                        case .failure(let error):
                            print("ERROR:", error)
                            result = .failure(error)
                        }
                        self.imageBuilder.close()
                        self.imageResult = ImageResult.newResultFrom(self.imageResult, newResult: result)
                    }
                },
                receiveValue: { (d) in
                    d.withUnsafeBytes { (bufPtr: UnsafeRawBufferPointer) in
                        if let addr = bufPtr.baseAddress, bufPtr.count > 0 {
//print("WRITE BYTES:", bufPtr.count)
                            let ptr: UnsafePointer<UInt8> = addr.assumingMemoryBound(to: UInt8.self)
                            self.imageBuilder.write(ptr, maxLength: bufPtr.count)
                        }
                    }
                }
            )
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
