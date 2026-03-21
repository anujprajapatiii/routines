import Foundation

struct MarkdownParser {
    /// Parse a markdown string into a Routine
    static func parse(_ content: String, fileName: String) -> Routine? {
        let lines = content.components(separatedBy: .newlines)

        var title: String?
        var steps: [Step] = []
        var currentStepTitle: String?
        var currentStepDuration: TimeInterval = 0
        var currentNotes: [Note] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("# ") && !trimmed.hasPrefix("## ") {
                // Routine title
                title = String(trimmed.dropFirst(2)).trimmingCharacters(in: .whitespaces)
            } else if trimmed.hasPrefix("## ") {
                // Save previous step if exists
                if let stepTitle = currentStepTitle {
                    steps.append(Step(title: stepTitle, duration: currentStepDuration, notes: currentNotes))
                }
                // Parse new step
                let stepLine = String(trimmed.dropFirst(3))
                let (name, duration) = parseStepLine(stepLine)
                currentStepTitle = name
                currentStepDuration = duration
                currentNotes = []
            } else if trimmed.hasPrefix("- ") {
                // Note for current step
                let noteText = String(trimmed.dropFirst(2))
                let note = parseNote(noteText)
                currentNotes.append(note)
            }
        }

        // Save last step
        if let stepTitle = currentStepTitle {
            steps.append(Step(title: stepTitle, duration: currentStepDuration, notes: currentNotes))
        }

        guard let routineTitle = title, !steps.isEmpty else { return nil }

        return Routine(title: routineTitle, steps: steps, fileName: fileName)
    }

    /// Extract step name and duration from a line like "Brush teeth (3m)" or "Exercise (1m 30s)"
    private static func parseStepLine(_ line: String) -> (String, TimeInterval) {
        let pattern = #"\((\d+m)?\s*(\d+s)?\)\s*$"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) else {
            // No duration found — default to 60 seconds
            return (line.trimmingCharacters(in: .whitespaces), 60)
        }

        let matchRange = Range(match.range, in: line)!
        let name = String(line[line.startIndex..<matchRange.lowerBound]).trimmingCharacters(in: .whitespaces)

        var seconds: TimeInterval = 0

        if let minuteRange = Range(match.range(at: 1), in: line) {
            let minuteStr = String(line[minuteRange]).dropLast() // remove 'm'
            seconds += (Double(minuteStr) ?? 0) * 60
        }

        if let secondRange = Range(match.range(at: 2), in: line) {
            let secondStr = String(line[secondRange]).dropLast() // remove 's'
            seconds += Double(secondStr) ?? 0
        }

        // If both are nil somehow, default to 60s
        if seconds == 0 { seconds = 60 }

        return (name, seconds)
    }

    /// Parse a note line, extracting any markdown link
    private static func parseNote(_ text: String) -> Note {
        let linkPattern = #"\[([^\]]+)\]\(([^)]+)\)"#
        guard let regex = try? NSRegularExpression(pattern: linkPattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) else {
            return Note(text: text)
        }

        // Extract link text and URL
        if let urlRange = Range(match.range(at: 2), in: text),
           let url = URL(string: String(text[urlRange])) {
            // Replace markdown link syntax with just the link text for display
            let displayText = regex.stringByReplacingMatches(
                in: text,
                range: NSRange(text.startIndex..., in: text),
                withTemplate: "$1"
            )
            return Note(text: displayText, link: url)
        }

        return Note(text: text)
    }
}
