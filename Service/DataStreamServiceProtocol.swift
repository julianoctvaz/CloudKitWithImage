//
//  DataStreamService.swift
//  CloudKitWithImage
//
//  Created by Juliano on 30/09/26.
//

import Foundation

/// Esse protocolo cria um contrato para o que cada a fonte dos posts deve fazer (CloudKit em produção, `MockedDataService` em #Preview),É sendable pois fazemos em tempo de compilacao a verificacao de segurança da concorrência do Swift. No Swift moderno, é melhor pensar em domínios de isolamento (actor, @MainActor, tasks etc.)
protocol DataStreamServiceProtocol: Sendable {
    func fetchPosts(limit: Int) async throws -> [PostModel]
    func save(text: String, photoURL: URL?) async throws -> PostModel
}
