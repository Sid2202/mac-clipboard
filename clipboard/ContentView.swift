//
//  ContentView.swift
//  clipboard
//
//  Created by Sidhanti Patil on 04/05/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var clipboardManager: ClipboardManager
    
    var body: some View {
        VStack(alignment: .leading) {
            
            Text("Clipboard History")
                .font(.title)
                .padding(.bottom, 10)
            
            List(clipboardManager.history, id: \.self){
                item in Button(action: {
                    clipboardManager.setClipboard(item)
                    clipboardManager.simulatePaste()
                }) {
                    Text(item)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
        }
        .padding()
        .frame(width:400, height:300)
    }
}
//
//#Preview {
//    ContentView()
//}
