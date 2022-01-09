//
//  EmojiArtDocument.swift
//  EmojiArt
//
//  Created by Serafima Nerush on 1/7/22.
//

import SwiftUI

class EmojiArtDocument: ObservableObject {
    
    @Published private(set) var emojiArt: EmojiArtModel {
        // If anything in a model changes, didSet gets called
        didSet {
            if emojiArt.background != oldValue.background {
                fetchBackgroundImageDataIfNecessary()
            }
        }
    }
    
    init() {
        emojiArt = EmojiArtModel()
        emojiArt.addEmoji("🪴", at: (-200, -100), size: 80)
        emojiArt.addEmoji("📟", at: (50, 100), size: 40)
    }
    
    var emojis: [EmojiArtModel.Emoji] { emojiArt.emojis }
    var background: EmojiArtModel.Background { emojiArt.background }
    
    //When background in a Model changes, we have to set this property
    @Published var backgroundImage: UIImage?
    @Published var backgroundImageFetchStatus = BackgroundImageFetchStatus.idle
    
    enum BackgroundImageFetchStatus {
        case idle
        case fetching
    }
    
    private func fetchBackgroundImageDataIfNecessary() {
        backgroundImage = nil
        switch emojiArt.background {
        case .url(let url):
            // Fetch the url
            // Goes to internet and fetches it, blocking the main thread
            // Make the code multithreaded
            backgroundImageFetchStatus = .fetching
            DispatchQueue.global(qos: .userInitiated).async {
                let imageData = try? Data(contentsOf: url)
                // When it gets the result, the UI changes happen in the main thread
                DispatchQueue.main.async { [weak self] in // Weak doesn't force self to keep itself in the heap. If no one else keeps the self, it is going to be nil.
                    // If the mage that was jsut loaded matches the current desired image
                    if self?.emojiArt.background == EmojiArtModel.Background.url(url) {
                        self?.backgroundImageFetchStatus = .idle
                        if imageData != nil {
                            self?.backgroundImage = UIImage(data: imageData!)
                        }
                    }
                }
            }
        case .imageData(let data):
            backgroundImage = UIImage(data: data)
        case .blank:
            break
        }
    }
    
    // MARK: - Intent(s)
    
    func setBackground(_ background: EmojiArtModel.Background) {
        emojiArt.background = background
        print("background set to \(background)")
    }
    
    func addEmoji(_ emoji: String, at location: (x: Int, y: Int), size: CGFloat) {
        emojiArt.addEmoji(emoji, at: location, size: Int(size))
    }
    
    func moveEmoji(_ emoji: EmojiArtModel.Emoji, by offset: CGSize) {
        if let index = emojiArt.emojis.index(matching: emoji) {
            emojiArt.emojis[index].x += Int(offset.width)
            emojiArt.emojis[index].y += Int(offset.height)
        }
    }
    
    func scaleEmoji(_ emoji: EmojiArtModel.Emoji, by scale: CGFloat) {
        if let index = emojiArt.emojis.index(matching: emoji) {
            emojiArt.emojis[index].size = Int((CGFloat(emojiArt.emojis[index].size) * scale).rounded(.toNearestOrAwayFromZero))
        }
    }
}

