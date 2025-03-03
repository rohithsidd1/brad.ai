import SwiftUI

struct HomeScreen: View {
    @State private var offset: CGFloat = 0
    @State private var gradientOffset: CGFloat = -1.0 // For shimmering effect
    @State private var newViewResponse: String = "" // Stores API response
    @State private var promptText: String = ""
    @State private var showNewView = false // State to track view change
    @Environment(\.colorScheme) var colorScheme // Detect dark/light mode
    var trendingPrompts: [TrendingPrompt] // Trending prompts received from SplashScreen
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: Conversation.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Conversation.conversationID, ascending: false)]
    ) private var conversations: FetchedResults<Conversation>
    @State private var isExpanded = false // Tracks view mode (horizontal or vertical)
    
    
    private func sendPrompt() {
        guard !promptText.isEmpty else { return }
        
        // Show the new view immediately
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.5)) {
                showNewView = true
            }
        }
        
        let apiKey = "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"
        let apiURL = URL(string: "https://api.groq.com/openai/v1/chat/completions")!
        
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let requestBody: [String: Any] = [
            "model": "llama-3.3-70b-versatile",
            "messages": [["role": "user", "content": promptText]],
            "temperature": 0.7,
            "max_completion_tokens": 8192,
            "stream": false,
            "top_p": 1
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody, options: [])
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("API Request failed: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = jsonResponse["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    
                    DispatchQueue.main.async {
                        newViewResponse = content // Store AI-generated response
                    }
                } else {
                    print("Invalid API response format: \(String(data: data, encoding: .utf8) ?? "No response")")
                }
            } catch {
                print("JSON Decoding Error: \(error.localizedDescription)")
            }
        }.resume()
    }
    
    var body: some View {
        NavigationView{
            ZStack {
                // Background Gradient Balls
                FloatingBallsBackground() // Custom floating balls animation
                VStack(spacing: 0) {
                    if showNewView {
                        NewView(initialPrompt: promptText, trendingPrompts: trendingPrompts) // Pass trending prompts
                            .transition(.move(edge: .trailing))
                    } else {
                        VStack(spacing: 0) {
                            // Title
                            HStack{
                                VStack(alignment: .leading, spacing: 0) {
                                    Text("What's on your")
                                        .font(.custom("LexendDeca-SemiBold", size: 38))
                                        .foregroundColor(.primary)
                                    
                                    // Sliding text with shine effect
                                    ZStack {
                                        // Base gray text (always visible)
                                        Text("Mind?")
                                            .font(.custom("LexendDeca-SemiBold", size: 62))
                                            .foregroundColor(colorScheme == .dark ? .white.opacity(1) : .black.opacity(1)) // Adjusts based on mode
                                        
                                        // Shining overlay
                                        Text("Mind?")
                                            .font(.custom("LexendDeca-SemiBold", size: 62))
                                            .foregroundColor(.purple) // Shining color
                                            .mask(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        Color.clear,
                                                        Color.white.opacity(1), // Increased shine opacity
                                                        Color.clear
                                                    ]),
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                                .frame(width: UIScreen.main.bounds.width * 1) // Extend gradient size for smooth animation
                                                    .offset(x: gradientOffset)
                                                    .onAppear {
                                                        gradientOffset = -UIScreen.main.bounds.width // Start from off-screen
                                                        withAnimation(Animation.linear(duration: 3.0).repeatForever(autoreverses: false)) {
                                                            gradientOffset = UIScreen.main.bounds.width // Smoothly move the gradient
                                                        }
                                                    }
                                            )
                                    }
                                    .opacity(offset == 0 ? 1 : 0) // Fade out when sliding starts
                                }
                                .padding()
                                Spacer()
                            }
                            
                            Spacer()
                            
                            VStack {
                                // Trending Prompt Section
                                HStack {
                                    Text("Trending Prompts")
                                        .font(.custom("LexendDeca-Regular", size: 18))
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Text(isExpanded ? "See Less" : "See All") // Toggle button text
                                        .font(.custom("LexendDeca-Regular", size: 14))
                                        .foregroundColor(.gray)
                                        .underline()
                                        .onTapGesture {
                                            withAnimation(.easeInOut(duration: 0.3)) { // Smooth transition
                                                isExpanded.toggle()
                                            }
                                        }
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 8)
                                
                                // ScrollView that changes layout based on isExpanded state
                                if isExpanded {
                                    // Vertical List View (VStack)
                                    ScrollView {
                                        VStack(spacing: 12) {
                                            ForEach(trendingPrompts.indices, id: \.self) { index in
                                                HStack(spacing: 8) {
                                                    // Number inside black circle
                                                    Text(trendingPrompts[index].number)
                                                        .font(.system(size: 14, weight: .bold))
                                                        .foregroundColor(colorScheme == .dark ? .black : .white)
                                                        .frame(width: 30, height: 30)
                                                        .background(Circle().fill(colorScheme == .dark ? Color.white : Color.black))
                                                    
                                                    // Text inside rounded capsule
                                                    Text(trendingPrompts[index].text)
                                                        .font(.custom("LexendDeca-Regular", size: 14))
                                                        .foregroundColor(.primary)
                                                    
                                                    Spacer()
                                                }
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 8)
                                                .background(.ultraThinMaterial)
                                                .clipShape(Capsule())
                                                .onTapGesture {
                                                    promptText = trendingPrompts[index].text
                                                    sendPrompt()
                                                }
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                    .frame(maxHeight: 340) // Set max height for vertical list
                                    .padding(.top, 8)
                                } else {
                                    // Horizontal ScrollView (HStack)
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 12) {
                                            ForEach(trendingPrompts.indices, id: \.self) { index in
                                                HStack(spacing: 8) {
                                                    Text(trendingPrompts[index].number)
                                                        .font(.system(size: 14, weight: .bold))
                                                        .foregroundColor(colorScheme == .dark ? .black : .white)
                                                        .frame(width: 30, height: 30)
                                                        .background(Circle().fill(colorScheme == .dark ? Color.white : Color.black))
                                                    
                                                    Text(trendingPrompts[index].text)
                                                        .font(.custom("LexendDeca-Regular", size: 14))
                                                        .foregroundColor(.primary)
                                                }
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 8)
                                                .background(.ultraThinMaterial)
                                                .clipShape(Capsule())
                                                .onTapGesture {
                                                    promptText = trendingPrompts[index].text
                                                    sendPrompt()
                                                }
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                    .padding(.top, 8)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Enter Prompt")
                                    .font(.custom("LexendDeca-Regular", size: 18))
                                    .padding(.leading)
                                
                                // Search Bar with dynamic button
                                HStack {
                                    TextField("Enter your Prompt here", text: $promptText)
                                        .font(.custom("LexendDeca-Regular", size: 18))
                                        .padding()
                                        .padding(.leading, 4)
                                    
                                    // Icon changes based on text input
                                    Button(action: {
                                        if !promptText.isEmpty {
                                            sendPrompt()
                                        }
                                    }) {
                                        Image(systemName: "paperplane.fill")
                                            .foregroundColor(colorScheme == .dark ? .black : .white) // Adjust icon color
                                            .padding()
                                            .background(colorScheme == .dark ? Color.white : Color.black) // Adjust background color
                                            .clipShape(Circle())
                                            .padding(4)
                                    }
                                    .disabled(promptText.isEmpty) // Disables send button if text is empty
                                }
                                .background(.ultraThinMaterial)
                                .cornerRadius(50)
                                .padding(.horizontal)
                            }
                            .padding(.top)
                            .padding(.bottom)
                            
                        }
                        .transition(.move(edge: .leading)) // Animate transition
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Image(colorScheme == .dark ? "1" : "2") // Conditionally display "1" or "2"
                            .resizable()
                            .scaledToFit()
                            .frame(width: 102, height: 24)
                    }
                }
            }
        }
    }
}

// Sample Data
// Trending Prompt Model
struct TrendingPrompt: Identifiable {
    var id = UUID()
    var number: String
    var text: String
}

