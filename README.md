# fyyd_swift

`fyyd_swift` is a Swift package for the [fyyd](https://fyyd.de) API.

It includes:

- read access to podcasts, episodes, categories, users, curations, collections, alerts, and search
- authenticated account access
- write helpers for actions, curations, collections, alerts, and collect/curate state changes
- simple OAuth setup helpers and direct access-token injection

The package currently declares `iOS 18+` in `Package.swift`.

## Installation

Add the package in Xcode using the repository URL, or include it in SwiftPM:

```swift
dependencies: [
    .package(url: "<repository-url>", branch: "main")
]
```

Then import the library:

```swift
import fyyd_swift
```

## Quick Start

`FyydClient` is a typealias for `FyydSearchManager`.

```swift
import fyyd_swift

let client = FyydClient()

await client.setLanguage("de")

if let hot = await client.getHotPodcasts(count: 10) {
    print(hot.map(\.title))
}

if let podcasts = await client.searchPodcasts(query: "Swift", count: 20) {
    print(podcasts.count)
}
```

Most request methods are `async` and return an optional value. A `nil` result usually means one of these things:

- the request failed
- authentication was required but missing
- the response shape did not match
- the input combination was invalid, such as omitting both `userID` and `nick`

The package logs request failures to the console. The OAuth helper methods `exchangeCodeForToken(code:)` and `handleRedirect(url:)` are the main throwing entry points.

## Authentication

You can use the package without authentication for public fyyd endpoints. For account-specific reads and all write actions, initialize the client with fyyd app credentials or set an access token directly.

### OAuth client setup

Register an app with fyyd and configure a redirect URL in your app.

If you are using a custom URL scheme on iOS, add it to your app `Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>myapp</string>
        </array>
        <key>CFBundleURLName</key>
        <string>com.example.myapp</string>
    </dict>
</array>
```

Create the client with credentials:

```swift
let client = FyydClient(
    clientId: "your_client_id",
    clientSecret: "your_client_secret",
    redirectURI: "myapp://oauth/callback"
)
```

Start authorization:

```swift
if let url = await client.getAuthorizationURL() {
    UIApplication.shared.open(url)
}
```

Handle the callback URL:

```swift
func handleIncomingURL(_ url: URL) {
    Task {
        try? await client.handleRedirect(url: url)
    }
}
```

`handleRedirect(url:)` accepts both fragment-style token redirects and code-based redirects.

### Direct access token setup

If your app already manages authentication, you can inject the token directly:

```swift
let client = FyydClient()

await client.setAccessToken(
    "access-token",
    refreshToken: "refresh-token",
    expiresIn: 3600
)
```

You can clear state again with:

```swift
await client.clearAuthentication()
```

## Common Usage

### Discover podcasts

```swift
let hot = await client.getHotPodcasts(lang: "en", count: 25)
let languages = await client.getLanguages()
let newest = await client.getLatestPodcasts(count: 20)
let categories = await client.getCategories()
let discover = await client.getDiscoverPodcasts(count: 10)
```

### Search

Simple podcast title search:

```swift
let podcasts = await client.searchPodcasts(query: "freak show", count: 20)
```

More advanced search:

```swift
let podcasts = await client.searchPodcasts(
    title: "Freak Show",
    language: "de",
    generator: "Podlove",
    count: 20
)

let episodes = await client.searchEpisodes(
    term: "Thunderbolt",
    podcastTitle: "Freak Show",
    count: 10
)

let curations = await client.searchCurations(term: "netzpolitik", count: 10)
let users = await client.searchUsers(nick: "eazy", count: 10)
let byColor = await client.searchPodcastsByColor(rgb: "103424", count: 10)
```

### Podcast and episode details

```swift
let details = await client.getPodcast(podcastID: 85, includeEpisodes: true, page: 0, count: 50)
let season = await client.getPodcastSeason(podcastID: 703, seasonNumber: 2, count: 50)
let recommendations = await client.getPodcastRecommendations(forPodcastID: 85, count: 10)
let collections = await client.getPodcastCollections(podcastID: 85, count: 10, page: 0)

let episode = await client.getEpisode(id: 42)
let latestEpisodes = await client.getLatestEpisodes(count: 20)
let episodeCurations = await client.getEpisodeCurations(episodeID: 42, count: 10, page: 0)
```

### Categories and paging

If you only want the podcast list for a category:

```swift
let page = await client.getPodcastsByCategory(id: 52, count: 20, page: 0)
print(page?.paging?.nextPage as Any)
```

If you also want category metadata and parent category info:

```swift
let page = await client.getCategoryPodcasts(categoryID: 52, count: 20, page: 0)
print(page?.category?.title as Any)
print(page?.parent?.title as Any)
```

There is a similar richer response for curations by category:

```swift
let page = await client.getCurationsByCategory(categoryID: 52, count: 20, page: 0)
```

### Users and account

Public user data:

```swift
let userByID = await client.getUser(userID: 1000)
let userByNick = await client.getUser(nick: "eazy")
let userCurations = await client.getUserCurations(nick: "eazy", includeEpisodes: false)
let userCollections = await client.getUserCollections(nick: "eazy", includePodcasts: true)
```

Authenticated account data:

```swift
let account = await client.getAccountInfo()
let myCurations = await client.getAccountCurations()
let myCollections = await client.getAccountCollections()
```

## Write Operations

These methods require authentication.

### Actions

```swift
let ok = await client.createAction(
    objectID: 85,
    objectType: .podcast,
    actionName: "played",
    metadata: "2026-03-25"
)

let actions = await client.getActions(objectType: .podcast, actionName: "played")
let deleted = await client.deleteAction(actionID: 1)
```

### Curations

Create:

```swift
let created = await client.saveCuration(
    title: "My picks",
    description: "Interesting episodes",
    isPublic: true,
    categoryIDs: [52, 39]
)
```

Update:

```swift
let updated = await client.saveCuration(
    curationID: 601,
    title: "Updated title",
    slug: "updated-title"
)
```

Add or remove an episode:

```swift
let state = await client.curate(
    curationID: 601,
    episodeID: 42,
    why: "Worth recommending",
    forceState: true
)
```

Read state or fetch content:

```swift
let curation = await client.getCuration(id: 601, includeEpisodes: true)
let curateState = await client.getCurateState(curationID: 601, episodeID: 42)
let deleted = await client.deleteCuration(id: 601)
```

### Collections

```swift
let collection = await client.saveCollection(
    title: "Daily listening",
    description: "Podcasts to keep an eye on",
    isPublic: true
)

let state = await client.collect(collectionID: 1, podcastID: 85, forceState: true)
let collectState = await client.getCollectState(collectionID: 1, podcastID: 85)
let detailed = await client.getCollection(id: 1, includePodcasts: true)
let deleted = await client.deleteCollection(id: 1)
```

### Alerts

```swift
let alert = await client.saveAlert(term: "swift")
let detailed = await client.getAlert(id: 4711, includeEpisodes: true)
let deleted = await client.deleteAlert(id: 4711)
```

### Podcast owner action

```swift
let ok = await client.performPodcastAction(podcastID: 85, action: .check)
```

## Image Uploads

`saveCuration` and `saveCollection` accept an optional `FyydUploadImage`.

```swift
let image = FyydUploadImage(
    data: imageData,
    filename: "cover.jpg",
    mimeType: "image/jpeg"
)

let curation = await client.saveCuration(
    title: "Cover test",
    image: image
)
```

## Main Return Types

The most important model types are:

- `FyydPodcast`
- `FyydEpisode`
- `FyydUser`
- `FyydCategory`
- `FyydCuration`
- `FyydCollection`
- `FyydAlert`

Paged or enriched responses use:

- `FyydPodcastListWithPaging`
- `FyydCollectionListWithPaging`
- `FyydCurationListWithPaging`
- `FyydPodcastDetails`
- `FyydCategoryPodcastsPage`
- `FyydCategoryCurationsPage`
- `PagingInfo`

State-changing helpers like `curate` and `collect` return `FyydStateChange`.

## Notes

- `FyydClient` is actor-based, so it is safe to share across tasks.
- Public methods are grouped closely to fyyd API sections, so the package should feel predictable if you know the fyyd docs.
- `getPodcastRecommendations(forPodcastID:podcastSlug:count:)` is the main recommendation method for a specific podcast.
- There is also a legacy convenience method `getPodcastRecommendations(count:)` to preserve the previous package surface.
