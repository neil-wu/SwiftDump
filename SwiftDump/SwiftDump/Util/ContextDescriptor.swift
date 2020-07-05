//
//  File.swift
//  SwiftDump
//
//  Created by neilwu on 2020/6/26.
//  Copyright © 2020 nw. All rights reserved.
//

import Foundation


// https://github.com/apple/swift/blob/a021e6ca020e667ce4bc8ee174e2de1cc0d9be73/include/swift/ABI/MetadataValues.h#L1183
enum SDContextDescriptorKind: UInt8, CustomStringConvertible {
    /// This context descriptor represents a module.
    case Module = 0
    
    /// This context descriptor represents an extension.
    case Extension = 1
    
    /// This context descriptor represents an anonymous possibly-generic context
    /// such as a function body.
    case Anonymous = 2
    
    /// This context descriptor represents a protocol context.
    case SwiftProtocol = 3
    
    /// This context descriptor represents an opaque type alias.
    case OpaqueType = 4
    
    /// First kind that represents a type of any sort.
    //case Type_First = 16
    
    /// This context descriptor represents a class.
    case Class = 16 // Type_First
    
    /// This context descriptor represents a struct.
    case Struct = 17 // Type_First + 1
    
    /// This context descriptor represents an enum.
    case Enum = 18 // Type_First + 2
    
    /// Last kind that represents a type of any sort.
    case Type_Last = 31
    
    case Unknow = 0xFF // It's not in swift source, this value only used for dump
    
    var description: String {
        switch self {
        case .Module: return "module";
        case .Extension: return "extension";
        case .Anonymous: return "anonymous";
        case .SwiftProtocol: return "protocol";
        case .OpaqueType: return "OpaqueType";
        case .Class: return "class";
        case .Struct: return "struct";
        case .Enum: return "enum";
        case .Type_Last: return "Type_Last";
        case .Unknow: return "unknow";
        }
    }
}

// https://github.com/apple/swift/blob/a021e6ca020e667ce4bc8ee174e2de1cc0d9be73/include/swift/ABI/MetadataValues.h#L1217
struct SDContextDescriptorFlags:CustomStringConvertible {
    let value: UInt32
    init(_ value: UInt32) {
        self.value = value;
    }
    
    /// The kind of context this descriptor describes.
    var kind: SDContextDescriptorKind {
        if let kind = SDContextDescriptorKind(rawValue: UInt8( value & 0x1F ) ) {
            return kind;
        }
        return SDContextDescriptorKind.Unknow;
    }
    
    /// Whether the context being described is generic.
    var isGeneric: Bool {
        return (value & 0x80) != 0;
    }
    
    /// Whether this is a unique record describing the referenced context.
    var isUnique: Bool {
        return (value & 0x40) != 0;
    }
    
    /// The format version of the descriptor. Higher version numbers may have
    /// additional fields that aren't present in older versions.
    var version: UInt8 {
        return UInt8((value >> 8) & 0xFF);
    }
    
    /// The most significant two bytes of the flags word, which can have
    /// kind-specific meaning.
    var kindSpecificFlags: UInt16 {
        return UInt16((value >> 16) & 0xFFFF);
    }
    
    var description: String {
        let kindDesc: String = kind.description;
        let kindSpecificFlagsStr: String = String(format: "0x%x", kindSpecificFlags);
        
        var desc: String = "<\(value.hex), \(kindDesc),";
        if isGeneric {
            desc += " isGeneric,"
        }
        if isUnique {
            desc += " isUnique,"
        } else {
            desc += " NotUnique,"
        }
        
        desc += " version \(version), kindSpecificFlags \(kindSpecificFlagsStr)>";
        return desc;
    }
}



