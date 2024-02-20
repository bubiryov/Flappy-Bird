//
//  ContentView.swift
//  Flappy Bird
//
//  Created by Egor Bubiryov on 15.02.2024.
//

import SwiftUI
import SpriteKit

struct ContentView: View {
    
    var scene: GameScene {
        let scene = GameScene()
        scene.size = CGSize(
            width: UIScreen.main.bounds.width,
            height: UIScreen.main.bounds.height
        )
        scene.scaleMode = .aspectFill
        return scene
    }
    
    var body: some View {
        SpriteView(scene: scene)
            .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}
