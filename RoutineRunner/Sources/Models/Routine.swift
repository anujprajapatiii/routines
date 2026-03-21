import Foundation

struct Routine: Identifiable {
    let id: UUID
    let title: String
    let steps: [Step]
    let fileName: String

    var totalDuration: TimeInterval {
        steps.reduce(0) { $0 + $1.duration }
    }

    init(id: UUID = UUID(), title: String, steps: [Step], fileName: String) {
        self.id = id
        self.title = title
        self.steps = steps
        self.fileName = fileName
    }
}

struct Step: Identifiable {
    let id: UUID
    let title: String
    let duration: TimeInterval
    let notes: [Note]

    init(id: UUID = UUID(), title: String, duration: TimeInterval, notes: [Note] = []) {
        self.id = id
        self.title = title
        self.duration = duration
        self.notes = notes
    }
}

struct Note {
    let text: String
    let link: URL?

    init(text: String, link: URL? = nil) {
        self.text = text
        self.link = link
    }
}
