//
//  TestView.swift
//  repCounter
//
//  Created by Fatlum Cikaqi on 18.01.2026.
//

import SwiftUI

struct TestView: View {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
        Button("This is a test", systemImage: "testtube.2") {
            print("This is a Test")
        }
    }
}

#Preview {
    TestView()
}
