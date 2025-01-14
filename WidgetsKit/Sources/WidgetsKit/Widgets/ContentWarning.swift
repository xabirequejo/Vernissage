//
//  https://mczachurski.dev
//  Copyright © 2023 Marcin Czachurski and the repository contributors.
//  Licensed under the Apache License 2.0.
//

import SwiftUI

public struct ContentWarning<Content: View, Blurred: View>: View {
    private let spoilerText: String?
    private let content: () -> Content
    private let blurred: () -> Blurred

    @State private var showSensitive = false

    public init(spoilerText: String?,
                @ViewBuilder content: @escaping () -> Content,
                @ViewBuilder blurred: @escaping () -> Blurred) {

        self.spoilerText = spoilerText
        self.content = content
        self.blurred = blurred
    }

    public var body: some View {
        if self.showSensitive {
            ZStack {
                content()
                    .transition(.opacity)

                VStack(alignment: .trailing) {
                    HStack(alignment: .top) {
                        Spacer()
                        Button {
                            withAnimation {
                                self.showSensitive = false
                            }
                        } label: {
                            Image(systemName: "eye.slash")
                                .font(.system(size: 18))
                                .foregroundColor(.white.opacity(0.8))
                                .shadow(color: Color.black, radius: 1)
                                .padding(.top, 11)
                                .padding(.trailing, 16)
                                .padding([.bottom, .leading], 16)
                        }
                    }
                    Spacer()
                }
                .foregroundColor(.mainTextColor)
            }
        } else {
            ZStack {
                self.blurred()

                VStack(alignment: .center) {
                    Spacer()
                    Image(systemName: "eye.slash.fill")
                        .font(.title2)
                        .shadow(color: Color.systemBackground, radius: 0.3)
                    Text("global.title.contentWarning", bundle: Bundle.module, comment: "Sensitive content")
                        .font(.title2)
                        .shadow(color: Color.systemBackground, radius: 0.3)
                    if let spoilerText {
                        Text(spoilerText)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .shadow(color: Color.systemBackground, radius: 0.3)
                    }
                    Button {
                        withAnimation {
                            self.showSensitive = true
                        }
                    } label: {
                        Text("global.title.seePost", bundle: Bundle.module, comment: "See post")
                            .shadow(color: Color.systemBackground, radius: 0.3)
                    }
                    .buttonStyle(.bordered)
                    Spacer()
                }
                .foregroundColor(.mainTextColor)
            }
            .transition(.opacity)
        }
    }
}
