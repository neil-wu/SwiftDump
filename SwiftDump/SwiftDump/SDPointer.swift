//
//  SDPointer.swift
//  SwiftDump
//
//  Created by neilwu on 2020/6/26.
//  Copyright © 2020 nw. All rights reserved.
//

import Foundation

struct SDPointer {
    private(set) var address: UInt64
    
    init(addr: UInt64) {
        self.address = addr;
    }
    
    func add(_ offset: Int64) -> SDPointer {
        var address: UInt64 = 0
        if (offset < 0) {
            address = self.address - UInt64(abs(offset) );
        } else {
            address = self.address + UInt64(offset);
        }
        return SDPointer(addr: address);
    }
    
    func fix() -> SDPointer {
        return SDPointer(addr: self.address & 0xFFFFFFFF);
    }
    
    var desc: String {
        return self.address.hex;
    }
}

