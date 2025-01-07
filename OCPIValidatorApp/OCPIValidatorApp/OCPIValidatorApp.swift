import OCPIValidator
import SwiftUI

@main
struct OCPIValidatorApp: App {
  var body: some Scene {
    WindowGroup {
      ContentView()
    }
    .windowStyle(.titleBar)
    .windowToolbarStyle(.unified)
  }
}

struct ContentView: View {
  @State private var selectedTab = 0

  var body: some View {
    TabView(selection: $selectedTab) {
      LocationValidatorView()
        .tabItem {
          Label("Locations", systemImage: "location.fill")
        }
        .tag(0)

      TokenValidatorView()
        .tabItem {
          Label("Tokens", systemImage: "key.fill")
        }
        .tag(1)

      SessionValidatorView()
        .tabItem {
          Label("Sessions", systemImage: "bolt.car.fill")
        }
        .tag(2)

      CDRValidatorView()
        .tabItem {
          Label("CDRs", systemImage: "doc.text.fill")
        }
        .tag(3)

      TariffValidatorView()
        .tabItem {
          Label("Tariffs", systemImage: "dollarsign.circle.fill")
        }
        .tag(4)
    }
    .padding()
  }
}
