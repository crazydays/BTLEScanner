//
//  BluetoothLEManager.swift
//  BTLE Scanner
//
//  Created by Aaron Day on 8/30/17.
//  Copyright © 2017 Aaron Day. All rights reserved.
//

import Foundation
import CoreBluetooth

final class BluetoothLEManager: NSObject {
    static let shared = BluetoothLEManager()

    static let BTLE_HardwareEnabled: String = "BluetoothLE_HardwareEnabled"
    static let BTLE_HardwareDisabled = "BluetoothLE_HardwareDisabled"

    static let BTLE_ScanStart = "BluetoothLE_ScanStart"
    static let BTLE_ScanStop = "BluetoothLE_ScanStop"

    static let BTLE_DiscoveredPeripheral = "BluetoothLE_DiscoveredPeripherial"

    static let BTLE_ConnectedPeripheral = "BluetoothLE_ConnectedPeripherial"
    static let BTLE_FailedToConnectPeripheral = "BluetoothLE_FailedToConnectPeripherial"
    static let BTLE_DisconnectedPeripheral = "BluetoothLE_DisconnectdPeripherial"

    static let BTLE_Peripheral_DiscoveredServices = "BluetoothLE_Peripheral_DiscoveredServices"
    static let BTLE_Peripheral_DiscoveredCharacteristics = "BluetoothLE_Peripheral_DiscoveredCharacteristics"
    static let BTLE_Peripheral_DiscoveredCharacteristicDescriptor = "BluetoothLE_Peripheral_DiscoveredCharacteristicDescriptor"
    static let BTLE_Peripheral_CharacteristicUpdatedValue = "BluetoothLE_Peripheral_CharacteristicUpdatedValue"

    static let BTLE_UserInfoState = "BluetoothLE_UserInfoState"
    static let BTLE_UserInfoPeripheral = "BluetoothLE_UserInfoPeripheral"
    static let BTLE_UserInfoService = "BluetoothLE_UserInfoService"
    static let BTLE_UserInfoCharacteristic = "BluetoothLE_UserInfoCharacteristic"
    static let BTLE_UserInfoRSSI = "BluetoothLE_UserInfoRSSI"
    static let BTLE_UserInfoError = "BluetoothLE_UserInfoError"

    var centralManager: CBCentralManager?

    var enabled = false
    var scanning = false

    private override init() {
        super.init()

        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func initialize() {
        // does nothing other than make sure the bluetooth system is initialized
    }

    func startScan() {
        print("startScan")
        if enabled && !scanning {
            centralManager?.scanForPeripherals(withServices: nil, options: nil)
            scanning = true
            NotificationCenter.default.post(name: Notification.Name(BluetoothLEManager.BTLE_ScanStart), object: self)
        }
    }

    func stopScan() {
        print("stopScan")
        if scanning {
            scanning = false
            centralManager?.stopScan()
            NotificationCenter.default.post(name: Notification.Name(BluetoothLEManager.BTLE_ScanStop), object: self)
        }
    }

    func connect(_ peripheral: CBPeripheral, _ options: [String: Any]? = nil) {
        print("connect \(peripheral.identifier.uuidString) \(options ?? [:])")
        centralManager?.connect(peripheral, options: options)
    }

    func disconnect(_ peripheral: CBPeripheral) {
        print("disconnect: \(peripheral.identifier.uuidString)")
        centralManager?.cancelPeripheralConnection(peripheral)
    }
}

// MARK: CBCentralManagerDelegate
extension BluetoothLEManager: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ centralManager: CBCentralManager) {
        switch centralManager.state {
        case .unsupported:
            print("centralManager.state: unsupported")
            self.enabled = false
            NotificationCenter.default.post(name: Notification.Name(BluetoothLEManager.BTLE_HardwareDisabled), object: self, userInfo: [BluetoothLEManager.BTLE_UserInfoRSSI: CBManagerState.unsupported])
        case .unauthorized:
            print("centralManager.state: unauthorized")
            self.enabled = false
            NotificationCenter.default.post(name: Notification.Name(BluetoothLEManager.BTLE_HardwareDisabled), object: self, userInfo: [BluetoothLEManager.BTLE_UserInfoRSSI: CBManagerState.unauthorized])
        case .unknown:
            print("centralManager.state: unknown")
            self.enabled = false
            NotificationCenter.default.post(name: Notification.Name(BluetoothLEManager.BTLE_HardwareDisabled), object: self, userInfo: [BluetoothLEManager.BTLE_UserInfoRSSI: CBManagerState.unknown])
        case .resetting:
            print("centralManager.state: resetting")
            self.enabled = false
            NotificationCenter.default.post(name: Notification.Name(BluetoothLEManager.BTLE_HardwareDisabled), object: self, userInfo: [BluetoothLEManager.BTLE_UserInfoRSSI: CBManagerState.resetting])
        case .poweredOn:
            print("centralManager.state: poweredOn")
            self.enabled = true
            NotificationCenter.default.post(name: Notification.Name(BluetoothLEManager.BTLE_HardwareEnabled), object: self, userInfo: [BluetoothLEManager.BTLE_UserInfoRSSI: CBManagerState.poweredOn])
        case .poweredOff:
            print("centralManager.state: poweredOff")
            self.enabled = false
            NotificationCenter.default.post(name: Notification.Name(BluetoothLEManager.BTLE_HardwareDisabled), object: self, userInfo: [BluetoothLEManager.BTLE_UserInfoRSSI: CBManagerState.poweredOff])
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("centralManager.discovered: \(peripheral.identifier.uuidString)")
        NotificationCenter.default.post(name: Notification.Name(BluetoothLEManager.BTLE_DiscoveredPeripheral), object: self, userInfo: [BluetoothLEManager.BTLE_UserInfoPeripheral: peripheral, BluetoothLEManager.BTLE_UserInfoRSSI: RSSI])
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("centralManager.didConnect: \(peripheral.identifier.uuidString)")

        peripheral.delegate = self
        peripheral.discoverServices(nil)

        NotificationCenter.default.post(name: Notification.Name(BluetoothLEManager.BTLE_ConnectedPeripheral), object: self, userInfo: [BluetoothLEManager.BTLE_UserInfoPeripheral: peripheral])
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("centralManager.didFailToConnect: \(peripheral.identifier.uuidString)")

        var userInfo: [AnyHashable: Any] = [:]
        userInfo[BluetoothLEManager.BTLE_UserInfoPeripheral] = peripheral
        if error != nil {
            userInfo[BluetoothLEManager.BTLE_UserInfoError] = error
        }

        NotificationCenter.default.post(name: Notification.Name(BluetoothLEManager.BTLE_FailedToConnectPeripheral), object: self, userInfo: userInfo)
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("centralManager.didDisconnect: \(peripheral.identifier.uuidString)")

        var userInfo: [AnyHashable: Any] = [:]
        userInfo[BluetoothLEManager.BTLE_UserInfoPeripheral] = peripheral
        if error != nil {
            userInfo[BluetoothLEManager.BTLE_UserInfoError] = error
        }

        NotificationCenter.default.post(name: Notification.Name(BluetoothLEManager.BTLE_DisconnectedPeripheral), object: self, userInfo: userInfo)
    }
}

extension BluetoothLEManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("peripheral:didDiscoverService: \(peripheral.identifier.uuidString)")

        NotificationCenter.default.post(name: Notification.Name(BluetoothLEManager.BTLE_Peripheral_DiscoveredServices), object: self, userInfo: [BluetoothLEManager.BTLE_UserInfoPeripheral: peripheral])

        for service: CBService in peripheral.services! {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("peripheral:didDiscoverCharacteristicsForService: \(service.uuid.uuidString)")

        NotificationCenter.default.post(name: Notification.Name(BluetoothLEManager.BTLE_Peripheral_DiscoveredCharacteristics), object: self, userInfo: [BluetoothLEManager.BTLE_UserInfoPeripheral: peripheral, BluetoothLEManager.BTLE_UserInfoService: service])

        for characteristic in service.characteristics! {
            peripheral.discoverDescriptors(for: characteristic)
            peripheral.readValue(for: characteristic)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        print("peripheral:didUpdateValueForCharacteristic: \(characteristic.uuid.uuidString)")

        NotificationCenter.default.post(name: Notification.Name(BluetoothLEManager.BTLE_Peripheral_CharacteristicUpdatedValue), object: self, userInfo: [BluetoothLEManager.BTLE_UserInfoPeripheral: peripheral, BluetoothLEManager.BTLE_UserInfoCharacteristic: characteristic])
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        print("peripheral:didDiscoverDescriptorsForCharacteristic: \(characteristic.uuid.uuidString)")
        for descriptor in (characteristic.descriptors ?? []) {
            print("peripheral:didDiscoverDescriptorsForCharacteristic: \(characteristic.uuid.uuidString) \(descriptor.uuid.uuidString)")
        }

        NotificationCenter.default.post(name: Notification.Name(BluetoothLEManager.BTLE_Peripheral_DiscoveredCharacteristicDescriptor), object: self, userInfo: [BluetoothLEManager.BTLE_UserInfoPeripheral: peripheral, BluetoothLEManager.BTLE_UserInfoCharacteristic: characteristic])

        for descriptor in characteristic.descriptors! {
            peripheral.readValue(for: descriptor)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        print("peripheral:diddidUpdateValueForDescriptor: \(descriptor.uuid.uuidString) \(descriptor.value ?? "")")
    }
}

