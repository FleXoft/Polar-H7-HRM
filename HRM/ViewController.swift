//
//  ViewController.swift
//  HRM
//
//  Created by FLEISCHMANN György on 2017. 03. 27..
//  Copyright © 2017. FLEISCHMANN György. All rights reserved.
//

import Cocoa
import CoreBluetooth

class ViewController: NSViewController, CBCentralManagerDelegate, CBPeripheralDelegate {

    let doc = NSApp.dockTile as NSDockTile
    
    @IBOutlet weak var BPMTextFiled: NSTextField!
    @IBOutlet weak var RSSITextField: NSTextField!
    @IBOutlet weak var BATTERYTextField: NSTextField!
    
    var centralManager:CBCentralManager!
    var connectingPeripheral:CBPeripheral!
    
    // "Generic Access" service
    let           POLARH7_HRM_GENERIC_ACCESS_SERVICE_UUID = "1800"
    // and its characteristics
    
    // "Device Information" service
    let              POLARH7_HRM_DEVICE_INFO_SERVICE_UUID = "180A"
    // and its characteristics
    let         POLARH7_HRM_SYSTEM_ID_CHARACTERISTIC_UUID = "2A23"
    let      POLARH7_HRM_MODEL_NUMBER_CHARACTERISTIC_UUID = "2A24"
    let     POLARH7_HRM_SERIAL_NUMBER_CHARACTERISTIC_UUID = "2A25"
    let POLARH7_HRM_FIRMWARE_REVISION_CHARACTERISTIC_UUID = "2A26"
    let POLARH7_HRM_HARDWARE_REVISION_CHARACTERISTIC_UUID = "2A27"
    let POLARH7_HRM_SOFTWARE_REVISION_CHARACTERISTIC_UUID = "2A28"
    let POLARH7_HRM_MANUFACTURER_NAME_CHARACTERISTIC_UUID = "2A29"
    
    // "Heart Rate" service
    let               POLARH7_HRM_HEART_RATE_SERVICE_UUID = "180D"
    // and its characteristics
    let        POLARH7_HRM_HEART_RATE_CHARACTERISTIC_UUID = "2A37"
    let   POLARH7_HRM_SENSOR_LOCATION_CHARACTERISTIC_UUID = "2A38"
    let     POLARH7_HRM_CONTROL_POINT_CHARACTERISTIC_UUID = "2A39"

    // "Battery Service" service
    let                  POLARH7_HRM_BATTERY_SERVICE_UUID = "180F"
    // and its characteristics
    let     POLARH7_HRM_BATTERY_LEVEL_CHARACTERISTIC_UUID = "2A19"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        print("- viewDidLoad begin")
        
//let services = [CBUUID(string: POLARH7_HRM_HEART_RATE_SERVICE_UUID), CBUUID(string: POLARH7_HRM_DEVICE_INFO_SERVICE_UUID)]
//let centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        
        let centralManager = CBCentralManager(delegate: self, queue: nil)
        
//centralManager.scanForPeripherals(withServices: services, options: [CBCentralManagerScanOptionAllowDuplicatesKey: NSNumber(value: true)])
//[centralManager scanForPeripheralsWithServices:services options:nil];
        
        self.centralManager = centralManager;
    
        print("- viewDidLoad end")
    }
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
            
        }
    }
    
    // centralManagerDidUpdateState
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("-- centralManagerDidUpdateState begin")
        
        switch central.state{
        case .poweredOn:
            print("-- central state is poweredOn")
            
            let services = [CBUUID(string: POLARH7_HRM_HEART_RATE_SERVICE_UUID), CBUUID(string: POLARH7_HRM_DEVICE_INFO_SERVICE_UUID)]

// let serviceUUIDs:[AnyObject] = [CBUUID(string: POLARH7_HRM_HEART_RATE_SERVICE_UUID)]
// let lastPeripherals = centralManager.retrieveConnectedPeripherals(withServices: serviceUUIDs as! [CBUUID])
            
            let lastPeripherals = centralManager.retrieveConnectedPeripherals(withServices: services)
            
            if lastPeripherals.count > 0 {
                let myDevice = lastPeripherals.last! as CBPeripheral;
                
                connectingPeripheral = myDevice;
                centralManager.connect(connectingPeripheral, options: nil)
                
                print("-- Found device: \(myDevice)")
            }
            else {
                print("-- Start scanning...")
                
                centralManager.scanForPeripherals(withServices: services, options: nil)
            }
        case .poweredOff:
            print("-- central state is powered off")
        case .resetting:
            print("-- central state is resetting")
        case .unauthorized:
            print("-- central state is unauthorized")
        case .unknown:
            print("-- central state is unknown")
        case .unsupported:
            print("-- central state is unsupported")
        @unknown default:
            print("Swift 5 migraion: @unknown default: case");
        }
        
        print("-- centralManagerDidUpdateState end")
    }
    
    // centralManager didDiscover
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("--- didDiscover peripheral begin")
        
        if let localName = advertisementData[CBAdvertisementDataLocalNameKey] as? String {
            print("--- Found POLAR H7 heart rate monitor named: \(localName).")
            print("--- Found POLAR H7 heart rate monitor  RSSI: \(RSSI) db (-30 dB Amazing, -67 dB Very Good, -70 dB Okay, -80 dB Not Good, -90 dB Unusable).")
            
            print("--- Stop scanning")
            self.centralManager.stopScan()
            
            connectingPeripheral = peripheral
            connectingPeripheral.delegate = self
            centralManager.connect(connectingPeripheral, options: nil)
        } else {
            print("--- ??? advertisementData[CBAdvertisementDataLocalNameKey] \(String(describing: advertisementData[CBAdvertisementDataLocalNameKey]))")
        }
        
        print("--- didDiscover peripheral end")
    }
    
    // centralManager didConnect
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("---- didConnectPeripheral begin")
        
        peripheral.delegate = self
        peripheral.discoverServices(nil)
        print("---- peripheral state is \(peripheral.state.rawValue)")
        
        print("---- didConnectPeripheral end")
    }
    
    // centralManager didDisonnect
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("---- didDisonnectPeripheral begin")
        
        // Start it over
        print("-- Start scanning over...")
        let services = [CBUUID(string: POLARH7_HRM_HEART_RATE_SERVICE_UUID), CBUUID(string: POLARH7_HRM_DEVICE_INFO_SERVICE_UUID)]
        centralManager.scanForPeripherals(withServices: services, options: nil)
            //[CBCentralManagerScanOptionAllowDuplicatesKey: NSNumber(value: true)])
        
        // update the badge on the icon
        doc.badgeLabel = "--- bpm"
        
        print("---- didDisconnectPeripheral end")
    }
    
    // peripheral didDiscoverServices
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        if (error) != nil{
            print("----- error in didDiscoverServices: \(String(describing: error?.localizedDescription))")
        }
        else {
            print("----- didDiscoverServices begin")
            
            for service in (peripheral.services as [CBService]?)! {
                print ("+++++ Service: \(String(describing: service.uuid))")
                
                peripheral.discoverCharacteristics(nil, for: service)
                
                print("      --------------------------------------------")
                print("      Service UUID: \(service.uuid.uuidString)")
                print("      Service isPrimary: \(service.isPrimary)")
                print("      Service isProxy: \(service.isProxy())")
                print("      --------------------------------------------")
            }
        }
        
        print("----- didDiscoverServices end")
    }
    
    // peripheral didDiscoverCharacteristicsFor
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        if (error) != nil {
            print("------ error in didDiscoverCharacteristicsFor: \(String(describing: error?.localizedDescription))")
        }
        else {
            print("------ didDiscoverCharacteristicsFor begin \(String(describing: error?.localizedDescription)) UUID \(service.uuid)")
            
            // Generic Access
            if service.uuid == CBUUID(string: POLARH7_HRM_GENERIC_ACCESS_SERVICE_UUID) {
                print("++++++ Found Generic Access")
            }
            
            // Device Information
            if service.uuid == CBUUID(string: POLARH7_HRM_DEVICE_INFO_SERVICE_UUID) {
                print("++++++ Found Device Information")
                
                for characteristic in service.characteristics! as [CBCharacteristic] {
                    
                    switch characteristic.uuid.uuidString {
                    case POLARH7_HRM_SYSTEM_ID_CHARACTERISTIC_UUID:
                        print("------ System ID")
                        peripheral.readValue(for: characteristic)

                    case POLARH7_HRM_SYSTEM_ID_CHARACTERISTIC_UUID:
                        print("------ Model Number String")
                        peripheral.readValue(for: characteristic)
                        
                    case POLARH7_HRM_SERIAL_NUMBER_CHARACTERISTIC_UUID:
                        print("------ Serial Number String")
                        peripheral.readValue(for: characteristic)
                        
                    case POLARH7_HRM_FIRMWARE_REVISION_CHARACTERISTIC_UUID:
                        print("------ Firmware Revision String")
                        peripheral.readValue(for: characteristic)
                        
                    case POLARH7_HRM_HARDWARE_REVISION_CHARACTERISTIC_UUID:
                        print("------ Hardware Revision String")
                        peripheral.readValue(for: characteristic)
                        
                    case POLARH7_HRM_SOFTWARE_REVISION_CHARACTERISTIC_UUID:
                        print("------ Software Revision String")
                        peripheral.readValue(for: characteristic)
                        
                    case POLARH7_HRM_MANUFACTURER_NAME_CHARACTERISTIC_UUID:
                        print("------ Manufacturer Name String")
                        peripheral.readValue(for: characteristic)
                        
                    default:
                        print()
                    }
                
                    print("       --------------------------------------------")
                    print("       Characteristic UUID: \(characteristic.uuid)")
                    print("       Characteristic UUID: \(characteristic.uuid.uuidString)")
                    print("       Characteristic isNotifying: \(characteristic.isNotifying)")
                    print("       Characteristic properties: \(characteristic.properties)")
                    
                    if (characteristic.properties.rawValue & CBCharacteristicProperties.broadcast.rawValue) > 0 {
                        print("broadcast")
                    }
                    if (characteristic.properties.rawValue & CBCharacteristicProperties.read.rawValue) > 0 {
                        print("read")
                    }
                    if (characteristic.properties.rawValue & CBCharacteristicProperties.writeWithoutResponse.rawValue) > 0 {
                        print("write without response")
                    }
                    if (characteristic.properties.rawValue & CBCharacteristicProperties.write.rawValue) > 0 {
                        print("write")
                    }
                    if (characteristic.properties.rawValue & CBCharacteristicProperties.notify.rawValue) > 0 {
                        print("notify")
                    }
                    if (characteristic.properties.rawValue & CBCharacteristicProperties.indicate.rawValue) > 0 {
                        print("indicate")
                    }
                    if (characteristic.properties.rawValue & CBCharacteristicProperties.authenticatedSignedWrites.rawValue) > 0 {
                        print("authenticated signed writes ")
                    }
                    if (characteristic.properties.rawValue & CBCharacteristicProperties.extendedProperties.rawValue) > 0 {
                        print("indicate")
                    }
                    if (characteristic.properties.rawValue & CBCharacteristicProperties.notifyEncryptionRequired.rawValue) > 0 {
                        print("notify encryption required")
                    }
                    if (characteristic.properties.rawValue & CBCharacteristicProperties.indicateEncryptionRequired.rawValue) > 0 {
                        print("indicate encryption required")
                    }
                    
                    print("       Characteristic descriptors: \(String(describing: characteristic.descriptors))")
                    print("       Characteristic value: \(String(describing: characteristic.value))")
                    print("       --------------------------------------------")
                }
            }
            
            // Heart Rate
            if service.uuid == CBUUID(string: POLARH7_HRM_HEART_RATE_SERVICE_UUID) {
                print("++++++ Heart Rate Service")
                
                for characteristic in service.characteristics! as [CBCharacteristic] {
                    
                    switch characteristic.uuid.uuidString {
                    case POLARH7_HRM_HEART_RATE_CHARACTERISTIC_UUID:
                        // Set notification on heart rate measurement
                        print("------ Found Heart Rate Measurement Characteristic")
                        peripheral.setNotifyValue(true, for: characteristic)
                        
                    case POLARH7_HRM_SENSOR_LOCATION_CHARACTERISTIC_UUID:
                        // Read body sensor location
                        print("------ Found Body Sensor Location Characteristic")
                        peripheral.readValue(for: characteristic)
                        
                    case POLARH7_HRM_MANUFACTURER_NAME_CHARACTERISTIC_UUID:
                        // Name
                        print("------ Found HRM manufacturer name Characteristic")
                        peripheral.readValue(for: characteristic)
                        
                    case POLARH7_HRM_CONTROL_POINT_CHARACTERISTIC_UUID:
                        // Write heart rate control point ???
                        print("------ Found Heart Rate Control Point Characteristic")
                        
                        var rawArray:[UInt8] = [0x01];
                        let data = NSData(bytes: &rawArray, length: rawArray.count)
                        peripheral.writeValue(data as Data, for: characteristic, type: CBCharacteristicWriteType.withoutResponse)
                        
                    default:
                        print()
                    }
                    
                    print("       --------------------------------------------")
                    print("       Characteristic UUID: \(characteristic.uuid)")
                    print("       Characteristic UUID: \(characteristic.uuid.uuidString)")
                    print("       Characteristic isNotifying: \(characteristic.isNotifying)")
                    print("       Characteristic properties: \(characteristic.properties)")
                    
                    if (characteristic.properties.rawValue & CBCharacteristicProperties.broadcast.rawValue) > 0 {
                        print("broadcast")
                    }
                    if (characteristic.properties.rawValue & CBCharacteristicProperties.read.rawValue) > 0 {
                        print("read")
                    }
                    if (characteristic.properties.rawValue & CBCharacteristicProperties.writeWithoutResponse.rawValue) > 0 {
                        print("write without response")
                    }
                    if (characteristic.properties.rawValue & CBCharacteristicProperties.write.rawValue) > 0 {
                        print("write")
                    }
                    if (characteristic.properties.rawValue & CBCharacteristicProperties.notify.rawValue) > 0 {
                        print("notify")
                    }
                    if (characteristic.properties.rawValue & CBCharacteristicProperties.indicate.rawValue) > 0 {
                        print("indicate")
                    }
                    if (characteristic.properties.rawValue & CBCharacteristicProperties.authenticatedSignedWrites.rawValue) > 0 {
                        print("authenticated signed writes ")
                    }
                    if (characteristic.properties.rawValue & CBCharacteristicProperties.extendedProperties.rawValue) > 0 {
                        print("indicate")
                    }
                    if (characteristic.properties.rawValue & CBCharacteristicProperties.notifyEncryptionRequired.rawValue) > 0 {
                        print("notify encryption required")
                    }
                    if (characteristic.properties.rawValue & CBCharacteristicProperties.indicateEncryptionRequired.rawValue) > 0 {
                        print("indicate encryption required")
                    }
                    
                    print("       Characteristic descriptors: \(String(describing: characteristic.descriptors))")
                    print("       Characteristic value: \(String(describing: characteristic.value))")
                    print("       --------------------------------------------")
                }
            }
            
            // Battery Service
            if service.uuid == CBUUID(string: POLARH7_HRM_BATTERY_SERVICE_UUID) {
                print("++++++ Found Battery Service")
                
                for characteristic in service.characteristics! as [CBCharacteristic] {
                    
                    switch characteristic.uuid.uuidString {
                    case POLARH7_HRM_BATTERY_LEVEL_CHARACTERISTIC_UUID:
                        print("------ Battery Level")
                        peripheral.readValue(for: characteristic)
                        
                    default:
                        print()
                    }
                    
                    print("       --------------------------------------------")
                    print("       Characteristic UUID: \(characteristic.uuid)")
                    print("       Characteristic UUID: \(characteristic.uuid.uuidString)")
                    print("       Characteristic isNotifying: \(characteristic.isNotifying)")
                    print("       Characteristic properties: \(characteristic.properties)")
                    
                    if (characteristic.properties.rawValue & CBCharacteristicProperties.broadcast.rawValue) > 0 {
                        print("broadcast")
                    }
                    if (characteristic.properties.rawValue & CBCharacteristicProperties.read.rawValue) > 0 {
                        print("read")
                    }
                    if (characteristic.properties.rawValue & CBCharacteristicProperties.writeWithoutResponse.rawValue) > 0 {
                        print("write without response")
                    }
                    if (characteristic.properties.rawValue & CBCharacteristicProperties.write.rawValue) > 0 {
                        print("write")
                    }
                    if (characteristic.properties.rawValue & CBCharacteristicProperties.notify.rawValue) > 0 {
                        print("notify")
                    }
                    if (characteristic.properties.rawValue & CBCharacteristicProperties.indicate.rawValue) > 0 {
                        print("indicate")
                    }
                    if (characteristic.properties.rawValue & CBCharacteristicProperties.authenticatedSignedWrites.rawValue) > 0 {
                        print("authenticated signed writes ")
                    }
                    if (characteristic.properties.rawValue & CBCharacteristicProperties.extendedProperties.rawValue) > 0 {
                        print("indicate")
                    }
                    if (characteristic.properties.rawValue & CBCharacteristicProperties.notifyEncryptionRequired.rawValue) > 0 {
                        print("notify encryption required")
                    }
                    if (characteristic.properties.rawValue & CBCharacteristicProperties.indicateEncryptionRequired.rawValue) > 0 {
                        print("indicate encryption required")
                    }
                    
                    print("       Characteristic descriptors: \(String(describing: characteristic.descriptors))")
                    print("       Characteristic value: \(String(describing: characteristic.value))")
                    print("       --------------------------------------------")
                }
            }
        }
        
        print("------ didDiscoverCharacteristicsFor end =====================================================")
    }
    
    // ??
    
//    func peripheral(_ peripheral: CBPeripheral, peripheralDidUpdateRSSI error: NSError) {
//        print("------- peripheralDidUpdateRSSI begin")
//
//       print("peripheralDidUpdateRSSI \(peripheral.name!) = \(peripheral.rssi ?? 0)")
//
//        print("------- peripheralDidUpdateRSSI end")
//    }
    
    
    // in iOS and tvOS, use the peripheral:didReadRSSI:error: method instead.
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        print("------- peripheralDidUpdateRSSI begin \(RSSI)")
        
        RSSITextField.stringValue = "RSSI: \(String(describing: RSSI)) db (-30 dB Amazing, -67 dB Very Good, -70 dB Okay, -80 dB Not Good, -90 dB Unusable)."
        
        print("------- peripheralDidUpdateRSSI end")
    }
    
    // peripheral didUpdateNotificationStateFor
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor
        characteristic: CBCharacteristic, error: Error?) {
        
        if ( error != nil ) {
            print("----- error in didUpdateNotificationStateFor: \(String(describing: error?.localizedDescription))")
            print("----- error in didUpdateNotificationStateFor: \(String(describing: error))")
        }
        else {
            
            print("------- didUpdateNotificationStateFor begin \(characteristic.uuid.uuidString)")
            
            print("       --------------------------------------------")
            print("       Characteristic UUID: \(characteristic.uuid)")
            print("       Characteristic UUID: \(characteristic.uuid.uuidString)")
            print("       Characteristic isNotifying: \(characteristic.isNotifying)")
            print("       Characteristic properties: \(characteristic.properties)")
            print("       Characteristic descriptors: \(String(describing: characteristic.descriptors))")
            print("       Characteristic value: \(String(describing: characteristic.value))")
            print("       --------------------------------------------")
            
            print("------- didUpdateNotificationStateFor end")
        }
    }
    
    // ??
    
    // peripheral didUpdateValueFor
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        print("------- didUpdateValueForCharacteristic begin \(characteristic.uuid.uuidString)")
    
        // continuous RSSI
        peripheral.readRSSI()
        //RSSITextField.stringValue = "RSSI: \(String(describing: peripheral.rssi ?? 0)) db (-30 dB Amazing, -67 dB Very Good, -70 dB Okay, -80 dB Not Good, -90 dB Unusable)."
        
        if ( error != nil ) {
            
        } else {
        
            switch characteristic.uuid.uuidString{
            case POLARH7_HRM_HEART_RATE_CHARACTERISTIC_UUID:
                updateHR(heartRateData:characteristic.value!)
                
            case POLARH7_HRM_BATTERY_LEVEL_CHARACTERISTIC_UUID:
                var buffer = [UInt8](repeating: 0x00, count: characteristic.value!.count)
                characteristic.value!.copyBytes(to: &buffer, count: buffer.count)
                
                print("UPDATING Battery Level: \(buffer[0])%")
            
                BATTERYTextField.stringValue = "Batt: \(buffer[0])%"
                
            case POLARH7_HRM_SENSOR_LOCATION_CHARACTERISTIC_UUID:
                var buffer = [UInt8](repeating: 0x00, count: characteristic.value!.count)
                characteristic.value!.copyBytes(to: &buffer, count: buffer.count)
                
                print("UPDATING Sensor Locaton: \(buffer[0]) (0 Other, 1 Chest, 2 Wrist, 3 Finger, 4 Hand, 5 Ear Lobe, 6 Foot, 7 - 255 Reserved for future use)")
                
            case POLARH7_HRM_SYSTEM_ID_CHARACTERISTIC_UUID:
                var buffer = [UInt8](repeating: 0x00, count: characteristic.value!.count)
                characteristic.value!.copyBytes(to: &buffer, count: buffer.count)
        
                print("UPDATING System ID: \(buffer[0...7])")
                
            case POLARH7_HRM_SYSTEM_ID_CHARACTERISTIC_UUID:
                printBuffer(string: "UPDATING Model Number: ", characteristic: characteristic)

            case POLARH7_HRM_SERIAL_NUMBER_CHARACTERISTIC_UUID:
                printBuffer(string: "UPDATING Serial Number: ", characteristic: characteristic)

            case POLARH7_HRM_FIRMWARE_REVISION_CHARACTERISTIC_UUID:
                printBuffer(string: "UPDATING Firmware Revision: ", characteristic: characteristic)

            case POLARH7_HRM_HARDWARE_REVISION_CHARACTERISTIC_UUID:
                printBuffer(string: "UPDATING Hardware Revision: ", characteristic: characteristic)

            case POLARH7_HRM_SOFTWARE_REVISION_CHARACTERISTIC_UUID:
                printBuffer(string: "UPDATING SW v: ", characteristic: characteristic)
                
            case POLARH7_HRM_MANUFACTURER_NAME_CHARACTERISTIC_UUID:
                printBuffer(string: "UPDATING Manufact: ", characteristic: characteristic)
                
            default:
                print()
            }
        }
        
        print("------- didUpdateValueForCharacteristic end")
    }
    
    func printBuffer(string:String, characteristic: CBCharacteristic) {
        var buffer = [UInt8](repeating: 0x00, count: characteristic.value!.count)
        characteristic.value!.copyBytes(to: &buffer, count: buffer.count)
        
        print("\(string)\(String(bytes: buffer, encoding: String.Encoding.utf8) ?? "")" )
    }
    
    // POLARH7_HRM_HEART_RATE_CHARACTERISTIC_UUID
    func updateHR(heartRateData:Data){
        var buffer = [UInt8](repeating: 0x00, count: heartRateData.count)
        heartRateData.copyBytes(to: &buffer, count: buffer.count)
        
        print("Count: \(buffer.count) \(buffer)")
        
        // uint8_t _hr_format_bit:1;
        // uint8_t _sensor_contact_bit:2;
        // uint8_t _energy_expended_bit:1;
        // uint8_t _rr_interval_bit:1;
        // uint8_t _reserved:3;
        
        let hr_format_MASK:UInt8       = 0x01
//        let sensor_contact_MASK:UInt8  = 0x06 // 4 Sensor Contact feature is supported and no contact, 6 Sensor Contact feature is supported and contact is detected
        let energy_expended_MASK:UInt8 = 0x08
        let rr_interval_MASK:UInt8     = 0x10
        // let reserved_MASK:UInt8        = 0xE0
        
        var offset = 0
        
        // 0 FLAGS
        offset += 1
        
        // BPM calculation
        var bpm:UInt16?
        var ene:UInt16?
        var rr:UInt16?
        var rr_value:Double?
        
        var logText:String = ""
        
        if (buffer.count >= 2) {
            if (buffer[0] & hr_format_MASK == 0) {
                print("Heart rate format UINT8")
                bpm = UInt16(buffer[offset+0]);
                offset += 1
            } else {
                print("Heart rate format UINT16")
                bpm = UInt16(buffer[offset+1]) << 8
                bpm =  bpm! | UInt16(buffer[offset+0])
                offset += 2
            }
        }
        logText += "\(String(bpm!))"
        
        // get energy if present
        if (buffer[0] & energy_expended_MASK != 0) {
            ene = UInt16(buffer[offset+1]) << 8
            ene = ene! | UInt16(buffer[offset+0])
            offset += 2
            print("EE: \(ene ?? 0)")
        }

        // get RRs if present
        while (offset < buffer.count ) {
            if (buffer[0] & rr_interval_MASK != 0) {
                // One or more RR-Interval values are present
                rr = UInt16(buffer[offset+1]) << 8
                rr = rr! | UInt16(buffer[offset+0])
                rr_value = (Double(rr!)/1024.0)*1000.0
                offset += 2
                print("RR: \(String(rr_value ?? 0)) ms")
                logText += ";\(String(Int(rr_value ?? 0)))"
                
                // RR file logging
                rrFileLogging(s: String(rr_value ?? 0))
            }
        }
        
        if (bpm!>70) {
            BPMTextFiled.textColor = NSColor.green
        } else if (bpm! > 100) {
            BPMTextFiled.textColor = NSColor.red
        } else {
            BPMTextFiled.textColor = NSColor.black
        }
        BPMTextFiled.stringValue = String(bpm!)
        
        // update the badge on the icon
        doc.badgeLabel = "\(String(bpm!)) bpm"

        print("Heart Rate: \(bpm!) bpm")
        
        // HRM file logging
        hrmFileLogging(s: logText)
        
    }
    
    // Simple file logging
    let hrmPath = "\(NSHomeDirectory())/hrm.log"
    //
    func hrmFileLogging(s:String) {
        print ("File logging HRM...")
        
        // path
        
        var dump = ""
        
        let date = Date()
        let calendar = Calendar.current
    
        let s2 = String(format: "%04d", calendar.component(.year, from: date)) + String(format: "%02d", calendar.component(.month, from: date)) + String(format: "%02d", calendar.component(.day, from: date)) + ";" + String(format: "%02d", calendar.component(.hour, from: date)) + String(format: "%02d", calendar.component(.minute, from: date)) + String(format: "%02d", calendar.component(.second, from: date)) + ";" + s
        
        if FileManager.default.fileExists(atPath: hrmPath) {
            dump =  try! String(contentsOfFile: hrmPath, encoding: String.Encoding.utf8)
        }
        do {
            // Write to the HRM file
            try  "\(dump)\n\(s2)".write(toFile: hrmPath, atomically: true, encoding: String.Encoding.utf8)
            
        } catch let error as NSError {
            print("Failed writing to HRM log file: \(hrmPath), Error: " + error.localizedDescription)
        }
    }

    // Simple file logging
    let rrPath = "\(NSHomeDirectory())/rr.log"
    //
    func rrFileLogging(s:String) {
        print ("File logging RR...")
        
        // path
        
        var dump = ""
    
        if FileManager.default.fileExists(atPath: rrPath) {
            dump =  try! String(contentsOfFile: rrPath, encoding: String.Encoding.utf8)
        }
        do {
            // Write to the RR file
            try  "\(dump)\n\(s)".write(toFile: rrPath, atomically: true, encoding: String.Encoding.utf8)
            
        } catch let error as NSError {
            print("Failed writing to RR log file: \(rrPath), Error: " + error.localizedDescription)
        }
    }
    
}
