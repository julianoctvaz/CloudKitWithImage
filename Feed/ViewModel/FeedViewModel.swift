//
//  FeedViewModel.swift
//  CloudKitWithImage
//
//  Created by Juliano on 30/09/26.
//

import Foundation
import CloudKit

@Observable
@MainActor
final class FeedViewModel {
    /// private(set) significa visivel para leitura, mas não para escrita fora da classe
    private(set) var posts: [PostModel] = []
    private(set) var isLoading = false
    var errorMessage: String?

    private let service: any DataStreamServiceProtocol

    /// a variavel service permite injetar o MockedDataService no #Preview com init(passando o service),
    init(service: any DataStreamServiceProtocol) {
        self.service = service
    }
    /// e  sem tocar no CloudKit com o init() de verdade
    init() {
        self.service = CloudKitService.shared
    }

    func load() async {
        isLoading = true
        defer { isLoading = false } ///defer significa rode isso por ultimo

        do {
            posts = try await service.fetchPosts(limit: 50)
        } catch let error as CKError {
            print("CKError code:", error.code) // ajuda a gente a saber o erro que esta dando
            print("CKError:", error)
            print("userInfo:", error.userInfo)

            errorMessage = error.localizedDescription
        } catch {
            print("Outro erro:", error)
            errorMessage = error.localizedDescription
        }
    }

    /// Inserção otimista: o índice do CloudKit é eventualmente consistente, então um fetch logo após o save pode ainda não trazer o post novo.
    func insert(_ post: PostModel) {
        posts.insert(post, at: 0)
    }
}
