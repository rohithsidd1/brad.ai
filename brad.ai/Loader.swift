import SwiftUI


// **Loading Animation View (Three Bouncing Dots)**
struct LoadingDotsView: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .frame(width: 10, height: 10)
                    .foregroundColor(.gray)
                    .scaleEffect(isAnimating ? 1.0 : 0.5)
                    .animation(Animation.easeInOut(duration: 0.6).repeatForever().delay(0.2 * Double(index)), value: isAnimating)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}
