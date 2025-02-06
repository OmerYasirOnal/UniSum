import SwiftUI

struct TermListView: View {
    // MARK: - Properties
    @StateObject private var viewModel = TermViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var isSidebarVisible = false
    @State private var isAddTermViewVisible = false
    @State private var navigationPath = NavigationPath()
    @Environment(\.colorScheme) var colorScheme
    
    // MARK: - Body
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack(alignment: .leading) {
                mainContent
                
                if isAddTermViewVisible {
                    AddTermPanel(
                        isVisible: $isAddTermViewVisible,
                        termViewModel: viewModel
                    )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .overlay { sidebarOverlay }
            .onAppear { viewModel.fetchTerms() }
        }
    }
    
    // MARK: - Main Content
    private var mainContent: some View {
        VStack {
            contentView
            addButton
        }
    }
    
    private var contentView: some View {
        VStack(spacing: 0) {
            if viewModel.isLoading {
                ProgressView()
            } else if !viewModel.errorMessage.isEmpty {
                errorView
            } else if viewModel.terms.isEmpty {
                emptyStateView
            } else {
                termListView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Toolbar
    private var toolbarContent: some ToolbarContent {
        Group {
            ToolbarItem(placement: .navigationBarLeading) {
                menuButton
            }
            
            ToolbarItem(placement: .principal) {
                titleView
            }
        }
    }
    
    private var menuButton: some View {
        Button(action: toggleSidebar) {
            Image(systemName: isSidebarVisible ? "xmark" : "line.horizontal.3")
                .imageScale(.large)
                .foregroundColor(.primary)
                .animation(.easeInOut(duration: 0.3), value: isSidebarVisible)
        }
    }
    
    private var titleView: some View {
        Group {
            if !isSidebarVisible {
                Text(LocalizedStringKey("your_terms"))
                    .font(.headline)
            }
        }
    }
    
    // MARK: - Term List
    private var termListView: some View {
        List {
            ForEach(viewModel.terms) { term in
                termListRow(term: term)
            }
            .onDelete(perform: deleteTerm)
        }
        .listStyle(PlainListStyle())
    }
    
    private func termListRow(term: Term) -> some View {
        NavigationLink(destination: CourseListView(term: term)) {
            termRow(term: term)
        }
    }
    
    private func deleteTerm(at offsets: IndexSet) {
        offsets.forEach { index in
            let term = viewModel.terms[index]
            viewModel.deleteTerm(termId: term.id) { _ in }
        }
    }
    
    private func termRow(term: Term) -> some View {
        VStack(alignment: .leading) {
            Text("Dönem \(term.termNumber)")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack {
                Text(LocalizedStringKey("class_level"))
                Text("\(term.classLevel)")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
    
    private func deleteButton(for term: Term) -> some View {
        Button(action: { deleteTerm(term) }) {
            Image(systemName: "minus.circle.fill")
                .foregroundColor(.red)
        }
        .buttonStyle(BorderlessButtonStyle())
    }
    
    // MARK: - Supporting Views
    private var errorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.red)
            Text(viewModel.errorMessage)
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundColor(.red)
        }
        .padding()
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray.fill")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            Text(LocalizedStringKey("no_terms"))
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var addButton: some View {
        Button(action: showAddTermPanel) {
            Image(systemName: "plus.circle.fill")
                .resizable()
                .frame(width: 60, height: 60)
                .foregroundColor(.accentColor)
        }
        .padding(.bottom, 30)
    }
    
    // MARK: - Sidebar Overlay
    private var sidebarOverlay: some View {
        Group {
            if isSidebarVisible {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture(perform: closeSidebar)
                    
                    HStack(spacing: 0) {
                        SidebarView(isVisible: $isSidebarVisible)
                            .environmentObject(authViewModel)
                            .frame(width: UIScreen.main.bounds.width * 0.75)
                        Spacer()
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .leading)))
                .zIndex(2)
            }
        }
    }
    
    // MARK: - Actions
    private func toggleSidebar() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.5)) {
            isSidebarVisible.toggle()
        }
    }
    
    private func closeSidebar() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.5)) {
            isSidebarVisible = false
        }
    }
    
    private func showAddTermPanel() {
        withAnimation(.spring()) {
            isAddTermViewVisible = true
        }
    }
    
    private func deleteTerm(_ term: Term) {
        viewModel.deleteTerm(termId: term.id) { _ in }
    }
}
