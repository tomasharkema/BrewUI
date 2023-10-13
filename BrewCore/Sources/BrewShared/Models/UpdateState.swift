//
//  UpdateState.swift
//
//
//  Created by Tomas Harkema on 06/10/2023.
//

public enum UpdateState {
  case updated(UpdateResult)
  case synced
}

public enum PackageState {
  case executed
  case updated
}
