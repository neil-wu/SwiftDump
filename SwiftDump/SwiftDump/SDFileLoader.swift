//
//  FileLoaderNew.swift
//  SwiftDump
//
//  Created by neilwu on 2020/6/26.
//  Copyright © 2020 nw. All rights reserved.
//

import Foundation

final class SDFileLoader {
    private let filePath: String;
    
    private(set) var machoFile: MachOFile? = nil;
    
    init(file: String) {
        self.filePath = file;
    }
    
    func load(cpu: MachOCpuType) -> Bool {
        
        Log("load file from \(self.filePath)")
        let fileURL = URL(fileURLWithPath: self.filePath);
        do {
            let fileObj = try MachOFile(url: fileURL, cpu: cpu);
            self.machoFile = fileObj;
            Log("load file success")
            return true;
        } catch {
            LogError("load fail, error \(error.localizedDescription)");
        }
        
        return false;
    }
    
    func getSegment(of seg: ESegment) -> MachOLoadCommand.Segment? {
        //return self.macho?.segments(withName: seg.rawValue).first?.value
        guard let machoFile = self.machoFile else {
            return nil;
        }
        for cmd in machoFile.commands {
            //seg.rawValue
            if let segment = cmd as? MachOLoadCommand.Segment {
                if (seg.rawValue == segment.name) {
                    return segment;
                }
            }
        }
        return nil;
    }
    
    func getSection(of section: ESection, seg: ESegment) -> Section64? {
        guard let segObj:MachOLoadCommand.Segment = self.getSegment(of: seg) else {
            return nil;
        }
        let ret = segObj.sections.first { (sect:Section64) -> Bool in
            return sect.sectname == section.rawValue;
        }
        return ret;
    }
    
    func readU32(_ archPtr: SDPointer) -> UInt32 {
        return self.machoFile?.dataSlice.readU32(offset: Int(archPtr.address)) ?? 0;
    }
    
    func readU64(_ archPtr: SDPointer) -> UInt64 {
        return self.machoFile?.dataSlice.readU64(offset: Int(archPtr.address)) ?? 0;
    }
    
    func readS32(_ archPtr: SDPointer) -> Int32 {
        return self.machoFile?.dataSlice.readS32(offset: Int(archPtr.address)) ?? 0;
    }
    
    func readMove(_ ptr: SDPointer) -> SDPointer {
        let val = readU32(ptr);
        return ptr.add(Int64(val));
    }
    
    func readStr(_ ptr: SDPointer) -> String? {
        return self.machoFile?.dataSlice.readCString(from: Int(ptr.address))
    }
    
}

