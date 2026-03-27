import SwiftUI
import Charts

// MARK: - Flashcard Model
class Flashcard: Identifiable, ObservableObject {
    let id = UUID()
    let question: String
    let answer: String
    @Published var reviewInterval: TimeInterval = 1 * 60 * 60 // 1 hour default
    @Published var lastReviewed: Date?
    @Published var difficultyLevel: Int = 2 // 1 = Easy, 2 = Medium, 3 = Hard
    
    init(question: String, answer: String) {
        self.question = question
        self.answer = answer
    }
    
    func updateReviewInterval(correct: Bool, difficulty: Int) {
        if correct {
            reviewInterval *= difficulty == 1 ? 3 : (difficulty == 2 ? 2 : 1.5) // Easy triples, Medium doubles, Hard 1.5x
        } else {
            reviewInterval = max(60, reviewInterval / 2) // Halve if incorrect, minimum 1 min
        }
        lastReviewed = Date()
    }
}

// MARK: - Flashcard Deck
class FlashcardDeck: ObservableObject {
    @Published var cards: [Flashcard] = [
        Flashcard(question: "What is SwiftUI?", answer: "A UI framework for Apple platforms."),
        Flashcard(question: "What is the capital of France?", answer: "Paris"),
        Flashcard(question: "Who wrote 'To Kill a Mockingbird'?", answer: "Harper Lee"),
        Flashcard(question: "What is the chemical symbol for gold?", answer: "Au"),
        Flashcard(question: "What is 2 + 2?", answer: "4")
    ]
    
    func addCard(question: String, answer: String) {
        let newCard = Flashcard(question: question, answer: answer)
        cards.append(newCard)
    }
    
    func getNextCard() -> Flashcard? {
        return cards.filter { card in
            guard let lastReviewed = card.lastReviewed else { return true }
            return Date().timeIntervalSince(lastReviewed) >= card.reviewInterval
        }.first
    }
    
    func resetReviewStatus() {
        cards.forEach { $0.lastReviewed = nil }
    }
}

// MARK: - Performance Report View
struct PerformanceReportView: View {
    @ObservedObject var deck: FlashcardDeck
    
    var body: some View {
        VStack {
            Text("Performance Report")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()
            
            let reviewedCards = deck.cards.filter { $0.lastReviewed != nil }
            let correctCount = reviewedCards.filter { $0.reviewInterval > 3600 }.count
            let incorrectCount = reviewedCards.count - correctCount
            
            Chart {
                BarMark(x: .value("Status", "Correct"), y: .value("Count", correctCount))
                    .foregroundStyle(.green)
                BarMark(x: .value("Status", "Incorrect"), y: .value("Count", incorrectCount))
                    .foregroundStyle(.red)
            }
            .frame(height: 200)
            .padding()
            
            Text("Total Reviewed: \(reviewedCards.count)")
            Text("Correct Answers: \(correctCount)")
            Text("Incorrect Answers: \(incorrectCount)")
        }
    }
}

// MARK: - All Flashcards View
struct AllFlashcardsView: View {
    @ObservedObject var deck: FlashcardDeck
    
    var body: some View {
        List(deck.cards) { card in
            VStack(alignment: .leading) {
                Text(card.question)
                    .font(.headline)
                Text(card.answer)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding()
        }
        .navigationTitle("All Flashcards")
    }
}

// MARK: - Main View
struct ContentView: View {
    @StateObject private var deck = FlashcardDeck()
    @State private var currentCard: Flashcard?
    @State private var showAnswer = false
    @State private var selectedDifficulty = 2
    @State private var showPerformanceReport = false
    @State private var showAllCards = false
    @State private var completedSession = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let card = currentCard {
                    VStack(spacing: 10) {
                        Text(card.question)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .padding()
                        
                        if showAnswer {
                            Text(card.answer)
                                .font(.title2)
                                .foregroundColor(.blue)
                                .padding()
                            
                            Picker("Difficulty", selection: $selectedDifficulty) {
                                Text("Easy").tag(1)
                                Text("Medium").tag(2)
                                Text("Hard").tag(3)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .padding()
                        }
                    }
                    
                    Button(action: { showAnswer.toggle() }) {
                        Text(showAnswer ? "Hide Answer" : "Show Answer")
                    }
                    
                    HStack {
                        Button("Incorrect") {
                            card.updateReviewInterval(correct: false, difficulty: selectedDifficulty)
                            nextCard()
                        }
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        
                        Button("Correct") {
                            card.updateReviewInterval(correct: true, difficulty: selectedDifficulty)
                            nextCard()
                        }
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                } else {
                    Text("All questions completed!")
                        .font(.largeTitle)
                        .padding()
                    
                    Button("Review Again") {
                        deck.resetReviewStatus()
                        nextCard()
                        showPerformanceReport = false
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    
                    Button("View Performance Report") {
                        showPerformanceReport.toggle()
                    }
                    .sheet(isPresented: $showPerformanceReport) {
                        PerformanceReportView(deck: deck)
                    }
                    
                    NavigationLink("View All Flashcards", destination: AllFlashcardsView(deck: deck))
                        .padding()
                }
            }
            .padding()
        }
        .onAppear {
            nextCard()
        }
    }
    
    func nextCard() {
        currentCard = deck.getNextCard()
        showAnswer = false
        selectedDifficulty = 2
    }
}

#Preview {
    ContentView()
}
