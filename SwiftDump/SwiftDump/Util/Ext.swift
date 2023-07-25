//
//  Ext.swift
//  SwiftDump
//
//  Created by neilwu on 2020/6/26.
//  Copyright © 2020 nw. All rights reserved.
//

import Foundation

extension Array where Element == UInt8 {
    var hex: String {
        let tmp = self.reduce("") { (result, val:UInt8) -> String in
            return result + String(format: "%02x", val);
        }
        return tmp;
    }
}

extension String {
    func isAsciiStr() -> Bool {
        return self.range(of: ".*[^A-Za-z0-9_$ ].*", options: .regularExpression) == nil;
    }
    
    var hexData: Data { .init(hexa) }
    var hexBytes: [UInt8] { .init(hexa) }
    private var hexa: UnfoldSequence<UInt8, Index> {
        sequence(state: startIndex) { startIndex in
            guard startIndex < self.endIndex else { return nil }
            let endIndex = self.index(startIndex, offsetBy: 2, limitedBy: self.endIndex) ?? self.endIndex
            defer { startIndex = endIndex }
            return UInt8(self[startIndex..<endIndex], radix: 16)
        }
    }
    
    func toPointer() -> UnsafePointer<UInt8>? {
        guard let data = self.data(using: String.Encoding.utf8) else { return nil }
        
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: data.count)
        let stream = OutputStream(toBuffer: buffer, capacity: data.count)
        
        stream.open()
        data.withUnsafeBytes { (bp:UnsafeRawBufferPointer) in
            if let sp:UnsafePointer<UInt8> = bp.baseAddress?.bindMemory(to: UInt8.self, capacity: MemoryLayout<Any>.stride) {
                stream.write(sp, maxLength: data.count)
            }
        }
        
        stream.close()
        
        return UnsafePointer<UInt8>(buffer)
    }
    func toCharPointer() -> UnsafePointer<Int8> {
        let strPtr:UnsafePointer<Int8> = self.withCString { (ptr:UnsafePointer<Int8>) -> UnsafePointer<Int8> in
            return ptr;
        }
        return strPtr;
    }
    
    
    public func removingPrefix(_ prefix: String) -> String {
        guard hasPrefix(prefix) else { return self }
        return String(dropFirst(prefix.count))
    }
    public func removingSuffix(_ suffix: String) -> String {
        guard hasSuffix(suffix) else { return self }
        return String(dropLast(suffix.count))
    }
}



extension Int64 {
    var hex: String {
        return String(format: "0x%llx", self);
    }
}

extension UInt64 {
    var hex: String {
        return String(format: "0x%llx", self);
    }
}


extension Int {
    var hex: String {
        return String(format: "0x%llx", self);
    }
}
extension Int32 {
    var hex: String {
        return String(format: "0x%llx", self);
    }
}
extension UInt32 {
    var hex: String {
        return String(format: "0x%llx", self);
    }
}

extension Data {
    
    func readS8(offset: Int) -> Int8 {
        return readValue(offset) ?? 0
    }
    func readU8(offset: Int) -> UInt8 {
        return readValue(offset) ?? 0
    }
    
    func readS16(offset: Int) -> Int16 {
        return readValue(offset) ?? 0
    }
    
    func readS32(offset: Int) -> Int32 {
        return readValue(offset) ?? 0
    }
    
    func readU32(offset: Int) -> UInt32 {
        return readValue(offset) ?? 0
    }
    func readU64(offset: Int) -> UInt64 {
        return readValue(offset) ?? 0
    }
    
    
    func readValue<Type>(_ offset: Int) -> Type? {
        let val:Type? = self.withUnsafeBytes { (ptr:UnsafeRawBufferPointer) -> Type? in
            return ptr.baseAddress?.advanced(by: offset).loadUnaligned(as: Type.self);
        }
        return val;
    }
    
    func readCString(from: Int) -> String? {
        if (from >= self.count) {
            return nil;
        }
        var address: Int = (from);
        var result:[UInt8] = [];
        while true {
            let val: UInt8 = self[address];
            if (val == 0) {
                break;
            }
            address += 1;
            result.append(val);
        }
        
        if let str = String(bytes: result, encoding: String.Encoding.ascii) {
            if (str.isAsciiStr()) {
                return str;
            }
        }
        
        if (result.count > 10000) {
            return nil
        }
        
        let tmp = result.reduce("0x") { (result, val:UInt8) -> String in
            return result + String(format: "%02x", val);
        }
        return tmp;
    }
}




