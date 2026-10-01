//
//  PostPhotoView.swift
//  CloudKitWithImage
//
//  Created by Juliano on 30/09/26.
//

import SwiftUI
import UIKit

struct PostPhotoView: View {
    let url: URL
    @State private var image: UIImage? // vamos carregar via funcao load abaixo

    var body: some View {
        Group { /// só tamo aqui agrupando duas possibilidades de conteúdo para aplicar os mesmos modificadores, nao criando layout (VSTAck etc)
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ProgressView()
            }
        }
        .frame(maxWidth: .infinity, minHeight: 200, maxHeight: 250)
        .clipShape(.rect(cornerRadius: 8))
        .task(id: url) { image = await load(from: url) }
    }
    /// poderia estar numa viewModel? Sim, mas ela resolve coisa de UI, entao preferi deixar aqui e por só funcao de um componente de FeedView
    private func load(from url: URL) async -> UIImage? {
        UIImage(contentsOfFile: url.path) // se nao achar vai devolver nil
        }
}

#Preview() {
    PostPhotoView(url: PreviewImageGenerator.file(named: "preview-teal", color: .systemTeal))
        .padding()
}
