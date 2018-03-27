# Gnomon

[![Build Status](https://travis-ci.org/netcosports/Gnomon.svg?branch=master)](https://travis-ci.org/netcosports/Gnomon)
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/Gnomon.svg)](http://cocoapods.org/pods/Gnomon)

## Yet another networking library?

Why did we decide to develop a new networking library?

1. **HTTP cache for better UX**. It's better to display outdated content than showing to user infinite loading indicator. To achieve this Gnomon is able to perform two-in-one requests: first request to receive cached content (optional) and second request to make an HTTP call. Furthermore, the library will return cached version even if there is no internet connection.

1. **RxSwift interface**. We decided that it is much easier to handle such compound responses with help of Rx observables:
the first `.next` event comes with a cached response, the second – with an actual response from web server.

1. **Models instead of Data as request result**. This is the usual step after app received Data – parse it to some model. We found it better to let library user skip this phase: every request has a generic parameter – response model type. As result subscriber receives model or array of models instead of plain Data.

## Installation

```ruby
pod 'Gnomon', '~> 3.0'
```

## Usage

### Define a model

We defined flexible generic protocol [`BaseModel`](https://github.com/netcosports/Gnomon/blob/c50cfd2a040b0093db040596a3bddcd5b96f5c5d/Sources/Core/Response.swift#L8) and several extensions for it ([`JSONModel`](https://github.com/netcosports/Gnomon/blob/c50cfd2a040b0093db040596a3bddcd5b96f5c5d/Sources/JSON/JSONModel.swift), [`XMLModel`](https://github.com/netcosports/Gnomon/blob/c50cfd2a040b0093db040596a3bddcd5b96f5c5d/Sources/XML/XMLModel.swift), [`DecodableModel`](https://github.com/netcosports/Gnomon/blob/c50cfd2a040b0093db040596a3bddcd5b96f5c5d/Sources/Decodable/Decodable.swift#L111)).

In most cases, we use `JSONModel`, which uses SwiftyJSON as a parser and provides a lightweight interface for model properties parsing.

```swift
import Gnomon
import SwiftyJSON

struct UserModel: JSONModel {

  let id: Int
  let login: String
  let avatarUrl: URL?
  let profileUrl: URL?

  init(_ json: JSON) throws {
    id = json["id"].intValue
    login = json["login"].stringValue
    avatarUrl = json["avatar_url"].url
    profileUrl = json["html_url"].url
  }

}
```

### Prepare a request

We have a flexible [`RequestBuilder`](https://github.com/netcosports/Gnomon/blob/11a28545c85edb6d7f259847d47e649d83b6f0d6/Sources/Request.swift#L84) which requires only URL string as an argument but provides builder interface to construct your complex HTTP request.

There are 4 `Result` types in the library – they configure how the library will parse your response:
- `SingleResult<T>` single model `T`, the request fails if parsing fails
- `MultipleResults<T>` array of model `T`, the request fails if parsing fails
- `SingleOptionalResult<T>` single optional model `T?`, request returns `nil` if parsing fails
- `MultipleOptionalResults<T>` array of optional models `T?`, request returns a mixed array of models and `nil`s if parsing fails

```swift
func prepareRequest() throws -> Request<MultipleOptionalResults<UserModel>> {
  return try RequestBuilder()
    .setURLString("https://api.github.com/users").build()
}
```

This API call returns us array of dictionaries, but we often meet calls which return multi-layered JSON where we need to parse only one part. In this case you can add `setXPath()` to your builder with path divided by `/` (e.g. `"document/result/data"`).

### Make an observable and subscribe to it

As we wrote above Gnomon interface is RxSwift-based – when you want to make a request you need to create an observable and then subscribe to it.

```swift
import RxSwift

let disposeBag = DisposeBag()

func loadData() {
  do {
    let request = try prepareRequest()
    Gnomon.cachedThenFetch(request).subscribe(onNext: { response in
      print(response.result.models)
    }).disposed(by: disposeBag)
  } catch {
    print("can't prepare request: \(error)")
  }
}
```

When we run this code first time we will see two logs in stdout: empty array and array of optional `UserModel`s.
After first call URLSession will store response in shared URLCache and on next call we will receive equal arrays twice.

You can optimize your UI updating logic by omitting UI update if you received cached version as second response. It possible because of URLSession internal logic: it checks cache expiration / validity by itself and can return cached response twice.
You can detect HTTP cache result by `response.responseType` property.

```swift
import RxSwift

let disposeBag = DisposeBag()

func loadData() {
  do {
    let request = try prepareRequest()
    Gnomon.cachedThenFetch(request).subscribe(onNext: { [weak self] response in
      guard response.responseType != .httpCache else { return }
      self?.updateUI(with: response.result.models)
    }).disposed(by: disposeBag)
  } catch {
    print("can't prepare request: \(error)")
  }
}

func updateUI(with models: [UserModel?]) {}
```

## Astrolabe

Gnomon is the best friend of [Astrolabe](https://github.com/netcosports/Astrolabe) :)

You can easily transform your models to cells for UITableView or UICollectionView with help of Astrolabe and [Loaders](https://github.com/netcosports/Astrolabe/tree/master/Sources/Loaders).

```swift
import Astrolabe
import Gnomon

class UsersViewController: UIViewController, Loader {
  let tableView = TableView<LoaderDecoratorSource<TableViewSource>>
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    tableView.source.loader = self
  }

  func performLoading(intent: LoaderIntent) -> SectionObservable? {
    return Astrolabe.load(pLoader: self, intent: intent)
  }
}

extension UsersViewController: PLoader {
  typealias PLResult = MultipleOptionalResults<UserModel>
  
  func request(for loadingIntent: LoaderIntent) throws -> Request<PLResult> {
    return try RequestBuilder()
      .setURLString("https://api.github.com/users").build()
  }
  
  func sections(from result: PLResult, loadingIntent: LoaderIntent) -> [Sectionable]? {
    let users = result.models.flatMap { $0 }
    return [Section(cells: users.map { TableCell<UserTableViewCell>(data: $0) })]
  }
}

```
