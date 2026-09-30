//
//  PreviewImage.swift
//  CloudKitWithImage
//
//  Created by Juliano on 30/09/26.
//

import UIKit

#if DEBUG
/// So em espaço de desenvolvimento que será usado para mostrar no preview

/// Gera uma imagem sólida e grava como JPEG.
/// Mesmo caminho do app real: Data -> arquivo -> URL. Sem depender de assets no catálogo.
enum PreviewImageGenerator {
    static func file(named name: String, color: UIColor) -> URL {
        let url = URL.temporaryDirectory
            .appending(path: name)
            .appendingPathExtension("jpg")

        let renderer = UIGraphicsImageRenderer(
            size: CGSize(width: 800, height: 600)
        )

        let image = renderer.image { context in
            color.setFill()
            context.fill(
                CGRect(x: 0, y: 0, width: 800, height: 600)
            )
        }

        guard let data = image.jpegData(compressionQuality: 0.8) else   {
            fatalError("Não foi possível gerar o JPEG do Preview.")
        }

        do {
            try data.write(to: url, options: .atomic)
        
            print("GERADOR:")
            print("Bytes em memória:", data.count)

            let diskData = try! Data(contentsOf: url)
            print("Bytes no disco:", diskData.count)

            let testImage = UIImage(data: diskData)
            print("UIImage a partir do Data:", testImage != nil)

            let testFile = UIImage(contentsOfFile: url.path)
            print("UIImage a partir do arquivo:", testFile != nil)

        } catch {
            fatalError("Não foi possível salvar a imagem: \(error)")
        }

        return url
    }
}

#endif
