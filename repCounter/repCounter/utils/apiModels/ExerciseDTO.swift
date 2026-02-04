//
//  ExerciseDTO.swift
//  repCounter
//
//  Created by Fatlum Cikaqi on 04.02.2026.
//

struct ExerciseDTO: Decodable {
    let exerciseId: String
    let name: String
    let gifUrl: String
    let targetMuscles: [String]
    let bodyParts: [String]
    let equipments: [String]
    let secondaryMuscles: [String]
    let instructions: [String]
}
