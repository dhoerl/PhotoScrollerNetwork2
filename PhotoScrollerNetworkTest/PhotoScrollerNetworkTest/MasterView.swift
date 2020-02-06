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
    "large_leaves_70mp": "large_leaves_70mp",
    "Shed": "Shed",
    "Tree": "Tree",
    "Space4": "Space4",
    "Space5": "Space5",
    "Space6": "Space6",
]

private let remoteFiles: KeyValuePairs<String, String> = [
    "File A": "xxx",
    "File B": "xxx",
    "File C": "xxx",
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
                        destination: DetailView(kvp: pair)
                    ) {
                        Text("\(pair.key)")
                    }
                }
            }
            Section(header: Text("Internet Based").font(.largeTitle)) { // font works!!!
                ForEach(remoteFiles, id: \.key) { pair in
                    NavigationLink(
                        destination: DetailView(kvp: pair)
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
