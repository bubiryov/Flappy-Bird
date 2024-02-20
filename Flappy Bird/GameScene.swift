//
//  GameScene.swift
//  Flappy Bird
//
//  Created by Egor Bubiryov on 15.02.2024.
//

import Foundation
import SpriteKit

class GameScene: SKScene {
    
    var background: SKSpriteNode!
    var ground: SKSpriteNode!
    var bird: SKSpriteNode!
    var introMessage: SKSpriteNode!
    var digitLabel: SKSpriteNode!
    var topBoundary: SKSpriteNode!
        
    var score: Int = 0 {
        didSet { updateDigitLabel() }
    }
    
    var isDead: Bool = false
    var gameIsStarted: Bool = false
    
    var cameraNode: SKCameraNode = .init()
    var cameraMovePointPerSecond: CGFloat = 180.0
    var lastUpdateTime: TimeInterval = 0.0
    var dt: TimeInterval = 0.0
    
    var cameraRect: CGRect {
        let x = cameraNode.position.x - size.width/2.0
        let y = cameraNode.position.y - size.height/2.0
        
        return CGRect(x: x, y: y, width: size.width, height: size.height)
    }
        
    override func didMove(to view: SKView) {
        physicsWorld.contactDelegate = self
        setupNodes()
    }
}

// MARK: - Game loop

extension GameScene {
    override func update(_ currentTime: TimeInterval) {
        if !isDead {
            if lastUpdateTime > 0 {
                dt = currentTime - lastUpdateTime
            } else {
                dt = 0
            }
            
            lastUpdateTime = currentTime
            moveCamera()
        }
    }
}

//  MARK: - Screen touch

extension GameScene {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        let jump: () -> Void = { [weak self] in
            self?.makeSound(name: .wing)
            self?.bird.physicsBody?.velocity = CGVectorMake(0, 0)
            self?.bird.physicsBody?.applyImpulse(CGVectorMake(0, 45))
        }
        
        let startTheGame: () -> Void = { [weak self] in
            self?.gameIsStarted = true
            self?.digitLabel.alpha = 1
            self?.spawnObstacles()
            self?.introMessage.removeFromParent()
            self?.bird.physicsBody?.affectedByGravity = true
            self?.bird.physicsBody?.isDynamic = true
            jump()
        }
        
        let resetTheGame: () -> Void = { [weak self] in
            self?.makeSound(name: .swooshing)
            self?.removeAllChildren()
            self?.score = 0
            self?.isDead = false
            self?.gameIsStarted = false
            self?.setupNodes()
        }
        
        switch (gameIsStarted, isDead) {
        case (false, _): startTheGame()
        case (true, false): jump()
        case (true, true): resetTheGame()
        }
    }
}

// MARK: - Elements

extension GameScene {
    
    func setupNodes() {
        createTopBoundary()
        createBackground()
        createGround()
        createBird()
        createDigitLabel()
        createIntroMessage()
        setupCamera()
    }
    
// MARK: Top boundary
    
    func createTopBoundary() {
        topBoundary = SKSpriteNode(color: .clear, size: CGSize(width: size.width, height: 1))
        topBoundary.position = CGPoint(x: frame.midX, y: cameraRect.maxY)
        topBoundary.physicsBody = SKPhysicsBody(rectangleOf: topBoundary.size)
        topBoundary.physicsBody?.isDynamic = false
        topBoundary.physicsBody!.affectedByGravity = false
        topBoundary.physicsBody?.categoryBitMask = ObjectBitMask.obstacle
        addChild(topBoundary)
    }
    
// MARK: Background

    func createBackground() {
        background = SKSpriteNode(imageNamed: "FB_BG")
        background.name = "Background"
        background.anchorPoint = .zero
        background.size = size
        background.zPosition = -1.0
        addChild(background)
    }
    
// MARK: Ground

    func createGround() {
        for i in 0...2 {
            ground = SKSpriteNode(imageNamed: "FB_Ground")
            ground.name = "Ground"
            ground.zPosition = 1.0
            ground.size.height = frame.width / 3.5
            ground.position = CGPoint(
                x: CGFloat(i) * ground.size.width,
                y: ground.size.height / 2)
            ground.physicsBody = SKPhysicsBody(rectangleOf: ground.size)
            ground.physicsBody!.categoryBitMask = ObjectBitMask.obstacle
            ground.physicsBody!.affectedByGravity = false
            ground.physicsBody!.isDynamic = false
            ground.physicsBody?.restitution = 0.0
            
            addChild(ground)
        }
    }
    
// MARK: Bird
    
    func createBird() {
        bird = SKSpriteNode(imageNamed: "bird-1")
        bird.name = "Bird"
        bird.zPosition = 5.0
        bird.position = CGPoint(
            x: frame.width / 2 - 70,
            y: frame.height / 2)
        let aspectRatio = bird.size.width / bird.size.height
        bird.size = CGSize(width: 40 * aspectRatio, height: 40)
        
        bird.physicsBody = SKPhysicsBody(rectangleOf: bird.size)
        bird.physicsBody!.categoryBitMask = ObjectBitMask.bird
        bird.physicsBody!.contactTestBitMask = ObjectBitMask.obstacle | ObjectBitMask.scoreLine
        bird.physicsBody!.collisionBitMask = ObjectBitMask.obstacle
        
        bird.physicsBody!.affectedByGravity = false
        bird.physicsBody!.isDynamic = false
        bird.physicsBody!.allowsRotation = false
        bird.physicsBody!.restitution = 0.0
        
        addChild(bird)
        
        animateBird()
    }
    
    func animateBird() {
        var textures: [SKTexture] = []
        for i in 1...3 {
            if i != 1 {
                textures.append(SKTexture(imageNamed: "bird-1"))
                textures.append(SKTexture(imageNamed: "bird-\(i)"))
            }
        }
        
        let animationAction = SKAction.repeatForever(SKAction.animate(with: textures, timePerFrame: 0.085))
        bird.run(animationAction, withKey: "birdAnimation")
    }
            
// MARK: Score label

    func createDigitLabel() {
        digitLabel = .init()
        digitLabel.alpha = 0
        addChild(digitLabel)
        digitLabel.position = CGPoint(x: frame.width / 2, y: frame.maxY - 100)
        digitLabel.zPosition = 10
        updateDigitLabel()
    }
    
    func updateDigitLabel() {
        digitLabel.removeAllChildren()
        
        let digitString = String(score)
        var totalWidth: CGFloat = 0.0
        
        for digitChar in digitString {
            let digitTexture = SKTexture(imageNamed: String(digitChar))
            totalWidth += digitTexture.size().width * 0.5
        }
        
        var offsetX: CGFloat = -totalWidth / 2.0
        
        for digitChar in digitString {
            let digitTexture = SKTexture(imageNamed: String(digitChar))
            let digitNode = SKSpriteNode(texture: digitTexture)
            digitNode.setScale(0.5)
            digitNode.position = CGPoint(x: offsetX + digitNode.frame.width / 2, y: 0)
            digitLabel.addChild(digitNode)
            offsetX += digitNode.frame.width
        }
    }
    
// MARK: Intro message
        
    func createIntroMessage() {
        introMessage = .init(imageNamed: "message")
        introMessage.name = "Intro"
        let ratio = introMessage.size.height / introMessage.size.width
        let width = frame.width * 0.7
        let height = width * ratio
        introMessage.size = CGSize(width: width, height: height)
        introMessage.zPosition = 20
        introMessage.position = CGPoint(x: frame.midX, y: frame.maxY - 100)
        introMessage.anchorPoint = CGPoint(x: 0.5, y: 1)
        addChild(introMessage)
    }
        
// MARK: Game over message
    
    func createGameOverMessage() {
        let gameoverMessage: SKSpriteNode = .init(imageNamed: "gameover")
        gameoverMessage.name = "Gameover"
        gameoverMessage.setScale(0.5)
        gameoverMessage.zPosition = 20
        gameoverMessage.position = CGPoint(x: background.frame.midX, y: background.frame.midY)
        addChild(gameoverMessage)
    }
 }

// MARK: - Obstacles

extension GameScene {
    
    func createObstacle() {
                           
        let obstacle = SKNode()
        let topPipe: SKSpriteNode = .init(imageNamed: "pipe green")
        let bottomPipe: SKSpriteNode = .init(imageNamed: "pipe green")

        let randomY = getRandomObstacleYPosition(topPipe: topPipe, bottomPipe: bottomPipe)

        topPipe.position = CGPoint(x: cameraRect.maxX + topPipe.frame.width / 2, y: randomY)
        bottomPipe.position = CGPoint(x: topPipe.position.x, y: topPipe.position.y - 170)

        topPipe.zRotation = .pi
            
        setupPipe(for: topPipe, name: "TopObstacle")
        setupPipe(for: bottomPipe, name: "BottomObstacle")
        
        let scoreLine = createScoreLine(xPosition: topPipe.frame.midX, randomY: randomY)
                
        obstacle.name = "Obstacle"
        obstacle.addChild(topPipe)
        obstacle.addChild(bottomPipe)
        obstacle.addChild(scoreLine)
        addChild(obstacle)
        
        removeObstacle(obstacle)
    }
    
    func removeObstacle(_ pair: SKNode) {
        pair.run(.sequence([
            .wait(forDuration: 3),
            .run { [weak self] in
                if !(self?.isDead ?? false) {
                    pair.removeFromParent()
                }
            }
        ]), withKey: "obstacleSequence")
    }
    
    func spawnObstacles() {
        run(.repeatForever(.sequence([
            .wait(forDuration: 1.5),
            .run { [weak self] in
                self?.createObstacle()
            }
        ])))
    }
    
    func getRandomObstacleYPosition(topPipe: SKSpriteNode, bottomPipe: SKSpriteNode) -> CGFloat {
        let topPipeMinY = max(
            frame.height - topPipe.size.height,
            frame.minY + ground.size.height + 170 + topPipe.size.height * 0.1
        )
        
        let topObstacleMaxY = min(
            bottomPipe.size.height + ground.size.height + 170,
            frame.height * 0.9
        )
        
        return CGFloat.random(in: topPipeMinY...topObstacleMaxY)
    }
    
//  MARK: Pipe
    
    func setupPipe(for pipe: SKSpriteNode, name: String) {
        pipe.setScale(0.5)
        pipe.anchorPoint = CGPoint(x: 0.5, y: 1.0)
        
        pipe.physicsBody = SKPhysicsBody(
            rectangleOf: pipe.size,
            center: CGPoint(x: 0, y: -pipe.size.height / 2)
        )
        pipe.name = name
        pipe.physicsBody!.categoryBitMask = ObjectBitMask.obstacle
        pipe.physicsBody!.affectedByGravity = false
        pipe.physicsBody!.isDynamic = false
        pipe.physicsBody?.restitution = 0.0
    }
    
//  MARK: Scoreline
    
    func createScoreLine(xPosition: CGFloat, randomY: CGFloat) -> SKSpriteNode {
        let scoreLine = SKSpriteNode()
        scoreLine.size = CGSize(width: 1, height: 170)
        scoreLine.anchorPoint = CGPoint(x: 0.5, y: 1.0)
        scoreLine.position = CGPoint(x: xPosition, y: randomY)
        
        scoreLine.physicsBody = SKPhysicsBody(
            rectangleOf: scoreLine.size,
            center: CGPoint(x: 0, y: -scoreLine.size.height / 2)
        )
        scoreLine.physicsBody!.affectedByGravity = false
        scoreLine.physicsBody!.isDynamic = false
        scoreLine.physicsBody!.restitution = 0.0
        scoreLine.physicsBody!.categoryBitMask = ObjectBitMask.scoreLine
        return scoreLine
    }
}

// MARK: - Camera

extension GameScene {
    func setupCamera() {
        addChild(cameraNode)
        camera = cameraNode
        cameraNode.position = CGPoint(x: frame.midX, y: frame.midY)
    }
    
    func moveCamera() {
        
        let amountToMove = CGPoint(x: cameraMovePointPerSecond * dt, y: 0)
        bird.position += amountToMove
        cameraNode.position += amountToMove
        digitLabel.position += amountToMove
        background.position += amountToMove
        introMessage.position += amountToMove
        topBoundary.position += amountToMove
        
        enumerateChildNodes(withName: "Ground") { [weak self] (node, _) in
            guard let self, let node = node as? SKSpriteNode else { return }
            
            if node.position.x + node.frame.width < self.cameraRect.minX {
                node.position = CGPoint(x: node.position.x + node.frame.width * 2, y: node.position.y)
            }
        }
    }
}

// MARK: - Contact handling

extension GameScene: SKPhysicsContactDelegate {
    
    func didBegin(_ contact: SKPhysicsContact) {
        let bodyA = contact.bodyA
        let bodyB = contact.bodyB
        
        if (bodyA.categoryBitMask == ObjectBitMask.bird && bodyB.categoryBitMask == ObjectBitMask.scoreLine) ||
           (bodyA.categoryBitMask == ObjectBitMask.scoreLine && bodyB.categoryBitMask == ObjectBitMask.bird) {
            makeSound(name: .point)
            score += 1
        }
                
        if (bodyA.categoryBitMask == ObjectBitMask.bird && bodyB.categoryBitMask == ObjectBitMask.obstacle) ||
           (bodyA.categoryBitMask == ObjectBitMask.obstacle && bodyB.categoryBitMask == ObjectBitMask.bird) {
            handleCollision()
        }
    }
    
    private func handleCollision() {
        removeAllActions()
        if !isDead {
            let hitSound = SKAction.playSoundFileNamed("sfx_hit", waitForCompletion: true)
            let dieSound = SKAction.playSoundFileNamed("sfx_die", waitForCompletion: false)
            run(SKAction.sequence([hitSound, dieSound]))
        }
        
        if let pair = view?.scene?.children.first(where: { $0.name == "Obstacle" }) {
            if let bottomObstacle = pair.children.first(where: { $0.name == "BottomObstacle" }) {
                bottomObstacle.physicsBody = nil
            }
        }
        bird.removeAction(forKey: "birdAnimation")
        isDead = true
        createGameOverMessage()
    }
}

// MARK: - Sounds

extension GameScene {
    private func makeSound(name: SoundEffect, waitForCompletion: Bool = false) {
        let sound = SKAction.playSoundFileNamed(name.rawValue, waitForCompletion: waitForCompletion)
        run(sound)
    }
}
