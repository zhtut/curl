# curl
curl ios and mac xcframework 

## how to use

### SPM

```swift
.package(name: "curl", url: "https://github.com/zhtut/curl.git", "7.8.0"..."10.0.0")

.target(name: "XXX",
        dependencies: [ "curl" ],
        linkerSettings: [ .linkedLibrary("z") ])

```

recommend use CFURLSessionInterface to import curl，easier to use

```swift
.package(url: "https://github.com/zhtut/CFURLSessionInterface.git", from: "0.1.0"),
```

### Cocoapods

```ruby
pod 'curl'
```
