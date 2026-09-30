//
//  Post.swift
//  CloudKitWithImage
//
//  Created by Juliano on 30/09/26.
//

import Foundation

struct PostModel: Identifiable, Hashable {
    let id: String
    let text: String
    let photoURL: URL?
    /// arquivo LOCAL (cópia no Caches), não a URL do CKAsset
    let createdAt: Date
    /// se for usar dentro do post precisa!
}
