//
//  CreatePostViewModel.swift
//  CloudKitWithImage
//
//  Created by Juliano on 30/09/26.
//

import CloudKit
import PhotosUI
import SwiftUI

@Observable
@MainActor
final class CreatePostViewModel {
    var text = ""
    var photoSelection: PhotosPickerItem?
    var errorMessage: String?

    private(set) var selectedImage: Image?   // o que a View desenha (preview)
    private(set) var isSaving = false

    private var photoLocalURL: URL?          // o que o CloudKit consome (arquivo)
    
    private let service: any DataStreamServiceProtocol

    /// a variavel service permite injetar o MockedDataService no #Preview com init(passando o service),
    init(service: any DataStreamServiceProtocol) {
        self.service = service
    }
    /// e  sem tocar no CloudKit com o init() de verdade
    init() {
        self.service = CloudKitService.shared
    }

    var canSave: Bool { !text.isEmpty && !isSaving } // Só permite publicar se houver texto e nenhum salvamento estiver em andamento

    /// /// O que ela faz? A conversao de Data → UIImage → jpegData(0.7). Uma parte vai para selectedImage (a tela) e outra para photoLocalURL (a nuvem). A conversão para JPEG corrige um bug silencioso do código base: a galeria entrega HEIC, e você salvava com a extensão .jpg.
    func processPhotoSelection() async {
        guard let item = photoSelection else { return }

        do {
            guard
                let data = try await item.loadTransferable(type: Data.self),
                let uiImage = UIImage(data: data),
                let jpeg = uiImage.jpegData(compressionQuality: 0.7) /// transforma numa imagem mais leve
            else { return }

            discardTemporaryFile()                               // descarta a seleção anterior
            selectedImage = Image(uiImage: uiImage)              // var da View
            photoLocalURL = saveToTemporaryDirectory(data: jpeg) // var do CloudKit
        } catch {
            errorMessage = "Não foi possível carregar a foto."
        }
    }

    /// O que ela faz? chama o service, limpa o arquivo temporário e reseta o formulário.
    func createPost() async -> PostModel? {
        isSaving = true
        errorMessage = nil

        defer { isSaving = false } // defer significa rode isso por ultimo

        do {
            let post = try await service.save(
                text: text,
                photoURL: photoLocalURL
            )

            discardTemporaryFile() // só depois do upload concluído
            reset()

            return post

            // Em caso de erro o arquivo temporário continua lá: o retry funciona.
        } catch let error as CKError {
            print("CKError code:", error.code) // ajuda a gente a saber o erro que esta dando
            print("CKError:", error)
            print("userInfo:", error.userInfo)

            errorMessage = error.localizedDescription
            return nil

        } catch {
            print("Outro erro:", error)

            errorMessage = error.localizedDescription
            return nil
        }
    }

    /// Ponte Data -> URL. CKAsset só conhece arquivos em disco.
    private func saveToTemporaryDirectory(data: Data) -> URL? {
        let fileURL = URL.temporaryDirectory
            .appending(path: UUID().uuidString)   // cada seleção de imagem gera um arquivo único
            .appendingPathExtension("jpg")

        do {
            try data.write(to: fileURL, options: .atomic)
            return fileURL
        } catch {
            print("Erro ao salvar imagem no diretório temporário: \(error)")
            return nil
        }
    }
    /// apaga a ponte quando ela não é mais necessária.
    private func discardTemporaryFile() {
        guard let photoLocalURL else { return }
        try? FileManager.default.removeItem(at: photoLocalURL)
        self.photoLocalURL = nil
    }

    private func reset() {
        text = ""
        photoSelection = nil
        selectedImage = nil
    }
}
