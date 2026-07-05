//
//  DemoData.swift
//  UNICalculate
//
//  DEBUG-only preview/demo harness. When the app is launched with the
//  `-UIDemoMode` argument (or `UNISUM_DEMO=1` env var), the view models load
//  this sample data instead of hitting the network, so the authenticated flow
//  can be exercised and screenshotted offline. Fully compiled out of Release.
//

import Foundation

enum DemoMode {
    static let isActive: Bool = {
        #if DEBUG
        return ProcessInfo.processInfo.arguments.contains("-UIDemoMode")
            || ProcessInfo.processInfo.environment["UNISUM_DEMO"] == "1"
        #else
        return false
        #endif
    }()
}

#if DEBUG
enum DemoData {
    static let user = User(
        id: 1,
        email: "elif.demir@ogr.edu.tr",
        university: "Fatih Sultan Mehmet Üniversitesi",
        department: "Bilgisayar Mühendisliği"
    )

    static let terms: [Term] = [
        Term(id: 1, user_id: 1, class_level: "pre", term_number: 1),
        Term(id: 2, user_id: 1, class_level: "1", term_number: 1),
        Term(id: 3, user_id: 1, class_level: "1", term_number: 2),
        Term(id: 4, user_id: 1, class_level: "2", term_number: 1)
    ]

    static func courses(forTerm termId: Int) -> [Course] {
        switch termId {
        case 2:
            return [
                Course(id: 101, termId: 2, userId: 1, name: "Calculus I", credits: 6, average: 88, letterGrade: "BA", gpa: 3.5),
                Course(id: 102, termId: 2, userId: 1, name: "Physics I", credits: 5, average: 76, letterGrade: "BB", gpa: 3.0),
                Course(id: 103, termId: 2, userId: 1, name: "Introduction to Programming", credits: 4, average: 93, letterGrade: "AA", gpa: 4.0),
                Course(id: 104, termId: 2, userId: 1, name: "Türk Dili I", credits: 2, average: 64, letterGrade: "CB", gpa: 2.5)
            ]
        case 3:
            return [
                Course(id: 201, termId: 3, userId: 1, name: "Calculus II", credits: 6, average: 71, letterGrade: "BB", gpa: 3.0),
                Course(id: 202, termId: 3, userId: 1, name: "Data Structures", credits: 5, average: 96, letterGrade: "AA", gpa: 4.0),
                Course(id: 203, termId: 3, userId: 1, name: "Linear Algebra", credits: 4, average: 58, letterGrade: "DC", gpa: 1.5)
            ]
        case 4:
            return [
                Course(id: 301, termId: 4, userId: 1, name: "Algorithms", credits: 6, average: 84, letterGrade: "BA", gpa: 3.5),
                Course(id: 302, termId: 4, userId: 1, name: "Database Systems", credits: 5, average: 90, letterGrade: "AA", gpa: 4.0)
            ]
        default:
            return []
        }
    }

    static func grades(forCourse courseId: Int) -> [Grade] {
        let now = "2026-02-01T10:00:00Z"
        switch courseId {
        case 101:
            return [
                Grade(id: 1001, courseId: 101, gradeType: "grade_type_midterm", score: 85, weight: 40, createdAt: now, updatedAt: now),
                Grade(id: 1002, courseId: 101, gradeType: "grade_type_final", score: 90, weight: 60, createdAt: now, updatedAt: now)
            ]
        case 103:
            return [
                Grade(id: 1003, courseId: 103, gradeType: "grade_type_quiz1", score: 95, weight: 20, createdAt: now, updatedAt: now),
                Grade(id: 1004, courseId: 103, gradeType: "grade_type_project", score: 100, weight: 30, createdAt: now, updatedAt: now),
                Grade(id: 1005, courseId: 103, gradeType: "grade_type_final", score: 89, weight: 50, createdAt: now, updatedAt: now)
            ]
        case 202:
            return [
                Grade(id: 1006, courseId: 202, gradeType: "grade_type_midterm", score: 92, weight: 30, createdAt: now, updatedAt: now),
                Grade(id: 1007, courseId: 202, gradeType: "grade_type_homework", score: 100, weight: 20, createdAt: now, updatedAt: now),
                Grade(id: 1008, courseId: 202, gradeType: "grade_type_final", score: 97, weight: 50, createdAt: now, updatedAt: now)
            ]
        default:
            return []
        }
    }

    /// Returns (termGPA, totalCredits) for a term from its demo courses.
    static func termSummary(forTerm termId: Int) -> (gpa: Double, credits: Double) {
        let courses = courses(forTerm: termId)
        let credits = courses.reduce(0.0) { $0 + $1.credits }
        guard credits > 0 else { return (0, 0) }
        let weighted = courses.reduce(0.0) { $0 + ($1.gpa ?? 0) * $1.credits }
        return (weighted / credits, credits)
    }
}
#endif
