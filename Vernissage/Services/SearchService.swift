//
//  https://mczachurski.dev
//  Copyright © 2023 Marcin Czachurski and the repository contributors.
//  Licensed under the MIT License.
//
    
import Foundation
import MastodonKit

public class SearchService {
    public static let shared = SearchService()
    private init() { }
    
    public func search(for account: AccountModel?,
                       query: String,
                       resultsType: Mastodon.Search.ResultsType) async throws -> SearchResults? {
        guard let accessToken = account?.accessToken, let serverUrl = account?.serverUrl else {
            return nil
        }
        
        let client = MastodonClient(baseURL: serverUrl).getAuthenticated(token: accessToken)
        return try await client.search(query: query, type: resultsType)
    }
}
