//
//  PaletteEditor.swift
//  EmojiArt
//
//  Created by Serafima Nerush on 1/12/22.
//

import SwiftUI

struct PaletteEditor: View {
    // Editing the palette using the source of truth
    @Binding private var palette: Palette
    
    var body: some View {
        Form {
            TextField("Name", text: $palette.name)
        }
        .frame(minWidth: 300, minHeight: 350)
    }
}

struct PaletteEditor_Previews: PreviewProvider {
    static var previews: some View {
        PaletteEditor()
            .previewLayout(.fixed(width: /*@START_MENU_TOKEN@*/300.0/*@END_MENU_TOKEN@*/, height: /*@START_MENU_TOKEN@*/350.0/*@END_MENU_TOKEN@*/))
    }
}
