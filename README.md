<p align="center">
    <img src="lingo.png" alt="Lingo logo" />
</p>

<p align="center">
	<img src="https://img.shields.io/badge/swift-3.1-brightgreen.svg" alt="swift 3.1"/>
	<img src="http://img.shields.io/badge/license-MIT-brightgreen.svg" alt="MIT License"/>
</p>

<p align="center">
    <a href="#features">Features</a>
  • <a href="#setup">Setup</a>
  • <a href="#usage">Usage</a>
  • <a href="#performance">Performance</a>
  • <a href="#license">License</a>
</p>

**Lingo** is a pure Swift localization library ready to be used in Server Side Swift project but not limited to those. 

## Features

* **Pluralization** - including custom language specific pluralization rules (CLDR compatible)
* **String interpolation**
* **Flexible data source** (read localizations from a JSON file, database or whatever suites your workflow the best)
* **Default locale** - if the localization for a requested locale is not available, it will fallback to the default one
* **Locale validation** - the library will warn you for using invalid locale identifiers (`en_fr` instead of `en_FR` etc.)

## Setup

There are two ways of integrating Lingo depending on whether you use Vapor or not:

### With Vapor

If you are using Vapor, we encourage you to use [LingoProvider](https://github.com/vapor-comunity/lingo-provider) which will provide seamless and native integration with Vapor. This way `Lingo` becomes part of `Droplet` and you will be able to get localizations even easier:

```swift
let localizedTitle = droplet.lingo.localize("welcome.title", locale: "en")
```

> LingoProvider is a separate package and and can be downloaded from [GitHub](https://github.com/vapor-comunity/lingo-provider). If you use LingoProvider you don't need the Lingo package dependency.

### Without Vapor

Add the dependency:

```swift
dependencies: [
	...,
	.Package(url: "https://github.com/miroslavkovac/Lingo.git", majorVersion: 2)
]
```

Optionally, if you are using Xcode, you can generate Xcode project by running:

```swift
swift package generate-xcodeproj
```

Create an instance of `Lingo` object passing the root directory path where the localization files are located:

```swift
import Vapor
import Lingo

let config = try Config()

// Create Lingo
let lingo = Lingo(rootPath: config.workDir.appending("Localizations"), defaultLocale: "en")

let droplet = try Droplet(config)
try drop.run()

```

## Usage

Use the following syntax for defining localizations in a JSON file:

```swift
{
	"title": "Hello Swift!",
	"greeting.message": "Hi %{full-name}!",
	"unread.messages": {
		"one": "You have an unread message.",
		"other": "You have %{count} unread messages."
	}
}
```

> Note that this syntax is compatible with `i18n-node-2`. This is can be useful in case you are using a 3rd party localization service which will export the localization files for you.

### Localization

You can retrieve localized string like this:

```swift
let localizedTitle = lingo.localize("title", locale: "en")

print(localizedTitle) // will print: "Hello Swift!"
```

### String interpolation

You can interpolate the localized strings like this:

```swift
let greeting = lingo.localize("greeting.message", locale: "en", interpolations: ["full-name": "John"])

print(greeting) // will print: "Hi John!"
```

### Pluralization

Lingo supports all Unicode plural categories as defined in [CLDR](http://cldr.unicode.org/index/cldr-spec/plural-rules):

* zero
* one
* two
* few
* many
* other

Example:

```swift
let unread1 = lingo.localize("unread.messages", locale: "en", interpolations: ["count": 1])
let unread24 = lingo.localize("unread.messages", locale: "en", interpolations: ["count": 24]) 

print(unread1) // Will print: "You have an unread message."
print(unread24) // Will print: "You have 24 unread messages."
```

Each language contains custom pluralization rules. Lingo currently implements rules for the following languages:
> ak, am, ar, az, be, bg, bh, bm, bn, bo, br, bs, by, ca, cs, cy, da, de\_AT, de\_CH, de\_DE, de, dz, el, en\_AU, en\_CA, en\_GB, en\_IN, en\_NZ, en, eo, es\_419, es\_AR, es\_CL, es\_CO, es\_CR, es\_EC, es\_ES, es\_MX, es\_NI, es\_PA, es\_PE, es\_US, es\_VE, es, et, eu, fa, ff, fi, fil, fr\_CA, fr\_CH, fr\_FR, fr, ga, gd, gl, guw, gv, he, hi\_IN, hi, hr, hsb, hu, id, ig, ii, it\_CH, it, iu, ja, jv, ka, kab, kde, kea, km, kn, ko, ksh, kw, lag, ln, lo, lt, lv, mg, mk, ml, mn, mo, mr\_IN, ms, mt, my, naq, nb, ne, nl, nn, nso, or, pa, pl, pt, ro, root, ru, sah, se, ses, sg, sh, shi, sk, sl, sma, smi, smj, smn, sms, sr, sv\_SE, sv, sw, th, ti, tl, to, tr, tzm, uk, ur, vi, wa, wo, yo, zh\_CN, zh\_HK, zh\_TW, zh\_YUE, zh

## Performance

In tests with a set of 1000 localization keys including plural forms, the library was able to handle:

* ~ 1M non interpolated localizations per second or 0.001ms per key.
* ~ 110K interpolated localizations per second or 0.009ms per key.

> String interpolation uses regular expressions under the hood, which can explain the difference in performance. All tests were performed on i7 4GHz CPU.

## Custom localizations data source

Although most of the time, the localizations will be defined in the JSON file, but if you prefer keeping them in a database, we've got you covered!

To implement a custom data source, all you need is to have an object that conforms to the `LocalizationDataSource` protocol:

```swift
public protocol LocalizationDataSource {   

    func availableLocales() -> [LocaleIdentifier]
    func localizations(`for` locale: LocaleIdentifier) -> [LocalizationKey: Localization]
    
}
```

So, let's say you are using MongoDB to store your localizations, all you need to do is to create a data source and pass it to Lingo's designated initializer:

```swift
let mongoDataSource = MongoLocalizationDataSource(...)
let lingo = Lingo(dataSource: mongoDataSource, defaultLocale: "en")
```

Lingo already includes `FileDataSource` conforming to this protocol, which, as you might guess, is wired up to the Longo's convenience initializer with `rootPath`.

## Note on locale identifiers

Although it is completely up to you how you name the locales, there is an easy way to get the list of all locales directly from `Locale` class:

```swift
#import Foundation

print(Locale.availableIdentifiers)
```

Just keep that in mind when adding a support for a new locale.

## Limitations

Currently the library doesn't support the case where different plural categories should be applied to different parts of the *same* localization string. For example, given the definition:

```
{
    "key": {
        "one": "You have 1 apple and 1 orange.",
        "other": "You have %{apples-count} apples and %{oranges-count} oranges."
    }
}
```

and passing numbers 1 and 7:

```swift
print(lingo.localize("key", locale: "en", interpolations: ["apples-count": 1, "oranges-count": 7]))

```

will print:

```
You have 1 apple and 7 orange.
```
> Note the missing *s* in the printed message.

This was done on purpose, and the reason for this was to keep the JSON file syntax simple and elegant (in contrast with iOS .stringsdict file and similar). If you still need to support a case like this, a possible workaround would be to split that string in two and combine it later in code.

## Further work

- Locale fallbacks, being RFC4647 compliant.
- Options for doubling the length of a localized string, which can be useful for debugging.
- Implement debug mode for easier testing and finding missing localizations.
- Support for non integer based pluralization rules

## License

MIT License. See the included LICENSE file.
