//
//  AppLogger.swift
//  PulseWorkout
//
//  Created by Robin Murray on 18/02/2026.
//


import Foundation
import os


final class ComponentLogger {
    
    private var component: String
    private var persistent: Bool
    
    init(component: String, persistent: Bool = true) {
        self.component = component
        self.persistent = persistent
    }
    
    // MARK: Public API

    func debug(_ message: String) {
        AppLogger.shared.debug(message, category: component, persistent: persistent)
    }

    func info(_ message: String) {
        AppLogger.shared.info(message, category: component, persistent: persistent)
    }

    func warning(_ message: String) {
        AppLogger.shared.warning(message, category: component, persistent: persistent)
    }

    func error(_ message: String) {
        AppLogger.shared.error(message, category: component, persistent: persistent)
    }

    func log(_ message: String) {
        AppLogger.shared.log(message, category: component, persistent: persistent)
    }
}


final class AppLogger {

    static let shared = AppLogger()

    enum Level: String {
        case debug = "DEBUG"
        case info = "INFO"
        case warning = "WARN"
        case error = "ERROR"
    }

    private let subsystem = Bundle.main.bundleIdentifier ?? "App"
//    private let osLogger: Logger
    private var osLoggers: [String: Logger] = [:]
    private let logDirectory: URL
    let currentLogURL: URL
    let exportLogURL: URL

    private let queue = DispatchQueue(label: "AppLogger.queue", qos: .utility)

    // MARK: Rotation settings

    private let maxFileSize: UInt64 = 250_000   // 250k
    private let maxArchivedFiles = 5

    // MARK: Init

    private init() {

//        osLogger = Logger(subsystem: subsystem, category: "general")
        osLoggers["general"] = Logger(subsystem: subsystem, category: "general")

        let cachePath = getCacheDirectory() ?? FileManager.default.urls(for: .cachesDirectory,
                                                                        in: .userDomainMask).first!

        logDirectory = cachePath.appendingPathComponent("Logs", isDirectory: true)
        currentLogURL = logDirectory.appendingPathComponent("current.log")
        exportLogURL = logDirectory.appendingPathComponent("pulseWorkout.log")
        createFileIfNeeded()


    }

    // MARK: Public API

    func debug(_ message: String, category: String = "general", persistent: Bool = true) {
        log(level: .debug, message: message, category: category, persistent: persistent)
    }

    func info(_ message: String, category: String = "general", persistent: Bool = true) {
        log(level: .info, message: message, category: category, persistent: persistent)
    }

    func warning(_ message: String, category: String = "general", persistent: Bool = true) {
        log(level: .warning, message: message, category: category, persistent: persistent)
    }

    func error(_ message: String, category: String = "general", persistent: Bool = true) {
        log(level: .error, message: message, category: category, persistent: persistent)
    }
    
    func log(_ message: String, category: String = "general", persistent: Bool = true) {
        log(level: .info, message: message, category: category, persistent: persistent)
    }

    
    // MARK: Export API

    func fullLogURL() -> URL {
        try? concatenateFiles(inputURLs:getAllLogFiles(),
                              outputURL: exportLogURL)
        return exportLogURL
    }
    
    
    // MARK: Core logging

    private func log(level: Level, message: String, category: String, persistent: Bool = true) {

        let timestamp = Self.timestamp()
        let thread = Thread.isMainThread ? "main" : "background"

        let formatted = "[\(timestamp)] [\(level.rawValue)] [\(category)] [\(thread)] \(message)"
        
        if osLoggers[category] == nil {
            osLoggers[category] = Logger(subsystem: subsystem, category: category)
        }
        let osLogger = osLoggers[category]!
        

        // System log
        switch level {
        case .debug:
            osLogger.debug("\(message)")
        case .info:
            osLogger.info("\(message)")
        case .warning:
            osLogger.warning("\(message)")
        case .error:
            osLogger.error("\(message)")
        }

        // File log
        if persistent {
            queue.async {
                self.rotateIfNeeded()
                self.writeToFile(formatted)
            }
        }
    }

    // MARK: File writing

    private func writeToFile(_ line: String) {

        guard let data = (line + "\n").data(using: .utf8) else { return }

        if let handle = try? FileHandle(forWritingTo: currentLogURL) {

            defer { try? handle.close() }

            _ = try? handle.seekToEnd()
            _ = try? handle.write(contentsOf: data)
        }
    }

    // MARK: Rotation

    private func rotateIfNeeded() {

        guard let attributes = try? FileManager.default.attributesOfItem(
            atPath: currentLogURL.path
        ),
        let size = attributes[.size] as? UInt64 else {
            return
        }

        guard size >= maxFileSize else { return }

        rotateLogs()
    }

    private func rotateLogs() {

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"

        let archiveName = "log_\(formatter.string(from: Date())).log"
        let archiveURL = logDirectory.appendingPathComponent(archiveName)

        try? FileManager.default.moveItem(
            at: currentLogURL,
            to: archiveURL
        )

        createFileIfNeeded()

        cleanupOldLogs()
    }

    private func cleanupOldLogs() {

        let files = try? FileManager.default.contentsOfDirectory(
            at: logDirectory,
            includingPropertiesForKeys: [.creationDateKey],
            options: []
        )

        guard let logFiles = files?
            .filter({ $0.lastPathComponent != "current.log" })
            .filter({ $0.lastPathComponent != "pulseWorkout.log" })
            .sorted(by: {
                let d1 = try? $0.resourceValues(forKeys: [.creationDateKey]).creationDate ?? Date.distantPast
                let d2 = try? $1.resourceValues(forKeys: [.creationDateKey]).creationDate ?? Date.distantPast
                return d1! > d2!
            }) else {
            return
        }

        if logFiles.count > maxArchivedFiles {

            for file in logFiles.dropFirst(maxArchivedFiles) {
                try? FileManager.default.removeItem(at: file)
            }
        }
    }

    // MARK: Setup


    private func createFileIfNeeded() {

        if !FileManager.default.fileExists(atPath: currentLogURL.path) {

            FileManager.default.createFile(
                atPath: currentLogURL.path,
                contents: nil
            )
        }
    }

    // MARK: Export

    // Return all log file URL sorted by creation date
    func getAllLogFiles() -> [URL] {

        let files = try? FileManager.default.contentsOfDirectory(
            at: logDirectory,
            includingPropertiesForKeys: [.creationDateKey],
            options: []
        )
        
        guard let logFiles = files?
            .filter({ $0.lastPathComponent != "pulseWorkout.log" })
            .sorted(by: {
                let d1 = try? $0.resourceValues(forKeys: [.creationDateKey]).creationDate ?? Date.distantPast
                let d2 = try? $1.resourceValues(forKeys: [.creationDateKey]).creationDate ?? Date.distantPast
                return d1! < d2!
            }) else {
            return []
        }
        return logFiles
    }


    func clearLogs() {

        queue.async {

            let files = try? FileManager.default.contentsOfDirectory(
                at: self.logDirectory,
                includingPropertiesForKeys: nil
            )

            files?.forEach {
                try? FileManager.default.removeItem(at: $0)
            }

            self.createFileIfNeeded()
        }
    }

    
    
    // MARK: Helpers

    private static func timestamp() -> String {

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"

        return formatter.string(from: Date())
    }
    
    private func concatenateFiles(
        inputURLs: [URL],
        outputURL: URL
    ) throws {

        var outputData = Data()

        for url in inputURLs {
            let data = try Data(contentsOf: url)
            outputData.append(data)
        }

        try outputData.write(to: outputURL)
    }
}

