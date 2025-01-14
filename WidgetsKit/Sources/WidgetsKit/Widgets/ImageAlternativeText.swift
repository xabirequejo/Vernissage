//
//  https://mczachurski.dev
//  Copyright © 2023 Marcin Czachurski and the repository contributors.
//  Licensed under the Apache License 2.0.
//

import SwiftUI
import EnvironmentKit

public struct ImageAlternativeText: View {
    @Environment(ApplicationState.self) var applicationState

    private let text: String?
    private let open: (String) -> Void

    public init(text: String?, open: @escaping (String) -> Void) {
        self.text = text
        self.open = open
    }

    public var body: some View {
        if let text = self.text, text.count > 0 && self.applicationState.showAltIconOnTimeline {
            VStack(alignment: .leading) {
                Spacer()

                HStack(alignment: .center) {
                    Spacer()

                    Button {
                        self.open(text)
                    } label: {
                        Text("status.title.altText", bundle: Bundle.module, comment: "ALT")
                            .font(.system(size: 12))
                            .shadow(color: .black, radius: 4)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(RoundedRectangle(cornerRadius: 8).foregroundColor(.black.opacity(0.8)))
                    }
                }
            }
            .padding(.trailing, 12)
            .padding(.bottom, 12)
        }
    }
}
