//
//  https://mczachurski.dev
//  Copyright © 2022 Marcin Czachurski and the repository contributors.
//  Licensed under the MIT License.
//

import Foundation

public struct Marker: Codable {
    public let lastReadId: EntityId
    public let version: Int64
    public let updatedAt: String

    private enum CodingKeys: String, CodingKey {
        case lastReadId = "last_read_id"
        case version
        case updatedAt = "updated_at"
    }
}

public struct Markers: Codable {
    public let home: Marker?
    public let notifications: Marker?

    private enum CodingKeys: String, CodingKey {
        case home
        case notifications
    }
}
