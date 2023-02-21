//
//  https://mczachurski.dev
//  Copyright © 2023 Marcin Czachurski and the repository contributors.
//  Licensed under the MIT License.
//

import SwiftUI
import PixelfedKit

struct CommentBodyView: View {
    @EnvironmentObject var applicationState: ApplicationState
    @EnvironmentObject var routerPath: RouterPath

    @State var statusViewModel: StatusModel
    private let contentWidth = Int(UIScreen.main.bounds.width) - 60
    
    var body: some View {
        HStack (alignment: .top) {
            UserAvatar(accountAvatar: self.statusViewModel.account.avatar, size: .comment)
                .onTapGesture {
                    routerPath.navigate(to: .userProfile(accountId: self.statusViewModel.account.id,
                                                         accountDisplayName: self.statusViewModel.account.displayNameWithoutEmojis,
                                                         accountUserName: self.statusViewModel.account.acct))
                }
            
            VStack (alignment: .leading, spacing: 0) {
                HStack (alignment: .top) {
                    Text(statusViewModel.account.displayNameWithoutEmojis)
                        .foregroundColor(.mainTextColor)
                        .font(.footnote)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Text(self.statusViewModel.createdAt.toRelative(.isoDateTimeMilliSec))
                        .foregroundColor(.lightGrayColor)
                        .font(.footnote)
                }
                
                MarkdownFormattedText(self.statusViewModel.content.asMarkdown, withFontSize: 14, andWidth: contentWidth)
                    .environment(\.openURL, OpenURLAction { url in .handled })
                    .padding(.top, 4)
                
                if self.statusViewModel.mediaAttachments.count > 0 {
                    LazyVGrid(
                        columns: self.statusViewModel.mediaAttachments.count == 1 ? [GridItem(.flexible())]: [GridItem(.flexible()), GridItem(.flexible())],
                        alignment: .center,
                        spacing: 4
                    ) {
                        ForEach(self.statusViewModel.mediaAttachments, id: \.id) { attachment in
                            AsyncImage(url: attachment.url) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(minWidth: 0, maxWidth: .infinity)
                                    .frame(height: self.statusViewModel.mediaAttachments.count == 1 ? 200 : 100)
                                    .cornerRadius(10)
                                    .shadow(color: .mainTextColor.opacity(0.3), radius: 2)
                            } placeholder: {
                                Image(systemName: "photo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(minWidth: 0, maxWidth: .infinity)
                                    .frame(height: self.statusViewModel.mediaAttachments.count == 1 ? 200 : 100)
                                    .foregroundColor(.mainTextColor)
                                    .opacity(0.05)
                            }
                        }
                    }
                    .padding(.bottom, 8)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.linear(duration: 0.3)) {
                    if self.statusViewModel.id == self.applicationState.showInteractionStatusId {
                        self.applicationState.showInteractionStatusId = String.empty()
                    } else {
                        self.applicationState.showInteractionStatusId = self.statusViewModel.id
                    }
                }
            }
        }
        .padding(8)
        .background(self.getSelectedRowColor(statusViewModel: statusViewModel))
    }
    
    private func getSelectedRowColor(statusViewModel: StatusModel) -> Color {
        return self.applicationState.showInteractionStatusId == statusViewModel.id ? Color.selectedRowColor : Color.systemBackground
    }
}
