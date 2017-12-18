//
//  SourceEditorCommand.swift
//  ColorWComment
//
//  Created by Shangxin Guo on 17/12/2017.
//  Copyright © 2017 Shangxin Guo. All rights reserved.
//

import Foundation
import XcodeKit

class SourceEditorCommand: NSObject, XCSourceEditorCommand {
    
    enum CommandError: Error, LocalizedError {
        case fileTypeNotSupported
        case failedToDecodeColor
        
        var errorDescription: String? {
            switch self {
            case .fileTypeNotSupported:
                return "This type of file is not support."
            case .failedToDecodeColor:
                return "Failed to decode color."
            }
        }
    }
    
    enum FileType: String {
        case objectiveC = "public.objective-c-source"
        case swift = "public.swift-source"
    }
    
    let matchingColorAfterComment = "//\\ ?#[0-9|a-z|A-Z]{6,8}"
    let matchingObjectiveCUIColor = "\\[UIColor.*?\\d\\ *?\\]"
    let matchingSwiftUIColor = "UIColor\\(.*?\\d\\ *?\\)"
    let matchingSwiftColorLiteral = "#colorLiteral\\(.*?\\d\\ *?\\)"
    
    func perform(
        with invocation: XCSourceEditorCommandInvocation,
        completionHandler: @escaping (Error?) -> Void 
    ) -> Void {
        
        guard let fileType = FileType(rawValue: invocation.buffer.contentUTI) else {
            completionHandler(CommandError.fileTypeNotSupported)
            return
        }
        
        for case let (index, line as String) in invocation.buffer.lines.enumerated() {
            guard let commentRange = find(pattern: matchingColorAfterComment, in: line) else { continue }
            guard let (r,g,b,a) = try? decodeColor(string: String(line[commentRange])) else { continue }
            
            switch fileType {
            case .objectiveC:
                let newString = "[UIColor colorWithRed:\(r) green:\(g) blue:\(b) alpha:\(a)]"
                if let range = find(pattern: matchingObjectiveCUIColor, in: line) {
                    let newLine = line.replacingCharacters(in: range, with: newString)
                    invocation.buffer.lines[index] = newLine
                } else {
                    let replacingIndex = line.index(before: commentRange.lowerBound)
                    let newLine = line.replacingCharacters(in: replacingIndex...replacingIndex, with: newString + "; ")
                    invocation.buffer.lines[index] = newLine
                }
            case .swift:
                let newStringUIColor = "UIColor(red: \(r), green: \(g), blue: \(b), alpha: \(a))"
                let newStringColorLiteral = "#colorLiteral(red: \(r), green: \(g), blue: \(b), alpha: \(a))"
                if let range = find(pattern: matchingSwiftUIColor, in: line) {
                    let newLine = line.replacingCharacters(in: range, with: newStringUIColor)
                    invocation.buffer.lines[index] = newLine // color
                } else if let range = find(pattern: matchingSwiftColorLiteral, in: line) {
                    let newLine = line.replacingCharacters(in: range, with: newStringColorLiteral)
                    invocation.buffer.lines[index] = newLine
                } else {
                    let replacingIndex = line.index(before: commentRange.lowerBound)
                    let newLine = line.replacingCharacters(in: replacingIndex...replacingIndex, with: newStringColorLiteral + " ")
                    invocation.buffer.lines[index] = newLine
                }
            }
        }
        
        completionHandler(nil)
    }
    
    func find(pattern: String, in string: String) -> Range<String.Index>? {
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(string.startIndex..., in: string)
        guard let result = regex.matches(in: string, options: [], range: range).last else { return nil }
        return Range(result.range, in: string)
    }
    
    func decodeColor(string: String) throws -> (r: Double, g: Double, b: Double, a: Double) {
        let matchingColor = "[0-9|a-z|A-Z]{6,8}"
        guard let range = find(pattern: matchingColor, in: string) else { throw CommandError.failedToDecodeColor }
        let hexString = string[range]
        
        var hexValue: UInt32 = 0
        let scanner = Scanner(string: String(hexString))
        scanner.scanHexInt32(&hexValue)
        
        switch hexString.count {
        case 6:
            let r = Double((hexValue & 0xff0000) >> 16) / 255.0
            let g = Double((hexValue & 0x00ff00) >> 8) / 255.0
            let b = Double((hexValue & 0x0000ff) >> 0) / 255.0
            return (r, g, b, 1)
        case 8:
            let r = Double((hexValue & 0xff000000) >> 24) / 255.0
            let g = Double((hexValue & 0x00ff0000) >> 16) / 255.0
            let b = Double((hexValue & 0x0000ff00) >> 8) / 255.0
            let a = Double((hexValue & 0x000000ff) >> 0) / 255.0
            return (r, g, b, a)
        default: throw CommandError.failedToDecodeColor
        }
    }
}
