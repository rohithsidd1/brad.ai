import SwiftUI

@main
struct brad_aiApp: App {
    @State private var showSplash = true // Track whether the splash screen should be shown
    @State private var trendingPrompts: [TrendingPrompt] = [] // Store fetched prompts

    var body: some Scene {
        WindowGroup {
            if showSplash {
                SplashScreen(trendingPrompts: $trendingPrompts) // Pass state binding
                    .onAppear {
                        // Delay transition to HomeScreen for 2 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                showSplash = false
                            }
                        }
                    }
            } else {
                HomeScreen(trendingPrompts: trendingPrompts) // Pass fetched prompts
            }
        }
    }
}

import SwiftUI

struct SplashScreen: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var scale: CGFloat = 2.5
    @State private var rotation: Double = 180
    @State private var navigateToHome = false // Controls navigation to HomeScreen
    @Binding var trendingPrompts: [TrendingPrompt] // Receive binding from brad_aiApp

    var body: some View {
        if navigateToHome {
            HomeScreen(trendingPrompts: trendingPrompts) // Pass parsed prompts
        } else {
            VStack {
                Image(colorScheme == .dark ? "3" : "4")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 320, height: 320)
                    .scaleEffect(scale)
                    .rotationEffect(.degrees(rotation))
                    .onAppear {
                        withAnimation(.easeOut(duration: 1.5)) {
                            scale = 1
                            rotation = 0
                        }
                        fetchTrendingPrompts()
                    }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // **Data Model for API Response**
    struct TrendingPromptResponse: Codable {
        let rank: Int
        let text: String
    }

    // **Fetch trending prompts function**
    func fetchTrendingPrompts() {
        let apiKey = "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"
        let apiURL = URL(string: "https://api.groq.com/openai/v1/chat/completions")!

        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let requestBody: [String: Any] = [
            "model": "llama-3.3-70b-versatile",
            "messages": [["role": "user", "content": "Provide the top 5 current prompts for user if he comes to AI chatbot in JSON array format with keys: rank and text. Ensure the response is a raw JSON array, without Markdown formatting."]],
            "temperature": 0.7,
            "max_completion_tokens": 8192,
            "stream": false,
            "top_p": 1
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody, options: [])

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("❌ Failed to fetch trending prompts: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            do {
                // Step 1: Decode JSON Response from Groq API
                if let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = jsonResponse["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let content = message["content"] as? String {

                    // Step 2: Clean Up AI Response for Safe Parsing
                    let cleanedJSON = sanitizeJSON(content)

                    // Step 3: Convert to Data for Decoding
                    guard let jsonData = cleanedJSON.data(using: .utf8) else {
                        print("❌ Failed to convert cleaned JSON string to Data.")
                        return
                    }

                    // Step 4: Decode JSON Array into TrendingPromptResponse Struct
                    let trendingData = try JSONDecoder().decode([TrendingPromptResponse].self, from: jsonData)

                    DispatchQueue.main.async {
                        trendingPrompts = trendingData.map { TrendingPrompt(number: "#\($0.rank)", text: $0.text) }

                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                navigateToHome = true
                            }
                        }
                    }
                } else {
                    print("❌ Invalid API response format: \(String(data: data, encoding: .utf8) ?? "No response")")
                }
            } catch {
                print("❌ JSON Decoding Error: \(error.localizedDescription)")
                print("🚨 RAW Response: \(String(data: data, encoding: .utf8) ?? "No response")")
            }
        }.resume()
    }

    // **Helper Function to Clean and Sanitize JSON Before Decoding**
    func sanitizeJSON(_ rawJSON: String) -> String {
        var cleaned = rawJSON
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Handle Markdown-style JSON formatting from AI
        if cleaned.hasPrefix("```json") {
            cleaned = cleaned.replacingOccurrences(of: "```json", with: "")
        }
        if cleaned.hasPrefix("```") {
            cleaned = cleaned.replacingOccurrences(of: "```", with: "")
        }
        if cleaned.hasSuffix("```") {
            cleaned = cleaned.replacingOccurrences(of: "```", with: "")
        }

        // Handle extra escape characters sometimes introduced
        cleaned = cleaned.replacingOccurrences(of: "\\", with: "")

        return cleaned
    }
}
