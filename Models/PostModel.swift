//
//  Post.swift
//  CloudKitWithImage
//
//  Created by Juliano on 30/09/26.
//

import Foundation

/// protocolos: usamos identifiable pois vamos usar uma List na view e queremos poder listar de maneira mais direta. mas poderiamos ter outros caso tivessemos outras necessidades
struct PostModel: Identifiable {
    let id: String
    let text: String
    let photoURL: URL?
    /// arquivo LOCAL (cópia no Caches), não a URL do CKAsset
    let createdAt: Date
    /// se for usar dentro do post precisa de uma var assim!
}
