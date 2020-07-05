//
//  Consts.swift
//  SwiftDump
//
//  Created by neilwu on 2020/6/26.
//  Copyright © 2020 nw. All rights reserved.
//

import Foundation


enum ESegment: String {
    case TEXT = "__TEXT"
    case DATA = "__DATA"
    case DATA_CONST = "__DATA_CONST"
    
}


enum ESection: String {
    case swift5types     = "__swift5_types"
    case swift5proto    = "__swift5_proto"
    case swift5protos    = "__swift5_protos"
    
    case swift5filemd   = "__swift5_fieldmd"
    case objc_classlist    = "__objc_classlist"

}


