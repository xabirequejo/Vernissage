//
//  https://mczachurski.dev
//  Copyright © 2023 Marcin Czachurski and the repository contributors.
//  Licensed under the MIT License.
//
    
import SwiftUI
import NukeUI

struct ImageGrid: View {
    @EnvironmentObject var applicationState: ApplicationState
    @EnvironmentObject var routerPath: RouterPath
    @StateObject var photoUrl: PhotoUrl
        
    var body: some View {
        if self.photoUrl.sensitive && !self.applicationState.showSensitive {
            BlurredImage(blurhash: self.photoUrl.blurhash)
                .aspectRatio(contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .onTapGesture {
                    if let statusId = self.photoUrl.statusId {
                        self.routerPath.navigate(to: .status(id: statusId))
                    }
                }
        } else if let url = photoUrl.url {
            LazyImage(url: url) { state in
                if let image = state.image {
                    image
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .onTapGesture {
                            if let statusId = self.photoUrl.statusId {
                                self.routerPath.navigate(to: .status(id: statusId))
                            }
                        }
                } else if state.isLoading {
                    self.placeholder()
                } else {
                    self.placeholder()
                }
            }
            .priority(.high)
        } else {
            self.placeholder()
        }
    }
    
    @ViewBuilder
    private func placeholder() -> some View {
        Image("ImagePlaceholder")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}