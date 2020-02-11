//
//  ContentMaster.swift
//  PhotoScrollerNetworkTest
//
//  Created by David Hoerl on 1/21/20.
//  Copyright © 2020 Self. All rights reserved.
//

import Foundation
import SwiftUI

private let dateFormatter: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .medium
    dateFormatter.timeStyle = .medium
    return dateFormatter
}()

//struct ImageModel: Identifiable {
//    let id: String
//    let url: URL
//    init(_ name: String, _ url: URL) {
//        self.id = name
//        self.url = url
//    }
//    var name: String { return id }
//}

typealias Resource = KeyValuePairs<String, String>
typealias ResourcePair = (key: String, url: String)

private let localFiles: KeyValuePairs<String, String> = [
    "Coffee": "Coffee",
    "Lake": "Lake",
    "Leaves": "Leaves",
    "Shed": "Shed",
    "Tree": "Tree",
    "Space4": "Space4",
    "Space5": "Space5",
    "Space6": "Space6",
]

private let remoteFiles: KeyValuePairs<String, String> = [
    "Coffee": "https://www.dropbox.com/s/7ektz3t4i6yefod/Coffee.jpg?dl=1",
    "Lake": "https://www.dropbox.com/s/b337y2sn1597sry/Lake.jpg?dl=1",
    "Leaves": "https://www.dropbox.com/s/xv4ftt95ud937w4/large_leaves_70mp.jpg?dl=1",
    "Shed": "https://www.dropbox.com/s/wq5ed0z4cwgu8xc/Shed.jpg?dl=1",
    "Tree": "https://www.dropbox.com/s/r1vf3irfero2f04/Tree.jpg?dl=1",
    "Space4": "https://www.dropbox.com/s/sbda3z1r0komm7g/Space4.jpg?dl=1",
    "Space5": "https://www.dropbox.com/s/w0s5905cqkcy4ua/Space5.jpg?dl=1",
    "Space6": "https://www.dropbox.com/s/yx63i2yf8eobrgt/Space6.jpg?dl=1",
]

struct MasterView: View {
    @Binding var dates: [Date]

    var body: some View {
        MasterViewInternal(dates: $dates)
            .navigationBarTitle(
                Text("Images")
            )
//            .navigationBarItems(
//                leading: EditButton(),
//                trailing: Button(
//                    action: {
//                        //withAnimation { self.dates.insert(Date(), at: 0) }
//                    }
//                ) {
//                    Image(systemName: "plus")
//                }
//            )
    }
}

/*
 Text("123").font(.largeTitle)
 Text("123").font(.title)
 Text("123").font(.headline)
 Text("123").font(.subheadline)
 Text("123").font(.body)
 Text("123").font(.callout)
 Text("123").font(.footnote)
 Text("123").font(.caption)
 */

struct MasterViewInternal: View {
    @Binding var dates: [Date]


    var body: some View {
        List {
            Section(header: Text("File Based").font(.largeTitle)) { // font works!!!
                ForEach(localFiles, id: \.key) { pair in
                    NavigationLink(
                        destination: DetailView(kvp: (pair.key, ImageProvider.fileURL(name: pair.value)))
                    ) {
                        Text("\(pair.key)")
                    }
                }
            }
            Section(header: Text("Internet Based").font(.largeTitle)) { // font works!!!
                ForEach(remoteFiles, id: \.key) { pair in
                    NavigationLink(
                        destination: DetailView(kvp: (pair.key, URL(string: pair.value)!))
                    ) {
                        Text("\(pair.key)")
                    }
                }
            }
        }.listStyle(GroupedListStyle())



//            }.onDelete { indices in
//                indices.forEach { self.dates.remove(at: $0) }
//            }
//        }
    }
}



struct MasterView_Previews: PreviewProvider {
    @State static private var dates: [Date] = [Date]()

    static var previews: some View {
        NavigationView {
            MasterView(dates: $dates)
        }
    }
}
