//
//  FeedView.swift
//  CloudKitWithImage
//
//  Created by Juliano on 30/09/26.
//

import PhotosUI
import SwiftUI

struct FeedView: View {
    
    @State private var viewModel: FeedViewModel
    @State private var isCreating = false
    
    private let service: any DataStreamServiceProtocol // pode ser o cloudkit ou o mockado
    
    init(service: any DataStreamServiceProtocol = CloudKitService.shared as DataStreamServiceProtocol) {
        /// A injeção de dependência ocorre aqui, dai a razao do init,  porque a FeedView não cria internamente o serviço (objeto) do qual depende; ela recebe esse serviço de fora pelo init
        self.service = service
        _viewModel = State(initialValue: FeedViewModel(service: service)) /// So aceita que uma var @State é criada assim
    }
    
    var body: some View {
        NavigationStack {
            List(viewModel.posts) { post in
                VStack(alignment: .leading, spacing: 8) {
                    if let url = post.photoURL {
                        PostPhotoView(url: url)
                    }
                    Text(post.text)
                        .font(.headline)
                    Text(post.createdAt, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
            .overlay { /// a gente vai colocar uma tela em cima caso:
                //1 - Está carregando e ainda não existem posts
                if viewModel.isLoading && viewModel.posts.isEmpty {
                    ProgressView()
                    
                // 2 - O carregamento falhou e não existem posts para exibir
                } else if let errorMessage = viewModel.errorMessage,
                          viewModel.posts.isEmpty {
                    
                    ContentUnavailableView {
                        Label(
                            "Não foi possível carregar",
                            systemImage: "exclamationmark.triangle"
                        )
                    } description: {
                        Text("O erro é: " + errorMessage)
                    } actions: {
                        Button("Tentar novamente") {
                            Task {
                                await viewModel.load()
                            }
                        }
                    }
                    
                // 3 - Terminou de carregar sem erro, mas nenhum post foi encontrado
                } else if viewModel.posts.isEmpty {
                    ContentUnavailableView(
                        "Nenhum post",
                        systemImage: "rectangle.stack",
                        description: Text("Os posts publicados aparecerão aqui.")
                    )
                }
            }
            .navigationTitle("Posts")
            .toolbar {
                Button("Novo post", systemImage: "plus") { isCreating = true }
            }
            .refreshable { await viewModel.load() } }
        /// Adiciona pull-to-refresh e mantém o indicador enquanto load() executa. Um ícone circular animado aparece no topo da tela mostrando que o aplicativo está buscando novos dados.
            
        .task { await viewModel.load() }
        .sheet(isPresented: $isCreating) {
            CreatePostView(service: service) { post in viewModel.insert(post) }
        }
    }
}



#Preview("Feed") {
    FeedView(service: MockedDataService())
}

#Preview("Feed vazio") {
    FeedView(service: MockedDataService(posts: []))
}

#Preview("Feed com erro") {
    FeedView(service: MockedDataService(shouldFail: true))
}
