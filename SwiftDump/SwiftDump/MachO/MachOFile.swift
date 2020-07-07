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
//  MachO.swift
//  Machismo
//
//  Created by Geoffrey Foster on 2018-05-12.
//  Copyright © 2018 g-Off.net. All rights reserved.
//
//  neilwu modify this file for SwiftDump

import Foundation

enum MachOFileError: Error {
    case archFail
}

public enum MachOCpuType:String, CaseIterable {
    case x86_64 = "x86_64"
    case arm64 = "arm64"
    
    var cputype:cpu_type_t {
        switch self {
        case .x86_64: return CPU_TYPE_X86_64;
        case .arm64: return CPU_TYPE_ARM64;
        }
    }
}

fileprivate struct MachAttributes {
    let is64Bit: Bool
    let isByteSwapped: Bool
}

public struct MachOFile {
    
	let url: URL
	let header: MachOHeader
	let commands: [MachOLoadCommandType]
    
    let dataSlice: Data
	
	public init(url: URL, cpu: MachOCpuType?) throws {
		let data = try Data(contentsOf: url)
        try self.init(url: url, data: data, cpu: cpu)
	}
	
    public init(url: URL, data: Data, cpu: MachOCpuType?) throws {
		self.url = url
		
		let dataSlice: Data
		if let fatHeader = MachOFatHeader(data: data) {
            var fatArch: MachOFatArch?
            if let cpu = cpu {
                fatArch = fatHeader.architectures.first { $0.cputype == cpu.cputype }
            }
            if nil != fatArch {
                dataSlice = data[fatArch!];
            } else {
                throw MachOFileError.archFail;
            }
		} else {
			dataSlice = data
		}
		let attributes = MachOFile.machAttributes(from: dataSlice)
		let header = MachOFile.header(from: dataSlice, attributes: attributes)
		
        self.dataSlice = dataSlice;
		self.header = header
		self.commands = MachOFile.segmentCommands(from: dataSlice, header: header, attributes: attributes)
	}
	
	private static func machAttributes(from data: Data) -> MachAttributes {
		let magic = data.extract(UInt32.self)
		let is64Bit = magic == MH_MAGIC_64 || magic == MH_CIGAM_64
		let isByteSwapped = magic == MH_CIGAM || magic == MH_CIGAM_64
		return MachAttributes(is64Bit: is64Bit, isByteSwapped: isByteSwapped)
	}
	
	private static func header(from data: Data, attributes: MachAttributes) -> MachOHeader {
		if attributes.is64Bit {
			let header = data.extract(mach_header_64.self)
			return MachOHeader(header: header)
		} else {
			let header = data.extract(mach_header.self)
			return MachOHeader(header: header)
		}
	}
	
	private static func segmentCommands(from data: Data, header: MachOHeader, attributes: MachAttributes) -> [MachOLoadCommandType] {
		var segmentCommands: [MachOLoadCommandType] = []
		var offset = header.size
		for _ in 0..<header.loadCommandCount {
			let loadCommand = MachOLoadCommand(data: data, offset: offset, byteSwapped: attributes.isByteSwapped)
			if let command = loadCommand.command(from: data, offset: offset, byteSwapped: attributes.isByteSwapped) {
				segmentCommands.append(command)
			}
			offset += Int(loadCommand.size)
		}
		return segmentCommands
	}
	
}
