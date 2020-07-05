//
//  Data+Extensions.swift
//  Machismo
//
//  Created by Geoffrey Foster on 2018-05-13.
//  Copyright © 2018 g-Off.net. All rights reserved.
//

import Foundation

extension Data {
	subscript(_ arch: MachOFatArch) -> Data {
		return Data(self[arch.offset..<(arch.offset + arch.size)])
	}
	
	func extract<T>(_ type: T.Type, offset: Int = 0) -> T {
        let data = self[offset..<offset + MemoryLayout<T>.size];
        let ret = data.withUnsafeBytes { (ptr:UnsafeRawBufferPointer) -> T in
            return ptr.load(as: T.self)
        }
        return ret;
	}
}
