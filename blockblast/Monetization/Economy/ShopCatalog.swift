import Foundation
import SwiftUI

enum ThemeCategory: String, Codable, CaseIterable {
    case block
    case grid
}

enum ThemeRarity: String, Codable, CaseIterable {
    case starter
    case premium
    case rare
    case epic
    case legendary
    case mythic

    var displayName: String {
        switch self {
        case .starter:
            return "Starter"
        case .premium:
            return "Premium"
        case .rare:
            return "Rare"
        case .epic:
            return "Epic"
        case .legendary:
            return "Legendary"
        case .mythic:
            return "Mythic"
        }
    }
}

struct ThemeDefinition: Identifiable, Hashable {
    let id: String
    let category: ThemeCategory
    let title: String
    let subtitle: String
    let priceCoins: Int
    let rarity: ThemeRarity
    let detailTags: [String]

    let accentA: Color
    let accentB: Color
    let accentC: Color

    var isFree: Bool {
        priceCoins == 0
    }
}

struct ShopCatalog {
    let blockThemes: [ThemeDefinition]
    let gridThemes: [ThemeDefinition]

    static let `default` = ShopCatalog(
        blockThemes: [
            ThemeDefinition(
                id: "theme.block.neon",
                category: .block,
                title: "Neon Core",
                subtitle: "Bright electric blocks",
                priceCoins: 0,
                rarity: .starter,
                detailTags: ["Pulse finish", "Glow outline", "Clean contrast"],
                accentA: Color(red: 0.27, green: 0.86, blue: 0.57),
                accentB: Color(red: 0.14, green: 0.58, blue: 0.98),
                accentC: Color(red: 0.61, green: 0.35, blue: 0.98)
            ),
            ThemeDefinition(
                id: "theme.block.sunset",
                category: .block,
                title: "Sunset",
                subtitle: "Warm amber and coral",
                priceCoins: 420,
                rarity: .premium,
                detailTags: ["Warm bloom", "Soft highlights", "Polished edges"],
                accentA: Color(red: 0.98, green: 0.58, blue: 0.24),
                accentB: Color(red: 0.95, green: 0.34, blue: 0.35),
                accentC: Color(red: 0.97, green: 0.77, blue: 0.28)
            ),
            ThemeDefinition(
                id: "theme.block.ice",
                category: .block,
                title: "Ice Pulse",
                subtitle: "Cool mint and frost",
                priceCoins: 560,
                rarity: .premium,
                detailTags: ["Crystal shine", "Frost gradient", "Sharp clarity"],
                accentA: Color(red: 0.39, green: 0.91, blue: 0.93),
                accentB: Color(red: 0.34, green: 0.66, blue: 1.00),
                accentC: Color(red: 0.81, green: 0.93, blue: 1.00)
            ),
            ThemeDefinition(
                id: "theme.block.jade_forge",
                category: .block,
                title: "Jade Forge",
                subtitle: "Deep green carved gemstone",
                priceCoins: 760,
                rarity: .rare,
                detailTags: ["Gem cut", "Metal trim", "Dense shadows"],
                accentA: Color(red: 0.23, green: 0.78, blue: 0.58),
                accentB: Color(red: 0.12, green: 0.50, blue: 0.40),
                accentC: Color(red: 0.72, green: 0.92, blue: 0.83)
            ),
            ThemeDefinition(
                id: "theme.block.aurora_prism",
                category: .block,
                title: "Aurora Prism",
                subtitle: "Northern light split tones",
                priceCoins: 940,
                rarity: .rare,
                detailTags: ["Iridescent wash", "Prism flare", "Night glow"],
                accentA: Color(red: 0.44, green: 0.93, blue: 0.70),
                accentB: Color(red: 0.42, green: 0.58, blue: 0.98),
                accentC: Color(red: 0.88, green: 0.62, blue: 1.00)
            ),
            ThemeDefinition(
                id: "theme.block.rose_quartz",
                category: .block,
                title: "Rose Quartz",
                subtitle: "Luxe pink crystal palette",
                priceCoins: 1_180,
                rarity: .rare,
                detailTags: ["Crystal depth", "Pearl sheen", "Soft radiance"],
                accentA: Color(red: 0.99, green: 0.66, blue: 0.79),
                accentB: Color(red: 0.92, green: 0.43, blue: 0.63),
                accentC: Color(red: 1.00, green: 0.86, blue: 0.93)
            ),
            ThemeDefinition(
                id: "theme.block.obsidian_pulse",
                category: .block,
                title: "Obsidian Pulse",
                subtitle: "Volcanic glass with ember cuts",
                priceCoins: 1_420,
                rarity: .epic,
                detailTags: ["Smoked glass", "Hot seams", "Hard contrast"],
                accentA: Color(red: 0.16, green: 0.17, blue: 0.21),
                accentB: Color(red: 0.38, green: 0.11, blue: 0.12),
                accentC: Color(red: 0.87, green: 0.32, blue: 0.24)
            ),
            ThemeDefinition(
                id: "theme.block.solar_flare",
                category: .block,
                title: "Solar Flare",
                subtitle: "Star-core yellow and plasma red",
                priceCoins: 1_680,
                rarity: .epic,
                detailTags: ["Core bloom", "Plasma edge", "Hot shimmer"],
                accentA: Color(red: 1.00, green: 0.82, blue: 0.27),
                accentB: Color(red: 1.00, green: 0.47, blue: 0.16),
                accentC: Color(red: 0.96, green: 0.19, blue: 0.14)
            ),
            ThemeDefinition(
                id: "theme.block.cobalt_storm",
                category: .block,
                title: "Cobalt Storm",
                subtitle: "Charged blue with steel highlights",
                priceCoins: 1_960,
                rarity: .epic,
                detailTags: ["Electric finish", "Steel shine", "Rainy depth"],
                accentA: Color(red: 0.24, green: 0.59, blue: 1.00),
                accentB: Color(red: 0.14, green: 0.31, blue: 0.72),
                accentC: Color(red: 0.63, green: 0.82, blue: 1.00)
            ),
            ThemeDefinition(
                id: "theme.block.royal_velvet",
                category: .block,
                title: "Royal Velvet",
                subtitle: "Rich royal tones with gold stitch",
                priceCoins: 2_280,
                rarity: .legendary,
                detailTags: ["Velvet matte", "Gold stitch", "Regal depth"],
                accentA: Color(red: 0.47, green: 0.21, blue: 0.83),
                accentB: Color(red: 0.29, green: 0.10, blue: 0.54),
                accentC: Color(red: 0.98, green: 0.77, blue: 0.29)
            ),
            ThemeDefinition(
                id: "theme.block.molten_gold",
                category: .block,
                title: "Molten Gold",
                subtitle: "Forged bullion with fiery core",
                priceCoins: 2_640,
                rarity: .legendary,
                detailTags: ["Liquid metal", "Heat fade", "Luxury glow"],
                accentA: Color(red: 0.99, green: 0.76, blue: 0.19),
                accentB: Color(red: 0.86, green: 0.49, blue: 0.06),
                accentC: Color(red: 1.00, green: 0.91, blue: 0.60)
            ),
            ThemeDefinition(
                id: "theme.block.starlight_cathedral",
                category: .block,
                title: "Starlight Cathedral",
                subtitle: "Prismatic glass and moonlit silver",
                priceCoins: 3_050,
                rarity: .legendary,
                detailTags: ["Glass facets", "Silver trim", "Moon shimmer"],
                accentA: Color(red: 0.70, green: 0.84, blue: 1.00),
                accentB: Color(red: 0.45, green: 0.56, blue: 0.87),
                accentC: Color(red: 0.93, green: 0.96, blue: 1.00)
            ),
            ThemeDefinition(
                id: "theme.block.chrono_titan",
                category: .block,
                title: "Chrono Titan",
                subtitle: "Time-forged alloy with rune glow",
                priceCoins: 3_590,
                rarity: .mythic,
                detailTags: ["Ancient alloy", "Rune pulse", "Heavy depth"],
                accentA: Color(red: 0.42, green: 0.54, blue: 0.63),
                accentB: Color(red: 0.24, green: 0.30, blue: 0.37),
                accentC: Color(red: 0.95, green: 0.79, blue: 0.44)
            ),
            ThemeDefinition(
                id: "theme.block.celestial_opera",
                category: .block,
                title: "Celestial Opera",
                subtitle: "Nebula magenta in high gloss lacquer",
                priceCoins: 4_290,
                rarity: .mythic,
                detailTags: ["Nebula bloom", "Lacquer shine", "Stage contrast"],
                accentA: Color(red: 0.95, green: 0.43, blue: 0.85),
                accentB: Color(red: 0.58, green: 0.24, blue: 0.83),
                accentC: Color(red: 0.34, green: 0.65, blue: 0.98)
            ),
            ThemeDefinition(
                id: "theme.block.void_monarch",
                category: .block,
                title: "Void Monarch",
                subtitle: "Dark crown edition with cosmic edges",
                priceCoins: 4_980,
                rarity: .mythic,
                detailTags: ["Deep-space black", "Royal edge", "Crown glint"],
                accentA: Color(red: 0.13, green: 0.12, blue: 0.21),
                accentB: Color(red: 0.29, green: 0.18, blue: 0.47),
                accentC: Color(red: 0.86, green: 0.76, blue: 1.00)
            ),
            ThemeDefinition(
                id: "theme.block.eternal_crown",
                category: .block,
                title: "Eternal Crown",
                subtitle: "Collector grade black-gold masterpiece",
                priceCoins: 6_800,
                rarity: .mythic,
                detailTags: ["Collector cut", "Black gold", "Museum polish"],
                accentA: Color(red: 0.08, green: 0.08, blue: 0.12),
                accentB: Color(red: 0.64, green: 0.47, blue: 0.12),
                accentC: Color(red: 0.94, green: 0.85, blue: 0.54)
            )
        ],
        gridThemes: [
            ThemeDefinition(
                id: "theme.grid.midnight",
                category: .grid,
                title: "Midnight",
                subtitle: "Classic dark board",
                priceCoins: 0,
                rarity: .starter,
                detailTags: ["Low glare", "Deep contrast", "Focused board"],
                accentA: Color(red: 0.05, green: 0.06, blue: 0.09),
                accentB: Color(red: 0.12, green: 0.13, blue: 0.17),
                accentC: Color(red: 0.24, green: 0.26, blue: 0.34)
            ),
            ThemeDefinition(
                id: "theme.grid.paper",
                category: .grid,
                title: "Paper Light",
                subtitle: "Soft daylight board",
                priceCoins: 380,
                rarity: .premium,
                detailTags: ["Matte texture", "Soft lines", "Reading comfort"],
                accentA: Color(red: 0.94, green: 0.95, blue: 0.98),
                accentB: Color(red: 0.84, green: 0.86, blue: 0.91),
                accentC: Color(red: 0.55, green: 0.58, blue: 0.67)
            ),
            ThemeDefinition(
                id: "theme.grid.ember",
                category: .grid,
                title: "Ember",
                subtitle: "Volcanic red ambience",
                priceCoins: 500,
                rarity: .premium,
                detailTags: ["Heat fade", "Ash depth", "Fire contrast"],
                accentA: Color(red: 0.10, green: 0.04, blue: 0.06),
                accentB: Color(red: 0.24, green: 0.09, blue: 0.11),
                accentC: Color(red: 0.56, green: 0.19, blue: 0.21)
            ),
            ThemeDefinition(
                id: "theme.grid.polar_weave",
                category: .grid,
                title: "Polar Weave",
                subtitle: "Glacier mesh with silver tracks",
                priceCoins: 720,
                rarity: .rare,
                detailTags: ["Frost grid", "Silver rails", "Cold clarity"],
                accentA: Color(red: 0.84, green: 0.94, blue: 1.00),
                accentB: Color(red: 0.58, green: 0.73, blue: 0.90),
                accentC: Color(red: 0.34, green: 0.48, blue: 0.67)
            ),
            ThemeDefinition(
                id: "theme.grid.mint_circuit",
                category: .grid,
                title: "Mint Circuit",
                subtitle: "High-tech boardline matrix",
                priceCoins: 860,
                rarity: .rare,
                detailTags: ["Circuit lines", "Precision glow", "Clean geometry"],
                accentA: Color(red: 0.63, green: 0.96, blue: 0.85),
                accentB: Color(red: 0.29, green: 0.74, blue: 0.63),
                accentC: Color(red: 0.12, green: 0.39, blue: 0.34)
            ),
            ThemeDefinition(
                id: "theme.grid.sand_temple",
                category: .grid,
                title: "Sand Temple",
                subtitle: "Sunlit stone with carved depth",
                priceCoins: 1_040,
                rarity: .rare,
                detailTags: ["Stone grain", "Warm haze", "Ancient carving"],
                accentA: Color(red: 0.91, green: 0.82, blue: 0.61),
                accentB: Color(red: 0.74, green: 0.60, blue: 0.37),
                accentC: Color(red: 0.45, green: 0.33, blue: 0.18)
            ),
            ThemeDefinition(
                id: "theme.grid.obsidian_vault",
                category: .grid,
                title: "Obsidian Vault",
                subtitle: "Dark steel lattice for high focus",
                priceCoins: 1_320,
                rarity: .epic,
                detailTags: ["Vault texture", "Steel ribs", "Contrast lock"],
                accentA: Color(red: 0.12, green: 0.13, blue: 0.17),
                accentB: Color(red: 0.24, green: 0.26, blue: 0.30),
                accentC: Color(red: 0.44, green: 0.47, blue: 0.55)
            ),
            ThemeDefinition(
                id: "theme.grid.stormline",
                category: .grid,
                title: "Stormline",
                subtitle: "Rain-soaked navy with neon cuts",
                priceCoins: 1_580,
                rarity: .epic,
                detailTags: ["Rain sheen", "Neon rails", "Night tension"],
                accentA: Color(red: 0.11, green: 0.20, blue: 0.36),
                accentB: Color(red: 0.18, green: 0.34, blue: 0.62),
                accentC: Color(red: 0.49, green: 0.73, blue: 0.96)
            ),
            ThemeDefinition(
                id: "theme.grid.lunar_glass",
                category: .grid,
                title: "Lunar Glass",
                subtitle: "Moonlit crystal board with soft halo",
                priceCoins: 1_860,
                rarity: .epic,
                detailTags: ["Glass clarity", "Halo lines", "Low noise"],
                accentA: Color(red: 0.79, green: 0.85, blue: 0.96),
                accentB: Color(red: 0.57, green: 0.64, blue: 0.84),
                accentC: Color(red: 0.37, green: 0.44, blue: 0.64)
            ),
            ThemeDefinition(
                id: "theme.grid.emerald_hall",
                category: .grid,
                title: "Emerald Hall",
                subtitle: "Jewel-toned board with royal polish",
                priceCoins: 2_180,
                rarity: .legendary,
                detailTags: ["Jewel depth", "Hall shine", "Rich framing"],
                accentA: Color(red: 0.20, green: 0.62, blue: 0.50),
                accentB: Color(red: 0.10, green: 0.39, blue: 0.31),
                accentC: Color(red: 0.68, green: 0.89, blue: 0.82)
            ),
            ThemeDefinition(
                id: "theme.grid.ruby_citadel",
                category: .grid,
                title: "Ruby Citadel",
                subtitle: "Bold gem red with metallic framing",
                priceCoins: 2_520,
                rarity: .legendary,
                detailTags: ["Citadel lines", "Gem red", "High definition"],
                accentA: Color(red: 0.74, green: 0.20, blue: 0.28),
                accentB: Color(red: 0.46, green: 0.09, blue: 0.15),
                accentC: Color(red: 0.95, green: 0.69, blue: 0.73)
            ),
            ThemeDefinition(
                id: "theme.grid.titanium_command",
                category: .grid,
                title: "Titanium Command",
                subtitle: "Aerospace grey with precision seams",
                priceCoins: 2_990,
                rarity: .legendary,
                detailTags: ["Alloy weave", "Command lines", "Pro clarity"],
                accentA: Color(red: 0.45, green: 0.52, blue: 0.59),
                accentB: Color(red: 0.29, green: 0.34, blue: 0.40),
                accentC: Color(red: 0.78, green: 0.84, blue: 0.90)
            ),
            ThemeDefinition(
                id: "theme.grid.astral_lattice",
                category: .grid,
                title: "Astral Lattice",
                subtitle: "Stellar geometry and soft cosmic fog",
                priceCoins: 3_520,
                rarity: .mythic,
                detailTags: ["Stellar mesh", "Cosmic haze", "Deep layering"],
                accentA: Color(red: 0.38, green: 0.54, blue: 0.95),
                accentB: Color(red: 0.25, green: 0.31, blue: 0.72),
                accentC: Color(red: 0.79, green: 0.73, blue: 1.00)
            ),
            ThemeDefinition(
                id: "theme.grid.nebula_drift",
                category: .grid,
                title: "Nebula Drift",
                subtitle: "Space dust gradients and aurora lines",
                priceCoins: 4_080,
                rarity: .mythic,
                detailTags: ["Dust glow", "Aurora rails", "Ambient depth"],
                accentA: Color(red: 0.30, green: 0.41, blue: 0.86),
                accentB: Color(red: 0.57, green: 0.30, blue: 0.84),
                accentC: Color(red: 0.88, green: 0.52, blue: 0.99)
            ),
            ThemeDefinition(
                id: "theme.grid.singularity_chamber",
                category: .grid,
                title: "Singularity Chamber",
                subtitle: "Black-hole contrast with bright rings",
                priceCoins: 4_820,
                rarity: .mythic,
                detailTags: ["Gravity rings", "Event-horizon black", "Sharp orbit"],
                accentA: Color(red: 0.08, green: 0.10, blue: 0.15),
                accentB: Color(red: 0.19, green: 0.20, blue: 0.32),
                accentC: Color(red: 0.79, green: 0.66, blue: 1.00)
            ),
            ThemeDefinition(
                id: "theme.grid.immortal_atlas",
                category: .grid,
                title: "Immortal Atlas",
                subtitle: "Collector board with gold-lined geometry",
                priceCoins: 6_400,
                rarity: .mythic,
                detailTags: ["Atlas engraving", "Gold geometry", "Collector polish"],
                accentA: Color(red: 0.14, green: 0.13, blue: 0.18),
                accentB: Color(red: 0.37, green: 0.32, blue: 0.21),
                accentC: Color(red: 0.95, green: 0.83, blue: 0.48)
            )
        ]
    )

    func theme(id: String) -> ThemeDefinition? {
        blockThemes.first(where: { $0.id == id }) ?? gridThemes.first(where: { $0.id == id })
    }

    var allThemeIDs: Set<String> {
        Set(blockThemes.map(\.id) + gridThemes.map(\.id))
    }

    var defaultBlockThemeID: String {
        blockThemes.first?.id ?? ""
    }

    var defaultGridThemeID: String {
        gridThemes.first?.id ?? ""
    }
}
