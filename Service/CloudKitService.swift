//
//  CloudKitService.swift
//  CloudKitWithImage
//
//  Created by Juliano on 30/09/26.
//

import CloudKit

/// poderiamos ter uma final classe marcada com @MainActor, mas como só usamos async/await, não precisamos. Pois não fazemos coisas de UI aqui, e o async/await já garante que não teremos problemas de concorrência com o banco do CloudKit. Então podemos usar um actor mesmo, novo padrão. E queremos para rodar em background.
actor CloudKitService: DataStreamServiceProtocol {
    static let shared = CloudKitService()

    private let container = CKContainer.default()
    private let database: CKDatabase
    private let recordType = "Post"

    private init() {
        database = container.publicCloudDatabase

        print(
            "CloudKit Container é:",
            container.containerIdentifier ?? "nil"
        )
    }

    // MARK: - Criacao do post

    /// Recebe a URL de um arquivo que JÁ EXISTE no disco.
    /// Como CKAsset não aceita o tipo Data , só fileURL por isso o ViewModel grava antes.
    /// O que fazemos aqui? Monta o CKRecord, transforma o arquivo em CKAsset e faz o upload. Ele devolve um Post e nunca um CKRecord, para que o CloudKit não vaze para a View.
    func save(text: String, photoURL: URL?) async throws -> PostModel {
        let record = CKRecord(recordType: recordType) // que é Post
        record["text"] = text

        /// Tratamento de arquivo físico (Imagem)
        if let photoURL {
            record["photo"] = CKAsset(fileURL: photoURL)
        }

        /// O upload le o arquivo durante esta chamada.
        /// Apagar o arquivo antes do `await` terminar = upload quebrado.
        let saved = try await database.save(record)
        return makePost(from: saved)
    }

    // MARK: - Buscando o post

    /// Requer presetar ou verificar se já presetado no CloudKit Console:
    /// a variavel recordName como Queryable (por causa do NSPredicate(value: true))
    /// a variavel createdTimestamp (creationDate) como Sortable
    /// O que fazemos aqui? Usamos records(matching:resultsLimit:), a API async que substitui o CKQueryOperation com closures. Cada resultado vem como Result, então um registro com defeito não derruba a lista inteira.
    func fetchPosts(limit: Int = 50) async throws -> [PostModel] {
        let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true)) // recordType é Post
        ///DPS: vamos precisar configurar p recordName (variavel idenfiticadora de todo registro)  como queyrable no Cloudkit Console depois que rodarmos pela primeira vez para conseguir buscar aqui
        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        ///DPS: vamos precisar configurar essa variavel como sortable no Cloudkit Console depois que rodarmos pela primeira vez

        let (results, _) = try await database.records(matching: query, resultsLimit: limit)

        // Um registro com erro não derruba a lista inteira, a gente varre os que ta bons e joga fora os ruins
        return results.compactMap { _, result in
            guard let record = try? result.get() else { return nil }
            return makePost(from: record)
        }
    }

    // MARK: - Mapeando do CKRecord para o Post
    /// aqui a gente transforma o dado do cloudkit para a estrutura que queremos usar na view
    private func makePost(from record: CKRecord) -> PostModel {
        var photoURL: URL? = nil
        if let asset = record["photo"] as? CKAsset {
            photoURL = saveToTemporaryDirectory(asset, named: record.recordID.recordName)
        }

        return PostModel(
            id: record.recordID.recordName,
            text: record["text"] as? String ?? "",
            photoURL: photoURL,
            createdAt: record.creationDate ?? .now
        )
    }

    /// asset.fileURL aponta para uma área de staging gerenciada pelo CloudKit, que pode ser limpa depois do fetch. Copiamos para o Caches do app.
    /// O que fazemos aqui? O asset.fileURL retornado no fetch aponta para uma área de staging do CloudKit que pode ser limpa depois. Por isso seu photoUrl = asset.fileURL funciona na demo e quebra em produção. A função copia o arquivo para Caches/PostPhotos/<recordName>.jpg, com um nome estável que evita duplicatas.
    private func saveToTemporaryDirectory(_ asset: CKAsset, named name: String) -> URL? {
        guard let source = asset.fileURL else { return nil }

        let folder = URL.cachesDirectory.appending(path: "PostPhotos", directoryHint: .isDirectory)
        let destination = folder.appending(path: name).appendingPathExtension("jpg")
        let fileManager = FileManager.default

        do {
            try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
            if fileManager.fileExists(atPath: destination.path()) {
                try fileManager.removeItem(at: destination)
            }
            try fileManager.copyItem(at: source, to: destination)
            return destination
        } catch {
            print("Erro ao copiar asset para o cache: \(error)")
            return nil
        }
    }
}
