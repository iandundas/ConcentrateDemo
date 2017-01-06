//
//  The MIT License (MIT)
//
//  Copyright (c) 2016 Tony Arnold (@tonyarnold)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import AppKit
import ReactiveKit

public extension ReactiveExtensions where Base: NSTextField {

  public var font: Bond<NSFont?> {
    return bond { $0.font = $1 }
  }

  public var textColor: Bond<NSColor?> {
    return bond { $0.textColor = $1 }
  }

  public var backgroundColor: Bond<NSColor?> {
    return bond { $0.backgroundColor = $1 }
  }

  public var placeholderString: Bond<String?> {
    return bond { $0.placeholderString = $1 }
  }

  public var placeholderAttributedString: Bond<NSAttributedString?> {
    return bond { $0.placeholderAttributedString = $1 }
  }
}

extension NSTextField: BindableProtocol {

  public func bind(signal: Signal<String, NoError>) -> Disposable {
    return reactive.stringValue.bind(signal: signal)
  }
}
