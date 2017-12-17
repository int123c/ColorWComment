# ColorWComment

An Xcode Source Editor extension to convert hex color strings in comments to codes.

For Objective-C

```objc
UIColor *color =  // #338822aa

// will be converted into

UIColor *color = [UIColor colorWithRed:0.2 green:0.533333333333333 blue:0.133333333333333 alpha:0.666666666666667]; // #338822aa

// changing the hex string will convert it again

UIColor *color = [UIColor colorWithRed:0.00784313725490196 green:0.00784313725490196 blue:0.00784313725490196 alpha:1.0]; // #020202

```

For Swift

```swift
// defaultly color literal is used
let color = #colorLiteral(red: 0, green: 0.003921568627, blue: 0.1137254902, alpha: 0.6705882353) // #00011dAB

// if UIColor initializer was used before conversion, UIColor initializer will be used
let color2 = UIColor(red: 0.184313725490196, green: 0.941176470588235, blue: 0.8, alpha: 1.0) // #2FF0CC
```

