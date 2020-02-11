//
//  ContentDetail.swift
//  PhotoScrollerNetworkTest
//
//  Created by David Hoerl on 1/21/20.
//  Copyright © 2020 Self. All rights reserved.
//

import SwiftUI
import Combine
import PhotoScrollerSwiftPackage


struct DetailView: View {
    @EnvironmentObject var appEnvironment: AppEnvironment
    @ObservedObject var imageProvider: ImageProvider

    let kvp: (key: String, url: URL)
    var subscriber: AnyCancellable?

    init(kvp: (key: String, url: URL)) {
        self.kvp = kvp

        // print("CALLED FOR IMAGE:", kvp.key, "URL", kvp.url.path)
        imageProvider = ImageProvider(kvp: kvp)
    }

//    @Binding var dates: [Date]

//    init(_ dates: Binding<[Date]>) {
//        self.dates = dates
//
//        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
//            self.dates.insert(Date(), at: 0)
//            print("FAD")
//        }
//    }

    var body: some View {

//NavigationView {
        VStack {
            if kvp.key != "" {
                Text("\(kvp.key)")
//                .onAppear {
//                    withAnimation(Animation.easeInOut(duration: 2.0)) {
//                        //self.animate = true
//                    }
//                }
            } else {

                Text("Detail view content goes here")
            }
            ImageView(imageProvider: self.imageProvider)
                .padding()
                .onAppear { print("onAppear:", self.kvp.key); self.imageProvider.fetch() }
        }
//}
            .navigationBarTitle(Text("Detail"), displayMode: .inline)
            .navigationBarItems(
                //leading: Text("Howdie"),
                trailing: Button(
                    action: {
                        //withAnimation { self.dates.insert(Date(), at: 0) }
                    }
                ) {
                    Image(systemName: "plus")
                }
            )
    }

}

struct ImageView: View {
    @ObservedObject var imageProvider: ImageProvider
    @State private var isAnimating = true

    var body: some View {
        Group {
            if imageProvider.imageResult.isSuccess() {
                    TiledImageView(view: self.imageProvider.imageResult.tilingView())
                        .onDisappear() { print("onDisappear", self.imageProvider.imageResult.name); self.imageProvider.clear() }
                        //.frame(width: 320, height: 320, alignment: .center)
            } else {
                ActivityIndicator(isAnimating: $isAnimating, style: .large)
                //Text("\(imageResult.name) failed \(imageResult.errorMsg())")
            }
        }
    }
}

struct ActivityIndicator: UIViewRepresentable {
    @Binding var isAnimating: Bool
    let style: UIActivityIndicatorView.Style

    func makeUIView(context: UIViewRepresentableContext<ActivityIndicator>) -> UIActivityIndicatorView {
        return UIActivityIndicatorView(style: style)
    }

    func updateUIView(_ uiView: UIActivityIndicatorView, context: UIViewRepresentableContext<ActivityIndicator>) {
        isAnimating ? uiView.startAnimating() : uiView.stopAnimating()
    }
}

struct TiledImageView: UIViewRepresentable {
    let view: TilingView

    func makeUIView(context: Context) -> ImageScrollView {
        ImageScrollView.annotateTiles = true
        let retView = ImageScrollView()
        retView.display(view)
        return retView
    }
/* From SwiftUI group
func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<Self>) {
    routeDetector.isRouteDetectionEnabled = true
    uiView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    uiView.setContentHuggingPriority(.defaultHigh, for: .vertical)
}*/
/*
in the private implementation of UIViewRepresentable that we cannot see
6:11
UIViewRepresentable bridges the SwiftUI layout system into auto layout, and back again, for us
6:12
you just needs make your UIView implement auto layout correctly for it to work
     */
     
    func updateUIView(_ uiView: ImageScrollView, context: Context) {
        print("TiledImageView: updateUIView")
    }
}

#if DEBUG
private let defaultName = "Coffee"

struct DetailView_Previews: PreviewProvider {
    static var previews: some View {
        DetailView(kvp: (key: defaultName, url: ImageProvider.fileURL(name: defaultName)))
    }
}
#endif
