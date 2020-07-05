//
//  RPath.swift
//  Machismo
//
//  Created by Geoffrey Foster on 2018-05-12.
//  Copyright © 2018 g-Off.net. All rights reserved.
//

import Foundation
import MachO

extension LoadCommand {
	public struct RPath: LoadCommandType {
		let path: String
		
		init(loadCommand: LoadCommand) {
			var command = loadCommand.data.extract(rpath_command.self, offset: loadCommand.offset)
			if loadCommand.byteSwapped {
				swap_rpath_command(&command, byteSwappedOrder)
			}
			self.path = String(data: loadCommand.data, offset: loadCommand.offset, commandSize: loadCommand.size, loadCommandString: command.path)
		}
	}
}
