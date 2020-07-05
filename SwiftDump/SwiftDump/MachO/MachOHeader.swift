//
//  Header.swift
//  Machismo
//
//  Created by Geoffrey Foster on 2018-05-05.
//  Copyright © 2018 g-Off.net. All rights reserved.
//

import Foundation
import MachO

public struct MachOHeader {
	public let magic: UInt32 /* mach magic number identifier */
	public let cputype: cpu_type_t /* cpu specifier */
	//public let cpusubtype: cpu_subtype_t /* machine specifier */
	public let filetype: UInt32 /* type of file */
	//public let ncmds: UInt32 /* number of load commands */
	//public var sizeofcmds: UInt32 /* the size of all the load commands */
	//public var flags: UInt32 /* flags */
	
	public let loadCommandCount: UInt32
	public let loadCommandSize: UInt32
	
	public let size: Int
	
	public init(header: mach_header_64) {
		self.magic = header.magic
		self.cputype = header.cputype
		self.filetype = header.filetype
		self.loadCommandCount = header.ncmds
		self.loadCommandSize = header.sizeofcmds
		self.size = MemoryLayout.size(ofValue: header)
	}
	
	public init(header: mach_header) {
		self.magic = header.magic
		self.cputype = header.cputype
		self.filetype = header.filetype
		self.loadCommandCount = header.ncmds
		self.loadCommandSize = header.sizeofcmds
		self.size = MemoryLayout.size(ofValue: header)
	}
}
