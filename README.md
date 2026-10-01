# CloudKitWithImage

Exemplo de aplicação SwiftUI utilizando **CloudKit** para salvar e consultar posts contendo texto e imagem.

## Imagens entre SwiftUI, PhotosUI e CloudKit

Um dos pontos importantes deste projeto é entender que uma imagem passa por diferentes representações dependendo de onde está sendo utilizada.

| Mundo | Tipo | Framework / Uso |
|---|---|---|
| Galeria | `PhotosPickerItem → Data` | PhotosUI |
| Tela | `Image` | SwiftUI |
| Nuvem | `URL de arquivo → CKAsset` | CloudKit |

Ou seja, a imagem não permanece no mesmo tipo durante todo o fluxo.

De forma simplificada:

```text
PhotosPickerItem
       ↓
      Data
       ↓
     UIImage
      ↙   ↘
 Image     JPEG
SwiftUI     ↓
           URL temporária
                ↓
              CKAsset
                ↓
             CloudKit
```

A `URL` é necessária porque o `CKAsset` trabalha com um arquivo armazenado localmente.

---

# Configuração do CloudKit

## 1. Adicionar a capability do CloudKit

No Xcode, abra:

```text
Target
→ Signing & Capabilities
→ + Capability
→ iCloud
```

Marque **CloudKit** e selecione ou crie o container que será utilizado pelo projeto.

Neste projeto:

```text
iCloud.Academy.UFPE.CloudKitWithImage
```

Depois, acesse o portal do Apple Developer e entre em:

```text
Identifiers
→ App IDs
→ [Bundle ID do projeto]
→ iCloud
```

Confirme que **iCloud + CloudKit** estão habilitados.

Em **Edit**, confirme também que o container utilizado pelo projeto está associado ao App ID.

Por exemplo:

```text
☑ iCloud.Academy.UFPE.CloudKitWithImage
```

### Atualizar o provisioning profile

Depois de alterar a configuração do CloudKit, pode ser necessário atualizar a assinatura utilizada pelo projeto.

Com assinatura automática, abra:

```text
Xcode
→ Target
→ Signing & Capabilities
→ Signing
```

Remova e selecione novamente o **Team** para atualizar a configuração de assinatura.

Depois execute:

```text
Product
→ Clean Build Folder
```

Se o aplicativo já tiver sido instalado anteriormente e continuar apresentando problemas de configuração, apague também o app do dispositivo ou Simulator e execute novamente pelo Xcode.

---

## 2. Conferir os Entitlements

O arquivo `CloudKitWithImage.entitlements` deve conter as configurações necessárias para o CloudKit.

Para Development:

```xml
<key>aps-environment</key>
<string>development</string>

<key>com.apple.developer.icloud-container-identifiers</key>
<array>
    <string>iCloud.Academy.UFPE.CloudKitWithImage</string>
</array>

<key>com.apple.developer.icloud-services</key>
<array>
    <string>CloudKit</string>
</array>
```

Um erro como:

```text
Bad Container

Couldn't get container configuration from the server
```

indica que o aplicativo não conseguiu acessar a configuração do container.

Nesse caso, confira principalmente:

```text
Entitlements
      ↓
App ID
      ↓
iCloud Container Assignment
      ↓
CloudKit Container
      ↓
Provisioning Profile
```

O identificador do container deve ser consistente entre essas configurações.

---

## 3. Gerar o schema em Development

Inicialmente, o banco ainda pode não possuir o `Record Type` utilizado pelo aplicativo.

Nesse caso, o primeiro carregamento pode apresentar um erro semelhante a:

```text
Did not find record type: Post
```

Durante o desenvolvimento, rode o aplicativo pelo Xcode e publique um **post completo**, contendo:

- legenda;
- foto.

O primeiro `save` permite que o CloudKit crie o `Record Type` utilizado pelo projeto e seus respectivos campos.

Neste projeto:

```text
Post
├── text  : String
└── photo : Asset
```

> **Atenção:** se o primeiro registro for salvo sem foto, o campo `photo` pode ainda não existir no schema.

Também é importante utilizar os tipos corretos desde o início. Durante o desenvolvimento, caso seja necessário reconstruir o schema, é possível utilizar **Reset Development Environment** no CloudKit Console.

---

## 4. Conferir o schema no CloudKit Console

Abra o **CloudKit Console** e acesse:

```text
Development
→ Schema
→ Record Types
→ Post
```

Confirme a existência dos campos utilizados pelo aplicativo:

| Campo | Tipo |
|---|---|
| `text` | String |
| `photo` | Asset |

---

## 5. Configurar os índices

Os índices utilizados pelas queries devem ser configurados no CloudKit Console.

Acesse:

```text
Schema
→ Indexes
→ Post
```

Para a consulta utilizada neste projeto, configure os índices necessários para permitir a consulta dos registros e sua ordenação.

O projeto utiliza:

```swift
let query = CKQuery(
    recordType: "Post",
    predicate: NSPredicate(value: true)
)

query.sortDescriptors = [
    NSSortDescriptor(
        key: "creationDate",
        ascending: false
    )
]
```

Portanto, confira os índices correspondentes no schema, incluindo os necessários para consulta e ordenação.

No CloudKit Console, acesse:

**Schema → Indexes → Post**

Caso o campo utilizado pela consulta não esteja marcado como **Queryable**, o CloudKit pode retornar:

```text
Field 'recordName' is not marked queryable
```

Nesse caso, configure o índice correspondente como **Queryable**.

Da mesma forma, como o projeto ordena os posts por `creationDate` (creationDataStamp), o CloudKit precisa permitir a ordenação pelo campo de criação. Caso esse índice não esteja configurado, pode ocorrer:

```text
Field '_createdTime' is not marked sortable
```

Nesse caso, no CloudKit Console, configure o campo de criação correspondente como **Sortable**.

Em resumo, para a consulta deste projeto, os índices devem permitir:

| Campo | Índice |
|---|---|
| `recordName` | `Queryable` |
| Campo de data de criação (`_createdTime`) | `Sortable` |

> **Observação:** o nome apresentado no CloudKit Console e o nome interno exibido na mensagem de erro podem ser diferentes. `_createdTime` na mensagem de erro está relacionado ao campo de data de criação utilizado pela ordenação com `creationDate`.

<img width="566" height="572" alt="image" src="https://github.com/user-attachments/assets/95cb0458-4287-406e-aced-8eacf79e7628" />
Os indexes de text foram gerados automaticamente.

---

## 6. Development x Production

O CloudKit possui ambientes separados:

```text
Development
Production
```

Durante o desenvolvimento pelo Xcode, trabalhamos com o ambiente **Development**.

Antes de distribuir o aplicativo pelo **TestFlight** ou pela **App Store**, é necessário enviar o schema para **Production**.

No CloudKit Console:

```text
Development
→ Deploy Schema Changes…
→ Production
```

O schema utilizado durante o desenvolvimento não deve ser considerado automaticamente disponível em Production.

Por isso, antes de distribuir uma build, confirme que os `Record Types`, campos e índices necessários foram enviados para o ambiente de Production.

---

## Fluxo geral

```text
Xcode
  │
  ├── Signing & Capabilities
  │       └── CloudKit
  │
  ├── Entitlements
  │       └── iCloud Container
  │
  ▼
Apple Developer
  │
  ├── App ID
  │       └── Container Assignment
  │
  ▼
CloudKit
  │
  ├── Development
  │     ├── Record Types
  │     ├── Fields
  │     └── Indexes
  │
  └── Production
        └── Schema publicado
```

## Tecnologias

- Swift
- SwiftUI
- PhotosUI
- CloudKit
- Swift Concurrency (`async`/`await`)
