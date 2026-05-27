import SwiftUI

struct ShelfDebugView: View {
    private let itemWidth: CGFloat = 110
    private let itemHeight: CGFloat = 160
    private let shelfHeight: CGFloat = 44

    private let shelves: [(name: String, color: String, icon: String, items: [String])] = [
        ("Action Figures", "E04030", "figure.stand", ["Darth Vader", "Spider-Man", "Optimus Prime", "Batman", "Goku"]),
        ("Books", "2080E0", "book.fill", ["Neuromancer", "Dune", "1984", "Foundation"]),
        ("Vinyl Records", "8B5CF6", "opticaldisc.fill", ["Abbey Road", "Dark Side", "Thriller"]),
        ("Board Games", "34C759", "gamecontroller.fill", ["Catan", "Wingspan", "Gloomhaven", "Azul", "Ticket to Ride", "Pandemic"]),
    ]

    private let cardGradients: [Color] = [
        .orange, .purple, .red, .blue, .green, .pink, .indigo, .mint, .teal, .cyan,
    ]

    var body: some View {
        ZStack {
            NavigationStack {
                ScrollView {
                    VStack(spacing: 0) {
                        VStack(spacing: 2) {
                            Text("Debug")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                            Text("SHELVES")
                                .font(.system(size: 38, weight: .black, design: .serif))
                                .tracking(2)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 20)
                        .padding(.bottom, 32)

                        LazyVStack(spacing: 28) {
                            ForEach(shelves, id: \.name) { shelf in
                                debugShelf(
                                    name: shelf.name,
                                    color: Color(hex: shelf.color) ?? .blue,
                                    icon: shelf.icon,
                                    items: shelf.items
                                )
                            }
                        }

                        Spacer(minLength: 40)
                    }
                }
                .background(Color(.systemBackground))
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }

    // MARK: - Shelf

    private func debugShelf(name: String, color: Color, icon: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text(name)
                    .font(.title3.weight(.semibold))

                Spacer()

                Text("\(items.count) items")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)

            ZStack(alignment: .bottom) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(Array(items.enumerated()), id: \.offset) { idx, itemName in
                            debugItemCard(
                                name: itemName,
                                icon: icon,
                                gradient: cardGradients[idx % cardGradients.count]
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, shelfHeight * 0.55)
                }

                ShelfBarView(color: color)
                    .zIndex(1)
            }
        }
    }

    // MARK: - Item Card (vibrant, like generated covers on the main page)

    private func debugItemCard(name: String, icon: String, gradient: Color) -> some View {
        ZStack {
            LinearGradient(
                colors: [gradient, gradient.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundStyle(.white.opacity(0.9))

                Text(name)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.horizontal, 6)
            }
        }
        .frame(width: itemWidth, height: itemHeight)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.12), radius: 6, x: 2, y: 4)
    }

}

#Preview {
    ShelfDebugView()
}
