//
//  EmojiArtDocumentView.swift
//  EmojiArt
//
//  Created by Serafima Nerush on 1/7/22.
//

import SwiftUI

struct EmojiArtDocumentView: View {
    @ObservedObject var document: EmojiArtDocument
    
    @State var selectedEmojis = Set<EmojiArtModel.Emoji>()
    
    let defaultEmojiFontSize: CGFloat = 40
    
    var body: some View {
        VStack(spacing: 0) {
            documentBody
            palette
        }
    }
    
    var documentBody: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white.overlay(
                    OptionalImage(uiImage: document.backgroundImage)
                        .scaleEffect(zoomScale)
                        .position(convertFromEmojiCoordinates((0, 0), in: geometry))
                )
                    .gesture(doubleTapToZoom(in: geometry.size))
                if document.backgroundImageFetchStatus == .fetching {
                    ProgressView().scaleEffect(2)
                } else {
                    ForEach(document.emojis) { emoji in
                        if selectedEmojis.contains(emoji) {
                                Text(emoji.text)
                                    .font(.system(size: fontSize(for: emoji)))
                                    .background(Color.blue.opacity(0.2))
                                    .frame(width: 100, height: 10)
                                    .scaleEffect(zoomScale)
                                    .position(position(for: emoji, in: geometry))
                                    
                        } else {
                            Text(emoji.text)
                                .font(.system(size: fontSize(for: emoji)))
                                .scaleEffect(zoomScale)
                                .position(position(for: emoji, in: geometry))
                        }
                    }
                }
            }
            // Don't take the palette space
            .clipped()
            .onDrop(of: [.plainText, .url, .image], isTargeted: nil) { providers, location in
                drop(providers: providers, at: location, in: geometry)
            }
            // You shouldn't put two gestures
            .gesture(panGesture().simultaneously(with: zoomGesture()).exclusively(before: tapToSelectEmoji(in: geometry)))
            //.gesture(tapToSelectEmoji(in: geometry))
        }
        
    }
    
    private func drop(providers: [NSItemProvider], at location: CGPoint, in geometry: GeometryProxy) -> Bool {
        var found = providers.loadObjects(ofType: URL.self) { url in
            document.setBackground(EmojiArtModel.Background.url(url.imageURL))
        }
        if !found {
            found = providers.loadObjects(ofType: UIImage.self) { image in
                if let data = image.jpegData(compressionQuality: 1.0) {
                    document.setBackground(.imageData(data))
                }
                
            }
        }
        if !found {
            found =  providers.loadObjects(ofType: String.self) { string in
                if let emoji = string.first, emoji.isEmoji {
                    document.addEmoji(
                        String(emoji),
                        at: convertToEmojiCoordinates(location, in: geometry),
                        size: defaultEmojiFontSize / zoomScale
                    )
                }
            }
        }
        return found
    }
    
    private func position(for emoji: EmojiArtModel.Emoji, in geometry: GeometryProxy) -> CGPoint {
        convertFromEmojiCoordinates((emoji.x, emoji.y), in: geometry)
    }
    
    private func convertToEmojiCoordinates( _ location: CGPoint, in geometry: GeometryProxy) -> (x: Int, y: Int) {
        let center = geometry.frame(in: .local).center
        let location = CGPoint(
            x: (location.x - panOffset.width - center.x) / zoomScale,
            y: (location.y -  panOffset.height - center.y) / zoomScale
        )
        return (Int(location.x), Int(location.y))
    }
    
    private func convertFromEmojiCoordinates(_ location: (x: Int, y: Int), in geometry: GeometryProxy) -> CGPoint {
        let center = geometry.frame(in: .local).center
        return CGPoint(
            x: center.x + CGFloat(location.x) * zoomScale + panOffset.width,
            y: center.y + CGFloat(location.y) * zoomScale + panOffset.height
        )
    }
    
    private func fontSize(for emoji: EmojiArtModel.Emoji) -> CGFloat {
        CGFloat(emoji.size)
    }
    
    @State private var steadyStatePanOffset: CGSize = CGSize.zero
    @GestureState private var gesturePanOffset: CGSize = CGSize.zero
    
    private var panOffset: CGSize {
        (steadyStatePanOffset + gesturePanOffset) * zoomScale
    }
    
    private func panGesture() -> some Gesture {
        DragGesture()
            .updating($gesturePanOffset) { latestDragGestureValue, gesturePanOffset, _ in
                if selectedEmojis.isEmpty {
                    gesturePanOffset = latestDragGestureValue.translation / zoomScale
                }
                
            }
            .onEnded { finalDragGestureValue in
                if selectedEmojis.isEmpty {
                    steadyStatePanOffset = steadyStatePanOffset + (finalDragGestureValue.translation / zoomScale)
                } else {
                    for emoji in selectedEmojis {
                        withAnimation {
                            document.moveEmoji(emoji, by: finalDragGestureValue.distance)
                        }
                       
                    }
                }
            }
    }
    
    @State private var steadyStateZoomScale: CGFloat = 1
    @GestureState private var gestureZoomScale: CGFloat = 1
    
    private var zoomScale: CGFloat {
        steadyStateZoomScale * gestureZoomScale
    }
    
    private func zoomGesture() -> some Gesture {
        MagnificationGesture()
            .updating($gestureZoomScale) { latestGestureScale, gestureZoomScale, _ in
                // Control the position of fingers
                gestureZoomScale = latestGestureScale
            }
            .onEnded { gestureScaleAtEnd in
                steadyStateZoomScale *= gestureScaleAtEnd
            }
    }
    
    private func doubleTapToZoom(in size: CGSize) -> some Gesture {
        TapGesture(count: 2)
            .onEnded {
                withAnimation {
                    zoomToFit(document.backgroundImage, in: size)
                }
            }
    }
    
    private func tapToSelectEmoji(in geometry: GeometryProxy) -> some Gesture {
        return DragGesture(minimumDistance: 0)
            .onEnded { value in
                selectEmoji(position: value.location, in: geometry)
            }
    }
    
    private func selectEmoji(position: CGPoint, in geometry: GeometryProxy) {
        let emojiLocation = convertToEmojiCoordinates(position, in: geometry)
        for emoji in document.emojis {
            if abs(emoji.x - Int(emojiLocation.x)) <= 20 * Int(zoomScale) && abs(emoji.y - Int(emojiLocation.y)) <= 20 * Int(zoomScale) {
                
                if selectedEmojis.contains(emoji) {
                    selectedEmojis.remove(emoji)
                    return
                } else {
                    selectedEmojis.update(with: emoji)
                    return
                }
            }
        }
        
        selectedEmojis = []
    }
    
    private func zoomToFit(_ image: UIImage?, in size: CGSize) {
        if let image = image, image.size.width > 0, image.size.height > 0, size.width > 0, size.height > 0 {
            let hZoom = size.width / image.size.width
            let vZoom = size.height / image.size.height
            steadyStatePanOffset = .zero
            steadyStateZoomScale = min(hZoom, vZoom)
        }
    }
    
    var palette: some View {
        ScrollingEmojisView(emojis: testEmojis)
            .font(.system(size: defaultEmojiFontSize))
    }
    
    let testEmojis = "🎉🚕🥂🪴🚞📲🖥🙃🎛📟💛💽☎️⏰🔌🧯🌃🌉🌁"
}

struct ScrollingEmojisView: View {
    let emojis: String
    
    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(emojis.map { String($0) }, id: \.self) { emoji in
                    Text(emoji)
                        .onDrag {
                            // NSItemProvider provides an Item to someone else asynchronously!
                            NSItemProvider(object: emoji as NSString)
                        }
                }
            }
        }
    }
}






















struct EmojiArtDocumentView_Previews: PreviewProvider {
    static var previews: some View {
        EmojiArtDocumentView(document: EmojiArtDocument())
.previewInterfaceOrientation(.landscapeLeft)
    }
}
