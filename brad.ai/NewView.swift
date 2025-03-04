import SwiftUI

struct NewView: View {
    let initialPrompt: String // First user prompt (used as conversation name)
    @State private var messages: [(Int, String, String?)] = [] // [(ID, UserPrompt, AIResponse)]
    @State private var newPromptText: String = "" // New user input
    @State private var isLoading = false // Loading state
    let trendingPrompts: [TrendingPrompt] // Trending prompts passed from HomeScreen
    @State private var conversationID: Int = 1 // Unique ID for conversation
    @State private var conversationName: String = "" // Name of conversation
    @Environment(\.colorScheme) var colorScheme // Detect dark/light mode
    @State private var showCopyAlert: Bool = false // State variable for showing alert

    var body: some View {
        VStack {
            ScrollViewReader { scrollView in
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(messages, id: \.0) { (id, userMessage, aiResponse) in
                            VStack(alignment: .leading, spacing: 8) {
                                // User Message Bubble (with Avatar)
                                HStack(alignment: .center, spacing: 8) {
                                    Image(systemName: "person.crop.circle.fill") // User Avatar
                                        .resizable()
                                        .frame(width: 24, height: 24)
                                        .foregroundColor(.primary)
                                    
                                    Text(userMessage)
                                        .font(.custom("LexendDeca-Regular", size: 18))
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                }
                                .id(id) // Assign ID for auto-scrolling
                                .contextMenu {
                                    Button(action: {
                                        UIPasteboard.general.string = userMessage
                                        showCopyAlert = true // Show success alert
                                    }) {
                                        Label("Copy", systemImage: "doc.on.doc")
                                    }
                                    
                                    Button(action: {
                                        let activityVC = UIActivityViewController(activityItems: [userMessage], applicationActivities: nil)
                                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                           let rootViewController = windowScene.windows.first?.rootViewController {
                                            rootViewController.present(activityVC, animated: true, completion: nil)
                                        }
                                    }) {
                                        Label("Share", systemImage: "square.and.arrow.up")
                                    }
                                }
                                .alert(isPresented: $showCopyAlert) {
                                    Alert(title: Text("Success"), message: Text("Message copied successfully!"), dismissButton: .default(Text("OK")))
                                }
                                
                                // AI Response Bubble (with AI Icon)
                                HStack(alignment: .top, spacing: 8) {
                                    Image("ai") // AI Icon
                                        .resizable()
                                        .frame(width: 24, height: 24)
                                        .foregroundColor(Color.green)
                                    
                                    if let aiResponse = aiResponse {
                                        VStack(alignment: .leading, spacing: 8) {
                                            VStack(alignment: .leading, spacing: 8) {
                                                let formattedResponse = formatResponse(aiResponse)
                                                
                                                Text(formattedResponse.textOutsideCode)
                                                    .font(.custom("LexendDeca-Regular", size: 16))
                                                    .foregroundColor(.primary)
                                                
                                                if !formattedResponse.codeBlocks.isEmpty {
                                                    ForEach(formattedResponse.codeBlocks, id: \.self) { codeBlock in
                                                        VStack(alignment: .leading, spacing: 8) {
                                                            ScrollView(.horizontal, showsIndicators: false) {
                                                                Text(codeBlock)
                                                                    .font(.system(.body, design: .monospaced))
                                                                    .foregroundColor(.white)
                                                                    .padding()
                                                                    .background(Color.black)
                                                                    .cornerRadius(8)
                                                            }
                                                            
                                                            HStack(spacing: 12) {
                                                                // Copy Code Button
                                                                Button(action: {
                                                                    UIPasteboard.general.string = codeBlock
                                                                    showCopyAlert = true // Show success alert
                                                                }) {
                                                                    HStack(spacing: 4) {
                                                                        Image(systemName: "doc.on.doc")
                                                                            .font(.footnote)
                                                                        Text("Copy Code")
                                                                            .font(.custom("LexendDeca-Regular", size: 12))
                                                                    }
                                                                    .foregroundColor(.primary)
                                                                    .padding(8)
                                                                    .background(.secondary.opacity(0.4))
                                                                    .cornerRadius(8)
                                                                    
                                                                }

                                                                // Share Code Button
                                                                Button(action: {
                                                                    let activityVC = UIActivityViewController(activityItems: [codeBlock], applicationActivities: nil)
                                                                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                                                       let rootViewController = windowScene.windows.first?.rootViewController {
                                                                        rootViewController.present(activityVC, animated: true, completion: nil)
                                                                    }
                                                                }) {
                                                                    HStack(spacing: 4) {
                                                                        Image(systemName: "square.and.arrow.up")
                                                                            .font(.footnote)
                                                                        Text("Share Code")
                                                                            .font(.custom("LexendDeca-Regular", size: 12))
                                                                    }
                                                                    .foregroundColor(.primary)
                                                                    .padding(8)
                                                                    .background(.secondary.opacity(0.4))
                                                                    .cornerRadius(8)
                                                                }
                                                            }
                                                            .padding(.bottom)
                                                            .alert(isPresented: $showCopyAlert) {
                                                                Alert(title: Text("Success"), message: Text("Code copied successfully!"), dismissButton: .default(Text("OK")))
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                            .padding()
                                            .background(Color.purple.opacity(0.2)) // Violet background for the full response
                                            .clipShape(RoundedRectangle(cornerRadius: 16))
                                            .contextMenu {
                                                Button(action: {
                                                    UIPasteboard.general.string = aiResponse
                                                    showCopyAlert = true // Show success alert
                                                }) {
                                                    Label("Copy", systemImage: "doc.on.doc")
                                                }
                                                
                                                Button(action: {
                                                    let activityVC = UIActivityViewController(activityItems: [aiResponse], applicationActivities: nil)
                                                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                                       let rootViewController = windowScene.windows.first?.rootViewController {
                                                        rootViewController.present(activityVC, animated: true, completion: nil)
                                                    }
                                                }) {
                                                    Label("Share", systemImage: "square.and.arrow.up")
                                                }
                                            }
                                        }
                                    } else {
                                        LoadingDotsView()
                                            .frame(height: 24)
                                    }
                                    
                                    Spacer()
                                }
                                .id(id + 1) // Assign ID for AI response
                                .alert(isPresented: $showCopyAlert) {
                                    Alert(title: Text("Success"), message: Text("Text copied successfully!"), dismissButton: .default(Text("OK")))
                                }
                            }
                        }
                    }
                    .padding()
                }
                .onAppear {
                    conversationName = initialPrompt // Set conversation name
                    addMessage(prompt: initialPrompt) // Show the first prompt on load
                }
                .onChange(of: messages.count) { _ in
                    // Auto-scroll to the latest message
                    if let lastID = messages.last?.0 {
                        withAnimation {
                            scrollView.scrollTo(lastID, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Horizontal Scroll for Trending Topics
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(trendingPrompts.indices, id: \.self) { index in
                        HStack(spacing: 8) {
                            // Number inside black circle
                            Text(trendingPrompts[index].number)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(colorScheme == .dark ? .black : .white) // Adjust text color
                                .frame(width: 30, height: 30)
                                .background(Circle().fill(colorScheme == .dark ? Color.white : Color.black)) // Adjust background color
                            
                            // Text inside rounded capsule
                            Text(trendingPrompts[index].text)
                                .font(.custom("LexendDeca-Regular", size: 14))
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .onTapGesture {
                            // Set the clicked trending prompt as the input and send it
                            newPromptText = trendingPrompts[index].text
                            sendPrompt()
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // Search Bar with dynamic button
            HStack {
                TextField("Ask Anything...", text: $newPromptText)
                    .font(.custom("LexendDeca-Regular", size: 16))
                    .padding()
                    .padding(.leading, 4)
                
                Button(action: {
                    if !newPromptText.isEmpty {
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
                .disabled(newPromptText.isEmpty) // Disable when empty
            }
            .background(.ultraThinMaterial)
            .cornerRadius(50)
            .padding(.horizontal)
        }
    }
    
    private func addMessage(prompt: String) {
        let messageID = messages.count * 2 + 1 // Assign unique ID for each conversation
        messages.append((messageID, prompt, nil)) // Append new user prompt with empty response
        isLoading = true
        
        // Perform an API call
        fetchAIResponse(for: prompt) { response in
            DispatchQueue.main.async {
                if let index = messages.firstIndex(where: { $0.0 == messageID && $0.2 == nil }) {
                    messages[index].2 = response // Update response in message list
                }
                isLoading = false
            }
        }
    }
    
    // Function to send prompt to AI API
    private func sendPrompt() {
        let prompt = newPromptText
        newPromptText = "" // Clear input field
        conversationID += 1 // Increment conversation ID
        addMessage(prompt: prompt)
    }
    
    private func fetchAIResponse(for prompt: String, completion: @escaping (String) -> Void) {
        let apiKey = ""
        let apiURL = URL(string: "https://api.groq.com/openai/v1/chat/completions")!
        
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let requestBody: [String: Any] = [
            "model": "llama-3.3-70b-versatile",
            "messages": [["role": "user", "content": prompt]],
            "temperature": 0.7,
            "max_completion_tokens": 8192,
            "stream": false,
            "top_p": 1
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody, options: [])
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("API Request failed: \(error?.localizedDescription ?? "Unknown error")")
                completion("Error: Unable to fetch response.")
                return
            }
            
            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = jsonResponse["choices"] as? [[String: Any]] {
                    var fullResponse = ""
                    for choice in choices {
                        if let message = choice["message"] as? [String: Any],
                           let content = message["content"] as? String {
                            fullResponse += content + "\n" // Append each part
                        }
                    }
                    completion(fullResponse)
                } else {
                    print("Invalid API response format: \(String(data: data, encoding: .utf8) ?? "No response")")
                    completion("Error: Unable to fetch full response.")
                }
            } catch {
                print("JSON Decoding Error: \(error.localizedDescription)")
                completion("Error: Unable to decode response.")
            }
        }.resume()
    }
    
    private func makeBold(text: String) -> AttributedString {
        var attributedString = AttributedString(text)
        
        do {
            let regex = try NSRegularExpression(pattern: "\\*\\*(.*?)\\*\\*") // Matches **bold** text
            let nsText = text as NSString // Convert to NSString for range compatibility
            let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))
            
            for match in matches.reversed() { // Reverse to avoid shifting issues
                let boldTextRange = match.range(at: 1) // Capturing group inside **
                let fullMatchRange = match.range // Full **bold** match
                
                if let boldTextRangeSwift = Range(boldTextRange, in: text),
                   let fullMatchRangeSwift = Range(fullMatchRange, in: text) {
                    
                    let boldText = String(text[boldTextRangeSwift])
                    
                    // Find range in AttributedString (conversion required)
                    if let attrRange = attributedString.range(of: String(text[fullMatchRangeSwift])) {
                        // Replace full match (**bold**) with just (bold)
                        attributedString.replaceSubrange(attrRange, with: AttributedString(boldText))
                        
                        // Apply bold styling
                        if let boldAttrRange = attributedString.range(of: boldText) {
                            attributedString[boldAttrRange].font = .boldSystemFont(ofSize: 16)
                        }
                    }
                }
            }
        } catch {
            print("Regex error: \(error.localizedDescription)")
        }
        
        return attributedString
    }
    
    private func formatResponse(_ text: String) -> (textOutsideCode: String, codeBlocks: [String]) {
        let pattern = "```[a-zA-Z]*\\n([\\s\\S]*?)```"
        var textOutsideCode = text
        var codeBlocks: [String] = []
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let nsText = text as NSString
            let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))
            
            for match in matches.reversed() {
                let range = match.range(at: 1)
                if let swiftRange = Range(range, in: text) {
                    let codeBlock = String(text[swiftRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                    codeBlocks.append(codeBlock)
                    
                    // Remove code block from the main text
                    if let fullMatchRange = Range(match.range, in: text) {
                        textOutsideCode = textOutsideCode.replacingOccurrences(of: String(text[fullMatchRange]), with: "")
                    }
                }
            }
        } catch {
            print("Regex error: \(error.localizedDescription)")
        }
        
        return (textOutsideCode.trimmingCharacters(in: .whitespacesAndNewlines), codeBlocks)
    }
}
