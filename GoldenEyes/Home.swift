//
//  Home.swift
//  GoldenEyes
//
//  Created by Yang Xu on 2023/5/28.
//

import Foundation
import SwiftUI

struct Home: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink("By Reality Composer", value: 1)
                NavigationLink("By Pure Code", value: 2)
            }
            .navigationDestination(for: Int.self) { value in
                switch value {
                case 1:
                    RealityFileView()
                default:
                    FullCodeDemo()
                }
            }
            .navigationTitle("Demo")
        }
    }
}
