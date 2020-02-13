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
    @State private var showingDetail = false

    let kvp: KVP

    init(kvp: KVP) {
        self.kvp = kvp
        imageProvider = ImageProvider(kvp: kvp)
    }

    var body: some View {

        VStack {
            if imageProvider.imageResult.name == "" {
                Text("Detail view content goes here")
            } else {
                ImageView(imageProvider: self.imageProvider)
                    .padding()
                    .onAppear { print("onAppear:", self.imageProvider.imageResult.name); self.imageProvider.fetch() }
            }
        }
            .navigationBarTitle(Text(imageProvider.imageResult.name), displayMode: .inline)
            .navigationBarItems(
                //leading: Text("Howdie"),
                trailing: Button(
                    action: {
print("WTF!")
                        self.showingDetail.toggle()
                        //withAnimation { self.dates.insert(Date(), at: 0) }
                    }
                ) {
                    Image(systemName: "plus")
                }
                .sheet(isPresented: $showingDetail, onDismiss: { print("DISMISSED") }, content: {
                    SnapShotView(image: self.imageProvider.currentImage)
                        .padding()
                })
            )
    }
}

/*
                Text("\(kvp.key)")
//                .onAppear {
//                    withAnimation(Animation.easeInOut(duration: 2.0)) {
//                        //self.animate = true
//                    }
//                }
            } else {
 */
 /*
 struct MySheet: View {
    @Environment (\.presentationMode) var presentationMode

    var body: some View {
        VStack(spacing: 20) {
            Text("Drag down to dismiss..., or")
            Text("Tap to Dismiss")
                .onTapGesture {
                    // Dismissing programmatically, instead of using the gesture,
                    // will not trigger the onDismiss callback
                    // If you need to perform a task on dismissal, do it here.
                    self.presentationMode.wrappedValue.dismiss()
            }

        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.green)
        .edgesIgnoringSafeArea(.all)
    }
}
*/
private struct SnapShotView: View {
    @Environment (\.presentationMode) var presentationMode
    let image: UIImage

//init(image: UIImage) {
//    print("IMAGE SIZE:", image.size)
//    self.image = image
//}
    var body: some View {
        VStack {
            HStack {
                Button(
                    action: {
                        self.presentationMode.wrappedValue.dismiss()
                        //self.showingDetail.toggle()
                        //withAnimation { self.dates.insert(Date(), at: 0) }
                    }
                ) {
                    //Image(systemName: "plus")
                    Text("Done")
                }
                Spacer()
                Text("Goopie").fontWeight(.bold)
                Spacer()
                Button(
                    action: {
                        print("HOWDIE")
                        //self.showingDetail.toggle()
                        //withAnimation { self.dates.insert(Date(), at: 0) }
                    }
                ) {
                    Image(systemName: "plus")
                }
            }
            .padding()
            .background(Color.white)
            //.layoutPriority(1)
            Spacer()
            Image(uiImage: image)
                .resizable()
                //.resizable(capInsets: EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10), resizingMode: .tile) // don't see it with stretch
                .aspectRatio(contentMode: .fit)
                .border(Color.gray, width: 3)
                // .frame(width: 200.0, height: 200.0)
//            .padding()
//            .background(Color.red)
//            .layoutPriority(0)
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.green)
        .edgesIgnoringSafeArea(.all)
    }
}

private struct ImageView: View {
    @ObservedObject var imageProvider: ImageProvider
    @State private var isAnimating = true

    var body: some View {
        Group {
            if imageProvider.imageResult.isSuccess() {
                    TiledImageView(imageProvider: self.imageProvider)
                        //.frame(width: 320, height: 320, alignment: .center)
            } else {
                ActivityIndicator(isAnimating: $isAnimating, style: .large)
                //Text("\(imageResult.name) failed \(imageResult.errorMsg())")
            }
        }
    }
}

private struct ActivityIndicator: UIViewRepresentable {
    @Binding var isAnimating: Bool
    let style: UIActivityIndicatorView.Style

    func makeUIView(context: UIViewRepresentableContext<ActivityIndicator>) -> UIActivityIndicatorView {
        return UIActivityIndicatorView(style: style)
    }

    func updateUIView(_ uiView: UIActivityIndicatorView, context: UIViewRepresentableContext<ActivityIndicator>) {
        isAnimating ? uiView.startAnimating() : uiView.stopAnimating()
    }
}

private struct TiledImageView: UIViewRepresentable {
    @ObservedObject var imageProvider: ImageProvider

    func makeUIView(context: Context) -> ImageScrollView {
ImageScrollView.annotateTiles = true
        let retView = ImageScrollView()
        retView.display(self.imageProvider.imageResult.tilingView())
        imageProvider.scrollView = retView
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
        //print("TiledImageView: updateUIView")
    }

//    static func dismantleUIView(_ uiView: Self.UIViewType, coordinator: Self.Coordinator) {
//    }
}

#if DEBUG
private let defaultName = "Coffee"

struct DetailView_Previews: PreviewProvider {
    static var previews: some View {
NavigationView {
        DetailView(kvp: (key: defaultName, url: ImageProvider.fileURL(name: defaultName)))
        .padding()
}
.navigationViewStyle(StackNavigationViewStyle())
.padding([.top], 50)
    }
}

struct SnapShotView_Previews: PreviewProvider {
    static var previews: some View {
        SnapShotView(image: UIImage(named: "err_image.jpg")!)
        .padding(50)
    }
}

#endif
