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

print("CALLED FOR IMAGE:", kvp.key, "URL", kvp.url.path)
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
        Group {
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
            ImageView(imageResult: $imageProvider.imageResult)
                .onAppear { self.imageProvider.fetch() }
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
    @Binding var imageResult: ImageResult

    var body: some View {
        Group {
            if imageResult.isSuccess() {
                TiledImageView(view: imageResult.tilingView())
                    .frame(width: 320, height: 320, alignment: .center)
            } else {
                Text("\(imageResult.name) failed \(imageResult.errorMsg())")
            }
        }
    }
}

struct TiledImageView: UIViewRepresentable {
    let view: TilingView

//    init(imageBuilder: TiledImageBuilder) {
//        self.imageBuilder = imageBuilder
//    }

    func makeUIView(context: Context) -> ImageScrollView {
        let retView = ImageScrollView(frame: CGRect(x: 0, y: 0, width: 320, height: 320))
        retView.display(view)
        return retView
    }

    func updateUIView(_ uiView: ImageScrollView, context: Context) {
        print("TiledImageView: updateUIView")
    }
}


//struct DetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        DetailView(selectedDate: Date())
//    }
//}

