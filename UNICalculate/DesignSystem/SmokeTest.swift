//
//  SmokeTest.swift
//  UNICalculate
//
//  DEBUG-only end-to-end network smoke test. Launch the app with `-SmokeTest`
//  to exercise the real NetworkManager + Codable models against the live
//  backend (login → terms → courses → grades) and write PASS/FAIL to
//  Documents/smoke.log. Compiled out of Release.
//

#if DEBUG
import Foundation

enum SmokeTest {
    static var isActive: Bool { ProcessInfo.processInfo.arguments.contains("-SmokeTest") }

    private static let logURL: URL = {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("smoke.log")
    }()

    static func log(_ s: String) {
        NSLog("SMOKE: \(s)")
        let line = s + "\n"
        guard let data = line.data(using: .utf8) else { return }
        if FileManager.default.fileExists(atPath: logURL.path),
           let fh = try? FileHandle(forWritingTo: logURL) {
            fh.seekToEndOfFile(); fh.write(data); try? fh.close()
        } else {
            try? data.write(to: logURL)
        }
    }

    static func run() {
        try? FileManager.default.removeItem(at: logURL)
        log("START")
        let nm = NetworkManager.shared

        nm.post(endpoint: "/auth/login",
                parameters: ["email": "apitest@unisum.dev", "password": "Test1234!"]) { (r: Result<LoginResponse, Error>) in
            switch r {
            case .failure(let e):
                log("LOGIN FAIL: \(e)"); finish(false)
            case .success(let resp):
                log("LOGIN OK user=\(resp.user.email) uni=\(resp.user.university) token=\(resp.token.prefix(6))…")
                UserDefaults.standard.set(resp.token, forKey: "authToken")
                UserDefaults.standard.set(resp.user.id, forKey: "userId")

                nm.get(endpoint: "/terms/my-terms", requiresAuth: true) { (tr: Result<[Term], Error>) in
                    switch tr {
                    case .failure(let e):
                        log("TERMS FAIL: \(e)"); finish(false)
                    case .success(let terms):
                        log("TERMS OK count=\(terms.count)")
                        guard let term = terms.first else { log("no terms → PASS(login+terms)"); finish(true); return }

                        nm.get(endpoint: "/courses/term/\(term.id)", requiresAuth: true) { (cr: Result<CoursesListResponse, Error>) in
                            switch cr {
                            case .failure(let e):
                                log("COURSES FAIL: \(e)"); finish(false)
                            case .success(let cl):
                                log("COURSES OK count=\(cl.courses.count) first=\(cl.courses.first?.name ?? "-") letter=\(cl.courses.first?.letterGrade ?? "-")")
                                guard let course = cl.courses.first else { log("no courses → PASS(login+terms)"); finish(true); return }

                                nm.get(endpoint: "/grades/courses/\(course.id)/grades", requiresAuth: true) { (gr: Result<[Grade], Error>) in
                                    switch gr {
                                    case .failure(let e):
                                        log("GRADES FAIL: \(e)"); finish(false)
                                    case .success(let grades):
                                        log("GRADES OK count=\(grades.count) first=\(grades.first?.gradeType ?? "-") score=\(grades.first.map { String($0.score) } ?? "-")")
                                        finish(true)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private static func finish(_ ok: Bool) {
        log("RESULT \(ok ? "PASS ✅" : "FAIL ❌")")
    }
}
#endif
