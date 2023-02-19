//
//  https://mczachurski.dev
//  Copyright © 2023 Marcin Czachurski and the repository contributors.
//  Licensed under the MIT License.
//
    
import SwiftUI
import PhotosUI
import PixelfedKit

struct ComposeView: View {
    @EnvironmentObject var applicationState: ApplicationState
    @EnvironmentObject var routerPath: RouterPath
    @EnvironmentObject var client: Client

    @Environment(\.dismiss) private var dismiss
    
    @State var statusViewModel: StatusModel?
    @State private var text = String.empty()
    @State private var visibility = Pixelfed.Statuses.Visibility.pub
    @State private var isSensitive = false
    @State private var spoilerText = String.empty()
    @State private var commentsDisabled = false
    @State private var place: Place?

    @State private var photosAreAttached = false
    @State private var publishDisabled = true
    @State private var interactiveDismissDisabled = false
    
    @State private var photosAreUploading = false
    @State private var photosPickerVisible = false
    
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var photosAttachment: [PhotoAttachment] = []
    
    @FocusState private var focusedField: FocusField?
    enum FocusField: Hashable {
        case unknown
        case content
        case spoilerText
    }
    
    @State private var showSheet: SheetType? = nil
    enum SheetType: Identifiable {
        case photoDetails(PhotoAttachment)
        case placeSelector
        
        public var id: String {
            switch self {
            case .photoDetails:
                return "photoDetails"
            case .placeSelector:
                return "placeSelector"
            }
        }
    }
    
    private let contentWidth = Int(UIScreen.main.bounds.width) - 50
    
    var body: some View {
        NavigationStack {
            NavigationView {
                ScrollView {
                    VStack (alignment: .leading){
                        if self.isSensitive {
                            TextField("Write content warning", text: $spoilerText, axis: .vertical)
                                .padding(8)
                                .lineLimit(1...2)
                                .focused($focusedField, equals: .spoilerText)
                                .keyboardType(.default)
                                .background(Color.dangerColor.opacity(0.4))
                        }
                        
                        if self.commentsDisabled {
                            HStack {
                                Spacer()
                                Text("Comments will be disabled")
                                    .textCase(.uppercase)
                                    .font(.caption2)
                                    .foregroundColor(.dangerColor)
                            }
                            .padding(.horizontal, 8)
                        }
                        
                        if let accountData = applicationState.account {
                            HStack {
                                UsernameRow(
                                    accountId: accountData.id,
                                    accountAvatar: accountData.avatar,
                                    accountDisplayName: accountData.displayName,
                                    accountUsername: accountData.username)
                                Spacer()
                            }
                            .padding(8)
                        }
                        
                        if let name = self.place?.name, let country = self.place?.country {
                            HStack {
                                Group {
                                    Image(systemName: "mappin.and.ellipse")
                                    Text("\(name), \(country)")
                                }
                                .font(.caption)
                                .foregroundColor(.lightGrayColor)
                                Spacer()
                            }
                            .padding(.horizontal, 8)
                        }
                        
                        TextField("Type what's on your mind", text: $text, axis: .vertical)
                            .padding(8)
                            .lineLimit(2...12)
                            .focused($focusedField, equals: .content)
                            .keyboardType(.default)
                            .onFirstAppear {
                                self.focusedField = .content
                            }
                            .onChange(of: self.text) { newValue in
                                self.publishDisabled = self.isPublishButtonDisabled()
                                self.interactiveDismissDisabled = self.isInteractiveDismissDisabled()
                            }
                            .toolbar {
                                self.keyboardToolbar()
                            }
                        
                        HStack(alignment: .center) {
                            ForEach(self.photosAttachment, id: \.id) { photoAttachment in
                                ImageUploadView(photoAttachment: photoAttachment) {
                                    self.showSheet = .photoDetails(photoAttachment)
                                } delete: {
                                    self.photosAttachment = self.photosAttachment.filter({ item in
                                        item != photoAttachment
                                    })
                                    
                                    self.photosAreAttached = self.photosAttachment.hasUploadedPhotos()
                                    self.publishDisabled = self.isPublishButtonDisabled()
                                    self.interactiveDismissDisabled = self.isInteractiveDismissDisabled()
                                }
                            }
                        }
                        .padding(8)
                        
                        if let status = self.statusViewModel {
                            HStack (alignment: .top) {                            
                                UserAvatar(accountAvatar: status.account.avatar, size: .comment)
                                
                                VStack (alignment: .leading, spacing: 0) {
                                    HStack (alignment: .top) {
                                        Text(statusViewModel?.account.displayNameWithoutEmojis ?? "")
                                            .foregroundColor(.mainTextColor)
                                            .font(.footnote)
                                            .fontWeight(.bold)
                                        
                                        Spacer()
                                    }
                                    
                                    MarkdownFormattedText(status.content.asMarkdown, withFontSize: 14, andWidth: contentWidth)
                                        .environment(\.openURL, OpenURLAction { url in .handled })
                                }
                            }
                            .padding(8)
                            .background(Color.selectedRowColor)
                        }
                        
                        Spacer()
                    }
                }
                .onTapGesture {
                    self.hideKeyboard()
                }
                .frame(alignment: .topLeading)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        ActionButton(showLoader: false) {
                            await self.publishStatus()
                        } label: {
                            Text("Publish")
                        }
                        .disabled(self.publishDisabled)
                        .buttonStyle(.borderedProminent)
                    }
                    
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel", role: .cancel) {
                            dismiss()
                        }
                    }
                }
                .onChange(of: self.selectedItems) { selectedItem in
                    Task {
                        await self.loadPhotos()
                    }
                }
                .sheet(item: $showSheet, content: { sheetType in
                    switch sheetType {
                    case .photoDetails(let photoAttachment):
                        PhotoEditorView(photoAttachment: photoAttachment)
                    case .placeSelector:
                        PlaceSelectorView(place: $place)
                    }
                })
                .photosPicker(isPresented: $photosPickerVisible, selection: $selectedItems, maxSelectionCount: 4, matching: .images)
                .navigationBarTitle(Text("Compose"), displayMode: .inline)
            }
            .withAppRouteur()
            .withOverlayDestinations(overlayDestinations: $routerPath.presentedOverlay)
        }
        .interactiveDismissDisabled(self.interactiveDismissDisabled)
    }
    
    @ToolbarContentBuilder
    private func keyboardToolbar() -> some ToolbarContent {
        ToolbarItemGroup(placement: .keyboard) {
            HStack(alignment: .center) {
                Button {
                    hideKeyboard()
                    self.focusedField = .unknown
                    self.photosPickerVisible = true
                } label: {
                    Image(systemName: self.photosAreAttached ? "photo.fill.on.rectangle.fill" : "photo.on.rectangle")
                }

                Button {
                    withAnimation(.easeInOut) {
                        self.isSensitive.toggle()
                        
                        if self.isSensitive {
                            self.focusedField = .spoilerText
                        } else {
                            self.focusedField = .content
                        }
                    }
                } label: {
                    Image(systemName: self.isSensitive ? "exclamationmark.square.fill" : "exclamationmark.square")
                }
                
                Button {
                    withAnimation(.easeInOut) {
                        self.commentsDisabled.toggle()
                    }
                } label: {
                    Image(systemName: self.commentsDisabled ? "person.2.slash" : "person.2.fill")
                }

                Button {
                    if self.place != nil {
                        withAnimation(.easeInOut) {
                            self.place = nil
                        }
                    } else {
                        self.showSheet = .placeSelector
                    }
                } label: {
                    Image(systemName: self.place == nil ? "mappin.square" : "mappin.square.fill")
                }
                
                Spacer()
                
                Picker("Post visibility", selection: $visibility) {
                    HStack {
                        Image(systemName: "globe.europe.africa")
                        Text(" Everyone")
                    }.tag(Pixelfed.Statuses.Visibility.pub)
                    
                    HStack {
                        Image(systemName: "lock.open")
                        Text(" Unlisted")
                    }.tag(Pixelfed.Statuses.Visibility.unlisted)
                        
                    HStack {
                        Image(systemName: "lock")
                        Text(" Followers")
                    }.tag(Pixelfed.Statuses.Visibility.priv)
                }.buttonStyle(.bordered)
            }
        }
    }
    
    private func isPublishButtonDisabled() -> Bool {
        // Publish always disabled when there is not status text.
        if self.text.isEmpty {
            return true
        }
        
        // When application is during uploading photos we cannot send new status.
        if self.photosAreUploading == true {
            return true
        }
        
        // When status is not a comment, then photo is required.
        if self.statusViewModel == nil && self.photosAttachment.hasUploadedPhotos() == false {
            return true
        }
        
        return false
    }
    
    private func isInteractiveDismissDisabled() -> Bool {
        if self.text.isEmpty == false {
            return true
        }
        
        if self.photosAreUploading == true {
            return true
        }
        
        if self.photosAttachment.hasUploadedPhotos() == true {
            return true
        }
        
        return false
    }
    
    private func loadPhotos() async {
        do {
            self.photosAreUploading = true
            self.photosAttachment = []
            self.publishDisabled = self.isPublishButtonDisabled()
            self.interactiveDismissDisabled = self.isInteractiveDismissDisabled()
            
            for item in self.selectedItems {
                if let photoData = try await item.loadTransferable(type: Data.self) {
                    self.photosAttachment.append(PhotoAttachment(photosPickerItem: item, photoData: photoData))
                }
            }
            
            self.focusedField = .content
            await self.upload()
            
            self.photosAreUploading = false
            self.photosAreAttached = self.photosAttachment.hasUploadedPhotos()
            self.publishDisabled = self.isPublishButtonDisabled()
            self.interactiveDismissDisabled = self.isInteractiveDismissDisabled()
        } catch {
            ErrorService.shared.handle(error, message: "Cannot retreive image from library.", showToastr: true)
        }
    }
    
    private func upload() async {
        for (index, photoAttachment) in self.photosAttachment.enumerated() {
            do {
                if let mediaAttachment = try await self.client.media?.upload(data: photoAttachment.photoData,
                                                                             fileName: "file-\(index).jpg",
                                                                             mimeType: "image/jpeg") {
                    photoAttachment.uploadedAttachment = mediaAttachment
                }
            } catch {
                photoAttachment.error = error
                ErrorService.shared.handle(error, message: "Error during post photo.", showToastr: true)
            }
        }
    }
    
    private func publishStatus() async {
        do {
            let status = self.createStatus()
            if let newStatus = try await self.client.statuses?.new(status: status) {
                ToastrService.shared.showSuccess("Status published", imageSystemName: "message.fill")

                let statusModel = StatusModel(status: newStatus)
                let commentModel = CommentModel(status: statusModel, showDivider: false)
                self.applicationState.newComment = commentModel

                dismiss()
            }
        } catch {
            ErrorService.shared.handle(error, message: "Error during post status.", showToastr: true)
        }
    }
    
    private func createStatus() -> Pixelfed.Statuses.Components {
        return Pixelfed.Statuses.Components(inReplyToId: self.statusViewModel?.id,
                                            text: self.text,
                                            spoilerText: self.isSensitive ? self.spoilerText : String.empty(),
                                            mediaIds: self.photosAttachment.getUploadedPhotoIds(),
                                            visibility: self.visibility,
                                            sensitive: self.isSensitive,
                                            placeId: self.place?.id,
                                            commentsDisabled: self.commentsDisabled)
    }
}
