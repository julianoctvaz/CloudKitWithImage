//
//  CreatePostView.swift
//  CloudKitWithImage
//
//  Created by Juliano on 30/09/26.
//

import PhotosUI
import SwiftUI

struct CreatePostView: View {
    var onCreated: (PostModel) -> Void

    @State private var viewModel: CreatePostViewModel
    @Environment(\.dismiss) private var dismiss

    init(service: any DataStreamServiceProtocol = CloudKitService.shared,
        onCreated: @escaping (PostModel) -> Void
    ) {
        /// A injeção de dependência ocorre aqui, dai a razao do init,  porque a CreatePostView não cria internamente o serviço (objeto) do qual depende; ela recebe esse serviço de fora pelo init
        ///         /// aqui usamos OnCreate com: escaping pois ela indica que uma closure (funcao) pode ser armazenada e executada depois que a função que a recebeu já terminou.
        self.onCreated = onCreated
        _viewModel = State(initialValue: CreatePostViewModel(service: service)) /// So aceita que uma var @State é criada assim
    }

    var body: some View {
        NavigationStack {
            Form {
                PhotosPicker(selection: $viewModel.photoSelection, matching: .images, photoLibrary: .shared()) {
                    [selectedImage = viewModel.selectedImage] in
                    if let selectedImage {
                        selectedImage
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity, maxHeight: 250)
                            .clipShape(.rect(cornerRadius: 8))
                    } else {
                        Label("Selecionar a foto", systemImage: "photo.on.rectangle")
                            .foregroundStyle(.tint)
                    }
                }

                TextField("Legenda", text: $viewModel.text)
            }
            .navigationTitle("Novo post")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Publicar") {
                        Task {
                            print("1 - Clicou em publicar")

                            if let post = await viewModel.createPost() {
                                print("2 - Post criado:", post)
                                
                                onCreated(post)
                                
                                print("3 - Vai fechar")
                                dismiss()
                            } else {
                                print("4 - createPost retornou nil")
                            }
                        }
                    }
                    .disabled(!viewModel.canSave)
                }
            }
            /// Tirei o didSet { Task { ... } } do photoPickerItem lá na viewModel, pois poderia ter problemas se a pessoa trocasse a foto rapidamente. Com o ID ele cria um task por foto e já faz cancelamento automático da task quando a seleção muda.
            .task(id: viewModel.photoSelection) {
                await viewModel.processPhotoSelection()
            }
        }
    }
}

#Preview("Criar post") {
    @Previewable @State var isCreating = true // usamos esse @previewable pra conseguir testar aqui

    Button("Abrir") {
        isCreating = true
    }
    .sheet(isPresented: $isCreating) {
        CreatePostView(service: MockedDataService()) { post in
            print("Post criado: \(post.text)")
        }
    }
}
