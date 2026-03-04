//
//  SplashView.swift
//  GentleAlarmMobileApp
//

import SwiftUI

struct SplashView: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image("SplashImage")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()

                // Cover the diamond in the bottom right corner
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color(red: 0.8, green: 0.4, blue: 0.1),
                                        Color(red: 0.8, green: 0.4, blue: 0.1),
                                        Color(red: 0.75, green: 0.35, blue: 0.1).opacity(0)
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 80
                                )
                            )
                            .frame(width: 160, height: 160)
                            .offset(x: 50, y: 50)
                    }
                }
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    SplashView()
}
