//===--- Markdown.swift ----------------------------------------------------===//
//
//Copyright (c) 2016 Daniel Leping (dileping)
//
//This file is part of Markdown.
//
//Swift Express is free software: you can redistribute it and/or modify
//it under the terms of the GNU Lesser General Public License as published by
//the Free Software Foundation, either version 3 of the License, or
//(at your option) any later version.
//
//Swift Express is distributed in the hope that it will be useful,
//but WITHOUT ANY WARRANTY; without even the implied warranty of
//MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//GNU Lesser General Public License for more details.
//
//You should have received a copy of the GNU Lesser General Public License
//along with Swift Express.  If not, see <http://www.gnu.org/licenses/>.
//
//===----------------------------------------------------------------------===//

import CDiscount

private typealias PMMIOT = UnsafeMutablePointer<Void>
private typealias MKDFUN = (PMMIOT, UnsafeMutablePointer<UnsafeMutablePointer<Int8>>) -> Int32

public class Markdown {
    private let _markdown:PMMIOT
    
    private init(markdown:PMMIOT, options:Options) throws {
        self._markdown = markdown
        let result = mkd_compile(markdown, options.rawValue)
        if result <= 0 {
            throw Error.Compile(code: result)
        }
    }
    
    deinit {
        mkd_cleanup(_markdown)
    }
    
    public convenience init(string:String, options:Options = .None) throws {
        try self.init(markdown: mkd_string(string, Int32(string.characters.count), 0), options: options)
    }
    
    private func data(fun:MKDFUN, deallocator:UnsafeMutablePointer<Int8>->Void) throws -> String {
        var dest = [UnsafeMutablePointer<Int8>](count: 1, repeatedValue: UnsafeMutablePointer<Int8>.alloc(1))
        
        let result = fun(_markdown, &dest)
        defer {
            if result >= 0 {
                deallocator(dest[0])
            }
        }
        if result < 0 {
            throw Error.Produce(code: result)
        }
        
        guard let string = String.fromCString(dest[0]) else {
            return ""
        }
        
        return string
    }
    
    public func document() throws -> String {
        return try data(mkd_document) { pointer in
        }
    }
    
    public func css() throws -> String {
        return try data(mkd_css) { pointer in
        }
    }
    
    public func tableOfContents() throws -> String {
        return try data(mkd_toc) { pointer in
        }
    }
    
    public var title:String? {
        get {
            return String.fromCString(mkd_doc_title(_markdown))
        }
    }
    
    public var author:String? {
        get {
            return String.fromCString(mkd_doc_author(_markdown))
        }
    }
    
    public var date:String? {
        get {
            return String.fromCString(mkd_doc_date(_markdown))
        }
    }
}