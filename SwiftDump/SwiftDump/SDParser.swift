//
//  Parser.swift
//  SwiftDump
//
//  Created by neilwu on 2020/6/26.
//  Copyright © 2020 nw. All rights reserved.
//

import Foundation

final class SDParser {
    private(set) var protocolObjs:[SDProtocolObj] = [];
    private(set) var cacheProtocolAddressMap:[UInt64: String] = [:];
    
    private(set) var nominalObjs:[SDNominalObj] = [];
    private(set) var cacheNominalOffsetMap:[Int64: String] = [:]; // used for name demangle
    
    private(set) var nominalProtoMap:[String: [String] ] = [:];
    private(set) var classNameInheritanceMap: [String : String] = [:]; // [className : SuperClassName]
    
    private var loader: SDFileLoader? = nil;
    
    init(with loader: SDFileLoader) {
        self.loader = loader
    }
    
    // mangledName -> TypeName
    private var mangledNameMap:[String : String] = ["0x02f36d": "Int32",
        "0x02cd6d": "Int16", "0x027b6e": "UInt16",
        "0x022b6c": "UInt32",
        "0x02b98502": "Int64", "0x02418a02" : "UInt64",
        "0x02958802": "CGFloat"];
    
    func parseSwiftProto() {
        guard let loader = self.loader else {
            return;
        }
        let sectionType = ESection.swift5proto;
        Log("start parse section \(sectionType.rawValue)")
        guard let typeSect:Section64 = loader.getSection(of: sectionType, seg: ESegment.TEXT) else {
            Log("did not find section \(sectionType.rawValue)")
            return;
        }
        
        // This section contains an array of 32-bit signed integers. Each integer is a relative offset that points to a protocol conformance descriptor in the __TEXT.__const section.
        if (4 != typeSect.align) {
            Log("error! section \(sectionType.rawValue) is not 4 bytes align. align \(typeSect.align)")
            return;
        }
        /*
        type ProtocolConformanceDescriptor struct {
            ProtocolDescriptor    int32
            NominalTypeDescriptor int32
            ProtocolWitnessTable  int32
            ConformanceFlags      uint32
        }*/
        
        let num: Int = typeSect.num;
        let fileOffset: Int64 = Int64(typeSect.fileOffset);
        
        for i in 0..<num {
            let localOffset: Int = i * 4;
            
            let tmpPtr = SDPointer(addr: UInt64(fileOffset) + UInt64(localOffset) );
            let pcdLocalOffset:Int32 = loader.readS32(tmpPtr); // may be negative value
            
            // address offset to current arch
            let pcdArchOffset:Int64 = Int64(fileOffset) + Int64(localOffset) + Int64(pcdLocalOffset);
                        
            //ProtocolConformanceDescriptor
            let pcdPtr:SDPointer = SDPointer(addr: UInt64(pcdArchOffset));
                        
            // https://github.com/apple/swift/blob/master/docs/ABI/TypeMetadata.rst#protocol-conformance-records
            let protocolDescriptorOffset:Int32 = loader.readS32(pcdPtr)
            var protoName: String = "";
            if ((protocolDescriptorOffset & 0x1) == 1) {
                let offset: Int32 = (protocolDescriptorOffset & 0xFFFE); // remove the lowest bit
                let val = loader.readU32(pcdPtr.add( Int64(offset) ));
                protoName = self.cacheProtocolAddressMap[ UInt64(val) ] ?? "";
            } else {
                let val:UInt64 = pcdPtr.add( Int64(protocolDescriptorOffset) ).address;
                protoName = self.cacheProtocolAddressMap[val] ?? "";
            }
            
            
            var nominalName: String = "";
            let nominalTypeDescriptorPtr = pcdPtr.add(4);
            let nominalTypeDescriptorVal:Int32 = loader.readS32(nominalTypeDescriptorPtr);
            let tmpVal = nominalTypeDescriptorVal & 0x3; // get last two bits
            
            if (tmpVal == 0) {
                //A direct reference to a nominal type descriptor.
                let ptr = nominalTypeDescriptorPtr.add(Int64(nominalTypeDescriptorVal));
                nominalName = self.cacheNominalOffsetMap[ Int64(ptr.address) ] ?? "";
                if (nominalName.isEmpty) {
                    if let str: String = loader.readStr(ptr) {
                        nominalName = str;
                        self.cacheNominalOffsetMap[ Int64(ptr.address) ] = str;
                    }
                }
            } else if (tmpVal == 1) {
                //An indirect reference to a nominal type descriptor.
                let ptr = nominalTypeDescriptorPtr.add(Int64(nominalTypeDescriptorVal ));
                let str: String? = loader.readStr(ptr)
                nominalName = str ?? "";
            } else if (tmpVal == 2) {
                let ptr = nominalTypeDescriptorPtr.add(Int64(nominalTypeDescriptorVal ));
                let str: String? = loader.readStr(ptr)
                nominalName = str ?? "";
                
            } else if (tmpVal == 3) {
                //A reference to a pointer to an Objective-C class object.
                //print(tmpVal.hex)
            }
            
            if (!protoName.isEmpty && !nominalName.isEmpty) {
                // nominalProtoMap
                if nil != self.nominalProtoMap[nominalName] {
                    self.nominalProtoMap[nominalName]?.append(protoName)
                } else {
                    self.nominalProtoMap[nominalName] = [protoName];
                }
            }
            
            //let protocolWitnessTablePtr: SDPointer = loader.readMove(pcdPtr.add(4*2)).fix();
            //let conformanceFlags = loader.readU32(pcdPtr.add(4*3));
            
            //print("\(i) \(pcdPtr.desc) protocolDescriptorOffset \(protocolDescriptorOffset.hex ) => \(protoName), nominalTypeDescriptorPtr \( nominalTypeDescriptorVal.hex ) => \(nominalName), protocolWitnessTablePtr \(protocolWitnessTablePtr.desc), conformanceFlags \(conformanceFlags.hex)");
            
            Log("\(i) \(pcdPtr.desc) proto=\(protoName), nominal=\(nominalName)");
            
        }
    }
    
    func parseSwiftProtos() {
        guard let loader = self.loader else {
            return;
        }
        let sectionType = ESection.swift5protos;
        Log("start parse section \(sectionType.rawValue)");
        
        guard let typeSect:Section64 = loader.getSection(of: sectionType, seg: ESegment.TEXT) else {
            Log("did not find section \(sectionType.rawValue)")
            return;
        }
        // This section contains an array of 32-bit signed integers. Each integer is a relative offset that points to a protocol descriptor in the __TEXT.__const section.
        if (4 != typeSect.align) {
            Log("error! section \(sectionType.rawValue) is not 4 bytes align. align \(typeSect.align)")
            return;
        }
        
        let num: Int = typeSect.num;
        let fileOffset: Int64 = Int64(typeSect.fileOffset);
        
        Log("section \(sectionType.rawValue) \(fileOffset.hex)")
        /*
        type ProtocolDescriptor struct {
            Flags                      uint32
            Parent                     int32
            Name                       int32
            NumRequirementsInSignature uint32
            NumRequirements            uint32
            AssociatedTypeNames        int32
            [The generic requirements that form the requirement signature]
            [The protocol requirements of the protocol]
        }*/
        for i in 0..<num {
            let tmp: Int = i * 4;
            let tmpPtr = SDPointer(addr: UInt64(tmp) + UInt64(fileOffset) );
            let localOffset:Int32 = loader.readS32(tmpPtr); // may be negative value
            
            // address offset to current arch
            let pdArchOffset:Int64 = Int64(fileOffset) + Int64(tmp) + Int64(localOffset);
            
            let pdPtr:SDPointer = SDPointer(addr: UInt64(pdArchOffset)); // ProtocolDescriptor
            
            // 1. flags
            let flags:UInt32 = loader.readU32(pdPtr);
            // 3. name
            let namePtr = loader.readMove(pdPtr.add(8)).fix();
            guard let nameStr: String = loader.readStr(namePtr) else {
                return;
            }
            
            let numRequirementsInSignature:UInt32 = loader.readU32(pdPtr.add(4 * 3));
            let numRequirements:UInt32 = loader.readU32(pdPtr.add(4 * 4));
            
            let associatedTypeNamesOffset:Int32 = loader.readS32(pdPtr.add(4 * 5));
            
            let obj = SDProtocolObj();
            obj.flags = flags;
            obj.name = nameStr;
            obj.numRequirementsInSignature = numRequirementsInSignature;
            obj.numRequirements = numRequirements;
            
            self.cacheProtocolAddressMap[pdPtr.address] = nameStr;
            
            Log("\(i) \(pdPtr.desc) flags \(flags.hex), \(nameStr), numRequirementsInSignature \(numRequirementsInSignature.hex), numRequirements \(numRequirements.hex) associatedTypeNames \(associatedTypeNamesOffset) \(associatedTypeNamesOffset.hex)")
            if (associatedTypeNamesOffset != 0) {
                let associatedTypeNamesPtr = pdPtr.add(4 * 5 + Int64(associatedTypeNamesOffset));
                let associatedTypeNames = loader.readStr(associatedTypeNamesPtr) ?? ""
                obj.associatedTypeNames = associatedTypeNames;
            }
            
            self.protocolObjs.append(obj)
        }
        
    }
    
    func parseSwiftType() {
        guard let loader = self.loader else {
            return;
        }
        let sectionType = ESection.swift5types;
        Log("start parse \(sectionType.rawValue)")
        
        guard let typeSect:Section64 = loader.getSection(of: sectionType, seg: ESegment.TEXT) else {
            Log("did find section \(ESection.swift5types.rawValue), may be the binary does not contain swift5 lib?")
            return;
        }
        
        //print("addr", String(format: "0x%llx", typeSect.fileOffset))
        
        // __swift5_types is 4 bytes align, equal to typeSect.align
        if (4 != typeSect.align) {
            Log("error! section \(sectionType.rawValue) is not 4 bytes align. align \(typeSect.align)")
            return;
        }
        
        let num: Int = typeSect.num;
        
        // mk_vm_address_t is uint64_t
        let fileOffset: Int64 = Int64(typeSect.fileOffset);
        
        for i in 0..<num {
            let localOffset: Int = i * 4;
            //let nominalLocalOffset:Int32 = data.readS32(offset: localOffset); // may be negative value
            
            let tmpPtr = SDPointer(addr: UInt64(fileOffset) + UInt64(localOffset) );
            let nominalLocalOffset:Int32 = loader.readS32(tmpPtr); // may be negative value
            
            
            // address offset to current arch
            let nominalArchOffset:Int64 = Int64(fileOffset) + Int64(localOffset) + Int64(nominalLocalOffset);
            
            //read nominal
            let nominalPtr:SDPointer = SDPointer(addr: UInt64(nominalArchOffset));
            
            // 1. flags
            let flags:UInt32 = loader.readU32(nominalPtr);
            let sdfObj = SDContextDescriptorFlags(flags);
            
            // 2. parentOffset
            let parentVal = loader.readS32(nominalPtr.add(4)); // may be the module name
            //let parentPtr:SDPointer = nominalPtr.add(4).add( Int64(parentVal) ).fix();
            //print("parentVal \(parentVal.hex)", parentPtr.desc); // look backwards it is the module name
            
            
            // 3. name
            let namePtr = loader.readMove(nominalPtr.add(8)).fix();
            guard let nameStr: String = loader.readStr(namePtr) else {
                return;
            }
            // 4. AccessFunction. // Access functions will always return the correct metadata record;
            let accessorPtr = loader.readMove(nominalPtr.add(12)).fix();
            
            #if DEBUG
            
            #endif
            
            let obj: SDNominalObj = SDNominalObj();
            obj.typeName = nameStr;
            obj.contextDescriptorFlag = sdfObj;
            obj.nominalOffset = nominalArchOffset;
            obj.accessorOffset = accessorPtr.address;
            self.nominalObjs.append(obj);
            
            if (sdfObj.kind == .Class) {
                obj.superClassName = resolveSuperClassName(nominalPtr);
            } else if (sdfObj.kind == .Enum) {
                //let numPayloadCasesAndPayloadSizeOffset:UInt32 = loader.readU32(nominalPtr.add(4 * 5));
                //let numEmptyCases:UInt32 = loader.readU32(nominalPtr.add(4 * 6));
                //print("\(i)  ", "numPayloadCasesAndPayloadSizeOffset \(numPayloadCasesAndPayloadSizeOffset), numEmptyCases \(numEmptyCases)");
            } else if (sdfObj.kind == .Struct) {
                //let numFields:UInt32 = loader.readU32(nominalPtr.add(4 * 5));
                //let fieldOffsetVectorOffset:UInt32 = loader.readU32(nominalPtr.add(4 * 6));
                //print("\(i)  ", "numFields \(numFields), fieldOffsetVectorOffset \(fieldOffsetVectorOffset)");
            }
            
            self.cacheNominalOffsetMap[nominalArchOffset] = nameStr;
            
            // in swift5_filedmd
            let fieldDescriptorPtr:SDPointer = loader.readMove(nominalPtr.add(4 * 4)).fix();
            
            let mangledTypeNamePtr = loader.readMove(fieldDescriptorPtr).fix();
            if let mangledTypeName = loader.readStr(mangledTypeNamePtr) {
                //Log("    mangledTypeName \(mangledTypeName) \(mangledTypeNamePtr.desc)")
                obj.mangledTypeName = mangledTypeName;
            }
            
            Log("\(i). nominalLocalOffset \(nominalLocalOffset ), nominalArchOffset \(nominalArchOffset.hex ), flags \(flags.hex)=\(sdfObj.kind), parent \(parentVal.hex), namePtr \(namePtr.desc) \(nameStr), mangledTypeName \(obj.mangledTypeName)");
            
            dumpFieldDescriptor(loader: loader, fieldDescriptorPtr: fieldDescriptorPtr, to: obj)
            if (obj.mangledTypeName.count > 0) {
                mangledNameMap[obj.mangledTypeName] = obj.typeName;
            }
        }
    }
    
    private func resolveSuperClassName(_ nominalPtr: SDPointer) -> String {
        //nominalPtr
        let ptr = nominalPtr.add(4 * 5)
        let superClassTypeVal = self.loader?.readS32(ptr) ?? 0;
        if (superClassTypeVal == 0) {
            return "";
        }
        
        var retName: String = "";
        
        let superClassRefPtr = ptr.add( Int64(superClassTypeVal) );
        if let superRefStr = self.loader?.readStr(superClassRefPtr), !superRefStr.isEmpty {
            if superRefStr.hasPrefix("0x") {
                retName = self.mangledNameMap[superRefStr] ?? superRefStr;
            } else {
                retName = superRefStr; // resolve later
            }
        }
        return retName;
    }
    
    private func getISAClassName(of obj:SDObjCClass) -> String {
        if (obj.isaAddress == 0) {
            return "";
        }
        
        let dataSlice: Data? = self.loader?.machoFile?.dataSlice;
        
        guard let metaObj:SDObjCClass = dataSlice?.extract(SDObjCClass.self, offset: Int(obj.isaAddress & 0xFFFFFFFF)) else {
            return "";
        }
        if (metaObj.dataAddr == 0) {
            return "";
        }
        // find class name string
        guard let dataObj:SDObjCClassROData = dataSlice?.extract(SDObjCClassROData.self, offset: Int(metaObj.dataAddr & 0xFFFFFFFF)) else {
            return "";
        }
        
        let name: String = self.loader?.readStr(SDPointer(addr: dataObj.nameAddr & 0xFFFFFFFF)) ?? "";
        //print("  metaname:", dataObj.nameAddr.hex, name)
        return name;
    }
    
    private func getSuperClassName(of obj:SDObjCClass) -> String {
        if (obj.superclassAddress == 0) {
            return "";
        }
        let dataSlice: Data? = self.loader?.machoFile?.dataSlice;
        
        guard let superClassObj:SDObjCClass = dataSlice?.extract(SDObjCClass.self, offset: Int(obj.superclassAddress & 0xFFFFFFFF)) else {
            return "";
        }
        
        if (superClassObj.isaAddress == 0) {
            // find class name string
            if let dataObj:SDObjCClassROData = dataSlice?.extract(SDObjCClassROData.self, offset: Int(superClassObj.dataAddr & 0xFFFFFFFF)) {
                //
                let name: String = self.loader?.readStr(SDPointer(addr: dataObj.nameAddr & 0xFFFFFFFF)) ?? "";
                //print("    super dataObj:", dataObj.nameAddr.hex, name)
                return name;
            }
        } else {
            return getISAClassName(of: superClassObj);
        }
        
        return "";
    }
    private func demangleClassName(_ name: String) -> String {
        var tmp: String = runtimeGetDemangledName(name);
        tmp = removeSwiftModulePrefix(tmp)
        return tmp;
    }
    
    func parseSwiftOCClass() {
        guard let loader = self.loader else {
            return;
        }
        Log("start parse section \(ESection.objc_classlist.rawValue)")
        let typeSect:Section64
        if let tmp:Section64 = loader.getSection(of: ESection.objc_classlist, seg: ESegment.DATA) {
            typeSect = tmp;
            Log("use seg \(ESegment.DATA.rawValue)");
        } else if let tmp:Section64 = loader.getSection(of: ESection.objc_classlist, seg: ESegment.DATA_CONST) {
            typeSect = tmp;
            Log("use seg \(ESegment.DATA_CONST.rawValue)");
        } else {
            LogWarn("didn't find section \(ESection.objc_classlist.rawValue)")
            return;
        }
        
        let fileOffset: UInt64 = UInt64(typeSect.fileOffset);
        
        var metaClassNameMap:[UInt64: String] = [:]; // isaAddress : name
        
        // align is 8
        for i in 0..<typeSect.num {
            let tmpOffset: UInt64 = UInt64(i) * UInt64(typeSect.align);
            var valAddress:UInt64 = loader.readU64(SDPointer(addr: fileOffset + tmpOffset ) );
            valAddress = valAddress & 0xFFFFFFFF;
            
            guard let obj:SDObjCClass = loader.machoFile?.dataSlice.extract(SDObjCClass.self, offset: Int(valAddress)) else {
                continue;
            }
            //print(obj)
            
            let metaClassName: String = demangleClassName(self.getISAClassName(of: obj));
            if (metaClassName.count > 0) {
                metaClassNameMap[obj.isaAddress] = metaClassName;
            } else {
                continue;
            }
            
            let superClassName: String = demangleClassName(self.getSuperClassName(of: obj) );
            if (superClassName.count > 0) {
                Log("\(i). \(metaClassName) : \(superClassName)")
                self.classNameInheritanceMap[metaClassName] = superClassName;
            } else {
                Log("\(i). \(metaClassName)")
            }
        }
        
    }
    
    
    func dumpAll() {
        
        for obj in self.protocolObjs {
            let protoName: String = obj.name;
            if let arr:[String] = self.nominalProtoMap[protoName] {
                obj.superProtocols = arr;
            }
            print(obj.dumpDefine)
        }
        
        for obj in nominalObjs {
            
            if let arr:[String] = self.nominalProtoMap[obj.typeName] {
                obj.protocols = arr;
            }
            
            var resoleSuperFromOC:Bool = obj.superClassName.isEmpty;
            if (obj.superClassName.hasPrefix("0x")) {
                if let tmp = self.mangledNameMap[obj.superClassName], !tmp.isEmpty {
                    obj.superClassName = tmp;
                    resoleSuperFromOC = false;
                }
            } else {
                let tmp = runtimeGetDemangledName("$s" + obj.superClassName);
                if (!tmp.hasPrefix("$s") && tmp != obj.superClassName) {
                    obj.superClassName = tmp;
                }
            }
            if (resoleSuperFromOC) {
                obj.superClassName = self.classNameInheritanceMap[obj.typeName] ?? obj.superClassName;
            }
            
            
            for field in obj.fields {
                let ft: String = field.type;
                if (ft.hasPrefix("0x")) {
                    if let fixName = mangledNameMap[ft] {
                        field.type = fixName;
                    } else {
                        //
                        field.type = fixMangledName(ft, startPtr: field.typePtr)
                    }
                    
                } else if (ft != "String") {
                    let checkName: String = "$s" + ft;
                    let tmp: String = runtimeGetDemangledName(checkName)
                    if (tmp != checkName ) {
                        field.type = tmp;
                    }
                }
            }
            print(obj.dumpDefine)
        }
    }
    
    func makeDemangledTypeName(_ type: String, header: String) -> String {
        
        let isArray:Bool = header.contains("Say") || header.contains("SDy");
        let suffix: String = isArray ? "G" : "";
        let fixName = "So\(type.count)\(type)C" + suffix;
        return fixName;
    }
    
    func fixMangledName(_ name: String, startPtr: SDPointer) -> String {
        // symbolic-references
        let hexName: String = name.removingPrefix("0x")
        let dataArray: [UInt8] = hexName.hexBytes
        //print(dataArray.map{ String(format: "0x%x", $0) })
        
        var mangledName: String = "";
        var i: Int = 0;
        
        while i < dataArray.count {
            let val = dataArray[i];
            if (val == 0x01) {
                //find
                let fromIdx:Int = i + 1; // ignore 0x01
                let toIdx:Int = i + 5; // 4 bytes
                if (toIdx > dataArray.count) {
                    mangledName = mangledName + String(format: "%c", val);
                    i = i + 1;
                    continue;
                }
                let offsetArray:[UInt8] = Array(dataArray[fromIdx..<toIdx]);
                
                let result: String = resoleSymbolicRefDirectly(offsetArray, ptr: startPtr.add( Int64(fromIdx) ));
                if (i == 0 && toIdx >= dataArray.count) {
                    mangledName = mangledName + result; // use original result
                } else {
                    let fixName = makeDemangledTypeName(result, header: "")
                    mangledName = mangledName + fixName;
                }
                
                i = i + 5;
            } else if (val == 0x02) {
                //indirectly
                let fromIdx:Int = i + 1; // ignore 0x02
                let toIdx:Int = ((i + 4) > dataArray.count) ? ( i + (dataArray.count - i) ) : (i + 4); // 4 bytes
                
                let offsetArray:[UInt8] = Array(dataArray[fromIdx..<toIdx]);
                let result: String = resoleSymbolicRefIndirectly(offsetArray, ptr: startPtr.add( Int64(fromIdx) ));
                
                if (i == 0 && toIdx >= dataArray.count) {
                    mangledName = mangledName + result;
                } else {
                    let fixName = makeDemangledTypeName(result, header: mangledName)
                    mangledName = mangledName + fixName
                }
                i = toIdx + 1;
            } else {
                //check next
                mangledName = mangledName + String(format: "%c", val);
                i = i + 1;
            }
        }
        
        let result: String = getTypeFromMangledName(mangledName)
        if (result == mangledName) {
            let tmp: String = runtimeGetDemangledName("$s" + mangledName)
            if (tmp != ("$s" + mangledName)) {
                return tmp;
            }
        }
        return result;
    }
    
    func resoleSymbolicRefDirectly(_ hexArray: [UInt8], ptr: SDPointer) -> String {
        // {any-generic-type, protocol, opaque-type-decl-name} ::= '\x01' .{4} // Reference points directly to context descriptor
        //print("resoleSymbolicRef", hexArray, ptr.desc)
        let origHex: String = "0x01" + hexArray.hex;
        let tmp = hexArray.reversed().hex;
        
        guard let address = Int64(tmp, radix: 16) else {
            return origHex;
        }
        
        let nominalArchPtr: SDPointer = ptr.add(address).fix();
        //print("ptr", tmpPtr.desc)
        let nominalArchOffset: Int64 = Int64(nominalArchPtr.address);
        return self.cacheNominalOffsetMap[nominalArchOffset] ?? origHex; // use hex as default value
    }
    
    func resoleSymbolicRefIndirectly(_ hexArray: [UInt8], ptr: SDPointer) -> String {
        // {any-generic-type, protocol, opaque-type-decl-name} ::= '\x02' .{4} // Reference points indirectly to context descriptor
        let origHex: String = "0x02" + hexArray.hex;
        let tmp = hexArray.reversed().hex;
        
        guard let address = Int64(tmp, radix: 16) else {
            return origHex;
        }
        let addrPtr = ptr.add(address).fix()
        
        if let loader = self.loader {
            // read the value from 'addrPtr' as address offset
            let val:UInt32 = loader.readU32(addrPtr);
            
            let nominalArchOffset: Int64 = Int64(val);
            return self.cacheNominalOffsetMap[nominalArchOffset] ?? origHex;
        }
        
        return origHex; // use hex as default value
    }
}



func dumpStruct(loader: SDFileLoader, nominalPtr: SDPointer, fieldDescriptorPtr: SDPointer, to: SDNominalObj) {
    //struct
    //let numFields:UInt32 = loader.readU32(nominalPtr.add(4 * 5));
    //let fieldOffsetVectorOffset:UInt32 = loader.readU32(nominalPtr.add(4 * 6));
    //print("  numFields \(numFields), fieldOffsetVectorOffset \(fieldOffsetVectorOffset)")
    dumpFieldDescriptor(loader: loader, fieldDescriptorPtr: fieldDescriptorPtr, to: to)
}


func dumpFieldDescriptor(loader: SDFileLoader, fieldDescriptorPtr: SDPointer, to: SDNominalObj) {
    //swift5_filedmd, FieldDescriptor
    
    let numFields = loader.readU32(fieldDescriptorPtr.add( 4 + 4 + 2 + 2) );
    if (0 == numFields) {
        return;
    }
    if (numFields >= 1000) {
        //TODO: sometimes it may be a invalid value
        Log("[dumpFieldDescriptor] \(numFields) too many fields of \(to.typeName), ignore format");
        return;
    }
    
    let fieldStart:SDPointer = fieldDescriptorPtr.add(4 + 4 + 2 + 2 + 4);
    for i in 0..<Int64(numFields) {
        let fieldAddr = fieldStart.add( i * (4 * 3) );
        
        let typeNamePtr = loader.readMove(fieldAddr.add(4)).fix();
        let typeName = loader.readStr(typeNamePtr);
        
        if let type = typeName, (type.count <= 0 || type.count > 100) {
            continue
        }
        
        let fieldNamePtr = loader.readMove(fieldAddr.add(8)).fix();
        let fieldName = loader.readStr(fieldNamePtr);
        
        if let field = fieldName, (field.count <= 0 || field.count > 100) {
            continue
        }
        
        if let type = typeName, let field = fieldName {
            
            let realType = getTypeFromMangledName(type);
            let fieldObj = SDNominalObjField();
            fieldObj.name = field; // name: field, type: realType
            fieldObj.type = realType;
            fieldObj.namePtr = fieldNamePtr;
            fieldObj.typePtr = typeNamePtr;
            to.fields.append(fieldObj);
            
            //print("    \(field) : \(realType),  \(fieldNamePtr.desc) : \(typeNamePtr.desc)")
        }
    }
}







