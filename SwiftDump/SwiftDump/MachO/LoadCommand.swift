//
//  LoadCommand.swift
//  Machismo
//
//  Created by Geoffrey Foster on 2018-05-06.
//  Copyright © 2018 g-Off.net. All rights reserved.
//

import Foundation

protocol MachOLoadCommandType {
	
}

struct MachOLoadCommand {
	let command: UInt32
	let size: Int
	
	let data: Data
	let offset: Int
	let byteSwapped: Bool
	
	init(data: Data, offset: Int, byteSwapped: Bool) {
		var loadCommand = data.extract(load_command.self, offset: offset)
		if byteSwapped {
			swap_load_command(&loadCommand, byteSwappedOrder)
		}
		self.command = loadCommand.cmd
		self.size = Int(loadCommand.cmdsize)
		self.data = data
		self.offset = offset
		self.byteSwapped = byteSwapped
	}
	
	func command(from data: Data, offset: Int, byteSwapped: Bool) -> MachOLoadCommandType? {
		switch Int(command) {
		case Int(LC_SEGMENT), Int(LC_SEGMENT_64):
			return Segment(loadCommand: self)
		default:
			return nil
		}
	}
}
