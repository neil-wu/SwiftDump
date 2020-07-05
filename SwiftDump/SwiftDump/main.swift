//
//  main.swift
//  SwiftDump
//
//  Created by neilwu on 2020/6/26.
//  Copyright © 2020 nw. All rights reserved.
//

import Foundation
import ArgumentParser

// https://github.com/apple/swift-argument-parser
// https://github.com/apple/swift/blob/master/docs/ABI/Mangling.rst#symbolic-references

func runMain(file: String, cpu: MachOCpuType) {
    let loader = SDFileLoader(file: file);
    let isSuccess: Bool = loader.load(cpu: cpu);
    if (!isSuccess) {
        LogError("fail to load file")
        return;
    }
    let parser = SDParser(with: loader);
    parser.parseSwiftProtos(); // find all Protocol
    parser.parseSwiftType(); // find all Type
    parser.parseSwiftProto(); // parse after Protocol & Type
    parser.parseSwiftOCClass();
    
    parser.dumpAll();
}

fileprivate let SDVersion: String = "1.0";
fileprivate let SDBuildTime: String = "2020-06-26";

struct SwiftDump: ParsableCommand {
    
    @Flag(name: .shortAndLong, help: "Show debug log.")
    var debug: Bool = false;
    
    @Option(name: .shortAndLong, help: "Choose architecture from a fat binary (only support x86_64/arm64).")
    var arch: String = "arm64"
    
    @Flag(name: .shortAndLong, help: "Version")
    var version: Bool = false;
    
    @Argument(help: "MachO File")
    var file: String = "";
    
    
    mutating func run() throws {
        if (version) {
            print("SwiftDump v\(SDVersion) \(SDBuildTime). Created by neilwu.");
            if (file.isEmpty) {
                return;
            }
            print("\n");
        }
        
        let isFileExist = FileManager.default.fileExists(atPath: file)
        if (!isFileExist) {
            print("input file [\(file)] does not exist")
            return;
        }
        //print("[run] debug ", debug)
        if (debug) {
            enableDebugLog();
        }
        #if DEBUG
        //enableDebugLog();
        #endif
        guard let archVal = self.getArchVal() else {
            print("Fail to find architecture [\(self.arch)] in [\(file)], SwiftDump only support x86_64/arm64");
            return;
        }
        
        runMain(file: file, cpu: archVal);
    }
    
    func getArchVal() -> MachOCpuType? {
        if let val = MachOCpuType(rawValue: self.arch) {
            return val;
        }
        return nil;
    }
    
    
}

SwiftDump.main()

