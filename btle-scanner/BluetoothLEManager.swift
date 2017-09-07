//
//  BluetoothLEManager.swift
//  BTLE Scanner
//
//  Created by Aaron Day on 8/30/17.
//  Copyright © 2017 Aaron Day. All rights reserved.
//

import Foundation
import CoreBluetooth

class BluetoothLEManager: NSObject {
    static let BTLE_HardwareEnabled: String = "BluetoothLE_HardwareEnabled"
    static let BTLE_HardwareDisabled = "BluetoothLE_HardwareDisabled"

    static let BTLE_ScanStart = "BluetoothLE_ScanStart"
    static let BTLE_ScanStop = "BluetoothLE_ScanStop"

    static let BTLE_DiscoveredPeripheral = "BluetoothLE_DiscoveredPeripherial"

    static let BTLE_ConnectedPeripheral = "BluetoothLE_ConnectedPeripherial"
    static let BTLE_FailedToConnectPeripheral = "BluetoothLE_FailedToConnectPeripherial"
    static let BTLE_DisconnectedPeripheral = "BluetoothLE_DisconnectdPeripherial"
    
    static let BTLE_UserInfoState = "BluetoothLE_UserInfoState"
    static let BTLE_UserInfoPeripheral = "BluetoothLE_UserInfoPeripheral"
    static let BTLE_UserInfoService = "BluetoothLE_UserInfoService"
    static let BTLE_UserInfoRSSI = "BluetoothLE_UserInfoRSSI"
    static let BTLE_UserInfoError = "BluetoothLE_UserInfoError"

    static let BTLE_Peripheral_DiscoveredServices = "BluetoothLE_Peripheral_DiscoveredServices"
    static let BTLE_Peripheral_DiscoveredCharacteristics = "BluetoothLE_Peripheral_DiscoveredCharacteristics"

    var centralManager: CBCentralManager?

    var enabled: Bool?
    var scanning: Bool?

    override init() {
        super.init()

        centralManager = CBCentralManager(delegate: self, queue: nil)
        enabled = false
        scanning = false
    }

    func startScan() {
        print("startScan")
        if enabled! && !scanning! {
            centralManager?.scanForPeripherals(withServices: nil, options: nil)
            scanning = true
            NotificationCenter.default.post(name: Notification.Name(BluetoothLEManager.BTLE_ScanStart), object: self)
        }
    }

    func stopScan() {
        print("stopScan")
        if scanning! {
            scanning = false
            centralManager?.stopScan()
            NotificationCenter.default.post(name: Notification.Name(BluetoothLEManager.BTLE_ScanStop), object: self)
        }
    }

    func connect(_ peripheral: CBPeripheral, _ options: [String: Any]? = nil) {
        print("connect \(peripheral) \(options ?? [:])")
        centralManager?.connect(peripheral, options: options)
    }

    func disconnect(_ peripheral: CBPeripheral) {
        print("disconnect: \(peripheral)")
        centralManager?.cancelPeripheralConnection(peripheral)
    }
}

// MARK: CBCentralManagerDelegate
extension BluetoothLEManager: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ centralManager: CBCentralManager) {
        switch centralManager.state {
        case CBCentralManagerState.unsupported:
            print("centralManager.state: unsupported")
            self.enabled = false
            NotificationCenter.default.post(name: Notification.Name(BluetoothLEManager.BTLE_HardwareDisabled), object: self, userInfo: [BluetoothLEManager.BTLE_UserInfoRSSI: CBCentralManagerState.unsupported])
        case CBCentralManagerState.unauthorized:
            print("centralManager.state: unauthorized")
            self.enabled = false
            NotificationCenter.default.post(name: Notification.Name(BluetoothLEManager.BTLE_HardwareDisabled), object: self, userInfo: [BluetoothLEManager.BTLE_UserInfoRSSI: CBCentralManagerState.unauthorized])
        case CBCentralManagerState.unknown:
            print("centralManager.state: unknown")
            self.enabled = false
            NotificationCenter.default.post(name: Notification.Name(BluetoothLEManager.BTLE_HardwareDisabled), object: self, userInfo: [BluetoothLEManager.BTLE_UserInfoRSSI: CBCentralManagerState.unknown])
        case CBCentralManagerState.resetting:
            print("centralManager.state: resetting")
            self.enabled = false
            NotificationCenter.default.post(name: Notification.Name(BluetoothLEManager.BTLE_HardwareDisabled), object: self, userInfo: [BluetoothLEManager.BTLE_UserInfoRSSI: CBCentralManagerState.resetting])
        case CBCentralManagerState.poweredOn:
            print("centralManager.state: poweredOn")
            self.enabled = true
            NotificationCenter.default.post(name: Notification.Name(BluetoothLEManager.BTLE_HardwareEnabled), object: self, userInfo: [BluetoothLEManager.BTLE_UserInfoRSSI: CBCentralManagerState.poweredOn])
        case CBCentralManagerState.poweredOff:
            print("centralManager.state: poweredOff")
            self.enabled = false
            NotificationCenter.default.post(name: Notification.Name(BluetoothLEManager.BTLE_HardwareDisabled), object: self, userInfo: [BluetoothLEManager.BTLE_UserInfoRSSI: CBCentralManagerState.poweredOff])
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("centralManager.discovered: \(peripheral)")
        NotificationCenter.default.post(name: Notification.Name(BluetoothLEManager.BTLE_DiscoveredPeripheral), object: self, userInfo: [BluetoothLEManager.BTLE_UserInfoPeripheral: peripheral, BluetoothLEManager.BTLE_UserInfoRSSI: RSSI])
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("centralManager.didConnect: \(peripheral)")

        peripheral.delegate = self
        peripheral.discoverServices(nil)

        NotificationCenter.default.post(name: Notification.Name(BluetoothLEManager.BTLE_ConnectedPeripheral), object: self, userInfo: [BluetoothLEManager.BTLE_UserInfoPeripheral: peripheral])
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("centralManager.didFailToConnect: \(peripheral)")

        var userInfo: [AnyHashable: Any] = [:]
        userInfo[BluetoothLEManager.BTLE_UserInfoPeripheral] = peripheral
        if error != nil {
            userInfo[BluetoothLEManager.BTLE_UserInfoError] = error
        }

        NotificationCenter.default.post(name: Notification.Name(BluetoothLEManager.BTLE_FailedToConnectPeripheral), object: self, userInfo: userInfo)
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("centralManager.didDisconnect: \(peripheral)")

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
        print("peripheral:didDiscoverService: \(peripheral.services ?? [])")

        NotificationCenter.default.post(name: Notification.Name(BluetoothLEManager.BTLE_Peripheral_DiscoveredServices), object: self, userInfo: [BluetoothLEManager.BTLE_UserInfoPeripheral: peripheral])

        for service: CBService in peripheral.services! {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("peripheral:didDiscoverCharacteristicsForService:")

        NotificationCenter.default.post(name: Notification.Name(BluetoothLEManager.BTLE_Peripheral_DiscoveredCharacteristics), object: self, userInfo: [BluetoothLEManager.BTLE_UserInfoPeripheral: peripheral, BluetoothLEManager.BTLE_UserInfoService: service])
    }
}

