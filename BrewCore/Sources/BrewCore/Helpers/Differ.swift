//
//  Differ.swift
//
//
//  Created by Tomas Harkema on 05/10/2023.
//

public struct Differ<InputType: Hashable & Identifiable, OutputType: Hashable & Identifiable>
  where InputType.ID == OutputType.ID {
  
  private let old: [InputType]
  private let new: [OutputType]

  let adds: Set<InputType.ID>
  let removes: Set<InputType.ID>
  let updates: Set<InputType.ID>

  private let oldDict: [InputType.ID: InputType]
  private let newDict: [InputType.ID: OutputType]

  init(old: any Sequence<InputType>, new: any Sequence<OutputType>) {
    self.init(old: Array(old), new: Array(new))
  }

  init(old: [InputType], new: [OutputType]) {
    self.old = old
    self.new = new

    let oldDict = Dictionary(old.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    let newDict = Dictionary(new.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

    let oldIds = Set(oldDict.keys)
    let newIds = Set(newDict.keys)

    adds = newIds.subtracting(oldIds)
    removes = oldIds.subtracting(newIds)

    let unions = newIds.union(oldIds)

    let updates: Set<InputType.ID> = Set(unions.compactMap { id in
      guard let oldItem = oldDict[id] else {
        return nil
      }
      guard let newItem = newDict[id] else {
        return nil
      }
      guard oldItem.hashValue != newItem.hashValue else {
        return nil
      }
      return newItem.id
    })

    self.updates = updates
    self.oldDict = oldDict
    self.newDict = newDict
  }

  func element(_ id: InputType.ID) -> OutputType? {
    newDict[id]
  }

  func oldElement(_ id: InputType.ID) -> InputType? {
    oldDict[id]
  }
}
