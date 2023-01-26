//
//  https://mczachurski.dev
//  Copyright © 2022 Marcin Czachurski and the repository contributors.
//  Licensed under the MIT License.
//

import SwiftUI
import MastodonKit

struct TrendStatusesView: View {
    
    @EnvironmentObject private var applicationState: ApplicationState
    @State public var accountId: String

    @State private var firstLoadFinished = false
    @State private var tabSelectedValue: Mastodon.PixelfedTrends.TrendRange = .daily
    
    @State private var statusViewModels: [StatusViewModel] = []

    var body: some View {
        ScrollView {
            
            Picker(selection: $tabSelectedValue, label: Text("")) {
                Text("Daily").tag(Mastodon.PixelfedTrends.TrendRange.daily)
                Text("Monthly").tag(Mastodon.PixelfedTrends.TrendRange.monthly)
                Text("Yearly").tag(Mastodon.PixelfedTrends.TrendRange.yearly)
                
            }
            .padding()
            .pickerStyle(SegmentedPickerStyle())
            .onChange(of: tabSelectedValue) { _ in
                Task {
                    do {
                        self.firstLoadFinished = false;
                        self.statusViewModels = []
                        try await self.loadStatuses()
                    } catch {
                        ErrorService.shared.handle(error, message: "Loading statuses failed.", showToastr: !Task.isCancelled)
                    }
                }
            }
            
            VStack(alignment: .center) {
                if firstLoadFinished == true {
                    ForEach(self.statusViewModels, id: \.uniqueId) { item in
                        NavigationLink(value: RouteurDestinations.status(
                            id: item.id,
                            blurhash: item.mediaAttachments.first?.blurhash,
                            metaImageWidth: item.getImageWidth(),
                            metaImageHeight: item.getImageHeight())
                        ) {
                            ImageRowAsync(statusViewModel: item)
                        }
                        .buttonStyle(EmptyButtonStyle())
                    }
                }
            }
        }
        .navigationBarTitle("Trends")
        .overlay(alignment: .center) {
            if firstLoadFinished == false {
                LoadingIndicator()
            } else {
                if self.statusViewModels.isEmpty {
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
        .task {
            do {
                try await self.loadStatuses()
            } catch {
                ErrorService.shared.handle(error, message: "Loading statuses failed.", showToastr: !Task.isCancelled)
            }
        }.refreshable {
            do {
                try await self.loadStatuses()
            } catch {
                ErrorService.shared.handle(error, message: "Loading statuses failed.", showToastr: !Task.isCancelled)
            }
        }
    }
    
    private func loadStatuses() async throws {
        guard firstLoadFinished == false else {
            return
        }
        
        let statuses = try await TrendsService.shared.statuses(
            accountData: self.applicationState.accountData,
            range: tabSelectedValue)

        var inPlaceStatuses: [StatusViewModel] = []

        for item in statuses.getStatusesWithImagesOnly() {
            inPlaceStatuses.append(StatusViewModel(status: item))
        }
        
        self.statusViewModels = inPlaceStatuses
        self.firstLoadFinished = true
    }
}