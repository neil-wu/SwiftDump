//
//  String+Extensions.swift
//  Machismo
//
//  Created by Geoffrey Foster on 2018-05-13.
//  Copyright © 2018 g-Off.net. All rights reserved.
//

import Foundation

extension String {
	init(_ rawCString: (Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8)) {
		var rawCString = rawCString
		let rawCStringSize = MemoryLayout.size(ofValue: rawCString)
		let string = withUnsafePointer(to: &rawCString) { (pointer) -> String in
			return pointer.withMemoryRebound(to: UInt8.self, capacity: rawCStringSize, {
				return String(cString: $0)
			})
		}
		self.init(string)
	}
	
	/*
	* A variable length string in a load command is represented by an lc_str
	* union.  The strings are stored just after the load command structure and
	* the offset is from the start of the load command structure.  The size
	* of the string is reflected in the cmdsize field of the load command.
	* Once again any padded bytes to bring the cmdsize field to a multiple
	* of 4 bytes must be zero.
	*/
	init(data: Data, offset: Int, commandSize: Int, loadCommandString: lc_str) {
		let loadCommandStringOffset = Int(loadCommandString.offset)
		let stringOffset = offset + loadCommandStringOffset
		let length = commandSize - loadCommandStringOffset
		self = String(data: data[stringOffset..<(stringOffset + length)], encoding: .utf8)!.trimmingCharacters(in: .controlCharacters)
	}
	
	init(loadCommand: MachOLoadCommand, string: lc_str) {
		let stringOffset = loadCommand.offset + Int(string.offset)
		self = String(data: loadCommand.data[stringOffset..<(loadCommand.offset + loadCommand.size)], encoding: .utf8)!.trimmingCharacters(in: .controlCharacters)
	}
}
