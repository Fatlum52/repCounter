//
//  ExerciseSearchResponseDTO.swift
//  repCounter
//
//  Created by Fatlum Cikaqi on 04.02.2026.
//

struct ExerciseSearchResponseDTO: Decodable {
    let success: Bool
    let metadata: MetadataDTO
    let data: [ExerciseDTO]
}
