//
//  ImageBuilding.swift
//  PhotoScrollerNetworkTestTests
//
//  Created by David Hoerl on 2/4/20.
//  Copyright © 2020 Self. All rights reserved.
//

import UIKit
import XCTest
import Combine
import PhotoScrollerSwiftPackage

/*
// Shared with Web tests
let TestAssetQueue = DispatchQueue(label: "com.AssetFetcher", qos: .userInitiated)

let FetcherDeinit = Notification.Name("FetcherDeinit")
let FetcherURL = "FetcherURL"
let AssetURL = "AssetURL"

final class ByURL {
    var streamOwner: InputStream?
    weak var inputStream: InputStream?

    var data = Data()
    var events = 0
    var image: UIImage?
    var dealloced = false
    var error: Error?
    var name = ""

    init(streamOwner: InputStream, inputStream: InputStream) {
        self.streamOwner = streamOwner  // so we can release it
        self.inputStream = inputStream
    }
}
*/
/* --- */

private let allFiles = ["Coffee", "err_image", "Lake", "large_leaves_70mp", "Shed", "Tree", "Space4", "Space5", "Space6"]

final class ImageBuilding: XCTestCase, StreamDelegate {

    private var assetQueue = TestAssetQueue
    private var expectation = XCTestExpectation(description: "")

    private var fetchers: [URL: ByURL] = [:]
    private var builders: [String: TiledImageBuilder] = [:]
    private var subscribers: [URL: AnyCancellable] = [:]    // Combine

//    private var urls: Set<URL> = []
//    private var data: [URL: Data] = [:]
//    private var events: [URL: Int] = [:]

//    override func invokeTest() {
//        for time in 0...3 {
//            print("FileBased invoking: \(time) times")
//            super.invokeTest()
//        }
//    }

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        continueAfterFailure = false

        expectation = XCTestExpectation(description: "FileFetchers deinit")
        expectation.assertForOverFulfill = true
        self.assetQueue.sync {
            self.fetchers.removeAll()
        }
//        // In UI tests it is usually best to stop immediately when a failure occurs.
//        continueAfterFailure = false
//
//        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
//        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.

        NotificationCenter.default.addObserver(self, selector: #selector(notification(_:)), name: FetcherDeinit, object: nil)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        NotificationCenter.default.removeObserver(self, name: FetcherDeinit, object: nil)

        self.assetQueue.sync {
            self.fetchers.removeAll()
        }
        expectation = XCTestExpectation(description: "")
        builders.removeAll()
    }

    @objc
    func notification(_ note: Notification) {
        if let url = note.userInfo?[FetcherURL] as? URL {
            self.assetQueue.async {
                guard let byURL = self.fetchers[url] else { return }    // Combine uses a fetcher, its not in this array
                byURL.dealloced = true
                DispatchQueue.main.async {
                    self.expectation.fulfill()
                }
            }
        } else
        if let _ = note.userInfo?[AssetURL] as? URL {
            DispatchQueue.main.async {
                self.expectation.fulfill()
            }
        }

    }

    func test1SingleFile() {
        let files = Array(allFiles[0..<1])
        runTest(files: files)
    }

    func xtest2TwoFiles() {
        let files = Array(allFiles[0..<2])
        runTest(files: files)
    }

    func xtest3NineFiles() {
        let files = allFiles
        runTest(files: files)
    }

    private func runTest(files: [String]) {
        var expectedFulfillmentCount = 0
        for file in files {
            // sadly, some of the fetchers get retained somehow if we don't autorelease...
            autoreleasepool {
                let path = Bundle.main.path(forResource: file, ofType: "jpg")!
                let url = URL(fileURLWithPath: path)
                let fetcher = FileFetcherStream(url: url, queue: assetQueue, delegate: self)
                let byURL = ByURL(streamOwner: fetcher, inputStream: fetcher.inputStream)
                byURL.name = file
                assetQueue.sync {
                    self.fetchers[url] = byURL
                }
                expectedFulfillmentCount += 2   // one for the final stream message, one for the dealloc
                expectation.expectedFulfillmentCount = expectedFulfillmentCount

                let builder = TiledImageBuilder(size: CGSize(width: 320, height: 320), orientation: 0 /* , queue: assetQueue, delegate: self */)
                builders[byURL.name] = builder

                builder.open()
                fetcher.open()
            }
        }

        wait(for: [expectation], timeout: TimeInterval(files.count * 10))

        var values: [ByURL] = []
        self.assetQueue.sync {
            self.fetchers.values.forEach({ values.append($0) })
        }
        for byURL in values {
            XCTAssert( !byURL.data.isEmpty )
            XCTAssert( byURL.image != nil )
        }
        for (_, builder) in builders {
            XCTAssert(builder.finished)
            let view = TilingView(imageBuilder: builder)
            print("SIZE:", view.imageSize())
        }
    }
/*
    func test4SingleCombine() {
        let files = Array(allFiles[0..<1])
        runTestCombine(files: files)
    }

    func test5TwoCombine() {
        let files = Array(allFiles[0..<2])
        runTestCombine(files: files)
    }

    func test6NineCombine() {
        let files = allFiles
        runTestCombine(files: files)
    }

    private func runTestCombine(files: [String]) {
        var expectedFulfillmentCount = 0
        expectation.expectedFulfillmentCount = 1

        for file in files {
            let path = Bundle.main.path(forResource: file, ofType: "jpg")!
            let url = URL(fileURLWithPath: path)

            expectedFulfillmentCount += 4   // AssetFetcher, the Subscription, FileFetcher, and the FileFetcher Stream
            expectation.expectedFulfillmentCount = expectedFulfillmentCount

            var data = Data()
            let mySubscriber = AssetFetcher(url: url)
                                .sink(receiveCompletion: { (completion) in
                                    switch completion {
                                    case .finished:
                                        XCTAssert(!data.isEmpty)
                                        XCTAssertNotNil(UIImage(data: data))
                                        //print("SUCCESS:", data.count, UIImage(data: data) ?? "WTF")
                                    case .failure(let error):
                                        print("ERROR:", error)
                                    }
                                    DispatchQueue.main.async {
                                        self.expectation.fulfill()
                                    }
                                },
                                receiveValue: { (d) in
                                    data.append(d)
                                })
            subscribers[url] = mySubscriber
        }

        wait(for: [expectation], timeout: TimeInterval(files.count * 10))
    }
*/
    @objc
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        dispatchPrecondition(condition: .onQueue(assetQueue))
        guard let stream = aStream as? InputStream else { fatalError() }
        guard let byURL = fetchers.values.first(where: { $0.inputStream === stream }) else { return print("Errant message type \(eventCode.rawValue)") }
        guard let builder = builders[byURL.name] else { fatalError() }

        byURL.events += 1
        var closeStream = false

        switch eventCode {
        case .openCompleted:
            XCTAssertEqual(byURL.events, 1)
        case .endEncountered:
            byURL.image = UIImage(data: byURL.data)
assert(byURL.image != nil)
            closeStream = true
assert(builder.finished)
        case .hasBytesAvailable:
            guard stream.hasBytesAvailable else { return }

            let askLen: Int
            do {
                //var byte: UInt8 = 0
                var ptr: UnsafeMutablePointer<UInt8>? = nil
                var len: Int = 0

                if stream.getBuffer(&ptr, length: &len) {
                    askLen = len
                } else {
                    askLen = 4_096
                }
            }
            let bytes = UnsafeMutablePointer<UInt8>.allocate(capacity: askLen)
            //let has0 = stream.hasBytesAvailable
            let readLen = stream.read(bytes, maxLength: askLen)
            if readLen > 0 {
                byURL.data.append(bytes, count: readLen)
                builder.write(bytes, maxLength: readLen)
            } else {
                // NSInputStream says it has bytes, but when we try to read them, it now claims "OOPS - thought I had some"
                //print("READ==0: ask:", askLen, "HAS BYTES:", stream.hasBytesAvailable, "HAD:", has0)
            }
        case .errorOccurred:
            aStream.close()
            if let error = aStream.streamError {
                byURL.error = error
                print("WTF!!! Error:", error)
            } else {
                print("ERROR BUT NO STREAM ERROR!!!")
            }
            closeStream = true
        default:
            print("UNEXPECTED \(eventCode)", String(describing: eventCode))
            XCTAssert(false)
        }
        if closeStream {
            stream.close()
            builder.close()
    
            DispatchQueue.main.async {
                byURL.streamOwner = nil
//print("byURL.streamOwner nil?:", byURL.streamOwner == nil, "URL:", byURL.name)
//                print(eventCode == .endEncountered ? "AT END :-)" : "ERROR")
                self.expectation.fulfill()
            }
        }
    }

}
