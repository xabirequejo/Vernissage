//
//  https://mczachurski.dev
//  Copyright © 2023 Marcin Czachurski and the repository contributors.
//  Licensed under the MIT License.
//
    
import SwiftUI

struct NoDataView: View {
    
    private let imageSystemName: String
    private let text: String
    
    init(imageSystemName: String, text: String) {
        self.imageSystemName = imageSystemName
        self.text = text
    }
    
    var body: some View {
        VStack {
            Image(systemName: self.imageSystemName)
                .font(.largeTitle)
                .padding(.bottom, 4)
            Text(self.text)
                .font(.title3)
        }
        .foregroundColor(.lightGrayColor)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}