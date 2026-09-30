//
//  MockedDataService.swift
//  CloudKitWithImage
//
//  Created by Juliano on 30/09/26.
//

#if DEBUG

import UIKit
/// So em espaço de desenvolvimento que será usado para mostrar no preview

/// Mock do servico: nada de rede, nada de iCloud, nada de índice.
struct MockedDataService: DataStreamServiceProtocol {
    var posts: [PostModel] = PostModel.samples
    var delay: Duration = .milliseconds(600) /// para mostrar o ProgressView aparecer no canvas
    var shouldFail = false ///shouldFail para fazer o o caminho de triste (de erro) ai setaria ela pra true

    func save(text: String, photoURL: URL?) async throws -> PostModel {
        try await Task.sleep(for: delay)

        if shouldFail { throw URLError(.notConnectedToInternet) }

        var savedPhotoURL: URL?

        if let photoURL {
            let destination = URL.temporaryDirectory
                .appending(path: UUID().uuidString)
                .appendingPathExtension("jpg")

            try FileManager.default.copyItem(at: photoURL, to: destination)

            savedPhotoURL = destination
        }

        return PostModel(
            id: UUID().uuidString,
            text: text,
            photoURL: savedPhotoURL,
            createdAt: .now)
    }

    func fetchPosts(limit: Int) async throws -> [PostModel] {
        try await Task.sleep(for: delay)
        if shouldFail { throw URLError(.notConnectedToInternet) }
        return Array(posts.prefix(limit)) /// pega os primeiros em ordem desse valor de limite
    }
}

#endif
