//
//  BrewProtocol.swift
//
//
//  Created by Tomas Harkema on 07/10/2023.
//

import BrewShared
import Foundation
import sXPC

public struct BrewProtocolRequest: Equatable, Codable {
  public let command: BrewCommand

  public init(command: BrewCommand) {
    self.command = command
  }
}

public struct BrewProtocolResponse: Equatable, Codable {
  public let output: CommandOutput

  public init(output: CommandOutput) {
    self.output = output
  }
}

public enum StreamCommand: Equatable, Codable {
  case start(BrewCommand)
}

public enum StreamCommandResponse: Equatable, Codable {
  case started(BrewCommand)
}

public protocol BrewProtocolService {
  func shell(command: BrewCommand) async throws -> CommandOutput

  func stream(command: StreamCommand) async throws -> CommandOutput
}

// MARK: Service + XPC

public typealias BrewProtocolServiceXPCConnection = XPCConnection<any BrewProtocolService, Never>
public extension BrewProtocolServiceXPCConnection {
  convenience init(xpc: XPCConnectionInit) {
    self.init(xpc, remoteInterface: .service)
  }
}

public typealias BrewProtocolServiceXPCListener = sXPC.XPCListener<any BrewProtocolService, Never>
public extension BrewProtocolServiceXPCListener {
  convenience init(xpc: XPCListenerInit) {
    self.init(xpc, exportedInterface: .service)
  }
}

// MARK: - TokenService implementation internals

/// Underlying Obj-C compatible protocol used for NSXPCConnection.
/// - note: If the file is not in the shared framework but linked to multiple targets, name it
/// explicitly like @objc(CCServiceXPC).
/// - warning: Leave it 'internal', not 'private', due to Swift-ObjC interoperability.
@objc(BrewProtocolServiceXPC) // important thing: obj-c protocol name should be the same on both
// sides of the connection
public protocol BrewProtocolServiceXPC {
  func shell(command: Data) async throws -> Data

  func stream(command: Data) async throws -> Data
}

public extension XPCInterface {
  static var service: XPCInterface<any BrewProtocolService, any BrewProtocolServiceXPC> {
    let interface = NSXPCInterface(with: (any BrewProtocolServiceXPC).self)
    return .init(interface: interface, toXPC: ServiceToXPC.init, fromXPC: ServiceFromXPC.init)
  }
}

private final class ServiceToXPC: NSObject, BrewProtocolServiceXPC {
  let instance: any BrewProtocolService
  init(_ instance: any BrewProtocolService) { self.instance = instance }

  func shell(command: Data) async throws -> Data {
    do {
      let decoded = try JSONDecoder().decode(BrewCommand.self, from: command)
      let object = try await instance.shell(command: decoded)
      let data = try JSONEncoder().encode(object)
      return data
    } catch {
      print(error)
      throw error
    }
  }

  func stream(command: Data) async throws -> Data {
    do {
      let decoded = try JSONDecoder().decode(StreamCommand.self, from: command)
      let object = try await instance.stream(command: decoded)
      let data = try JSONEncoder().encode(object)
      return data
    } catch {
      print(error)
      throw error
    }
  }
}

private struct ServiceFromXPC: BrewProtocolService {
  let proxy: any BrewProtocolServiceXPC

  func shell(command: BrewCommand) async throws -> CommandOutput {
    do {
      let encoded = try JSONEncoder().encode(command)
      let data = try await proxy.shell(command: encoded)
      let response = try JSONDecoder().decode(CommandOutput.self, from: data)
      return response
    } catch {
      print(error)
      throw error
    }
  }

  func stream(command: StreamCommand) async throws -> CommandOutput {
    do {
      let encoded = try JSONEncoder().encode(command)
      let data = try await proxy.stream(command: encoded)
      let response = try JSONDecoder().decode(CommandOutput.self, from: data)
      return response
    } catch {
      print(error)
      throw error
    }
  }
}
