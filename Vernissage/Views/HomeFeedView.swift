//
//  https://mczachurski.dev
//  Copyright © 2022 Marcin Czachurski and the repository contributors.
//  Licensed under the MIT License.
//

import SwiftUI

struct HomeFeedView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var applicationState: ApplicationState
    @EnvironmentObject var routerPath: RouterPath
    
    @State private var firstLoadFinished = false
    @State private var allItemsBottomLoaded = false
    
    private static let initialColumns = 1
    @State private var gridColumns = Array(repeating: GridItem(.flexible()), count: initialColumns)
        
    @FetchRequest var dbStatuses: FetchedResults<StatusData>
    
    init(accountId: String) {
        _dbStatuses = FetchRequest<StatusData>(
            sortDescriptors: [SortDescriptor(\.id, order: .reverse)],
            predicate: NSPredicate(format: "pixelfedAccount.id = %@", accountId))
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: gridColumns) {
                ForEach(dbStatuses, id: \.self) { item in
                    
                    if self.shouldUpToDateBeVisible(statusId: item.id) {
                        self.upToDatePlaceholder()
                    }
                    
                    NavigationLink(value: RouteurDestinations.status(
                        id: item.rebloggedStatusId ?? item.id,
                        blurhash: item.attachments().first?.blurhash,
                        highestImageUrl: item.attachments().getHighestImage()?.url,
                        metaImageWidth: item.attachments().first?.metaImageWidth,
                        metaImageHeight: item.attachments().first?.metaImageHeight)
                    ) {
                        ImageRow(statusData: item)
                    }
                    .buttonStyle(EmptyButtonStyle())
                }
                
                if allItemsBottomLoaded == false && firstLoadFinished == true {
                    LoadingIndicator()
                        .task {
                            do {
                                if let account = self.applicationState.account {
                                    let newStatusesCount = try await HomeTimelineService.shared.loadOnBottom(for: account)
                                    if newStatusesCount == 0 {
                                        allItemsBottomLoaded = true
                                    }
                                }
                            } catch {
                                ErrorService.shared.handle(error, message: "Error during download statuses from server.", showToastr: !Task.isCancelled)
                            }
                        }
                }
            }
        }
        .overlay(alignment: .center) {
            if firstLoadFinished == false {
                LoadingIndicator()
            } else {
                if self.dbStatuses.isEmpty {
                    VStack {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.largeTitle)
                            .padding(.bottom, 4)
                        Text("Unfortunately, there are no photos here.")
                            .font(.title3)
                    }.foregroundColor(.lightGrayColor)
                }
            }
        }
        .refreshable {
            do {
                if let account = self.applicationState.account {
                    if let lastSeenStatusId = try await HomeTimelineService.shared.loadOnTop(for: account) {   
                        try await HomeTimelineService.shared.save(lastSeenStatusId: lastSeenStatusId, for: account)
                        self.applicationState.lastSeenStatusId = lastSeenStatusId
                    }
                }
            } catch {
                print("Error", error)
            }
        }
        .task {
            do {
                defer {
                    Task { @MainActor in
                        self.firstLoadFinished = true
                    }
                }

                if self.dbStatuses.isEmpty == false {
                    return
                }

                if let account = self.applicationState.account {
                    _ = try await HomeTimelineService.shared.loadOnTop(for: account)
                }
            } catch {
                ErrorService.shared.handle(error, message: "Error during download statuses from server.", showToastr: !Task.isCancelled)
            }
        }
    }
    
    private func shouldUpToDateBeVisible(statusId: String) -> Bool {
        return self.applicationState.lastSeenStatusId != dbStatuses.first?.id && self.applicationState.lastSeenStatusId == statusId
    }
    
    @ViewBuilder
    private func upToDatePlaceholder() -> some View {
        VStack(alignment: .center) {
            Image(systemName: "checkmark.seal")
                .resizable()
                .frame(width: 64, height: 64)
                .fontWeight(.ultraLight)
                .foregroundColor(.accentColor.opacity(0.6))
            Text("You're all caught up")
                .font(.title2)
                .fontWeight(.thin)
                .foregroundColor(Color.mainTextColor.opacity(0.6))
        }
        .padding(.vertical, 8)
        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width * 0.75)
    }
}
