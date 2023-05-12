//
//  DataBaseModel.swift
//  RapsodoApp
//
//  Created by Ömer Faruk Başaran on 4.05.2023.
//

import Foundation
import RealmSwift

class Player: Object, Decodable {
    @objc dynamic var fullName: String = ""
    @objc dynamic var name: String = ""
    @objc dynamic var surname: String = ""
    let shots = List<Shot>()

    enum CodingKeys: String, CodingKey {
        case name, surname, shots
    }

    override static func primaryKey() -> String? {
        return "fullName"
    }

    convenience required init(from decoder: Decoder) throws {
        self.init()

        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.surname = try container.decode(String.self, forKey: .surname)
        self.fullName = "\(name) \(surname)"
        let shots = try container.decode([Shot].self, forKey: .shots)
        self.shots.append(objectsIn: shots)
    }
}

class Shot: Object, Decodable {
    @objc dynamic var _id: String = ""
    @objc dynamic var point: Int = 0
    @objc dynamic var segment: Int = 0
    @objc dynamic var InOut: Bool = false
    @objc dynamic var ShotPosX: Double = 0.0
    @objc dynamic var ShotPosY: Double = 0.0
    @objc dynamic var videoURL: String?

    enum CodingKeys: String, CodingKey {
        case _id, point, segment, InOut, ShotPosX, ShotPosY
    }

    override static func primaryKey() -> String? {
        return "_id"
    }

    convenience required init(from decoder: Decoder) throws {
        self.init()

        let container = try decoder.container(keyedBy: CodingKeys.self)
        self._id = try container.decode(String.self, forKey: ._id)
        self.point = try container.decode(Int.self, forKey: .point)
        self.segment = try container.decode(Int.self, forKey: .segment)
        self.InOut = try container.decode(Bool.self, forKey: .InOut)
        self.ShotPosX = try container.decode(Double.self, forKey: .ShotPosX)
        self.ShotPosY = try container.decode(Double.self, forKey: .ShotPosY)
    }
}
