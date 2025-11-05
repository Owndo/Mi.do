import Foundation
import NaturalLanguage

public final class MagicManager {
    private var dateManager: DateManagerProtocol
    
    init(dateManager: DateManagerProtocol) {
        self.dateManager = dateManager
    }
    
    private var calendar: Calendar {
        dateManager.calendar
    }
    
    private var selectedDate: Date {
        dateManager.selectedDate
    }
    
    private let knownActions = [
        "call", "phone", "ring", "dial", "contact",
        "send", "email", "message", "text", "mail",
        "buy", "purchase", "get", "order", "shop",
        "set", "schedule", "book", "reserve", "plan",
        "pay", "submit", "complete", "finish",
        "clean", "wash", "organize", "fix", "repair",
        "read", "study", "learn", "practice", "exercise",
        "visit", "meet", "attend", "watch", "listen"
    ]
    
    private let knownTargets = [
        // Family and people
        "mom", "dad", "family", "grandma", "grandpa", "sibling", "partner",
        "manager", "boss", "client", "customer", "team", "friend", "colleague",
        
        // Message and documents
        "email", "message", "text", "letter", "note", "report", "document",
        "proposal", "contract", "invoice", "application", "form",
        
        // Food
        "groceries", "food", "meal", "dinner", "lunch", "breakfast",
        "milk", "bread", "vegetables", "meat", "fruit", "snacks",
        
        // Devices
        "phone", "laptop", "computer", "tablet", "device", "software",
        "app", "program", "system", "website",
        
        // House and place
        "home", "house", "kitchen", "room", "bathroom", "garage",
        "car", "bike", "garden", "yard", "office", "gym",
        
        // Time and scheduling
        "alarm", "reminder", "meeting", "appointment", "conference",
        "schedule", "calendar", "deadline", "event",
        
        // Bills and finance
        "bill", "payment", "rent", "utilities", "subscription",
        "insurance", "tax", "salary", "budget",
        
        // Healt
        "doctor", "dentist", "hospital", "medicine", "prescription",
        "checkup", "appointment", "treatment",
        
        // Educations and works
        "assignment", "homework", "project", "presentation", "class",
        "course", "exam", "test", "training",
        
        // Hobbies
        "movie", "book", "music", "game", "show", "video",
        "podcast", "news", "article",
        
        // Exercise and workout
        "exercise", "workout", "training", "sport", "walk", "run"
    ]
    
    
    private let actionSynonyms: [String: String] = [
        // Calling
        "phone": "call", "ring": "call", "dial": "call", "contact": "call", "reach": "call",
        "telephone": "call", "buzz": "call", "chat": "call", "talk": "call",
        
        // Sent message
        "email": "send", "message": "send", "text": "send", "mail": "send", "write": "send",
        "compose": "send", "forward": "send", "reply": "send", "respond": "send",
        
        // Shopping
        "purchase": "buy", "get": "buy", "shop": "buy", "acquire": "buy", "obtain": "buy",
        "pick": "buy", "grab": "buy", "fetch": "buy",
        
        // Planning
        "schedule": "set", "book": "set", "reserve": "set", "plan": "set", "arrange": "set",
        "organize": "set", "setup": "set", "configure": "set", "program": "set",
        
        // Bills
        "settle": "pay", "remit": "pay", "transfer": "pay", "submit": "pay",
        
        // Cleaning
        "tidy": "clean", "wash": "clean", "scrub": "clean", "wipe": "clean", "dust": "clean",
        "vacuum": "clean", "mop": "clean", "sanitize": "clean",
        
        // Reading and learning
        "study": "read", "review": "read", "examine": "read", "browse": "read",
        
        // Fix
        "repair": "fix", "mend": "fix", "restore": "fix", "correct": "fix"
    ]
    
    private let targetSynonyms: [String: String] = [
        // Family
        "mother": "mom", "mama": "mom", "mommy": "mom", "mum": "mom", "ma": "mom",
        "father": "dad", "papa": "dad", "daddy": "dad", "pop": "dad", "pa": "dad",
        "parents": "family", "grandmother": "grandma", "grandfather": "grandpa",
        "brother": "sibling", "sister": "sibling", "spouse": "partner", "wife": "partner", "husband": "partner",
        
        // Food
        "food": "groceries", "dinner": "meal", "lunch": "meal", "breakfast": "meal",
        "shopping": "groceries", "supplies": "groceries", "items": "groceries",
        "stuff": "groceries", "things": "groceries",
        
        // Messages and documents
        "message": "email", "letter": "email", "note": "email", "memo": "email",
        "document": "report", "file": "report", "paper": "report",
        
        // Devices
        "computer": "laptop", "pc": "laptop", "machine": "laptop",
        "cellphone": "phone", "mobile": "phone", "smartphone": "phone", "device": "phone",
        
        // House and place
        "house": "home", "apartment": "home", "place": "home",
        "automobile": "car", "vehicle": "car", "truck": "car",
        
        // Work and commits
        "conference": "meeting", "appointment": "meeting", "session": "meeting",
        "boss": "manager", "supervisor": "manager", "chief": "manager",
        
        // Bills and payment
        "invoice": "bill", "payment": "bill", "charge": "bill", "fee": "bill",
        "subscription": "bill", "utilities": "bill",
        
        // Reminder
        "reminder": "alarm", "notification": "alarm", "alert": "alarm",
        
        // Workout and activity
        "workout": "exercise", "training": "exercise", "fitness": "exercise",
        "gym": "exercise", "sport": "exercise",
        
        // Health
        "physician": "doctor", "dentist": "doctor", "specialist": "doctor",
        "medication": "medicine", "pills": "medicine", "drugs": "medicine",
        
        // Stady
        "homework": "assignment", "task": "assignment", "project": "assignment",
        "lesson": "class", "course": "class", "lecture": "class"
    ]
    
    func extractTaskTitle(from text: String) -> String {
        let cleanText = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let directMatch = findDirectMatch(in: cleanText) {
            return directMatch
        }
        
        if let nlpMatch = findNLPMatch(in: cleanText) {
            return nlpMatch
        }
        
        if let keywordMatch = extractKeywords(from: cleanText) {
            return keywordMatch
        }
        
        return extractFallback(from: cleanText)
    }
    
    private func findDirectMatch(in text: String) -> String? {
        let words = text.split(separator: " ").map(String.init)
        
        var foundAction: String?
        var foundTarget: String?
        
        for word in words {
            if foundAction == nil {
                if knownActions.contains(word) {
                    foundAction = actionSynonyms[word] ?? word
                }
            }
            
            if foundTarget == nil {
                if knownTargets.contains(word) {
                    foundTarget = targetSynonyms[word] ?? word
                }
            }
            
            if foundAction != nil && foundTarget != nil {
                break
            }
        }
        
        if let action = foundAction, let target = foundTarget {
            return "\(action.capitalized) \(target)"
        }
        
        return nil
    }
    
    private func findNLPMatch(in text: String) -> String? {
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = text
        
        var verbs: [(word: String, position: Int)] = []
        var nouns: [(word: String, position: Int)] = []
        var position = 0
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex,
                             unit: .word,
                             scheme: .lexicalClass) { tag, range in
            let word = String(text[range]).lowercased()
            
            if !["i", "to", "the", "a", "an", "my", "for", "and", "or"].contains(word) {
                if tag == .verb {
                    verbs.append((word: word, position: position))
                }
                if tag == .noun {
                    nouns.append((word: word, position: position))
                }
            }
            position += 1
            return true
        }
        
        let bestVerb = selectBestWord(from: verbs, knownWords: knownActions)
        let bestNoun = selectBestWord(from: nouns, knownWords: knownTargets)
        
        if let verb = bestVerb, let noun = bestNoun {
            let action = actionSynonyms[verb] ?? verb
            let target = targetSynonyms[noun] ?? noun
            return "\(action.capitalized) \(target)"
        }
        
        return nil
    }
    
    
    private func selectBestWord(from words: [(word: String, position: Int)],
                                knownWords: [String]) -> String? {
        
        let knownWordMatches = words.filter { knownWords.contains($0.word) }
        if !knownWordMatches.isEmpty {
            return knownWordMatches.first?.word
        }
        
        return words.first?.word
    }
    
    private func extractKeywords(from text: String) -> String? {
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = text
        
        var keywords: [String] = []
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex,
                             unit: .word,
                             scheme: .lexicalClass) { tag, range in
            let word = String(text[range]).lowercased()
            
            if [.verb, .noun, .adjective].contains(tag) &&
                !["i", "to", "the", "a", "an", "my", "for", "and", "or", "need", "want", "should"].contains(word) {
                keywords.append(word)
            }
            return true
        }
        
        if keywords.count >= 2 {
            return keywords.prefix(2).map { $0.capitalized }.joined(separator: " ")
        }
        
        return nil
    }
    
    private func extractFallback(from text: String) -> String {
        let words = text.split(separator: " ")
            .map(String.init)
            .filter { word in
                !["i", "to", "the", "a", "an", "my", "for", "and", "or", "need", "want", "should", "please", "can", "you"].contains(word.lowercased())
            }
        
        let result = words.prefix(2).map { $0.capitalized }.joined(separator: " ")
        return result
    }
    
    //MARK: Date logic
    func extractDateTime(from text: String) -> DateTimeResult? {
        let cleanText = text.lowercased()
        
        let timeResult = extractTime(from: cleanText)
        
        let dateResult = extractDate(from: cleanText)
        
        if !timeResult.found && !dateResult.found {
            return nil
        }
        
        let finalDate = combineDateAndTime(date: dateResult.date, time: timeResult.time)
        
        let confidence = calculateDateTimeConfidence(
            timeFound: timeResult.found,
            dateFound: dateResult.found,
            text: cleanText
        )
        
        return DateTimeResult(
            date: finalDate,
            timeString: timeResult.timeString,
            dateString: dateResult.dateString,
            isRelative: dateResult.isRelative,
            confidence: confidence
        )
    }
    
    // MARK: - Time fetching
    private func extractTime(from text: String) -> (time: DateComponents?, timeString: String?, found: Bool) {
        let timePatterns = [
            
            #"(\d{1,2}):(\d{2})"#,
            #"(\d{1,2})\.(\d{2})"#,
            
            
            #"(\d{1,2}):(\d{2})\s*(am|pm|а\.м\.|п\.м\.)"#,
            #"(\d{1,2})\s*(am|pm|а\.м\.|п\.м\.)"#,
            
            #"(\d{1,2})\s*ч(?:асов?)?(?:\s*(\d{1,2})\s*мин(?:ут?)?)?"#,
        ]
        
        for pattern in timePatterns {
            if let match = extractTimeWithRegex(text: text, pattern: pattern) {
                return (time: match.time, timeString: match.string, found: true)
            }
        }
        
        if let relativeTime = extractRelativeTime(from: text) {
            return (time: relativeTime.time, timeString: relativeTime.string, found: true)
        }
        
        return (time: nil, timeString: nil, found: false)
    }
    
    private func extractTimeWithRegex(text: String, pattern: String) -> (time: DateComponents, string: String)? {
        let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let range = NSRange(text.startIndex..., in: text)
        
        guard let match = regex?.firstMatch(in: text, options: [], range: range) else {
            return nil
        }
        
        let matchedString = String(text[Range(match.range, in: text)!])
        
        var hour = 0
        var minute = 0
        
        if match.numberOfRanges >= 2 {
            let hourRange = Range(match.range(at: 1), in: text)!
            hour = Int(String(text[hourRange])) ?? 0
        }
        
        if match.numberOfRanges >= 3 {
            let minuteRange = Range(match.range(at: 2), in: text)!
            let minuteString = String(text[minuteRange])
            if !minuteString.lowercased().contains("am") && !minuteString.lowercased().contains("pm") {
                minute = Int(minuteString) ?? 0
            }
        }
        
        for i in 1..<match.numberOfRanges {
            let groupRange = Range(match.range(at: i), in: text)!
            let groupString = String(text[groupRange]).lowercased().trimmingCharacters(in: .whitespaces)
            
            if groupString.contains("pm") && hour < 12 {
                hour += 12
                break
            } else if groupString.contains("am") && hour == 12 {
                hour = 0
                break
            }
        }
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        return (time: dateComponents, string: matchedString)
    }
    
    private func extractRelativeTime(from text: String) -> (time: DateComponents, string: String)? {
        let timeKeywords: [String: (hour: Int, minute: Int)] = [
            "morning": (9, 0),
            "afternoon": (14, 0),
            "evening": (18, 0),
            "night": (22, 0),
            "noon": (12, 0),
            "midnight": (0, 0)
        ]
        
        let wordNumbers: [String: Int] = [
            "one": 1, "two": 2, "three": 3, "four": 4, "five": 5,
            "six": 6, "seven": 7, "eight": 8, "nine": 9, "ten": 10,
            "eleven": 11, "twelve": 12, "thirteen": 13, "fourteen": 14, "fifteen": 15,
            "sixteen": 16, "seventeen": 17, "eighteen": 18, "nineteen": 19, "twenty": 20,
            "twentyone": 21, "twentytwo": 22, "twentythree": 23, "twentyfour": 24
        ]
        
        for (keyword, time) in timeKeywords {
            if text.contains(keyword) {
                var dateComponents = DateComponents()
                dateComponents.hour = time.hour
                dateComponents.minute = time.minute
                return (time: dateComponents, string: keyword)
            }
        }
        
        let timeWordPatterns = [
            #"at\s+(one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|thirteen|fourteen|fifteen|sixteen|seventeen|eighteen|nineteen|twenty|twentyone|twentytwo|twentythree|twentyfour)\s*(?:o'clock|oclock)?"#,
            #"at\s+(one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve)\s*(am|pm)"#
        ]
        
        for pattern in timeWordPatterns {
            if let match = extractTimeWordWithRegex(text: text, pattern: pattern, wordNumbers: wordNumbers) {
                return (time: match.time, string: match.string)
            }
        }
        
        return nil
    }
    
    private func extractTimeWordWithRegex(text: String, pattern: String, wordNumbers: [String: Int]) -> (time: DateComponents, string: String)? {
        let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let range = NSRange(text.startIndex..., in: text)
        
        guard let match = regex?.firstMatch(in: text, options: [], range: range) else {
            return nil
        }
        
        let matchedString = String(text[Range(match.range, in: text)!])
        
        guard match.numberOfRanges >= 2 else { return nil }
        let numberWordRange = Range(match.range(at: 1), in: text)!
        let numberWord = String(text[numberWordRange]).lowercased()
        
        guard let hour = wordNumbers[numberWord] else { return nil }
        
        var finalHour = hour
        
        if match.numberOfRanges >= 3 {
            let ampmRange = Range(match.range(at: 2), in: text)!
            let ampm = String(text[ampmRange]).lowercased()
            
            if ampm.contains("pm") && finalHour < 12 {
                finalHour += 12
            } else if ampm.contains("am") && finalHour == 12 {
                finalHour = 0
            }
        } else {
            finalHour = determineAMPMFromContext(hour: finalHour, text: text)
        }
        
        var dateComponents = DateComponents()
        dateComponents.hour = finalHour
        dateComponents.minute = 0
        
        return (time: dateComponents, string: matchedString)
    }
    
    private func determineAMPMFromContext(hour: Int, text: String) -> Int {
        let lowerText = text.lowercased()
        
        let pmIndicators = [
            "evening", "night", "afternoon", "dinner", "lunch",
            "after work", "end of day", "sunset", "late"
        ]
        
        let amIndicators = [
            "morning", "dawn", "sunrise", "early", "breakfast",
            "start of day", "wake up", "alarm"
        ]
        
        for indicator in pmIndicators {
            if lowerText.contains(indicator) {
                return hour < 12 ? hour + 12 : hour
            }
        }
        
        for indicator in amIndicators {
            if lowerText.contains(indicator) {
                return hour == 12 ? 0 : hour
            }
        }
        
        switch hour {
        case 1...6:
            if containsWorkRelatedWords(text: lowerText) {
                return hour + 12
            }
            return hour
            
        case 7...11:
            if containsEveningActions(text: lowerText) {
                return hour + 12
            }
            if containsMorningActions(text: lowerText) {
                return hour
            }
            return hour
            
        case 12:
            if containsNightActions(text: lowerText) {
                return 0
            }
            return 12
            
        default:
            return hour
        }
    }
    
    private func containsWorkRelatedWords(text: String) -> Bool {
        let workWords = [
            "meeting", "call", "conference", "office", "work",
            "boss", "client", "manager", "team", "project"
        ]
        return workWords.contains { text.contains($0) }
    }
    
    private func containsEveningActions(text: String) -> Bool {
        let eveningActions = [
            "dinner", "movie", "date", "party", "drinks", "restaurant",
            "watch", "relax", "family time", "home"
        ]
        return eveningActions.contains { text.contains($0) }
    }
    
    private func containsMorningActions(text: String) -> Bool {
        let morningActions = [
            "breakfast", "coffee", "gym", "exercise", "jog", "run",
            "wake", "start", "commute", "school"
        ]
        return morningActions.contains { text.contains($0) }
    }
    
    private func containsNightActions(text: String) -> Bool {
        let nightActions = [
            "sleep", "bed", "midnight", "late night", "night shift"
        ]
        return nightActions.contains { text.contains($0) }
    }
    
    // MARK: - Date's fetching
    private func extractDate(from text: String) -> (date: Date?, dateString: String?, isRelative: Bool, found: Bool) {
        if let relativeDate = extractRelativeDate(from: text) {
            return (date: relativeDate.date, dateString: relativeDate.string, isRelative: true, found: true)
        }
        
        if let absoluteDate = extractAbsoluteDate(from: text) {
            return (date: absoluteDate.date, dateString: absoluteDate.string, isRelative: false, found: true)
        }
        
        if let weekdayDate = extractWeekday(from: text) {
            return (date: weekdayDate.date, dateString: weekdayDate.string, isRelative: true, found: true)
        }
        
        return (date: nil, dateString: nil, isRelative: false, found: false)
    }
    
    private func extractRelativeDate(from text: String) -> (date: Date, string: String)? {
        let today = selectedDate
        
        let relativeDates: [String: Int] = [
            "today": 0,
            "tomorrow": 1,
            "yesterday": -1
        ]
        
        for (keyword, dayOffset) in relativeDates {
            if text.contains(keyword) {
                if let date = calendar.date(byAdding: .day, value: dayOffset, to: today) {
                    return (date: date, string: keyword)
                }
            }
        }
        
        // "in N minutes"
        let inMinutesPattern = #"in\s+(\d+)\s+minutes?"#
        if let match = extractNumberWithRegex(text: text, pattern: inMinutesPattern) {
            if let date = calendar.date(byAdding: .minute, value: match.number, to: today) {
                return (date: date, string: match.string)
            }
        }
        
        // "in N hours"
        let inHoursPattern = #"in\s+(\d+)\s+hours?"#
        if let match = extractNumberWithRegex(text: text, pattern: inHoursPattern) {
            if let date = calendar.date(byAdding: .hour, value: match.number, to: today) {
                return (date: date, string: match.string)
            }
        }
        
        // "in N days"
        let inDaysPattern = #"in\s+(\d+)\s+days?"#
        if let match = extractNumberWithRegex(text: text, pattern: inDaysPattern) {
            if let date = calendar.date(byAdding: .day, value: match.number, to: today) {
                return (date: date, string: match.string)
            }
        }
        
        // "in N weeks" - НОВОЕ
        let inWeeksPattern = #"in\s+(\d+)\s+weeks?"#
        if let match = extractNumberWithRegex(text: text, pattern: inWeeksPattern) {
            if let date = calendar.date(byAdding: .weekOfYear, value: match.number, to: today) {
                return (date: date, string: match.string)
            }
        }
        
        // "in N months" - НОВОЕ
        let inMonthsPattern = #"in\s+(\d+)\s+months?"#
        if let match = extractNumberWithRegex(text: text, pattern: inMonthsPattern) {
            if let date = calendar.date(byAdding: .month, value: match.number, to: today) {
                return (date: date, string: match.string)
            }
        }
        
        
        // "next week"
        if text.contains("next week") {
            if let date = calendar.date(byAdding: .weekOfYear, value: 1, to: today) {
                return (date: date, string: "next week")
            }
        }
        
        // "next month"
        if text.contains("next month") {
            if let date = calendar.date(byAdding: .month, value: 1, to: today) {
                return (date: date, string: "next month")
            }
        }
        
        return nil
    }
    
    private func extractAbsoluteDate(from text: String) -> (date: Date, string: String)? {
        let datePatterns = [
            #"(\d{1,2})\.(\d{1,2})\.(\d{4})"#,        // 15.03.2024
            #"(\d{1,2})/(\d{1,2})/(\d{4})"#,         // 15/03/2024
            #"(\d{1,2})-(\d{1,2})-(\d{4})"#,         // 15-03-2024
            #"(\d{4})-(\d{1,2})-(\d{1,2})"#,         // 2024-03-15
        ]
        
        for pattern in datePatterns {
            if let match = extractDateWithRegex(text: text, pattern: pattern) {
                return match
            }
        }
        
        return nil
    }
    
    private func extractDateWithRegex(text: String, pattern: String) -> (date: Date, string: String)? {
        let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let range = NSRange(text.startIndex..., in: text)
        
        guard let match = regex?.firstMatch(in: text, options: [], range: range) else {
            return nil
        }
        
        let matchedString = String(text[Range(match.range, in: text)!])
        
        var day = 0, month = 0, year = 0
        
        if pattern.contains("(\\d{4})-(\\d{1,2})-(\\d{1,2})") {
            
            year = Int(String(text[Range(match.range(at: 1), in: text)!])) ?? 0
            month = Int(String(text[Range(match.range(at: 2), in: text)!])) ?? 0
            day = Int(String(text[Range(match.range(at: 3), in: text)!])) ?? 0
        } else {
            
            day = Int(String(text[Range(match.range(at: 1), in: text)!])) ?? 0
            month = Int(String(text[Range(match.range(at: 2), in: text)!])) ?? 0
            year = Int(String(text[Range(match.range(at: 3), in: text)!])) ?? 0
        }
        
        var dateComponents = DateComponents()
        dateComponents.day = day
        dateComponents.month = month
        dateComponents.year = year
        
        let calendar = Calendar.current
        if let date = calendar.date(from: dateComponents) {
            return (date: date, string: matchedString)
        }
        
        return nil
    }
    
    private func extractWeekday(from text: String) -> (date: Date, string: String)? {
        let weekdays = [
            "monday", "tuesday", "wednesday", "thursday",
            "friday", "saturday", "sunday"
        ]
        
        for weekday in weekdays {
            if text.contains(weekday) {
                let weekdaySymbols = calendar.weekdaySymbols.map { $0.lowercased() }
                
                guard let weekdayIndex = weekdaySymbols.firstIndex(of: weekday) else { continue }
                
                let targetWeekday = weekdayIndex + 1
                
                if let nextWeekdayDate = calendar.nextDate(
                    after: selectedDate,
                    matching: DateComponents(weekday: targetWeekday),
                    matchingPolicy: .nextTime
                ) {
                    return (date: nextWeekdayDate, string: weekday)
                }
            }
        }
        
        return nil
    }
    
    private func extractNumberWithRegex(text: String, pattern: String) -> (number: Int, string: String)? {
        let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let range = NSRange(text.startIndex..., in: text)
        
        guard let match = regex?.firstMatch(in: text, options: [], range: range) else {
            return nil
        }
        
        let matchedString = String(text[Range(match.range, in: text)!])
        let numberRange = Range(match.range(at: 1), in: text)!
        let number = Int(String(text[numberRange])) ?? 0
        
        return (number: number, string: matchedString)
    }
    
    private func combineDateAndTime(date: Date?, time: DateComponents?) -> Date? {
        let calendar = Calendar.current
        
        guard let baseDate = date ?? Calendar.current.date(byAdding: .day, value: 0, to: Date()) else {
            return nil
        }
        
        guard let timeComponents = time else {
            return baseDate
        }
        
        var finalComponents = calendar.dateComponents([.year, .month, .day], from: baseDate)
        finalComponents.hour = timeComponents.hour
        finalComponents.minute = timeComponents.minute
        finalComponents.second = 0
        
        return calendar.date(from: finalComponents)
    }
    
    private func calculateDateTimeConfidence(timeFound: Bool, dateFound: Bool, text: String) -> Double {
        var score = 0.0
        
        if timeFound { score += 0.5 }
        if dateFound { score += 0.5 }
        
        let timeIndicators = ["at", "before", "after"]
        for indicator in timeIndicators {
            if text.contains(indicator) {
                score += 0.1
                break
            }
        }
        
        return min(score, 1.0)
    }
}

extension MagicManager {
    func extractTaskTitleWithContext(from text: String) -> (title: String, confidence: Double) {
        let title = extractTaskTitle(from: text)
        let confidence = calculateConfidence(for: title, in: text)
        return (title: title, confidence: confidence)
    }
    
    private func calculateConfidence(for title: String, in originalText: String) -> Double {
        let titleWords = title.lowercased().split(separator: " ").map(String.init)
        let textWords = originalText.lowercased().split(separator: " ").map(String.init)
        
        var score = 0.0
        
        for titleWord in titleWords {
            if knownActions.contains(titleWord) || knownTargets.contains(titleWord) {
                score += 0.5
            }
            if textWords.contains(titleWord) {
                score += 0.3
            }
        }
        
        return min(score, 1.0)
    }
    
    func processBatch(_ texts: [String]) -> [(input: String, output: String, confidence: Double)] {
        return texts.map { text in
            let result = extractTaskTitleWithContext(from: text)
            return (input: text, output: result.title, confidence: result.confidence)
        }
    }
}

//MARK: - Extension for name
struct NameResult {
    let names: [String]
    let primaryName: String?
    let confidence: Double
    let context: String?
}

extension MagicManager {
    
    func extractNames(from text: String) -> NameResult {
        let cleanText = text.lowercased()
        
        let nerNames = extractNamesWithNER(from: text)
        
        let contextNames = extractNamesWithContext(from: cleanText)
        
        
        let knownNames = extractKnownNames(from: cleanText)
        
        
        let allNames = Array(Set(nerNames + contextNames.names + knownNames))
            .filter { !$0.isEmpty }
        
        
        let primaryName = determinePrimaryName(from: allNames, context: contextNames.context, text: cleanText)
        
        
        let confidence = calculateNameConfidence(
            nerFound: !nerNames.isEmpty,
            contextFound: !contextNames.names.isEmpty,
            knownFound: !knownNames.isEmpty,
            text: cleanText
        )
        
        return NameResult(
            names: allNames,
            primaryName: primaryName,
            confidence: confidence,
            context: contextNames.context
        )
    }
    
    // MARK: - Named Entity Recognition
    
    private func extractNamesWithNER(from text: String) -> [String] {
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text
        
        var names: [String] = []
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex,
                             unit: .word,
                             scheme: .nameType) { tag, range in
            if tag == .personalName {
                let name = String(text[range])
                if name.count > 1 && !["I", "me", "my", "you", "he", "she", "it"].contains(name) {
                    names.append(name.capitalized)
                }
            }
            return true
        }
        
        return names
    }
    
    private func extractNamesWithContext(from text: String) -> (names: [String], context: String?) {
        let patterns: [(pattern: String, context: String)] = [
            (#"call\s+([A-Za-z]+(?:\s+[A-Za-z]+)?)"#, "call"),
            (#"phone\s+([A-Za-z]+(?:\s+[A-Za-z]+)?)"#, "call"),
            (#"ring\s+([A-Za-z]+(?:\s+[A-Za-z]+)?)"#, "call"),
            (#"contact\s+([A-Za-z]+(?:\s+[A-Za-z]+)?)"#, "call"),
            
            (#"send\s+(?:email\s+)?(?:message\s+)?(?:to\s+)?([A-Za-z]+(?:\s+[A-Za-z]+)?)"#, "send"),
            (#"email\s+([A-Za-z]+(?:\s+[A-Za-z]+)?)"#, "send"),
            (#"text\s+([A-Za-z]+(?:\s+[A-Za-z]+)?)"#, "send"),
            (#"message\s+([A-Za-z]+(?:\s+[A-Za-z]+)?)"#, "send"),
            
            (#"meet\s+(?:with\s+)?([A-Za-z]+(?:\s+[A-Za-z]+)?)"#, "meet"),
            (#"meeting\s+(?:with\s+)?([A-Za-z]+(?:\s+[A-Za-z]+)?)"#, "meet"),
            (#"schedule\s+(?:with\s+)?([A-Za-z]+(?:\s+[A-Za-z]+)?)"#, "meet"),
            
            (#"invite\s+([A-Za-z]+(?:\s+[A-Za-z]+)?)"#, "invite"),
            (#"remind\s+([A-Za-z]+(?:\s+[A-Za-z]+)?)"#, "remind")
        ]
        
        var foundNames: [String] = []
        var foundContext: String?
        
        for (pattern, context) in patterns {
            if let names = extractNamesWithRegex(text: text, pattern: pattern) {
                foundNames.append(contentsOf: names)
                if foundContext == nil {
                    foundContext = context
                }
            }
        }
        
        return (names: foundNames, context: foundContext)
    }
    
    private func extractNamesWithRegex(text: String, pattern: String) -> [String]? {
        let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let range = NSRange(text.startIndex..., in: text)
        
        var names: [String] = []
        
        regex?.enumerateMatches(in: text, options: [], range: range) { match, _, _ in
            guard let match = match, match.numberOfRanges >= 2 else { return }
            
            let nameRange = Range(match.range(at: 1), in: text)!
            let nameString = String(text[nameRange]).trimmingCharacters(in: .whitespaces)
            
            if !isServiceWord(nameString) && nameString.count > 1 {
                names.append(nameString.capitalized)
            }
        }
        
        return names.isEmpty ? nil : names
    }
    
    // MARK: - Popular name
    private func extractKnownNames(from text: String) -> [String] {
        let commonNames = [
            "alex", "alexander", "andrew", "anthony", "boris", "brad", "brian", "bruce",
            "carlos", "charles", "chris", "christopher", "daniel", "david", "edward",
            "frank", "george", "henry", "jack", "james", "jason", "jeff", "jeffrey",
            "john", "jonathan", "joseph", "kevin", "mark", "martin", "matthew", "michael",
            "mike", "nick", "nicholas", "paul", "peter", "richard", "robert", "ryan",
            "sam", "samuel", "steve", "steven", "thomas", "tim", "timothy", "tom",
            "tony", "william", "will",
            
            "alice", "amanda", "amy", "andrea", "angela", "anna", "ashley", "barbara",
            "betty", "brenda", "carol", "catherine", "christine", "deborah", "diana",
            "donna", "dorothy", "elizabeth", "emily", "helen", "jennifer", "jessica",
            "julie", "karen", "kimberly", "laura", "linda", "lisa", "maria", "marie",
            "mary", "melissa", "michelle", "nancy", "patricia", "rebecca", "ruth",
            "sandra", "sarah", "sharon", "stephanie", "susan", "tiffany", "virginia"
        ]
        
        let words = text.split(separator: " ").map { String($0).lowercased() }
        var foundNames: [String] = []
        
        for word in words {
            let cleanWord = word.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
            if commonNames.contains(cleanWord) {
                foundNames.append(cleanWord.capitalized)
            }
        }
        
        return foundNames
    }
    
    // MARK: - Find a main name
    private func determinePrimaryName(from names: [String], context: String?, text: String) -> String? {
        guard !names.isEmpty else { return nil }
        
        // if only one
        if names.count == 1 {
            return names.first
        }
        
        if let context = context {
            let contextPatterns = [
                "\(context)\\s+(\\w+)",
                "\(context)\\s+(?:to\\s+)?(\\w+)"
            ]
            
            for pattern in contextPatterns {
                let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
                let range = NSRange(text.startIndex..., in: text)
                
                if let match = regex?.firstMatch(in: text, options: [], range: range),
                   match.numberOfRanges >= 2 {
                    let nameRange = Range(match.range(at: 1), in: text)!
                    let foundName = String(text[nameRange]).capitalized
                    
                    if names.contains(foundName) {
                        return foundName
                    }
                }
            }
        }
        
        return names.first
    }
    
    // MARK: - Вспомогательные методы
    
    private func isServiceWord(_ word: String) -> Bool {
        let serviceWords = [
            "to", "the", "and", "or", "but", "with", "about", "from", "into",
            "during", "before", "after", "above", "below", "up", "down", "out",
            "off", "over", "under", "again", "further", "then", "once", "here",
            "there", "when", "where", "why", "how", "all", "any", "both", "each",
            "few", "more", "most", "other", "some", "such", "only", "own", "same",
            "so", "than", "too", "very", "can", "will", "just", "should", "now",
            "my", "your", "his", "her", "its", "our", "their", "me", "you", "him",
            "them", "us", "i", "he", "she", "it", "we", "they"
        ]
        
        return serviceWords.contains(word.lowercased())
    }
    
    private func calculateNameConfidence(nerFound: Bool, contextFound: Bool, knownFound: Bool, text: String) -> Double {
        var score = 0.0
        
        if nerFound { score += 0.5 }
        if contextFound { score += 0.3 }
        if knownFound { score += 0.2 }
        
        return min(score, 1.0)
    }
}

// MARK: - Updated full function
extension MagicManager {
    func extractFullTaskInfoWithNames(from text: String) -> (
        title: String,
        dateTime: DateTimeResult?,
        names: NameResult,
        confidence: Double
    ) {
        let title = extractTaskTitle(from: text)
        let dateTime = extractDateTime(from: text)
        let names = extractNames(from: text)
        
        let titleConfidence = calculateConfidence(for: title, in: text)
        let dateTimeConfidence = dateTime?.confidence ?? 0.0
        let nameConfidence = names.confidence
        
        let overallConfidence = (titleConfidence + dateTimeConfidence + nameConfidence) / 3.0
        
        return (
            title: title,
            dateTime: dateTime,
            names: names,
            confidence: overallConfidence
        )
    }
    
    func extractTaskTitleWithNames(from text: String) -> String {
        let nameResult = extractNames(from: text)
        let baseTitle = extractTaskTitle(from: text)
        
        if let primaryName = nameResult.primaryName {
            let wordsToReplace = ["someone", "person", "guy", "girl", "friend", "colleague"]
            var title = baseTitle
            
            for word in wordsToReplace {
                title = title.replacingOccurrences(
                    of: word,
                    with: primaryName,
                    options: .caseInsensitive
                )
            }
            
            if let context = nameResult.context {
                if title.lowercased().contains(context) && !title.contains(primaryName) {
                    title = "\(context.capitalized) \(primaryName)"
                }
            }
            
            return title
        }
        
        return baseTitle
    }
}


//MARK: - Logic for extractor date
struct DateTimeResult {
    let date: Date?
    let timeString: String?
    let dateString: String?
    let isRelative: Bool
    let confidence: Double
}

// MARK: - Extension
extension MagicManager {
    func extractFullTaskInfo(from text: String) -> (title: String, dateTime: DateTimeResult?, confidence: Double) {
        let title = extractTaskTitle(from: text)
        let dateTime = extractDateTime(from: text)
        
        let titleConfidence = calculateConfidence(for: title, in: text)
        let dateTimeConfidence = dateTime?.confidence ?? 0.0
        
        let overallConfidence = (titleConfidence + dateTimeConfidence) / 2.0
        
        return (title: title, dateTime: dateTime, confidence: overallConfidence)
    }
}
