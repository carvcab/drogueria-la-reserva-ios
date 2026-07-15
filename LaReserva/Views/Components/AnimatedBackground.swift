import SwiftUI

struct FloatingParticle: Identifiable {
    let id = UUID()
    var x: Double
    var y: Double
    let size: CGFloat
    let speed: Double
    let wobbleFreq: Double
    let wobbleAmp: Double
    let colorIndex: Int
}

struct AnimatedBackground<Content: View>: View {
    let showParticles: Bool
    let content: Content

    init(showParticles: Bool = true, @ViewBuilder content: () -> Content) {
        self.showParticles = showParticles
        self.content = content()
    }

    // Gradient groups (matching Flutter exactly!)
    private let gradients: [[Color]] = [
        [Color(hex: "FFDBE4"), Color(hex: "DBEAFE"), Color(hex: "E0D4FC")],
        [Color(hex: "D4FCE0"), Color(hex: "FCE8D4"), Color(hex: "F0E6FF")],
        [Color(hex: "DBEAFE"), Color(hex: "E0D4FC"), Color(hex: "D1FAE5")],
        [Color(hex: "FFE4E6"), Color(hex: "DBEAFE"), Color(hex: "FEF9C3")],
        [Color(hex: "E0D4FC"), Color(hex: "FCE8D4"), Color(hex: "D4FCE0")]
    ]

    @State private var gradientIndex = 0
    @State private var animateBegin = UnitPoint.topLeading
    @State private var animateEnd = UnitPoint.bottomTrailing

    // Particles state
    @State private var particles: [FloatingParticle] = []

    var body: some View {
        ZStack {
            // Animated Gradient background
            LinearGradient(
                colors: gradients[gradientIndex],
                startPoint: animateBegin,
                endPoint: animateEnd
            )
            .ignoresSafeArea()
            .onAppear {
                withAnimation(.easeInOut(duration: 8.0).repeatForever(autoreverses: true)) {
                    gradientIndex = (gradientIndex + 1) % gradients.count
                }
                
                withAnimation(.linear(duration: 15.0).repeatForever(autoreverses: false)) {
                    animateBegin = .bottomTrailing
                    animateEnd = .topLeading
                }
                
                if particles.isEmpty {
                    particles = (0..<12).map { _ in
                        FloatingParticle(
                            x: Double.random(in: 0...1),
                            y: Double.random(in: 0...1),
                            size: CGFloat.random(in: 15...45),
                            speed: Double.random(in: 0.015...0.03),
                            wobbleFreq: Double.random(in: 1...3),
                            wobbleAmp: Double.random(in: 0.02...0.05),
                            colorIndex: Int.random(in: 0...4)
                        )
                    }
                }
            }
            .onChange(of: gradientIndex) { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) {
                    withAnimation(.easeInOut(duration: 8.0)) {
                        gradientIndex = (gradientIndex + 1) % gradients.count
                    }
                }
            }

            // Floating Particles Layer
            if showParticles {
                TimelineView(.animation) { timeline in
                    let time = timeline.date.timeIntervalSinceReferenceDate
                    
                    Canvas { context, size in
                        let particleColors: [Color] = [
                            Color(hex: "FFE4E1").opacity(0.35),
                            Color(hex: "DBEAFE").opacity(0.35),
                            Color(hex: "E0D4FC").opacity(0.35),
                            Color(hex: "D4FCE0").opacity(0.35),
                            Color(hex: "FEF9C3").opacity(0.35)
                        ]
                        
                        for p in particles {
                            let yProgress = (p.y - (time * p.speed)).truncatingRemainder(dividingBy: 1.0)
                            let currentY = yProgress < 0 ? yProgress + 1.0 : yProgress
                            
                            let wobble = sin(time * p.wobbleFreq) * p.wobbleAmp
                            let xProgress = (p.x + wobble).truncatingRemainder(dividingBy: 1.0)
                            let currentX = xProgress < 0 ? xProgress + 1.0 : xProgress
                            
                            let alpha: Double
                            if currentY < 0.2 {
                                alpha = currentY / 0.2
                            } else if currentY > 0.8 {
                                alpha = (1.0 - currentY) / 0.2
                            } else {
                                alpha = 1.0
                            }
                            
                            let rect = CGRect(
                                x: currentX * size.width - p.size/2,
                                y: currentY * size.height - p.size/2,
                                width: p.size,
                                height: p.size
                            )
                            
                            context.opacity = alpha
                            context.fill(Path(ellipseIn: rect), with: .color(particleColors[p.colorIndex]))
                        }
                    }
                    .blur(radius: 12)
                    .ignoresSafeArea()
                }
            }

            // Content
            content
        }
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct PulseDotView: View {
    let color: Color
    @State private var isPulsing = false

    var body: some View {
        Circle()
            .fill(color)
            .scaleEffect(isPulsing ? 1.3 : 0.85)
            .opacity(isPulsing ? 0.4 : 1.0)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
    }
}
