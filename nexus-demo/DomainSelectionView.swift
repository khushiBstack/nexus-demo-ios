import SwiftUI

struct DomainTile: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let systemImage: String
    let gradient: [Color]
}

struct DomainSelectionView: View {
    private let tiles: [DomainTile] = [
        DomainTile(title: "E-commerce", subtitle: "Shop, scan & checkout", systemImage: "bag.fill", gradient: [.orange, .purple]),
        DomainTile(title: "Healthcare", subtitle: "Care, records & nearby", systemImage: "cross.case.fill", gradient: [.teal, .blue]),
        DomainTile(title: "BFSI", subtitle: "Banking & transfers", systemImage: "building.columns.fill", gradient: [.indigo, .blue]),
        DomainTile(title: "Travel", subtitle: "Flights, stays & keys", systemImage: "airplane", gradient: [.pink, .purple])
    ]

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var hSize

    private var isRegular: Bool { hSize == .regular }

    var body: some View {
        ZStack {
            // Rich dark background
            if colorScheme == .dark {
                LinearGradient(
                    colors: [Color(red: 0.08, green: 0.08, blue: 0.14), Color(red: 0.05, green: 0.05, blue: 0.10)],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()
            }
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.grid.2x2.fill")
                            .foregroundStyle(.indigo)
                        Text("Nexus Demo")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.indigo)
                    }
                    Text("Choose a domain")
                        .font(isRegular ? .system(size: 44, weight: .bold) : .largeTitle.bold())
                    Text("Each journey covers biometrics, camera capture, and geolocation for automated testing.")
                        .foregroundStyle(.secondary)
                        .font(isRegular ? .title3 : .subheadline)
                }
                .padding(.horizontal)
                .padding(.top, isRegular ? 32 : 16)

                // Domain grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: isRegular ? 24 : 16), count: 2), spacing: isRegular ? 24 : 16) {
                    ForEach(tiles) { tile in
                        NavigationLink {
                            destination(for: tile.title)
                        } label: {
                            DomainTileCard(tile: tile, isLarge: isRegular)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)

                // Standalone demo
                NavigationLink {
                    StandaloneDemoView().readableWidth()
                } label: {
                    StandaloneTileCard(isLarge: isRegular)
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
            }
            .padding(.bottom, 24)
            .frame(maxWidth: isRegular ? 1000 : .infinity)
            .frame(maxWidth: .infinity)
        .navigationTitle("Nexus Demo")
        .navigationBarTitleDisplayMode(.inline)
        } // end ScrollView
        } // end ZStack
    }

    @ViewBuilder
    private func destination(for title: String) -> some View {
        switch title {
        case "E-commerce": ECommerceRootView().readableWidth()
        case "Healthcare": HealthcareRootView().readableWidth()
        case "BFSI":       BFSIEntryView().readableWidth()
        case "Travel":     TravelRootView().readableWidth()
        default:           EmptyView()
        }
    }
}

struct DomainTileCard: View {
    let tile: DomainTile
    var isLarge: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: isLarge ? 80 : 40) {
            ZStack {
                RoundedRectangle(cornerRadius: isLarge ? 16 : 10)
                    .fill(.white.opacity(0.25))
                    .frame(width: isLarge ? 72 : 44, height: isLarge ? 72 : 44)
                Image(systemName: tile.systemImage)
                    .font(isLarge ? .largeTitle : .title2)
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: isLarge ? 6 : 2) {
                Text(tile.title)
                    .font(isLarge ? .title.bold() : .title3.bold())
                    .foregroundStyle(.white)
                Text(tile.subtitle)
                    .font(isLarge ? .title3 : .subheadline)
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
        .padding(isLarge ? 28 : 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: isLarge ? 340 : 190)
        .background(
            LinearGradient(colors: tile.gradient, startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 20)
        )
    }
}

struct StandaloneTileCard: View {
    var isLarge: Bool = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Standalone demo")
                    .font(isLarge ? .title.bold() : .title3.bold())
                    .foregroundStyle(.white)
                Text("Test features without the full flow")
                    .font(isLarge ? .title3 : .subheadline)
                    .foregroundStyle(.white.opacity(0.85))
            }
            Spacer()
            Image(systemName: "play.circle.fill")
                .font(isLarge ? .system(size: 48) : .title)
                .foregroundStyle(.white)
        }
        .padding(isLarge ? 28 : 16)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(colors: [.indigo, .purple], startPoint: .leading, endPoint: .trailing),
            in: RoundedRectangle(cornerRadius: 20)
        )
    }
}

#Preview {
    NavigationStack {
        DomainSelectionView()
    }
}
