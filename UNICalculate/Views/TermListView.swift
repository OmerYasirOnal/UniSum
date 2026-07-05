import SwiftUI

struct TermListView: View {
    // MARK: - Properties
    @StateObject private var viewModel = TermViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var isSidebarVisible = false
    @State private var isAddTermViewVisible = false
    @State private var navigationPath = NavigationPath()
    @Environment(\.colorScheme) var colorScheme

    // Ordered class levels for grouped display.
    private let classLevelOrder: [String] = ["pre", "1", "2", "3", "4"]

    // MARK: - Body
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack(alignment: .bottomTrailing) {
                Color.appBackground.ignoresSafeArea()

                contentView

                FloatingAddButton { showAddTermPanel() }
                    .padding(DS.Spacing.lg)

                if isAddTermViewVisible {
                    AddTermPanel(isVisible: $isAddTermViewVisible, termViewModel: viewModel)
                        .zIndex(3)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .overlay { sidebarOverlay }
            .onAppear { viewModel.fetchTerms() }
        }
    }

    // MARK: - Content
    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if !viewModel.errorMessage.isEmpty {
            errorView
        } else if viewModel.terms.isEmpty {
            emptyStateView
        } else {
            termList
        }
    }

    private var termList: some View {
        let grouped = Dictionary(grouping: viewModel.terms, by: { $0.classLevel })
        return List {
            ForEach(classLevelOrder, id: \.self) { level in
                let termsForLevel = grouped[level] ?? []
                if !termsForLevel.isEmpty {
                    Section {
                        ForEach(termsForLevel) { term in
                            ZStack {
                                TermRowCard(term: term)
                                NavigationLink(destination: CourseListView(term: term)) { EmptyView() }
                                    .opacity(0)
                            }
                            .listRowInsets(EdgeInsets(top: 5, leading: DS.Spacing.md, bottom: 5, trailing: DS.Spacing.md))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                        .onDelete { offsets in
                            for offset in offsets {
                                let term = termsForLevel[offset]
                                viewModel.deleteTerm(termId: term.id) { _ in }
                            }
                        }
                    } header: {
                        SectionHeaderLabel(title: classLevelKey(for: level), systemImage: "graduationcap.fill")
                            .padding(.top, DS.Spacing.xs)
                            .padding(.bottom, 2)
                    }
                }
            }
            // Spacer so the FAB never covers the last row.
            Color.clear
                .frame(height: 84)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .environment(\.defaultMinListHeaderHeight, 0)
    }

    // MARK: - Toolbar
    private var toolbarContent: some ToolbarContent {
        Group {
            ToolbarItem(placement: .navigationBarLeading) {
                menuButton
            }
            ToolbarItem(placement: .principal) {
                if !isSidebarVisible {
                    Text(LocalizedStringKey("your_terms"))
                        .font(.headline)
                }
            }
        }
    }

    private var menuButton: some View {
        Button(action: toggleSidebar) {
            Image(systemName: isSidebarVisible ? "xmark" : "line.3.horizontal")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.brandPrimary)
        }
    }

    // MARK: - States
    private var errorView: some View {
        VStack(spacing: DS.Spacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 46))
                .foregroundStyle(Color.dangerRed)
            Text(viewModel.errorMessage)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding(DS.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyStateView: some View {
        EmptyStateView(
            systemImage: "tray.and.arrow.down",
            title: "no_terms",
            message: "no_terms_message"
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Sidebar overlay
    private var sidebarOverlay: some View {
        Group {
            if isSidebarVisible {
                ZStack {
                    Color.black.opacity(0.35)
                        .ignoresSafeArea()
                        .onTapGesture(perform: closeSidebar)

                    HStack(spacing: 0) {
                        SidebarView(isVisible: $isSidebarVisible)
                            .environmentObject(authViewModel)
                            .frame(width: UIScreen.main.bounds.width * 0.78)
                        Spacer()
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .leading)))
                .zIndex(4)
            }
        }
    }

    // MARK: - Helpers
    private func classLevelKey(for level: String) -> LocalizedStringKey {
        classLevelLocalizedKey(level)
    }

    // MARK: - Actions
    private func toggleSidebar() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            isSidebarVisible.toggle()
        }
    }

    private func closeSidebar() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            isSidebarVisible = false
        }
    }

    private func showAddTermPanel() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            isAddTermViewVisible = true
        }
    }
}

// MARK: - Term row card

struct TermRowCard: View {
    let term: Term

    var body: some View {
        HStack(spacing: DS.Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(Color.brandTint)
                    .frame(width: 48, height: 48)
                Image(systemName: "calendar")
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundStyle(Color.brandPrimary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(String(format: NSLocalizedString("term_format", comment: ""), term.termNumber))
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(classLevelLocalizedKey(term.classLevel))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.bold))
                .foregroundStyle(Color.textSecondary)
        }
        .card()
    }
}

// MARK: - Shared class-level localization

func classLevelLocalizedKey(_ level: String) -> LocalizedStringKey {
    switch level {
    case "pre": return "class_level_pre"
    case "1":   return "class_level_1"
    case "2":   return "class_level_2"
    case "3":   return "class_level_3"
    case "4":   return "class_level_4"
    default:    return LocalizedStringKey(level)
    }
}
