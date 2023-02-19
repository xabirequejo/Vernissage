//
//  https://mczachurski.dev
//  Copyright © 2023 Marcin Czachurski and the repository contributors.
//  Licensed under the MIT License.
//

import SwiftUI
import MastodonKit

struct PlaceSelectorView: View {
    @EnvironmentObject var applicationState: ApplicationState
    @EnvironmentObject var client: Client
    @Environment(\.dismiss) private var dismiss

    @State private var places: [Place] = []
    @State private var query = String.empty()
    
    @Binding public var place: Place?
    
    @FocusState private var focusedField: FocusField?
    enum FocusField: Hashable {
        case unknown
        case search
    }
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                List {
                    Section {
                        HStack {
                            TextField("Search...", text: $query)
                                .padding(8)
                                .focused($focusedField, equals: .search)
                                .keyboardType(.default)
                                .autocorrectionDisabled()
                                .onAppear() {
                                    self.focusedField = .search
                                }
                            Button {
                                Task {
                                    await self.searchPlaces()
                                }
                            } label: {
                                Text("Search")
                                    
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    
                    Section {
                        ForEach(self.places, id: \.id) { place in
                            Button {
                                self.place = place
                                self.dismiss()
                            } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(place.name ?? String.empty())
                                            .foregroundColor(.mainTextColor)
                                        Text(place.country ?? String.empty())
                                            .font(.subheadline)
                                            .foregroundColor(.lightGrayColor)
                                    }

                                    Spacer()
                                    if self.place?.id == place.id {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(self.applicationState.tintColor.color())
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationBarTitle(Text("Places"), displayMode: .inline)
            .toolbar {
                self.getTrailingToolbar()
            }
        }
    }
    
    @ToolbarContentBuilder
    private func getTrailingToolbar() -> some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel", role: .cancel) {
                self.dismiss()
            }
        }
    }
    
    private func searchPlaces() async {
        do {
            if let placesFromApi = try await self.client.places?.search(query: self.query) {
                self.places = placesFromApi
            }
        } catch {
            ErrorService.shared.handle(error, message: "Cannot download places.", showToastr: true)
        }
    }
}

