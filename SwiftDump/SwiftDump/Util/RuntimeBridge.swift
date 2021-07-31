//
//  RuntimeBridge.swift
//  SwiftDump
//
//  Created by neilwu on 2020/6/26.
//  Copyright © 2020 nw. All rights reserved.
//

import Foundation

@_silgen_name("swift_getTypeByMangledNameInContext")
public func _getTypeByMangledNameInContext(_ name: UnsafePointer<UInt8>,
                                           _ nameLength: Int,
                                           genericContext: UnsafeRawPointer?,
                                           genericArguments: UnsafeRawPointer?) -> Any.Type?


// size_t swift_demangle_getDemangledName(const char *MangledName, char *OutputBuffer,size_t Length)
@_silgen_name("swift_demangle_getDemangledName")
public func _getDemangledName(_ name:UnsafePointer<Int8>?, output:UnsafeMutablePointer<Int8>?, len:Int) -> Int;



// ex. So8UIButtonCSg -> UIButton?
// if demangle fail, will return the origin string
// Only demangle str start with So/$So/_$so/_T
func canDemangleFromRuntime(_ instr: String) -> Bool {
    return instr.hasPrefix("So") || instr.hasPrefix("$So") || instr.hasPrefix("_$So") || instr.hasPrefix("_T")
}
func runtimeGetDemangledName(_ instr: String) -> String {
    var str: String = instr;
    if (instr.hasPrefix("$s")) {
        str = instr;
    } else if (instr.hasPrefix("So")) {
        str = "$s" + instr;
    } else if (instr.hasPrefix("_T")) {
        //
    } else {
        return instr;
    }
    
    let strPtr:UnsafePointer<Int8> = str.withCString { (ptr:UnsafePointer<Int8>) -> UnsafePointer<Int8> in
        return ptr;
    }
    
    let bufLen: Int = 128; // may be 128 is big enough
    var buf:[Int8] = Array(repeating: 0, count: bufLen);
    let retLen = _getDemangledName(strPtr, output: &buf, len: bufLen)
    
    if retLen > 0 && retLen < bufLen {
        let resultBuf:[UInt8] = buf[0..<retLen].map{ UInt8($0) }
        let retStr = String(bytes:  resultBuf, encoding: .utf8)
        
        return retStr?.replacingOccurrences(of: "__C.", with: "") ?? instr;
    }
    return instr; // return the original string
    
}


func getTypeFromMangledName(_ str: String) -> String {
    if (canDemangleFromRuntime(str)) {
        return runtimeGetDemangledName(str);
    }
    //check is ascii string
    if (!str.isAsciiStr()) {
        return str;
    }
    guard let ptr = str.toPointer() else {
        return str;
    }
    
    var useCnt:Int = str.count
    if (str.hasSuffix("_pG")) {
        useCnt = useCnt - 3
    }
    
    guard let typeRet: Any.Type = _getTypeByMangledNameInContext(ptr, useCnt, genericContext: nil, genericArguments: nil) else {
        return str;
    }
    
    let tstr: String = String(describing: typeRet)
    //print("\(str) -> \(tstr)")
    return fixOptionalTypeName(tstr);
}

// Optional<Any.Type>  => Any.Type?
// Optional<Int>  => Int?
func fixOptionalTypeName(_ typeName: String) -> String {
    let prefix: String = "Optional";
    if (!typeName.hasPrefix(prefix)) {
        return typeName;
    }
    var name: String = typeName.removingPrefix(prefix);
    name = name.removingPrefix("<")
    name = name.removingSuffix(">")
    if (name.contains(" ")) {
        return "(" + name + ")?"
    }
    return name + "?";
}

func removeSwiftModulePrefix(_ typeName: String) -> String {
    if let idx = typeName.firstIndex(of: ".") {
        let useIdx = typeName.index(after: idx)
        return String(typeName.suffix(from: useIdx ));
    }
    
    return typeName;
}



