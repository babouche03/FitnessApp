import SwiftUI
import PhotosUI

struct DiaryEditView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var diaryText: String = ""
    @State private var selectedImages: [UIImage] = []
    @State private var selectedVideos: [URL] = []
    @State private var showImagePicker = false
    @State private var showVideoPicker = false
    @State private var hasEdited = false
    @State private var selectedImageForPreview: UIImage? = nil
    @State private var showDeleteAlert = false
    @State private var imageIndexToDelete: Int? = nil
    
    let isEditing: Bool
    let existingDiary: DiaryEntry?
    let moodValue: Double
    
    init(isEditing: Bool = false, existingDiary: DiaryEntry? = nil, moodValue: Double = 5.0) {
        self.isEditing = isEditing
        self.existingDiary = existingDiary
        self.moodValue = existingDiary?.mood ?? moodValue
        _diaryText = State(initialValue: existingDiary?.content ?? "")
        _selectedImages = State(initialValue: existingDiary?.images ?? [])
        _selectedVideos = State(initialValue: existingDiary?.videos ?? [])
    }
    
    var currentDate: Date {
        existingDiary?.date ?? Date()
    }
    
    var body: some View {
        ZStack {
            NavigationView {
                VStack {
                    // 顶部日期时间显示
                    HStack {
                        Text(currentDate.formatted(.dateTime.locale(Locale(identifier: "zh_CN")).year().month().day().hour().minute()))
                            .font(.headline)
                        Spacer()
                        Text("心情指数: \(String(format: "%.1f", moodValue))")
                            .font(.subheadline)
                    }
                    .padding()
                    
                    // 日记编辑区域
                    TextEditor(text: $diaryText)
                        .frame(maxHeight: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    
                    // 媒体内容预览区
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(selectedImages.indices, id: \.self) { index in
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: selectedImages[index])
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 100)
                                        .cornerRadius(8)
                                        .onTapGesture {
                                            selectedImageForPreview = selectedImages[index]
                                        }
                                    
                                    // 删除按钮
                                    Button(action: {
                                        imageIndexToDelete = index
                                        showDeleteAlert = true
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.red)
                                            .background(Color.white.clipShape(Circle()))
                                    }
                                    .padding(4)
                                }
                            }
                        }
                        .padding()
                    }
                    
                    // 底部工具栏
                    HStack {
                        Button(action: { showImagePicker = true }) {
                            HStack {
                                Image(systemName: "photo.fill")
                                    .font(.title2)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.blue.opacity(0.7))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                        }

                    }
                    .padding()
                }
                .navigationBarItems(
                    leading: Button(action: {
                        if hasEdited {
                            saveDiary()
                        }
                        dismiss()
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.title2)
                    }
                )
                .sheet(isPresented: $showImagePicker) {
                    ImagePicker(selectedImages: $selectedImages)
                }
            }
            
            // 图片预览覆盖层
            if let previewImage = selectedImageForPreview {
                Color.black
                    .edgesIgnoringSafeArea(.all)
                    .opacity(0.9)
                    .overlay(
                        ZStack {
                            Image(uiImage: previewImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            
                            // 关闭按钮
                            VStack {
                                HStack {
                                    Spacer()
                                    Button(action: {
                                        selectedImageForPreview = nil
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.title)
                                            .foregroundColor(.white)
                                            .padding()
                                    }
                                }
                                Spacer()
                            }
                        }
                    )
                    .onTapGesture {
                        selectedImageForPreview = nil
                    }
            }
        }
        .alert("确认删除", isPresented: $showDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                if let index = imageIndexToDelete {
                    selectedImages.remove(at: index)
                    hasEdited = true
                }
            }
        } message: {
            Text("确定要删除这张图片吗？")
        }
        .onChange(of: diaryText) { oldValue, newValue in
            hasEdited = true
        }
        .onChange(of: selectedImages) { oldValue, newValue in
            hasEdited = true
        }
        .onChange(of: selectedVideos) { oldValue, newValue in
            hasEdited = true
        }
    }
    
    private func saveDiary() {
        if !diaryText.trim().isEmpty || !selectedImages.isEmpty || !selectedVideos.isEmpty {
            let diary = DiaryEntry(
                id: existingDiary?.id ?? UUID(),  // 保持原有ID
                date: existingDiary?.date ?? Date(),  // 保持原有日期
                mood: moodValue,
                content: diaryText,
                imageData: selectedImages.compactMap { $0.jpegData(compressionQuality: 0.7) },
                videoURLs: selectedVideos.map { $0.absoluteString }
            )
            DiaryManager.shared.saveDiary(diary)
        }
    }
}

// 图片选择器
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImages: [UIImage]
    @Environment(\.presentationMode) private var presentationMode
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.selectionLimit = 0
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            for result in results {
                result.itemProvider.loadObject(ofClass: UIImage.self) { image, error in
                    if let image = image as? UIImage {
                        DispatchQueue.main.async {
                            self.parent.selectedImages.append(image)
                        }
                    }
                }
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// 添加String扩展来处理空白字符
extension String {
    func trim() -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
