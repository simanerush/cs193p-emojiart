//
//  EmojiArtApp.swift
//  EmojiArt
//
//  Created by Serafima Nerush on 1/7/22.
//

import SwiftUI

@main
struct EmojiArtApp: App {
    let document = EmojiArtDocument()
    
    var body: some Scene {
        WindowGroup {
            EmojiArtDocumentView(document: document)
        }
    }
}
