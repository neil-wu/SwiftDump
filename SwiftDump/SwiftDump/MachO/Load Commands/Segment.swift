//
//  Segment.swift
//  Machismo
//
//  Created by Geoffrey Foster on 2018-05-06.
//  Copyright © 2018 g-Off.net. All rights reserved.
//

import Foundation
import MachO


extension MachOLoadCommand {
	public struct Segment: MachOLoadCommandType {
		
		//	public var cmd: UInt32 /* for 64-bit architectures */ /* LC_SEGMENT_64 */
		//	public var cmdsize: UInt32 /* includes sizeof section_64 structs */
		//	public var segname: (Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8) /* segment name */
		//	public var vmaddr: UInt64 /* memory address of this segment */
		//	public var vmsize: UInt64 /* memory size of this segment */
		//	public var fileoff: UInt64 /* file offset of this segment */
		//	public var filesize: UInt64 /* amount to map from the file */
		//	public var maxprot: vm_prot_t /* maximum VM protection */
		//	public var initprot: vm_prot_t /* initial VM protection */
		//	public var nsects: UInt32 /* number of sections in segment */
		//	public var flags: UInt32 /* flags */
		
		public let name: String
        
        private(set) var command64: segment_command_64? = nil; // neilwu added
        private(set) var command: segment_command? = nil; //
        
        private(set) var sections:[Section64] = []
        
		init(command: segment_command_64) {
			self.name = String(command.segname)
            self.command64 = command
		}
		
		init(command: segment_command) {
			self.name = String(command.segname)
            self.command = command;
		}
		
		init(loadCommand: MachOLoadCommand) {
			if loadCommand.command == LC_SEGMENT_64 {
                var segmentCommand64:segment_command_64 = loadCommand.data.extract(segment_command_64.self, offset: loadCommand.offset)
				if loadCommand.byteSwapped {
					swap_segment_command_64(&segmentCommand64, byteSwappedOrder)
				}
				self.init(command: segmentCommand64)
                
                if (segmentCommand64.nsects <= 0) {
                    return;
                }
                let sectionOffset = loadCommand.offset + 0x48; // 0x48=sizeof(segment_command_64)
                
                for i in 0..<segmentCommand64.nsects {
                    let offset = sectionOffset + 0x50 * Int(i);
                    //print("\(self.name) \(i)", offset.hex )
                    let section:section_64 = loadCommand.data.extract(section_64.self, offset: offset)
                    let sec = Section64(section: section);
                    self.sections.append(sec);
                }
			} else {
				var segmentCommand = loadCommand.data.extract(segment_command.self, offset: loadCommand.offset)
				if loadCommand.byteSwapped {
					swap_segment_command(&segmentCommand, byteSwappedOrder)
				}
				self.init(command: segmentCommand)
                
                //TODO: parse sections
			}
		}
        
        
        
	}
}
