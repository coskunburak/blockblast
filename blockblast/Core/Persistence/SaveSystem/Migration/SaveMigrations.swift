import Foundation

enum SaveMigrations {
    static let currentVersion = 1

    static func migrateIfNeeded(_ dto: SaveGameDTO) -> SaveGameDTO {
        // Placeholder for future migrations.
        if dto.version == currentVersion {
            return dto
        }
        return SaveGameDTO(
            version: currentVersion,
            savedAt: dto.savedAt,
            state: dto.state
        )
    }
}
