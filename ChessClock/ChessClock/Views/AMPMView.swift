import SwiftUI

struct AMPMView: View {
    let isAM: Bool

    var body: some View {
        HStack(spacing: 6) {
            if isAM {
                Image(systemName: "sun.max.fill")
                    .font(.title2)
                    .foregroundColor(.yellow)
                Text("AM")
                    .font(.title2)
                    .foregroundColor(.primary)
            } else {
                Image(systemName: "moon.fill")
                    .font(.title2)
                    .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.9))
                Text("PM")
                    .font(.title2)
                    .foregroundColor(.primary)
            }
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        AMPMView(isAM: true)
        AMPMView(isAM: false)
    }
    .padding()
}
