//
//  ProtocolObj.swift
//  SwiftDump
//
//  Created by neilwu on 2020/6/26.
//  Copyright © 2020 nw. All rights reserved.
//

import Foundation

final class SDProtocolObj {
    var flags: UInt32 = 0;
    var name: String = "";
    var numRequirementsInSignature: UInt32 = 0;
    var numRequirements: UInt32 = 0;
    var associatedTypeNames: String = ""; // joined by " "
    
    var superProtocols:[String] = [];
    
    var dumpDefine: String {
        let intent: String = "    "
        var str: String = "protocol \(name)";
        if (superProtocols.count > 0) {
            let superStr: String = superProtocols.joined(separator: ",")
            str += " : " + superStr;
        }
        str += " {\n";
        str += intent + "//flags \(flags.hex), numRequirements \(numRequirements)" + "\n"
        for astype in associatedTypeNames.split(separator: " ") {
            str += intent + "associatedtype " + String(astype) + "\n"
        }
        
        str += "}\n"
        return str;
    }
}
