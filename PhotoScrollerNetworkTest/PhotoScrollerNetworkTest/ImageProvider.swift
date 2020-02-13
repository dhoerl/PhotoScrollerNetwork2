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

typealias KVP = (key: String, url: URL)

struct ImageResult {
    let name: String
    let url: URL
    var result: Result<TilingView, Error>

    static func newResultFrom(_ old: ImageResult, newResult: Result<TilingView, Error>) -> ImageResult {
        return ImageResult(name: old.name, url: old.url, result: newResult)
    }

    static func new(kvp: KVP) -> ImageResult {
        return ImageResult(name: kvp.key, url: kvp.url, result: .failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Nothing Happened Yet"])))
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

    private static let defaultImageBuilder = TiledImageBuilder(size: CGSize(width: 320, height: 320), orientation: 0)
    private static let defaultName = "Coffee"
    static let defaultKVP: KVP = (key: "", url: ImageProvider.fileURL(name: defaultName))
    fileprivate static let selectionPublisher = PassthroughSubject<KVP, Never>()

    @Published var imageResult: ImageResult

    var scrollView: ImageScrollView?                                // Set elsewhere
    var currentImage: UIImage { scrollView?.image() ?? UIImage() }  // Image retrieved later after scrollview is set

    private var subscriber: AnyCancellable?

    private let kvp: KVP
    private var imageBuilder: TiledImageBuilder
    private var isFetching = false

    private var kvpSubscriber: AnyCancellable?

    init(kvp: KVP) {
        self.kvp = kvp

        // For internet up and down, must do this first (more times is fine)
        // AssetFetcher.startMonitoring(onQueue: nil)   // put in App Delegate
        imageBuilder = Self.defaultImageBuilder
        imageResult = ImageResult.new(kvp: kvp)
    }
    deinit {
print("DEINIT:", kvp.key)
        subscriber?.cancel()
    }

    func clear() {
print("CLEAR:", kvp.key)
        subscriber?.cancel()
        imageBuilder = Self.defaultImageBuilder
        imageResult = ImageResult.new(kvp: kvp)
        isFetching = false
        kvpSubscriber = nil
    }

    func fetch() {
        guard !isFetching, !kvp.key.isEmpty else { return print("DID NOT FETCH:", kvp.key) }

//print("FETCHING \(kvp.key)...")
        isFetching = true

        Self.selectionPublisher.send(self.kvp)
        kvpSubscriber = Self.selectionPublisher
        .sink(receiveValue: { (kvp) in
            if self.isFetching, self.kvp != kvp {
                self.clear()
            }
        })

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
//print("WRITE BYTES:", bufPtr.count, "...")
                            let ptr: UnsafePointer<UInt8> = addr.assumingMemoryBound(to: UInt8.self)
                            self.imageBuilder.write(ptr, maxLength: bufPtr.count)
//print("...WRITE BYTES:", bufPtr.count)
                        }
                    }
                }
            )
    }

}
