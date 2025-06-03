# ``Accelera``

Accelera library

## Overview

Small example how to initialize and use the library

```swift
let accelera = Accelera(
    config: AcceleraConfig(
        token: "Token",
        url: "https://flow2.accelera.ai",
        userId: "userId"
    )
)
accelera.delegate = self
accelera.logEvent(string: "{\"event\": \"some_event\"}")
accelera.loadBanner()
```
