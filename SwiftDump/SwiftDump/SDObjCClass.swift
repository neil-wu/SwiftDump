//
//  SwiftObj.swift
//  SwiftDump
//
//  Created by neilwu on 2020/6/26.
//  Copyright © 2020 nw. All rights reserved.
//

import Foundation

struct SDObjCClassROData {
    var flags: UInt32 = 0;
    var instanceStart: UInt32 = 0;
    var instanceSize: UInt32 = 0;
    var unknowField: UInt32 = 0; //
    var instanceVarLayout: UInt64 = 0;
    var nameAddr: UInt64 = 0;
    var weakInstanceVarLayout: UInt64 = 0;
}
struct SDObjCClass {
    var isaAddress: UInt64 = 0; // pointer
    var superclassAddress: UInt64 = 0; // pointer
    var cache: UInt64 = 0; // pointer
    var mask:UInt32 = 0;
    var occupied: UInt32 = 0;
    var dataAddr: UInt64 = 0;
}



