import SwiftUI

struct ExerciseSheetTemplateView: View {
    
    @State private var showText:Bool = false
    
    var body: some View {
        
        VStack {
            Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
            Button("This is a test", systemImage: "testtube.2") {
                showText = true
            }
            
            if showText {
                Text("Hoi Fabian")
                    .font(.largeTitle)
            }
        }
    }
}

#Preview {
    ExerciseSheetTemplateView()
}
