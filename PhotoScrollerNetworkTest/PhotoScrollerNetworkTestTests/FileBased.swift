//
//  FileBased.swift
//  PhotoScrollerNetworkTestTests
//
//  Created by David Hoerl on 1/31/20.
//  Copyright © 2020 Self. All rights reserved.
//

import UIKit
import XCTest
import Combine

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
/* --- */

private let allFiles = ["Coffee", "err_image", "Lake", "Leaves", "Shed", "Tree", "Space4", "Space5", "Space6"]

final class FileBased: XCTestCase, StreamDelegate {

    private var assetQueue = TestAssetQueue
    private var expectation = XCTestExpectation(description: "")

    private var fetchers: [URL: ByURL] = [:]
    private var subscribers: [URL: AnyCancellable] = [:]
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
    }

    @objc
    func notification(_ note: Notification) {
        if let url = note.userInfo?[FetcherURL] as? URL {
            self.assetQueue.async {
                // print("DEINIT notification for \(url)")
                if let byURL = self.fetchers[url] {
                    byURL.dealloced = true
                }
                DispatchQueue.main.async {
                    self.expectation.fulfill()
                }
            }
        } else
        if let url = note.userInfo?[AssetURL] as? URL {
            // print("DEINIT ASSET notification for \(url)")
            DispatchQueue.main.async {
                self.expectation.fulfill()
            }
        }

    }

    func test1SingleFile() {
        let files = Array(allFiles[0..<1])
        runTest(files: files)
    }

    func test2TwoFiles() {
        let files = Array(allFiles[0..<2])
        runTest(files: files)
    }

    func test3NineFiles() {
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
    }

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
        //expectation.expectedFulfillmentCount = 0

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
                                        print("SUCCESS:", data.count, UIImage(data: data) ?? "WTF")
                                    case .failure(let error):
                                        print("ERROR:", error)
                                    }
                                    DispatchQueue.main.async {
                                        self.expectation.fulfill()
                                    }
                                },
                                receiveValue: { (assetData) in
//print("HAHAHHA:", assetData.data.count)
                                    data.append(assetData.data)
                                })
            subscribers[url] = mySubscriber
        }

        wait(for: [expectation], timeout: TimeInterval(files.count * 10))
    }

    @objc
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        dispatchPrecondition(condition: .onQueue(assetQueue))
        guard let stream = aStream as? InputStream else { fatalError() }
        guard let byURL = fetchers.values.first(where: { $0.inputStream === stream }) else { return print("Errant message type \(eventCode.rawValue)") }
        //let fetcher = byURL.fetcher

        byURL.events += 1
        var closeStream = false

        switch eventCode {
        case .openCompleted:
            XCTAssertEqual(byURL.events, 1)
        case .endEncountered:
            byURL.image = UIImage(data: byURL.data)
assert(byURL.image != nil)
            closeStream = true
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
            DispatchQueue.main.async {
                byURL.streamOwner = nil
//print("byURL.streamOwner nil?:", byURL.streamOwner == nil, "URL:", byURL.name)
//                print(eventCode == .endEncountered ? "AT END :-)" : "ERROR")
                self.expectation.fulfill()
            }
        }
    }

}
