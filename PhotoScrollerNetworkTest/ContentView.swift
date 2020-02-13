//
//  ContentView.swift
//  PhotoScrollerNetworkTest
//
//  Created by David Hoerl on 1/21/20.
//  Copyright © 2020 Self. All rights reserved.
//

import SwiftUI

struct ContentView: View {

    var body: some View {
        NavigationView {
            //MV(dates: $dates)
            MasterView()
//                .navigationBarTitle(
//                    Text("Image Management").font(.largeTitle)
//                )
            DetailView(kvp: ImageProvider.defaultKVP)
        }
        .modifier( WTF() )
    }
    // .navigationViewStyle(appEnvironment.useSideBySide ? DoubleColumnNavigationViewStyle() : StackNavigationViewStyle())

//    func navSty() -> some NavigationViewStyle {
//        if appEnvironment.useSideBySide {
//            return DoubleColumnNavigationViewStyle()
//        } else {
//            return StackNavigationViewStyle()
//        }
//    }

//struct MV: View {
//    var body: some View {
//        MasterView()
//        .navigationBarTitle(
//            Text("Image Management").font(.largeTitle)
//        )
//        .navigationBarItems(
//            leading: EditButton(),
//            trailing: Button(
//                action: {
//                    withAnimation { self.dates.insert(Date(), at: 0) }
//                }
//            ) {
//                Image(systemName: "plus")
//            }
//        )
//    }
//}

    struct WTF: ViewModifier {
        @EnvironmentObject var appEnvironment: AppEnvironment

        func body(content: Content) -> some View  {
            Group {
                if appEnvironment.useSideBySide == true {
                    content
                        .navigationViewStyle(DoubleColumnNavigationViewStyle())
                } else {
                    content
                        .navigationViewStyle(DoubleColumnNavigationViewStyle()) // StackNavigationViewStyle
                }
            }
        }
    }

}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(AppEnvironment())   // needed if we have a var in our View
    }
}

/*
horizontalSizeClass
 */
