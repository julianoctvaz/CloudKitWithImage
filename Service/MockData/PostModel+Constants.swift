//
//  PostModel+Constants.swift
//  CloudKitWithImage
//
//  Created by Juliano on 30/09/26.
//

import UIKit ///para usar algumas da propriedades abaixo

#if DEBUG

/// So em espaço de desenvolvimento que será usado para mostrar no preview

extension PostModel {
    /// A variavel photoURL precisa ser um ARQUIVO real, porque o PostPhotoView lê do disco.
    /// Por isso as amostras geram JPEGs de verdade no diretório temporário.
    static let samples: [PostModel] = [
        PostModel(
            id: "sample-1",
            text: "Primeiro protótipo do Challenge",
            photoURL: PreviewImageGenerator.file(named: "sample-1", color: .systemTeal),
            createdAt: .now.addingTimeInterval(-300)
        ),
        PostModel(
            id: "sample-2",
            text: "Post sem foto: testa o layout só com texto",
            photoURL: nil,
            createdAt: .now.addingTimeInterval(-3_600)
        ),
        PostModel(
            id: "sample-3",
            text: "Pôr do sol no Recife Antigo",
            photoURL: PreviewImageGenerator.file(named: "sample-3", color: .systemOrange),
            createdAt: .now.addingTimeInterval(-86_400)
        ),
    ]
}
#endif
