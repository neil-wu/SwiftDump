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
//  FatHeader.swift
//  Machismo
//
//  Created by Geoffrey Foster on 2018-05-13.
//  Copyright © 2018 g-Off.net. All rights reserved.
//

import Foundation
import MachO.fat

public struct MachOFatArch {
    public var cputype: cpu_type_t /* cpu specifier (int) */
    public var cpusubtype: cpu_subtype_t /* machine specifier (int) */
    public var offset: UInt64 /* file offset to this object file */
    public var size: UInt64 /* size of this object file */
    public var align: UInt32 /* alignment as a power of 2 */
    
    init(arch: fat_arch_64) {
        self.cputype = arch.cputype
        self.cpusubtype = arch.cpusubtype
        self.offset = arch.offset
        self.size = arch.size
        self.align = arch.align
    }
    
    init(arch: fat_arch) {
        self.cputype = arch.cputype
        self.cpusubtype = arch.cpusubtype
        self.offset = UInt64(arch.offset)
        self.size = UInt64(arch.size)
        self.align = arch.align
    }
}

public struct MachOFatHeader {
	
    public let architectures: [MachOFatArch];
    
	init?(data: Data) {
		let magic = data.extract(UInt32.self)
		guard [FAT_MAGIC, FAT_MAGIC_64, FAT_CIGAM, FAT_CIGAM_64].contains(magic) else { return nil }
		
		var header = data.extract(fat_header.self)
		let is64Bit = [FAT_MAGIC_64, FAT_CIGAM_64].contains(magic)
		let byteSwapped = [FAT_CIGAM, FAT_CIGAM_64].contains(magic)
		if [FAT_CIGAM, FAT_CIGAM_64].contains(magic) {
			swap_fat_header(&header, byteSwappedOrder)
		}
		var offset = MemoryLayout.size(ofValue: header)
		var architectures: [MachOFatArch] = []
		if is64Bit {
			for _ in 0..<header.nfat_arch {
				var fatArch = data.extract(fat_arch_64.self, offset: offset)
				offset += MemoryLayout.size(ofValue: fatArch)
				if byteSwapped {
					swap_fat_arch_64(&fatArch, 1, byteSwappedOrder)
				}
				architectures.append(MachOFatArch(arch: fatArch))
			}
		} else {
			for _ in 0..<header.nfat_arch {
				var fatArch = data.extract(fat_arch.self, offset: offset)
				offset += MemoryLayout.size(ofValue: fatArch)
				if byteSwapped {
					swap_fat_arch(&fatArch, 1, byteSwappedOrder)
				}
				architectures.append(MachOFatArch(arch: fatArch))
			}
		}
		
		self.architectures = architectures
	}
}
