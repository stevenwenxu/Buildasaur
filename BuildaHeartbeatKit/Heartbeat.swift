//
//  Heartbeat.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 17/09/2015.
//  Copyright © 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import ekgclient
import BuildaUtils

public protocol HeartbeatManagerDelegate {
    func typesOfRunningSyncers() -> [String: Int]
}

//READ: https://github.com/czechboy0/Buildasaur/tree/master#heartpulse-heartbeat
@objc public class HeartbeatManager: NSObject {
    
    public var delegate: HeartbeatManagerDelegate?
    
    private let client: EkgClient
    private let creationTime: Double
    private var timer: NSTimer?
    private var initialTimer: NSTimer?
    private let interval: Double = 24 * 60 * 60 //send heartbeat once in 24 hours
    
    public init(server: String) {
        let bundle = NSBundle.mainBundle()
        let appIdentifier = EkgClientHelper.pullAppIdentifierFromBundle(bundle) ?? "Unknown app"
        let version = EkgClientHelper.pullVersionFromBundle(bundle) ?? "?"
        let buildNumber = EkgClientHelper.pullBuildNumberFromBundle(bundle) ?? "?"
        let appInfo = AppInfo(appIdentifier: appIdentifier, version: version, build: buildNumber)
        let host = NSURL(string: server)!
        let serverInfo = ServerInfo(host: host)
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        self.creationTime = NSDate().timeIntervalSince1970
        let client = EkgClient(userDefaults: userDefaults, appInfo: appInfo, serverInfo: serverInfo)
        self.client = client
    }
    
    deinit {
        self.stop()
    }
    
    public func start() {
        self.sendLaunchedEvent()
        self.startSendingHeartbeat()
    }
    
    public func stop() {
        self.stopSendingHeartbeat()
    }
    
    public func willInstallSparkleUpdate() {
        self.sendEvent(UpdateEvent())
    }
    
    private func sendEvent(event: Event) {
        
        Log.info("Sending heartbeat event \(event.jsonify())")
        
        self.client.sendEvent(event) {
            if let error = $0 {
                Log.error("Failed to send a heartbeat event. Error \(error)")
            }
        }
    }
    
    private func sendLaunchedEvent() {
        self.sendEvent(LaunchEvent())
    }
    
    private func sendHeartbeatEvent() {
        let uptime = NSDate().timeIntervalSince1970 - self.creationTime
        let typesOfRunningSyncers = self.delegate?.typesOfRunningSyncers() ?? [:]
        self.sendEvent(HeartbeatEvent(uptime: uptime, typesOfRunningSyncers: typesOfRunningSyncers))
    }
    
    func _timerFired(timer: NSTimer?=nil) {
        self.sendHeartbeatEvent()
        
        if let initialTimer = self.initialTimer where initialTimer.valid {
            initialTimer.invalidate()
            self.initialTimer = nil
        }
    }
    
    private func startSendingHeartbeat() {
        
        //send once in 10 seconds to give builda a chance to init and start
        self.initialTimer?.invalidate()
        self.initialTimer = NSTimer.scheduledTimerWithTimeInterval(
            20,
            target: self,
            selector: #selector(_timerFired(_:)),
            userInfo: nil,
            repeats: false)
        
        self.timer?.invalidate()
        self.timer = NSTimer.scheduledTimerWithTimeInterval(
            self.interval,
            target: self,
            selector: #selector(_timerFired(_:)),
            userInfo: nil,
            repeats: true)
    }
    
    private func stopSendingHeartbeat() {
        self.timer?.invalidate()
    }
}
