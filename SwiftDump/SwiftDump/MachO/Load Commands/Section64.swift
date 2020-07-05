//
//  Section64.swift
//  SwiftDump
//
//  Created by neilwu on 2020/6/26.
//  Copyright © 2020 nw. All rights reserved.
//

import Foundation
import MachO

public struct Section64 {
    private(set) var sectname: String
    private(set) var segname: String
    
    private(set) var info:section_64
    
    var align: UInt32 {
        return UInt32(pow(Double(2), Double(info.align)))
    }
    var fileOffset: UInt32 {
        return info.offset;
    }
    
    var num:Int {
        let num: Int = Int(info.size) / Int(align);
        return num;
    }
    
    
    init(section: section_64) {
        segname = String(section.segname);
        
        var strSect = String(section.sectname);
        // max len is 16
        if (strSect.count > 16) {
            strSect = String(strSect.prefix(16));
        }
        sectname = strSect;
        self.info = section;
    }
    
    
}

