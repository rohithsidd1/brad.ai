import SwiftUI

struct FloatingBallsBackground: View {
    @Environment(\.colorScheme) var colorScheme // Detect dark/light mode
    
    let screenSize = UIScreen.main.bounds
    let ballCount = 6
    
    @State private var positions: [CGSize] = []
    @State private var velocities: [CGSize] = []
    
    let ballSize: CGFloat = 80 // Standard ball size

    init() {
        _positions = State(initialValue: (0..<ballCount).map { _ in
            CGSize(
                width: CGFloat.random(in: 50...(UIScreen.main.bounds.width - 50)),
                height: CGFloat.random(in: 50...(UIScreen.main.bounds.height - 50))
            )
        })
        
        _velocities = State(initialValue: (0..<ballCount).map { _ in
            CGSize(
                width: CGFloat.random(in: -2...2),
                height: CGFloat.random(in: -2...2)
            )
        })
    }

    var body: some View {
        ZStack {
            ForEach(0..<ballCount, id: \.self) { index in
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.purple.opacity(0.6),
                                Color.blue.opacity(0.4)
                            ]),
                            center: .center,
                            startRadius: 30,
                            endRadius: 80
                        )
                    )
                    .frame(width: ballSize, height: ballSize)
                    .position(x: positions[index].width, y: positions[index].height)
                    .blur(radius: 60)
            }
        }
        .background(Color(.systemBackground))
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            startBallMovement()
        }
    }
    
    private func startBallMovement() {
        Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { _ in
            moveBalls()
        }
    }

    private func moveBalls() {
        var newPositions = positions
        var newVelocities = velocities
        
        for i in 0..<ballCount {
            var newX = newPositions[i].width + newVelocities[i].width
            var newY = newPositions[i].height + newVelocities[i].height

            // Collision with screen edges
            if newX - ballSize / 2 <= 0 || newX + ballSize / 2 >= screenSize.width {
                newVelocities[i].width *= -1
                newX = min(max(ballSize / 2, newX), screenSize.width - ballSize / 2)
            }
            if newY - ballSize / 2 <= 0 || newY + ballSize / 2 >= screenSize.height {
                newVelocities[i].height *= -1
                newY = min(max(ballSize / 2, newY), screenSize.height - ballSize / 2)
            }

            // Check for collisions with other balls
            for j in 0..<ballCount where i != j {
                let dx = newPositions[j].width - newX
                let dy = newPositions[j].height - newY
                let distance = sqrt(dx * dx + dy * dy)
                
                if distance < ballSize {
                    // Swap velocities to simulate bounce effect
                    let temp = newVelocities[i]
                    newVelocities[i] = newVelocities[j]
                    newVelocities[j] = temp
                }
            }
            
            newPositions[i] = CGSize(width: newX, height: newY)
        }
        
        DispatchQueue.main.async {
            positions = newPositions
            velocities = newVelocities
        }
    }
}
