//
//  BrewProtocolServiceImpl.swift
//
//
//  Created by Tomas Harkema on 07/10/2023.
//

import BrewHelperXPC
import BrewShared

public class BrewProtocolServiceImpl: BrewProtocolService {
  private let service = BrewProcessService()

  public func shell(command: BrewCommand) async throws -> CommandOutput {
    try await service.shell(command: command)
  }

  public func stream(command _: StreamCommand) async throws -> CommandOutput {
    fatalError()
//        return try await service.stream(command: command)
  }

//    public func requestToken(_ request: BrewProtocolRequest) async throws -> BrewProtocolResponse
//    {
//        print(request)
//        do {
//            switch request.command {
//            case .info(let infoCommand):
//                fatalError()
//
//            case .install(let packageIdentifier):
//                fatalError()
//
//            case .uninstall(let packageIdentifier):
//                fatalError()
//
//            case .upgrade(let upgradeCommand):
//                fatalError()
//
//            case .update:
//                let update = try await service.update()
//                print(update)
//
//                return .init(output: .init(stream: [
//                    .init(level: .out, rawEntry: String(describing: update))
//                ]))
//
//            case .search(let string):
//                fatalError()
//
//            case .list(let listCommand):
//                fatalError()
//
//            case .tap:
//                fatalError()
//
//            case .tapInfo(let string):
//                fatalError()
//
//            }
//        } catch {
//            print(error)
//            throw error
//        }
//    }
}
