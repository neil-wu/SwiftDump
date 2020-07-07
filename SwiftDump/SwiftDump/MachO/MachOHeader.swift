/*
 Copyright Geoffrey Foster
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */
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
